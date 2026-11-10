"""T-05: сводка по команде и утренняя сводка из очереди."""

from aiogram.exceptions import TelegramBadRequest

from app import texts
from app.notifications import deliver_pending
from tests.support import MINI_APP_URL, employee

OWNER = 100000001
DIGEST_TEXT = "<b>Сводка на 10 ноября</b>\n\n🆕 Новое за сутки: 3\n\n⏰ Зависло: 2"


def digest_notification(nid: int, telegram_id: int, buttons: list) -> dict:
    return {
        "id": nid,
        "kind": "digest",
        "text": DIGEST_TEXT,
        "appeal": None,
        "path": "/analytics",
        "buttons": buttons,
        "is_read": False,
        "created_at": "2026-11-10T09:00:00+05:00",
        "recipient": {"user_id": 1, "telegram_id": telegram_id},
        "attempts": 0,
    }


async def test_digest_command_returns_it_at_once_with_analytics_button(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(OWNER, analytics_scope="company"))
    harness.backend.on(
        "GET",
        "/api/v1/analytics/digest",
        200,
        {"scope": "company", "department": None, "generated_at": "2026-11-10T09:00:00+05:00", "text": DIGEST_TEXT},
    )

    await harness.send_text("/digest", user_id=OWNER)

    [reply] = harness.telegram.sent()
    assert reply.text == DIGEST_TEXT
    [[button]] = reply.reply_markup.inline_keyboard
    assert button.text == texts.BTN_OPEN_ANALYTICS
    assert button.web_app.url == MINI_APP_URL + "/analytics"


async def test_employee_without_rights_is_told_digest_is_unavailable(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(100000004))
    harness.backend.error("GET", "/api/v1/analytics/digest", 403, "forbidden", "Недостаточно прав.")

    await harness.send_text("/digest")

    assert harness.telegram.sent()[0].text == texts.DIGEST_UNAVAILABLE


async def test_morning_digest_from_queue_gets_analytics_button(harness):
    harness.backend.on(
        "GET",
        "/api/v1/bot/notifications/pending",
        200,
        [
            digest_notification(910, OWNER, []),
            digest_notification(
                911, 100000003, [{"type": "open_analytics", "text": "Аналитика", "appeal_id": None, "discussion_id": None}]
            ),
        ],
    )
    harness.backend.on("POST", "/api/v1/bot/notifications/910/ack", 204, None)
    harness.backend.on("POST", "/api/v1/bot/notifications/911/ack", 204, None)

    assert await deliver_pending(harness.bot, harness.api, harness.settings) == 2

    owner, head = harness.telegram.sent()
    assert (owner.chat_id, head.chat_id) == (OWNER, 100000003)
    assert owner.text == DIGEST_TEXT
    [[added]] = owner.reply_markup.inline_keyboard
    assert added.text == texts.BTN_OPEN_ANALYTICS and added.web_app.url == MINI_APP_URL + "/analytics"
    [[from_backend]] = head.reply_markup.inline_keyboard
    assert from_backend.text == "Аналитика"


async def test_digest_command_with_broken_html_is_sent_as_plain_text(harness):
    broken = "Сводка: маржа < 10% в A-003"
    harness.backend.on("GET", "/api/v1/me", 200, employee(OWNER, analytics_scope="company"))
    harness.backend.on(
        "GET",
        "/api/v1/analytics/digest",
        200,
        {"scope": "company", "department": None, "generated_at": "2026-11-10T09:00:00+05:00", "text": broken},
    )
    harness.telegram.errors[OWNER] = lambda m: (
        TelegramBadRequest(m, "Bad Request: can't parse entities") if m.parse_mode else None
    )

    await harness.send_text("/digest", user_id=OWNER)

    first, second = harness.telegram.sent()
    assert second.text == broken and second.parse_mode is None
    assert second.reply_markup is not None
