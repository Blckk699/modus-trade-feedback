"""Бот против настоящего бэкенда: подача текстом и голосом, уведомления с ack, ответ на уточнение, код входа.

Фейки только на границе: Telegram (сессия aiogram), Claude и ElevenLabs внутри бэкенда.
"""

import json
import re
from datetime import datetime, timedelta, timezone

import pytest

from app import texts, widgets
from app.notifications import deliver_pending

EMPLOYEE = "Айгерим Нурланова"  # сотрудник закупок
STRANGER = 555_000_555


def in_days(days: int) -> str:
    return (datetime.now(timezone(timedelta(hours=5))) + timedelta(days=days)).isoformat(timespec="seconds")


def as_user(telegram_id: int) -> dict[str, str]:
    return {"X-Telegram-Id": str(telegram_id)}


def shown(message) -> str:
    """Что видит пользователь: текст сообщения или подпись виджета (Bot API 10.4)."""
    return getattr(message, "text", None) or message.caption or ""


def last(bot) -> str:
    return shown(bot.telegram.messages()[-1])


def card(bot, html: str) -> tuple:
    """Последний виджет с этим шаблоном: сообщение и его chat_data."""
    widget = [w for w in bot.telegram.widgets() if w.html == html][-1]
    return widget, json.loads(widget.chat_data)


async def drain(bot) -> list:
    """Доставить всю очередь бэкенда (фоновая задача бота делает то же раз в несколько секунд)."""
    before = len(bot.telegram.messages())
    while await deliver_pending(bot.bot, bot.api, bot.settings):
        pass
    return bot.telegram.messages()[before:]


async def submit_text(bot, telegram_id: int, text: str) -> str:
    await bot.send_text(text, user_id=telegram_id)
    draft, fields = card(bot, widgets.DRAFT_CARD)
    assert fields["q"] == text and fields["x"] == "", fields
    await bot.press(draft, texts.BTN_DRAFT_SEND, user_id=telegram_id)
    _, created = card(bot, widgets.APPEAL_CARD)  # подтверждение — карточка обращения
    assert re.fullmatch(r"A-\d{3}", created["n"]), created
    return created["n"]


async def appeal_by_number(backend, telegram_id: int, number: str) -> dict:
    page = (await backend.get("/api/v1/appeals", params={"q": number}, headers=as_user(telegram_id))).json()
    [item] = [i for i in page["items"] if i["number"] == number]
    return (await backend.get(f"/api/v1/appeals/{item['id']}", headers=as_user(telegram_id))).json()


async def test_employee_is_recognised_and_stranger_offered_request(bot, people):
    await bot.send_text("/start", user_id=people[EMPLOYEE])
    await bot.send_text("/start", user_id=STRANGER)

    greeting, offer = bot.telegram.sent()
    assert greeting.text.startswith("Здравствуйте")
    assert offer.text.startswith(texts.REQUEST_INTRO)  # T-09: вместо отказа — заявка на доступ
    assert texts.LINK_HINT in offer.text  # T-11: или привязать Telegram к аккаунту по почте


async def test_login_code_from_bot_is_accepted_once(bot, backend, people):
    await bot.send_text(texts.BTN_LOGIN_CODE, user_id=people[EMPLOYEE])
    widget, fields = card(bot, widgets.LOGIN_CODE)
    code = fields["c"]
    assert widget.reply_markup.inline_keyboard[0][0].copy_text.text == code

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
    assert card(bot, widgets.APPEAL_CARD)[1]["a"] == assignee  # бот назвал ответственного

    delivered = await drain(bot)
    recipients = {m.chat_id for m in delivered}
    assert people[assignee] in recipients  # «Вам назначено обращение»
    assert any(number in shown(m) for m in delivered)
    # Всё подтверждено: повторно очередь ничего не отдаёт.
    assert (await backend.get("/api/v1/bot/notifications/pending")).json() == []


