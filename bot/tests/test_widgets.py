"""Bot API 10.4: карточки HTML-виджетами — код входа, созданное обращение, уведомления по обращению.

Telegram подменён фейком: проверяем, что ушло в sendWidget (HTML, chat_data, подпись, кнопки)
и что при отказе Telegram бот отправляет прежний текст. Скрипты виджетов прогоняются в node
с заглушкой `TelegramWidget` и DOM — так ловятся ошибки JS без живого клиента.
"""

import json
import re
import shutil
import subprocess
import zlib

import pytest
from aiogram.exceptions import TelegramBadRequest
from aiogram.methods import SendMessage

from app import formatting, texts, widgets
from app.notifications import deliver_pending
from app.widgets import SendWidget
from tests.support import MINI_APP_URL, BotHarness, employee

USER = 100000004

LOGIN = {"code": "482913", "expires_at": "2026-11-12T19:35:00+05:00", "ttl_seconds": 300}
STATUS_CHANGED = {
    "id": 950,
    "kind": "status_changed",
    "text": "Обращение <b>A-021</b>: статус «В работе».",
    "appeal": {"id": 21, "number": "A-021", "summary": "Счёт дважды: в 1С и в Битрикс", "status": "in_progress",
               "type": "problem"},
    "path": "/appeals/21",
    "buttons": [{"type": "open_appeal", "text": "Открыть обращение", "appeal_id": 21, "discussion_id": None}],
    "is_read": False,
    "created_at": "2026-11-12T10:00:00+05:00",
    "recipient": {"user_id": 4, "telegram_id": USER},
    "attempts": 0,
}


@pytest.fixture
def backend(harness):
    b = harness.backend
    b.on("GET", "/api/v1/me", 200, employee(USER))
    b.on("POST", "/api/v1/auth/login-codes", 201, LOGIN)
    b.on("POST", "/api/v1/bot/notifications/950/ack", 204, None)
    return b


def data(widget: SendWidget) -> dict:
    return json.loads(widget.chat_data)


# ------------------------------------------------------------------ шаблоны


@pytest.mark.parametrize("template", [widgets.APPEAL_CARD, widgets.LOGIN_CODE])
def test_templates_fit_telegram_limits(template):
    raw = template.encode()
    assert len(raw) <= 32768
    assert len(zlib.compress(raw, 9)) <= 4096
    assert "@font-face" not in template and "http" not in template  # без внешних ресурсов и шрифтов


def test_chat_data_is_trimmed_to_1024_bytes():
    appeal = {"number": "A-021", "type": "problem", "status": "new", "summary": "Очень длинная суть. " * 200}
    packed = formatting.appeal_card_data(appeal, {})
    assert len(packed.encode()) <= 1024
    assert json.loads(packed)["s"].endswith("…")


# ------------------------------------------------------------------ код входа


async def test_login_code_comes_as_widget_with_copyable_code(harness, backend):
    await harness.send_text(texts.BTN_LOGIN_CODE)

    [widget] = harness.telegram.widgets()
    assert widget.__api_method__ == "sendWidget"
    assert widget.html == widgets.LOGIN_CODE
    assert data(widget) == {"c": "482913", "e": 1794494100000}  # 19:35 +05:00
    assert "<code>482913</code>" in widget.caption and widget.parse_mode == "HTML"
    assert harness.telegram.sent() == []


async def test_without_widget_support_the_same_text_is_sent(harness, backend):
    harness.telegram.reject_widgets = lambda m: TelegramBadRequest(method=m, message="Bad Request: method not found")

    await harness.send_text(texts.BTN_LOGIN_CODE)

    [message] = harness.telegram.sent()
    assert "<code>482913</code>" in message.text


async def test_widgets_can_be_switched_off():
    h = BotHarness()
    h.settings.widgets_enabled = False
    h.backend.on("GET", "/api/v1/me", 200, employee(USER))
    h.backend.on("POST", "/api/v1/auth/login-codes", 201, LOGIN)
    try:
        await h.send_text("/code")
    finally:
        await h.close()

    assert h.telegram.widgets() == []
    assert "<code>482913</code>" in h.telegram.sent()[0].text


# ------------------------------------------------------------------ уведомления


