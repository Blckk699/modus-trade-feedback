"""T-09: незнакомый аккаунт подаёт заявку на доступ или входит по приглашению (истории 71–74)."""

import json

import pytest
from aiogram.types import InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove

from app import texts
from app.notifications import deliver_pending
from tests.support import MINI_APP_URL, SERVICE_KEY, BotHarness, employee

STRANGER = 555000111
INTRO = f"{texts.REQUEST_INTRO}\n\n{texts.LINK_HINT}"
NOT_REGISTERED = "Вас нет в списке сотрудников. Обратитесь к администратору."

DEPARTMENTS = [{"id": 1, "name": "Закупки"}, {"id": 3, "name": "Продажи"}, {"id": 6, "name": "IT"}]
PENDING = {
    "id": 7,
    "status": "pending",
    "full_name": "Ильдар Хасанов",
    "telegram_username": "sergey_kim",
    "department": {"id": 3, "name": "Продажи"},
    "comment": "Менеджер по продажам",
    "created_at": "2026-11-11T09:12:00+05:00",
    "updated_at": "2026-11-11T09:12:00+05:00",
    "assigned_role": None,
    "assigned_department": None,
    "decided_by": None,
    "decided_at": None,
    "reject_reason": None,
    "user_id": None,
}


def inline_texts(markup: InlineKeyboardMarkup | None) -> list[str]:
    return [b.text for row in markup.inline_keyboard for b in row] if markup else []


def reply_texts(markup: ReplyKeyboardMarkup) -> list[str]:
    return [b.text for row in markup.keyboard for b in row]


@pytest.fixture
def backend(harness):
    b = harness.backend
    b.error("GET", "/api/v1/me", 403, "user_not_registered", NOT_REGISTERED)
    b.on("POST", "/api/v1/access-requests/mine", 200, {"state": "none", "request": None})
    b.on("GET", "/api/v1/access-requests/departments", 200, DEPARTMENTS)
    b.on("POST", "/api/v1/access-requests", 201, PENDING)
    return b


def body(request) -> dict:
    return json.loads(request.content)


# ------------------------------------------------------------------ заявка


async def test_stranger_start_offers_access_request(harness, backend):
    await harness.send_text("/start", user_id=STRANGER, first_name="Ильдар", last_name="Хасанов")

    [reply] = harness.telegram.sent()
    assert reply.text == INTRO
    assert inline_texts(reply.reply_markup) == [texts.BTN_REQUEST_ACCESS, texts.BTN_LINK_TELEGRAM]
    # Уже есть аккаунт по почте (T-11): ссылка на профиль сайта в браузере, не Mini App.
    link = reply.reply_markup.inline_keyboard[1][0]
    assert link.url == MINI_APP_URL + "/profile" and link.web_app is None
    [status] = backend.calls("POST", "/api/v1/access-requests/mine")
    assert status.headers["X-Telegram-Id"] == str(STRANGER)
    assert status.headers["X-Service-Key"] == SERVICE_KEY
    assert body(status) == {}


async def test_stranger_submits_request_with_profile_name_department_and_comment(harness, backend):
    await harness.send_text("/start", user_id=STRANGER, first_name="Ильдар", last_name="Хасанов", username="sergey_kim")
    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=STRANGER)

    ask_name = harness.telegram.sent()[-1]
    assert "Оставить: Карина" in ask_name.text  # имя из профиля того, кто нажал кнопку
    await harness.send_text("Ильдар  Хасанов", user_id=STRANGER, username="sergey_kim")

    ask_department = harness.telegram.sent()[-1]
    assert ask_department.text == texts.ASK_DEPARTMENT
    assert inline_texts(ask_department.reply_markup) == ["Закупки", "Продажи", "IT", texts.BTN_NO_DEPARTMENT]
    await harness.press(ask_department, "Продажи", user_id=STRANGER)

    assert harness.telegram.sent()[-1].text == texts.ASK_COMMENT
    await harness.send_text("Менеджер по продажам", user_id=STRANGER, username="sergey_kim")

    [submitted] = backend.calls("POST", "/api/v1/access-requests")
    assert submitted.headers["X-Telegram-Id"] == str(STRANGER)
    assert body(submitted) == {
        "full_name": "Ильдар Хасанов",
        "department_id": 3,
        "comment": "Менеджер по продажам",
        "telegram_username": "sergey_kim",
    }
    assert harness.telegram.sent()[-1].text == texts.request_sent(updated=False)


