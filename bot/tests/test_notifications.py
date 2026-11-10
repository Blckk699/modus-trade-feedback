"""T-04: уведомления из очереди бэкенда, ответ на уточняющий вопрос, согласие на имя."""

import json

import pytest
from aiogram.exceptions import TelegramForbiddenError, TelegramNetworkError

from app import texts
from app.notifications import deliver_pending
from tests.support import MINI_APP_URL, SERVICE_KEY, employee

USER = 100000006

CLARIFICATION = {
    "id": 905,
    "kind": "clarification_requested",
    "text": "По обращению <b>A-005</b> вопрос от ответственного:\nКакие документы теряются?",
    "appeal": {"id": 5, "number": "A-005", "summary": "Не видно этап", "status": "awaiting_info", "type": "problem"},
    "path": "/appeals/5",
    "buttons": [
        {"type": "reply_clarification", "text": "Ответить", "appeal_id": 5, "discussion_id": None},
        {"type": "open_appeal", "text": "Открыть обращение", "appeal_id": 5, "discussion_id": None},
    ],
    "is_read": False,
    "created_at": "2026-11-09T12:40:00+05:00",
    "recipient": {"user_id": 6, "telegram_id": USER},
    "attempts": 0,
}
CONSENT = {
    "id": 906,
    "kind": "name_consent_request",
    "text": "Ваше обращение <b>A-020</b> вынесено на общее обсуждение.\nПоказывать ваше имя?",
    "appeal": {"id": 20, "number": "A-020", "summary": "Обзор улучшений", "status": "in_review", "type": "suggestion"},
    "path": "/discussions/12",
    "buttons": [
        {"type": "name_consent_show", "text": "Показать имя", "appeal_id": 20, "discussion_id": 12},
        {"type": "name_consent_hide", "text": "Скрыть", "appeal_id": 20, "discussion_id": 12},
    ],
    "is_read": False,
    "created_at": "2026-11-10T13:00:00+05:00",
    "recipient": {"user_id": 6, "telegram_id": USER},
    "attempts": 0,
}
STATUS_CHANGED = {
    **CLARIFICATION,
    "id": 907,
    "kind": "status_changed",
    "text": "Обращение <b>A-005</b>: статус «В работе».",
    "buttons": [],
}


@pytest.fixture
def backend(harness):
    b = harness.backend
    b.on("GET", "/api/v1/me", 200, employee(USER))
    b.on("POST", "/api/v1/bot/notifications/905/ack", 204, None)
    b.on("POST", "/api/v1/bot/notifications/906/ack", 204, None)
    b.on("POST", "/api/v1/bot/notifications/907/ack", 204, None)
    b.on("POST", "/api/v1/bot/notifications/905/fail", 204, None)
    return b


def body(request) -> dict:
    return json.loads(request.content)


async def deliver(harness) -> int:
    return await deliver_pending(harness.bot, harness.api, harness.settings)


async def test_queue_is_delivered_and_acknowledged(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION, CONSENT])

    assert await deliver(harness) == 2

    [pending] = backend.calls("GET", "/api/v1/bot/notifications/pending")
    assert pending.headers["X-Service-Key"] == SERVICE_KEY
    assert "X-Telegram-Id" not in pending.headers
    first, second = harness.telegram.sent()
    assert first.chat_id == USER and "A-005" in first.text
    [ack] = backend.calls("POST", "/api/v1/bot/notifications/905/ack")
    assert body(ack) == {"telegram_message_id": harness.telegram.message_id_of(first)}
    assert backend.calls("POST", "/api/v1/bot/notifications/906/ack")


async def test_every_appeal_notification_opens_card_in_mini_app(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION, STATUS_CHANGED])

    await deliver(harness)

    with_button, without_buttons = harness.telegram.sent()
    urls = [b.web_app.url for row in with_button.reply_markup.inline_keyboard for b in row if b.web_app]
    assert urls == [MINI_APP_URL + "/appeals/5"]
    # Бэкенд не прислал кнопок — бот всё равно добавляет переход к карточке.
    [[button]] = without_buttons.reply_markup.inline_keyboard
    assert button.text == texts.BTN_OPEN_APPEAL
    assert button.web_app.url == MINI_APP_URL + "/appeals/5"