async def test_voice_appeal_shows_transcript_and_is_created(bot, backend, people):
    await bot.send_voice(b"OggS-e2e-voice", duration=9, user_id=people[EMPLOYEE])
    draft, fields = card(bot, widgets.DRAFT_CARD)
    assert fields["v"] == 1  # плашка «Расшифровка голосового»
    assert "1С" in fields["q"]  # текст фейковой расшифровки бэкенда

    await bot.press(draft, texts.BTN_DRAFT_SEND, user_id=people[EMPLOYEE])
    number = card(bot, widgets.APPEAL_CARD)[1]["n"]
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
    assert any("Какие документы теряются" in shown(m) for m in to_author)
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
    assert any(m.chat_id == responsible and number in shown(m) for m in answered)


async def test_my_appeals_lists_what_was_submitted(bot, people):
    await bot.send_text(texts.BTN_MY_APPEALS, user_id=people[EMPLOYEE])
    _, listing = card(bot, widgets.APPEAL_LIST)
    assert listing["T"] >= 1
    assert all(re.fullmatch(r"A-\d{3}", row[0]) for row in listing["i"])


async def test_digest_command(bot, backend, people):
    owner = people["Ержан Касымов"]
    probe = await backend.get("/api/v1/analytics/digest", headers=as_user(owner))
    assert probe.status_code == 200, probe.text
    await bot.send_text("/digest", user_id=owner)
    reply = bot.telegram.sent()[-1]
    assert reply.text == probe.json()["text"]
    [[button]] = reply.reply_markup.inline_keyboard
    assert button.text == texts.BTN_OPEN_ANALYTICS


async def test_digest_is_unavailable_for_employee(bot, people):
    await bot.send_text("/digest", user_id=people[EMPLOYEE])
    assert bot.telegram.sent()[-1].text == texts.DIGEST_UNAVAILABLE


async def test_morning_digest_reaches_owner_and_heads(bot, backend, people):
    await drain(bot)
    admin = people["Анна Ли"]
    # Время рассылки — «сейчас» по UTC+5; задача сверки запускается сразу, без ожидания расписания.
    now_local = datetime.now(timezone(timedelta(hours=5))).strftime("%H:%M")
    patched = await backend.patch("/api/v1/admin/settings", headers=as_user(admin), json={"digest_time": now_local})
    assert patched.status_code == 200, patched.text
    ran = await backend.post("/e2e/run-job/digest.check")
    assert ran.status_code == 200, ran.text

    delivered = await drain(bot)
    recipients = {m.chat_id for m in delivered}
    assert people["Ержан Касымов"] in recipients  # собственник — по компании
    assert people["Марат Сейткали"] in recipients  # руководитель закупок — по подразделению
    assert people[EMPLOYEE] not in recipients
    owner_digest = next(m for m in delivered if m.chat_id == people["Ержан Касымов"])
    captions = [b.text for row in owner_digest.reply_markup.inline_keyboard for b in row]
    assert captions  # кнопка перехода к аналитике
    assert (await backend.get("/api/v1/bot/notifications/pending")).json() == []


async def test_name_consent_buttons_reach_discussion(bot, backend, people):
    author = people[EMPLOYEE]
    number = await submit_text(bot, author, "Публиковать обзор завершённых улучшений раз в квартал")
    appeal = await appeal_by_number(backend, author, number)
    responsible = people[appeal["assignee"]["full_name"]]
    await drain(bot)

    # Ответственный выносит обращение на общее обсуждение (как в вебе).
    created = await backend.post(
        f"/api/v1/appeals/{appeal['id']}/discussion",
        headers=as_user(responsible),
        json={"public_text": "Публиковать раз в квартал обзор улучшений?", "deadline": in_days(7)},
    )
    if created.status_code == 404:
        pytest.skip("обсуждений в бэкенде ещё нет (B-11)")
    assert created.status_code == 201, created.text
    discussion = created.json()

    delivered = await drain(bot)
    [request] = [m for m in delivered if m.chat_id == author and "Показывать ваше имя" in shown(m)]
    await bot.press(request, "Показать имя", user_id=author)
    assert bot.telegram.sent()[-1].text == texts.NAME_SHOWN

    after = (await backend.get(f"/api/v1/discussions/{discussion['id']}", headers=as_user(author))).json()
    assert after["author_name_consent"] == "shown"
    assert after["author_display"] == EMPLOYEE