async def test_keep_profile_name_and_skip_optional_fields(harness, backend):
    await harness.send_text("/start", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.keep_name_button("Карина"), user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_NO_DEPARTMENT, user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_SKIP, user_id=STRANGER)

    [submitted] = backend.calls("POST", "/api/v1/access-requests")
    assert body(submitted) == {
        "full_name": "Карина",
        "department_id": None,
        "comment": None,
        "telegram_username": None,
    }


async def test_request_without_department_list_skips_that_step(harness, backend):
    backend.error("GET", "/api/v1/access-requests/departments", 500, "internal_error", "Сбой")

    await harness.send_text("/start", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=STRANGER)
    await harness.send_text("Ильдар Хасанов", user_id=STRANGER)

    assert harness.telegram.sent()[-1].text == texts.ASK_COMMENT


async def test_repeated_start_shows_pending_request(harness, backend):
    backend.on("POST", "/api/v1/access-requests/mine", 200, {"state": "pending", "request": PENDING})

    await harness.send_text("/start", user_id=STRANGER)

    [reply] = harness.telegram.sent()
    assert "на рассмотрении" in reply.text
    assert "Ильдар Хасанов" in reply.text and "Продажи" in reply.text and "11.11.2026 09:12" in reply.text
    assert inline_texts(reply.reply_markup) == [texts.BTN_EDIT_REQUEST]


async def test_resubmitting_pending_request_says_updated(harness, backend):
    backend.on("POST", "/api/v1/access-requests", 200, {**PENDING, "updated_at": "2026-11-11T10:00:00+05:00"})

    await harness.send_text("/start", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=STRANGER)
    await harness.send_text("Ильдар Хасанов", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], "IT", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_SKIP, user_id=STRANGER)

    assert harness.telegram.sent()[-1].text == texts.request_sent(updated=True)


async def test_rejected_request_shows_reason_and_offers_new_one(harness, backend):
    rejected = {**PENDING, "status": "rejected", "reject_reason": "Подрядчикам <доступ> не выдаём"}
    backend.on("POST", "/api/v1/access-requests/mine", 200, {"state": "rejected", "request": rejected})

    await harness.send_text("/start", user_id=STRANGER)

    [reply] = harness.telegram.sent()
    assert "отклонена" in reply.text
    assert "Подрядчикам &lt;доступ&gt; не выдаём" in reply.text
    assert inline_texts(reply.reply_markup) == [texts.BTN_REQUEST_AGAIN]


async def test_stranger_menu_buttons_lead_to_status_not_to_employee_features(harness, backend):
    await harness.send_text(texts.BTN_LOGIN_CODE, user_id=STRANGER)
    await harness.send_text("Сломался принтер на складе", user_id=STRANGER)

    replies = harness.telegram.sent()
    assert [r.text for r in replies] == [INTRO, INTRO]
    assert backend.calls("POST", "/api/v1/auth/login-codes") == []
    assert backend.calls("POST", "/api/v1/drafts/text") == []


async def test_rate_limit_message_is_shown(harness, backend):
    backend.error("POST", "/api/v1/access-requests", 429, "too_many_requests", "Слишком много заявок. Попробуйте позже.")

    await harness.send_text("/start", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=STRANGER)
    await harness.send_text("Ильдар Хасанов", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], "IT", user_id=STRANGER)
    await harness.send_text("Подрядчик", user_id=STRANGER)

    assert harness.telegram.sent()[-1].text == "Слишком много заявок. Попробуйте позже."