async def test_failed_delivery_is_reported_for_retry(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION])
    harness.telegram.errors[USER] = lambda m: TelegramNetworkError(m, "timeout")

    assert await deliver(harness) == 0

    [fail] = backend.calls("POST", "/api/v1/bot/notifications/905/fail")
    assert body(fail)["permanent"] is False
    assert backend.calls("POST", "/api/v1/bot/notifications/905/ack") == []


async def test_blocked_bot_is_permanent_failure(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION])
    harness.telegram.errors[USER] = lambda m: TelegramForbiddenError(m, "Forbidden: bot was blocked by the user")

    await deliver(harness)

    [fail] = backend.calls("POST", "/api/v1/bot/notifications/905/fail")
    assert body(fail)["permanent"] is True


async def test_reply_button_sends_answer_to_appeal_messages(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION])
    backend.on("POST", "/api/v1/appeals/5/messages", 201, {"id": 502})
    await deliver(harness)
    [notification] = harness.telegram.sent()

    await harness.press(notification, "Ответить", user_id=USER)
    await harness.send_text("Акты сверки и счета-фактуры", user_id=USER)

    [request] = backend.calls("POST", "/api/v1/appeals/5/messages")
    assert request.headers["X-Telegram-Id"] == str(USER)
    assert body(request) == {"text": "Акты сверки и счета-фактуры"}
    assert harness.telegram.sent()[-1].text == texts.clarification_sent("A-005")
    assert backend.calls("POST", "/api/v1/drafts/text") == []  # ответ не стал новым обращением


async def test_swipe_reply_to_question_goes_to_appeal(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION])
    backend.on("POST", "/api/v1/appeals/5/messages", 201, {"id": 503})
    await deliver(harness)
    [notification] = harness.telegram.sent()

    await harness.send_reply("Счета-фактуры", to=notification, user_id=USER)

    [request] = backend.calls("POST", "/api/v1/appeals/5/messages")
    assert body(request) == {"text": "Счета-фактуры"}


async def test_menu_button_cancels_waiting_for_answer(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CLARIFICATION])
    backend.on("POST", "/api/v1/auth/login-codes", 201, {"code": "1", "expires_at": "x", "ttl_seconds": 60})
    backend.on("POST", "/api/v1/drafts/text", 503, {"error": {"code": "ai_unavailable", "message": "Нет", "details": None}})
    await deliver(harness)
    [notification] = harness.telegram.sent()

    await harness.press(notification, "Ответить", user_id=USER)
    await harness.send_text(texts.BTN_LOGIN_CODE, user_id=USER)
    await harness.send_text("Новая проблема", user_id=USER)

    assert backend.calls("POST", "/api/v1/appeals/5/messages") == []
    assert len(backend.calls("POST", "/api/v1/drafts/text")) == 1


async def test_name_consent_buttons(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CONSENT])
    backend.on("POST", "/api/v1/discussions/12/name-consent", 200, {"id": 12})
    await deliver(harness)
    [notification] = harness.telegram.sent()
    captions = [b.text for row in notification.reply_markup.inline_keyboard for b in row]
    assert captions[:2] == ["Показать имя", "Скрыть"]

    await harness.press(notification, "Скрыть", user_id=USER)

    [request] = backend.calls("POST", "/api/v1/discussions/12/name-consent")
    assert body(request) == {"show_name": False}
    assert harness.telegram.sent()[-1].text == texts.NAME_HIDDEN


async def test_api_error_in_callback_alert_is_plain_text(harness, backend):
    backend.error("GET", "/api/v1/me", 403, "user_disabled", "Доступ <отключён>.")
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [CONSENT])
    await deliver(harness)
    [notification] = harness.telegram.sent()

    await harness.press(notification, "Скрыть", user_id=USER)

    from aiogram.methods import AnswerCallbackQuery

    [alert] = harness.telegram.of_type(AnswerCallbackQuery)
    assert alert.text == "Доступ <отключён>."
