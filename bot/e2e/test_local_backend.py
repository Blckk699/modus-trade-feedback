"""Бот против настоящего бэкенда: подача текстом и голосом, уведомления с ack, ответ на уточнение, код входа.

Фейки только на границе: Telegram (сессия aiogram), Claude и ElevenLabs внутри бэкенда.
"""

import json
import re

import httpx
import pytest

from app import texts
from app.notifications import deliver_pending

EMPLOYEE = "Айгерим Нурланова"  # сотрудник закупок
STRANGER = 555_000_555


def as_user(telegram_id: int) -> dict[str, str]:
    return {"X-Telegram-Id": str(telegram_id)}


async def drain(bot) -> list:
    """Доставить всю очередь бэкенда (фоновая задача бота делает то же раз в несколько секунд)."""
    before = len(bot.telegram.sent())
    while await deliver_pending(bot.bot, bot.api, bot.settings):
        pass
    return bot.telegram.sent()[before:]


async def submit_text(bot, telegram_id: int, text: str) -> str:
    await bot.send_text(text, user_id=telegram_id)
    card = bot.telegram.sent()[-1]
    assert "Черновик обращения" in card.text, card.text
    await bot.press(card, texts.BTN_DRAFT_SEND, user_id=telegram_id)
    confirmation = bot.telegram.sent()[-1].text
    number = re.search(r"A-\d{3}", confirmation)
    assert number, confirmation
    return number.group(0)


async def appeal_by_number(backend, telegram_id: int, number: str) -> dict:
    page = (await backend.get("/api/v1/appeals", params={"q": number}, headers=as_user(telegram_id))).json()
    [item] = [i for i in page["items"] if i["number"] == number]
    return (await backend.get(f"/api/v1/appeals/{item['id']}", headers=as_user(telegram_id))).json()


async def test_employee_is_recognised_and_stranger_refused(bot, people):
    await bot.send_text("/start", user_id=people[EMPLOYEE])
    await bot.send_text("/start", user_id=STRANGER)

    greeting, refusal = bot.telegram.sent()
    assert greeting.text.startswith("Здравствуйте")
    assert "нет в списке сотрудников" in refusal.text


async def test_login_code_from_bot_is_accepted_once(bot, backend, people):
    await bot.send_text(texts.BTN_LOGIN_CODE, user_id=people[EMPLOYEE])
    code = re.search(r"<code>(\d{6})</code>", bot.telegram.sent()[-1].text).group(1)

    first = await backend.post("/api/v1/auth/code", json={"code": code})
    again = await backend.post("/api/v1/auth/code", json={"code": code})

    assert first.status_code == 200, first.text
    assert first.json()["user"]["full_name"] == EMPLOYEE
    assert again.status_code == 401


async def test_text_appeal_is_created_and_notifications_are_delivered(bot, backend, people):
    await drain(bot)  # очередь от прошлых тестов
    number = await submit_text(bot, people[EMPLOYEE], "Опять в заявке на камеры не написали объект и разрешение")

    appeal = await appeal_by_number(backend, people[EMPLOYEE], number)
    assert appeal["source"] == "bot"
    assert appeal["category"]["name"] == "Межотдельное взаимодействие"
    assignee = appeal["assignee"]["full_name"]
    assert assignee in bot.telegram.sent()[-1].text  # бот назвал ответственного

    delivered = await drain(bot)
    recipients = {m.chat_id for m in delivered}
    assert people[assignee] in recipients  # «Вам назначено обращение»
    assert any(number in m.text for m in delivered)
    # Всё подтверждено: повторно очередь ничего не отдаёт.
    assert (await backend.get("/api/v1/bot/notifications/pending")).json() == []


async def test_voice_appeal_shows_transcript_and_is_created(bot, backend, people):
    await bot.send_voice(b"OggS-e2e-voice", duration=9, user_id=people[EMPLOYEE])
    card = bot.telegram.sent()[-1]
    assert "Расшифровка голосового" in card.text
    assert "1С" in card.text  # текст фейковой расшифровки бэкенда

    await bot.press(card, texts.BTN_DRAFT_SEND, user_id=people[EMPLOYEE])
    number = re.search(r"A-\d{3}", bot.telegram.sent()[-1].text).group(0)
    appeal = await appeal_by_number(backend, people[EMPLOYEE], number)
    assert appeal["text"].startswith("Счёт сначала забиваю в 1С")


async def test_too_long_voice_is_refused_by_backend_too(bot, backend, people):
    # Бот отсекает сам; здесь проверяем, что бэкенд принимает duration_seconds и отвечает так же.
    response = await backend.post(
        "/api/v1/drafts/voice",
        headers=as_user(people[EMPLOYEE]),
        files={"file": ("voice.ogg", b"OggS", "audio/ogg")},
        data={"duration_seconds": "301"},
    )
    assert (response.status_code, response.json()["error"]["code"]) == (422, "audio_too_long")


async def test_clarification_answered_in_bot_returns_appeal_to_review(bot, backend, people):
    author = people[EMPLOYEE]
    number = await submit_text(bot, author, "Не видно, на каком этапе пакет документов")
    appeal = await appeal_by_number(backend, author, number)
    responsible = people[appeal["assignee"]["full_name"]]
    await drain(bot)

    # Ответственный берёт обращение и задаёт вопрос (так сделали бы веб или мобильное приложение).
    took = await backend.post(f"/api/v1/appeals/{appeal['id']}/take", headers=as_user(responsible))
    assert took.status_code == 200, took.text
    asked = await backend.post(
        f"/api/v1/appeals/{appeal['id']}/request-info",
        headers=as_user(responsible),
        json={"question": "Какие документы теряются чаще всего?"},
    )
    assert asked.status_code == 200, asked.text

    delivered = await drain(bot)
    to_author = [m for m in delivered if m.chat_id == author]
    assert any("Какие документы теряются" in m.text for m in to_author)
    [question] = [m for m in to_author if m.reply_markup and any(
        b.text == "Ответить" for row in m.reply_markup.inline_keyboard for b in row)]

    await bot.press(question, "Ответить", user_id=author)
    await bot.send_text("Акты сверки и счета-фактуры", user_id=author)
    assert bot.telegram.sent()[-1].text == texts.clarification_sent(number)

    after = await appeal_by_number(backend, author, number)
    assert after["status"] == "in_review"
    messages = (await backend.get(f"/api/v1/appeals/{appeal['id']}/messages", headers=as_user(author))).json()
    assert any(m["text"] == "Акты сверки и счета-фактуры" for m in messages)
    answered = await drain(bot)
    assert any(m.chat_id == responsible and number in m.text for m in answered)


async def test_my_appeals_lists_what_was_submitted(bot, people):
    await bot.send_text(texts.BTN_MY_APPEALS, user_id=people[EMPLOYEE])
    reply = bot.telegram.sent()[-1].text
    assert "Мои обращения" in reply
    assert re.search(r"<b>A-\d{3}</b> · ", reply)


async def test_digest_command(bot, backend, people):
    owner = people["Ержан Касымов"]
    probe = await backend.get("/api/v1/analytics/digest", headers=as_user(owner))
    if probe.status_code == 404:
        pytest.skip("сводки в бэкенде ещё нет (B-13)")
    await bot.send_text("/digest", user_id=owner)
    assert bot.telegram.sent()[-1].text == probe.json()["text"]
