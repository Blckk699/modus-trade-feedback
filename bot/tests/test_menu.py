"""T-01: запуск, опознание сотрудника, код входа, Mini App, сервисный ключ."""

from aiogram.methods import SetChatMenuButton
from aiogram.types import ReplyKeyboardMarkup, ReplyKeyboardRemove

from app import texts
from app.config import Settings
from app.main import main
from tests.support import MINI_APP_URL, SERVICE_KEY, employee

USER = 100000004


def buttons(markup: ReplyKeyboardMarkup) -> list[str]:
    return [b.text for row in markup.keyboard for b in row]


async def test_start_greets_employee_and_shows_menu(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER))

    await harness.send_text("/start")

    [reply] = harness.telegram.sent()
    assert "Здравствуйте, Айгерим!" in reply.text
    assert buttons(reply.reply_markup) == [texts.BTN_SUBMIT, texts.BTN_MY_APPEALS, texts.BTN_LOGIN_CODE]


async def test_digest_button_only_for_those_with_analytics(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER, analytics_scope="company"))

    await harness.send_text("/start")

    [reply] = harness.telegram.sent()
    assert texts.BTN_DIGEST in buttons(reply.reply_markup)


async def test_stranger_is_politely_refused(harness):
    message = "Вас нет в списке сотрудников. Обратитесь к администратору."
    harness.backend.error("GET", "/api/v1/me", 403, "user_not_registered", message)

    await harness.send_text("/start", user_id=555)
    await harness.send_text(texts.BTN_LOGIN_CODE, user_id=555)

    replies = harness.telegram.sent()
    assert [r.text for r in replies] == [message, message]
    assert all(isinstance(r.reply_markup, ReplyKeyboardRemove) for r in replies)
    assert harness.backend.calls("POST", "/api/v1/auth/login-codes") == []


async def test_disabled_user_is_refused(harness):
    harness.backend.error("GET", "/api/v1/me", 403, "user_disabled", "Доступ отключён. Обратитесь к администратору.")

    await harness.send_text("/start")

    [reply] = harness.telegram.sent()
    assert reply.text == "Доступ отключён. Обратитесь к администратору."


async def test_login_code_is_issued_with_instructions(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER))
    harness.backend.on(
        "POST",
        "/api/v1/auth/login-codes",
        201,
        {"code": "482913", "expires_at": "2026-11-10T19:35:00+05:00", "ttl_seconds": 300},
    )

    await harness.send_text(texts.BTN_LOGIN_CODE)
    await harness.send_text("/code")

    replies = harness.telegram.sent()
    assert len(replies) == 2
    assert "<code>482913</code>" in replies[0].text
    assert "«Модус Трейд»" in replies[0].text
    assert "5 минут" in replies[0].text
    assert len(harness.backend.calls("POST", "/api/v1/auth/login-codes")) == 2


async def test_api_is_called_with_service_key_on_behalf_of_user(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER))

    await harness.send_text("/start")

    [request] = harness.backend.calls("GET", "/api/v1/me")
    assert request.headers["X-Service-Key"] == SERVICE_KEY
    assert request.headers["X-Telegram-Id"] == str(USER)
    assert "Authorization" not in request.headers


async def test_start_sets_chat_menu_button_to_mini_app(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER))

    await harness.send_text("/start")

    [menu] = [c for c in harness.telegram.calls if isinstance(c, SetChatMenuButton)]
    assert menu.chat_id == USER
    assert menu.menu_button.web_app.url == MINI_APP_URL


async def test_my_appeals_opens_mini_app_with_inline_button(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER))

    await harness.send_text(texts.BTN_MY_APPEALS)

    [reply] = harness.telegram.sent()
    [[button]] = reply.reply_markup.inline_keyboard
    assert button.web_app.url == MINI_APP_URL


async def test_without_mini_app_url_no_mini_app_buttons(harness_without_mini_app):
    h = harness_without_mini_app
    h.backend.on("GET", "/api/v1/me", 200, employee(USER))

    await h.send_text("/start")

    [reply] = h.telegram.sent()
    assert texts.BTN_MY_APPEALS not in buttons(reply.reply_markup)
    assert not [c for c in h.telegram.calls if isinstance(c, SetChatMenuButton)]


async def test_digest_is_sent_as_is(harness):
    harness.backend.on("GET", "/api/v1/me", 200, employee(USER, analytics_scope="company"))
    harness.backend.on(
        "GET",
        "/api/v1/analytics/digest",
        200,
        {"scope": "company", "department": None, "generated_at": "2026-11-10T09:00:00+05:00", "text": "<b>Сводка</b>"},
    )

    await harness.send_text(texts.BTN_DIGEST)

    [reply] = harness.telegram.sent()
    assert reply.text == "<b>Сводка</b>"


async def test_api_unavailable_is_reported(harness):
    harness.backend.on("GET", "/api/v1/me", 500, "oops")

    await harness.send_text("/start")

    [reply] = harness.telegram.sent()
    assert reply.text == texts.API_UNAVAILABLE


def test_ttl_text_plurals():
    assert texts.ttl_text(60) == "1 минуту"
    assert texts.ttl_text(180) == "3 минуты"
    assert texts.ttl_text(300) == "5 минут"
    assert texts.ttl_text(45) == "45 секунд"


def test_without_token_bot_reports_not_configured(monkeypatch, capsys):
    monkeypatch.delenv("TELEGRAM_BOT_TOKEN", raising=False)
    monkeypatch.delenv("BOT_SERVICE_KEY", raising=False)
    monkeypatch.setattr(Settings, "model_config", {**Settings.model_config, "env_file": None})

    assert main() == 2
    assert "TELEGRAM_BOT_TOKEN" in capsys.readouterr().err
