"""T-09 против настоящего бэкенда (B-18): заявка → решение администратора → уведомление; приглашение."""

from app import texts
from e2e.conftest import ADMIN_TELEGRAM_ID
from e2e.test_local_backend import as_user, drain

ADMIN = as_user(ADMIN_TELEGRAM_ID)


async def apply(bot, telegram_id: int, name: str, department: str, comment: str) -> None:
    await bot.send_text("/start", user_id=telegram_id)
    await bot.press(bot.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=telegram_id)
    await bot.send_text(name, user_id=telegram_id, username=f"user{telegram_id}")
    await bot.press(bot.telegram.sent()[-1], department, user_id=telegram_id)
    await bot.send_text(comment, user_id=telegram_id, username=f"user{telegram_id}")
    assert bot.telegram.sent()[-1].text == texts.request_sent(updated=False)


async def pending_request(backend, name: str) -> dict:
    page = (await backend.get("/api/v1/admin/access-requests", params={"status": "pending"}, headers=ADMIN)).json()
    [request] = [r for r in page["items"] if r["full_name"] == name]
    return request


async def test_request_is_approved_and_applicant_gets_menu(bot, backend):
    applicant = 555_100_001
    await drain(bot)
    await apply(bot, applicant, "Сергей Ким", "Продажи", "Менеджер по продажам")

    request = await pending_request(backend, "Сергей Ким")
    assert request["department"]["name"] == "Продажи"
    assert request["telegram_username"] == f"user{applicant}"
    to_admins = await drain(bot)
    [admin_note] = [m for m in to_admins if m.chat_id == ADMIN_TELEGRAM_ID]
    [[button]] = admin_note.reply_markup.inline_keyboard
    assert button.web_app.url.endswith("/settings/access-requests")

    await bot.send_text("/start", user_id=applicant)
    assert "на рассмотрении" in bot.telegram.sent()[-1].text

    approved = await backend.post(f"/api/v1/admin/access-requests/{request['id']}/approve", json={}, headers=ADMIN)
    assert approved.status_code == 200, approved.text
    [welcome] = [m for m in await drain(bot) if m.chat_id == applicant]
    assert [b.text for row in welcome.reply_markup.keyboard for b in row][:2] == [
        texts.BTN_SUBMIT,
        texts.BTN_MY_APPEALS,
    ]

    await bot.send_text("/start", user_id=applicant)
    assert bot.telegram.sent()[-1].text.startswith("Здравствуйте")


async def test_rejected_applicant_sees_reason_and_can_apply_again(bot, backend):
    applicant = 555_100_002
    await drain(bot)
    await apply(bot, applicant, "Олег Петров", "IT", "Подрядчик")
    request = await pending_request(backend, "Олег Петров")

    reason = {"reason": "Подрядчикам доступ не выдаём"}
    rejected = await backend.post(f"/api/v1/admin/access-requests/{request['id']}/reject", json=reason, headers=ADMIN)
    assert rejected.status_code == 200, rejected.text
    [note] = [m for m in await drain(bot) if m.chat_id == applicant]
    assert [b.text for row in note.reply_markup.inline_keyboard for b in row] == [texts.BTN_REQUEST_AGAIN]

    await bot.send_text("/start", user_id=applicant)
    status = bot.telegram.sent()[-1]
    assert "Подрядчикам доступ не выдаём" in status.text
    await bot.press(note, texts.BTN_REQUEST_AGAIN, user_id=applicant)
    assert "Как вас записать?" in bot.telegram.sent()[-1].text


async def test_invite_link_opens_menu_once(bot, backend):
    created = await backend.post("/api/v1/admin/invites", json={"role": "employee", "max_uses": 1}, headers=ADMIN)
    assert created.status_code == 201, created.text
    invite = created.json()
    start = invite["bot_link"].split("?start=", 1)[1]
    assert start == f"inv_{invite['token']}"

    await bot.send_text(f"/start {start}", user_id=555_100_003, first_name="Дина", last_name="Ахметова")
    assert bot.telegram.sent()[-1].text.startswith("Здравствуйте, Дина!")

    await bot.send_text(f"/start {start}", user_id=555_100_004)
    reply = bot.telegram.sent()[-1]
    assert reply.text == texts.INVITE_INVALID
    assert [b.text for row in reply.reply_markup.inline_keyboard for b in row] == [texts.BTN_REQUEST_ACCESS]