async def test_disabled_user_still_refused_without_form(harness):
    harness.backend.error("GET", "/api/v1/me", 403, "user_disabled", "Доступ отключён. Обратитесь к администратору.")

    await harness.send_text("/start")

    [reply] = harness.telegram.sent()
    assert reply.text == "Доступ отключён. Обратитесь к администратору."
    assert isinstance(reply.reply_markup, ReplyKeyboardRemove)
    assert harness.backend.calls("POST", "/api/v1/access-requests/mine") == []


# ------------------------------------------------------------------ приглашение


async def test_valid_invite_opens_role_menu_at_once(harness, backend):
    new_user = {**employee(STRANGER), "full_name": "Ильдар Хасанов"}
    backend.on("POST", "/api/v1/invites/accept", 200, {"created": True, "user": new_user, "session": None})

    await harness.send_text(
        "/start inv_k3J9xQ2mP0", user_id=STRANGER, first_name="Ильдар", last_name="Хасанов", username="sergey_kim"
    )

    [accepted] = backend.calls("POST", "/api/v1/invites/accept")
    assert accepted.headers["X-Telegram-Id"] == str(STRANGER)
    assert body(accepted) == {"token": "k3J9xQ2mP0", "full_name": "Ильдар Хасанов", "telegram_username": "sergey_kim"}
    [reply] = harness.telegram.sent()
    assert "Здравствуйте, Ильдар!" in reply.text
    assert reply_texts(reply.reply_markup) == [texts.BTN_SUBMIT, texts.BTN_MY_APPEALS, texts.BTN_LOGIN_CODE]
    assert backend.calls("POST", "/api/v1/access-requests/mine") == []


async def test_invalid_invite_explains_and_offers_request(harness, backend):
    backend.error("POST", "/api/v1/invites/accept", 410, "invite_invalid", "Приглашение недействительно.")

    await harness.send_text("/start inv_expired", user_id=STRANGER)

    [reply] = harness.telegram.sent()
    assert reply.text == texts.INVITE_INVALID
    assert inline_texts(reply.reply_markup) == [texts.BTN_REQUEST_ACCESS]

    await harness.press(reply, texts.BTN_REQUEST_ACCESS, user_id=STRANGER)
    assert "Как вас записать?" in harness.telegram.sent()[-1].text


async def test_registered_user_with_invite_link_just_gets_menu(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(100000004))

    await harness.send_text("/start inv_k3J9xQ2mP0")

    [reply] = harness.telegram.sent()
    assert "Здравствуйте, Карина!" in reply.text
    assert harness.backend.calls("POST", "/api/v1/invites/accept") == []


# ------------------------------------------------------------------ уведомления о заявке


def access_notification(nid: int, kind: str, text: str, telegram_id: int, user_id, buttons=(), path=None) -> dict:
    return {
        "id": nid,
        "kind": kind,
        "text": text,
        "appeal": None,
        "path": path,
        "buttons": list(buttons),
        "is_read": False,
        "created_at": "2026-11-11T09:13:00+05:00",
        "recipient": {"user_id": user_id, "telegram_id": telegram_id},
        "attempts": 0,
    }


async def test_new_request_notification_opens_requests_screen_for_admin(harness):
    note = access_notification(
        931,
        "access_request_created",
        "Новая заявка на доступ: <b>Ильдар Хасанов</b>, Продажи.",
        100000002,
        2,
        buttons=[{"type": "open_access_requests", "text": "Открыть заявки", "appeal_id": None, "discussion_id": None}],
        path="/settings/access-requests",
    )
    harness.backend.on("GET", "/api/v1/bot/notifications/pending", 200, [note])
    harness.backend.on("POST", "/api/v1/bot/notifications/931/ack", 204, None)

    assert await deliver_pending(harness.bot, harness.api, harness.settings) == 1

    [sent] = harness.telegram.sent()
    [[button]] = sent.reply_markup.inline_keyboard
    assert button.text == "Открыть заявки"
    assert button.web_app.url == MINI_APP_URL + "/settings/access-requests"