async def test_status_change_is_a_card_with_buttons_and_acked_by_its_id(harness, backend):
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [STATUS_CHANGED])

    assert await deliver_pending(harness.bot, harness.api, harness.settings) == 1

    [widget] = harness.telegram.widgets()
    assert widget.chat_id == USER
    assert widget.html == widgets.APPEAL_CARD
    assert widget.caption == STATUS_CHANGED["text"]
    card = data(widget)
    assert card["n"] == "A-021" and card["st"] == "in_progress" and card["sl"] == "В работе"
    assert card["h"] == "Статус изменён" and card["k"] == "Проблема"
    [[button]] = widget.reply_markup.inline_keyboard
    assert button.web_app.url == MINI_APP_URL + "/appeals/21"
    [ack] = backend.calls("POST", "/api/v1/bot/notifications/950/ack")
    assert json.loads(ack.content) == {"telegram_message_id": harness.telegram.message_id_of(widget)}


async def test_clarification_question_stays_text_for_swipe_reply(harness, backend):
    question = {**STATUS_CHANGED, "kind": "clarification_requested", "text": "Вопрос по <b>A-021</b>"}
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [question])

    await deliver_pending(harness.bot, harness.api, harness.settings)

    assert harness.telegram.widgets() == []
    assert [type(m) for m in harness.telegram.messages()] == [SendMessage]


async def test_long_notification_text_goes_as_message(harness, backend):
    long_text = {**STATUS_CHANGED, "text": "Обращение <b>A-021</b>: " + "длинный комментарий " * 60}
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [long_text])

    await deliver_pending(harness.bot, harness.api, harness.settings)

    assert harness.telegram.widgets() == []
    assert harness.telegram.sent()[0].text == long_text["text"]


# ------------------------------------------------------------------ скрипты виджетов в node

NODE_STUB = """
const els = {};
global.document = {getElementById: id => (els[id] ||= {innerHTML: '', textContent: '', className: '', disabled: false})};
global.window = {TelegramWidget: {chatData: process.argv[1], onEvent() {}, ready() {}, copyText(t) { els.copied = t }}};
global.setInterval = () => 0;
"""


def run_widget(template: str, chat_data: str) -> dict:
    script = re.search(r"<script>(.*)</script>", template, re.DOTALL).group(1)
    program = NODE_STUB + script + "\nconsole.log(JSON.stringify(els))"
    out = subprocess.run(["node", "-e", program, chat_data], capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


needs_node = pytest.mark.skipif(shutil.which("node") is None, reason="нужен node")


@needs_node
def test_appeal_card_script_renders_and_escapes():
    appeal = {
        "number": "A-021",
        "type": "problem",
        "status": "in_progress",
        "summary": "Счёт <script> дважды",
        "assignee": {"full_name": "Марат Сейткали"},
        "first_response_due_at": "2026-11-13T18:00:00+05:00",
    }
    dictionaries = {"statuses": [{"code": "in_progress", "label": "В работе"}]}
    html = run_widget(widgets.APPEAL_CARD, formatting.appeal_card_data(appeal, dictionaries, "Статус изменён"))["r"][
        "innerHTML"
    ]
    assert "A-021" in html and "В работе" in html and "Марат Сейткали" in html and "13 ноября, 18:00" in html
    assert "&lt;script&gt;" in html and "<script>" not in html
    assert html.count('class="on"') == 3  # новое → рассмотрение → в работе


@needs_node
def test_rejected_card_has_no_progress_bar():
    html = run_widget(widgets.APPEAL_CARD, json.dumps({"n": "A-3", "st": "rejected", "sl": "Отклонено"}))["r"][
        "innerHTML"
    ]
    assert 'class="p no"' in html and "Готово" not in html


@needs_node
def test_login_code_script_shows_code_and_countdown():
    future = json.dumps({"c": "482913", "e": 4102444800000})
    els = run_widget(widgets.LOGIN_CODE, future)
    assert els["c"]["textContent"] == "482913"
    assert els["t"]["textContent"].startswith("Действует ещё")

    expired = run_widget(widgets.LOGIN_CODE, json.dumps({"c": "482913", "e": 1}))
    assert expired["t"]["textContent"].startswith("Код истёк")
    assert expired["b"]["disabled"] is True