async def test_approval_notification_comes_with_role_menu(harness):
    note = access_notification(932, "access_request_approved", "Заявка одобрена. Добро пожаловать!", STRANGER, 41)
    harness.backend.on("GET", "/api/v1/bot/notifications/pending", 200, [note])
    harness.backend.on("POST", "/api/v1/bot/notifications/932/ack", 204, None)
    harness.backend.on("GET", "/api/v1/me", 200, employee(STRANGER))

    await deliver_pending(harness.bot, harness.api, harness.settings)

    [sent] = harness.telegram.sent()
    assert sent.chat_id == STRANGER
    assert reply_texts(sent.reply_markup) == [texts.BTN_SUBMIT, texts.BTN_MY_APPEALS, texts.BTN_LOGIN_CODE]
    [me] = harness.backend.calls("GET", "/api/v1/me")
    assert me.headers["X-Telegram-Id"] == str(STRANGER)


async def test_rejection_goes_by_telegram_id_and_offers_new_request(harness, backend):
    note = access_notification(
        933, "access_request_rejected", "Заявка отклонена. Причина: подрядчикам не выдаём.", STRANGER, None
    )
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [note])
    backend.on("POST", "/api/v1/bot/notifications/933/ack", 204, None)

    await deliver_pending(harness.bot, harness.api, harness.settings)

    [sent] = harness.telegram.sent()
    assert sent.chat_id == STRANGER
    assert inline_texts(sent.reply_markup) == [texts.BTN_REQUEST_AGAIN]
    assert len(backend.calls("POST", "/api/v1/bot/notifications/933/ack")) == 1

    await harness.press(sent, texts.BTN_REQUEST_AGAIN, user_id=STRANGER)
    assert "Как вас записать?" in harness.telegram.sent()[-1].text


async def test_old_request_button_after_approval_shows_menu(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(100000004))
    note = access_notification(934, "access_request_rejected", "Заявка отклонена.", 100000004, None)
    harness.backend.on("GET", "/api/v1/bot/notifications/pending", 200, [note])
    harness.backend.on("POST", "/api/v1/bot/notifications/934/ack", 204, None)
    await deliver_pending(harness.bot, harness.api, harness.settings)

    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_AGAIN)

    reply = harness.telegram.sent()[-1]
    assert reply.text == texts.ALREADY_IN
    assert reply_texts(reply.reply_markup) == [texts.BTN_SUBMIT, texts.BTN_MY_APPEALS, texts.BTN_LOGIN_CODE]


async def test_voice_in_the_middle_of_form_keeps_it(harness, backend):
    await harness.send_text("/start", user_id=STRANGER)
    await harness.press(harness.telegram.sent()[-1], texts.BTN_REQUEST_ACCESS, user_id=STRANGER)
    await harness.send_voice(b"ogg", duration=3, user_id=STRANGER)

    assert harness.telegram.sent()[-1].text == texts.FORM_NEEDS_TEXT
    assert backend.calls("POST", "/api/v1/drafts/voice") == []

    await harness.send_text("Ильдар Хасанов", user_id=STRANGER)
    assert harness.telegram.sent()[-1].text == texts.ASK_DEPARTMENT


async def test_link_hint_goes_to_web_url_when_set(backend):
    h = BotHarness(mini_app_url=None)
    h.settings.web_url = "https://modus.example/"
    h.backend.routes.update(backend.routes)
    try:
        await h.send_text("/start", user_id=STRANGER)
    finally:
        await h.close()

    [reply] = h.telegram.sent()
    assert reply.reply_markup.inline_keyboard[1][0].url == "https://modus.example/profile"


async def test_no_site_address_means_no_link_button(backend):
    h = BotHarness(mini_app_url=None)
    h.backend.routes.update(backend.routes)
    try:
        await h.send_text("/start", user_id=STRANGER)
    finally:
        await h.close()

    [reply] = h.telegram.sent()
    assert inline_texts(reply.reply_markup) == [texts.BTN_REQUEST_ACCESS]
