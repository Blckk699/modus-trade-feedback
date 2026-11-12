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
from aiogram.methods import EditMessageCaption, EditMessageReplyMarkup, SendMessage

from app import formatting, texts, widgets
from app.notifications import deliver_pending
from app.widgets import EditMessageWidgetData, SendWidget
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


@pytest.mark.parametrize(
    "template", [widgets.APPEAL_CARD, widgets.LOGIN_CODE, widgets.DRAFT_CARD, widgets.APPEAL_LIST]
)
def test_templates_fit_telegram_limits(template):
    raw = template.encode()
    assert len(raw) <= 32768
    assert len(zlib.compress(raw, 9)) <= 4096
    assert "@font-face" not in template and "http" not in template  # без внешних ресурсов и шрифтов


def test_closed_appeal_card_shows_no_deadline():
    appeal = {"number": "A-1", "type": "praise", "status": "closed", "due_state": "on_time",
              "first_response_due_at": "2026-11-13T18:00:00+05:00"}
    card = json.loads(formatting.appeal_card_data(appeal, {}))
    assert card["dl"] == "" and card["d"] == ""


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
    assert data(widget) == {"c": "482913", "e": 1794494100000, "l": 300}  # 19:35 +05:00
    assert "482913" not in widget.caption and widget.parse_mode == "HTML"  # подпись не повторяет код
    # Копирует кнопка Telegram под виджетом: copyText внутри защищённого виджета запрещён.
    [[button]] = widget.reply_markup.inline_keyboard
    assert button.text == texts.BTN_COPY_CODE and button.copy_text.text == "482913"
    assert "copyText" not in widgets.LOGIN_CODE
    assert harness.telegram.sent() == []


async def test_without_widget_support_the_same_text_is_sent(harness, backend):
    harness.telegram.reject_widgets = lambda m: TelegramBadRequest(method=m, message="Bad Request: method not found")

    await harness.send_text(texts.BTN_LOGIN_CODE)

    [message] = harness.telegram.sent()
    assert "<code>482913</code>" in message.text
    assert message.reply_markup.inline_keyboard[0][0].copy_text.text == "482913"  # и в простом тексте


async def test_after_method_not_found_widgets_are_not_tried_again(harness, backend):
    harness.telegram.reject_widgets = lambda m: TelegramBadRequest(method=m, message="Bad Request: method not found")

    await harness.send_text("/code")
    await harness.send_text("/code")

    assert len(harness.telegram.widgets()) == 1  # вторая попытка не делалась
    assert len(harness.telegram.sent()) == 2


async def test_other_rejection_does_not_switch_widgets_off(harness, backend):
    harness.telegram.reject_widgets = lambda m: TelegramBadRequest(method=m, message="Bad Request: widget is too big")

    await harness.send_text("/code")
    await harness.send_text("/code")

    assert len(harness.telegram.widgets()) == 2


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
    assert widget.caption == STATUS_CHANGED["text"]  # суть не в кавычках — подпись как у бэкенда
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


# ------------------------------------------------------------------ черновик


DICTIONARIES = {
    "statuses": [{"code": "new", "label": "Новое"}, {"code": "in_progress", "label": "В работе"}],
    "appeal_types": [{"code": "problem", "label": "Проблема"}, {"code": "suggestion", "label": "Предложение"}],
    "priorities": [{"code": "high", "label": "Высокий"}, {"code": "medium", "label": "Средний"}],
}
DRAFT = {
    "type": "problem",
    "category": {"id": 1, "name": "Межотдельное взаимодействие"},
    "priority": "medium",
    "summary": "В заявках на камеры не указан объект",
    "text": "Опять в заявке на камеры не написали, для какого объекта",
    "proposed_solution": None,
    "transcript": None,
}
CREATED = {
    "id": 21,
    "number": "A-021",
    "type": "problem",
    "status": "new",
    "summary": DRAFT["summary"],
    "assignee": {"id": 3, "full_name": "Марат Сейткали"},
    "first_response_due_at": "2026-11-13T18:00:00+05:00",
}


@pytest.fixture
def drafting(backend):
    backend.on("GET", "/api/v1/dictionaries", 200, DICTIONARIES)
    backend.on("POST", "/api/v1/drafts/text", 200, DRAFT)
    backend.on("POST", "/api/v1/appeals", 201, CREATED)
    return backend


async def test_draft_comes_as_widget_and_is_redrawn_in_place(harness, drafting):
    await harness.send_text("Опять в заявке на камеры не написали")

    [card] = harness.telegram.widgets()
    assert card.html == widgets.DRAFT_CARD and card.caption == texts.DRAFT_CAPTION
    fields = data(card)
    assert (fields["k"], fields["c"], fields["p"], fields["s"]) == (
        "Проблема", "Межотдельное взаимодействие", "Средний", DRAFT["summary"])
    assert fields["q"] == DRAFT["text"] and fields["x"] == ""

    await harness.press(card, texts.BTN_DRAFT_PRIORITY)
    await harness.press(harness.telegram.of_type(EditMessageReplyMarkup)[-1], "Высокий")

    [edit] = harness.telegram.of_type(EditMessageWidgetData)
    assert edit.message_id == harness.telegram.message_id_of(card)
    assert json.loads(edit.chat_data)["p"] == "Высокий"
    assert len(harness.telegram.widgets()) == 1  # та же карточка, не новая
    assert harness.telegram.of_type(EditMessageReplyMarkup)[-1].reply_markup is not None  # кнопки на месте


async def test_sent_draft_is_marked_and_appeal_card_follows(harness, drafting):
    await harness.send_text("Опять в заявке на камеры не написали")
    [card] = harness.telegram.widgets()

    await harness.press(card, texts.BTN_DRAFT_SEND)

    mark = json.loads(harness.telegram.of_type(EditMessageWidgetData)[-1].chat_data)
    assert mark["x"] == "sent" and mark["n"] == "A-021"
    caption = harness.telegram.of_type(EditMessageCaption)[-1]
    assert caption.caption == texts.DRAFT_SENT and caption.reply_markup is None
    appeal = harness.telegram.widgets()[-1]
    assert appeal.html == widgets.APPEAL_CARD
    assert appeal.caption == texts.appeal_created_caption("A-021")
    assert "Марат Сейткали" not in appeal.caption  # ответственный и срок — в карточке
    assert data(appeal)["a"] == "Марат Сейткали" and data(appeal)["d"] == "13 ноября, 18:00"


async def test_cancelled_draft_widget_is_marked(harness, drafting):
    await harness.send_text("Передумал")
    [card] = harness.telegram.widgets()

    await harness.press(card, texts.BTN_DRAFT_CANCEL)

    assert json.loads(harness.telegram.of_type(EditMessageWidgetData)[-1].chat_data)["x"] == "cancelled"
    assert harness.telegram.of_type(EditMessageCaption)[-1].caption == texts.DRAFT_CANCELLED
    assert drafting.calls("POST", "/api/v1/appeals") == []


async def test_draft_is_resent_when_widget_cannot_be_redrawn(harness, drafting):
    harness.telegram.reject_widget_edits = lambda m: TelegramBadRequest(method=m, message="Bad Request: no")
    await harness.send_text("Опять в заявке на камеры не написали")
    [card] = harness.telegram.widgets()

    await harness.press(card, texts.BTN_DRAFT_PRIORITY)
    await harness.press(harness.telegram.of_type(EditMessageReplyMarkup)[-1], "Высокий")

    old, new = harness.telegram.widgets()
    assert data(new)["p"] == "Высокий"
    await harness.press(new, texts.BTN_DRAFT_SEND)
    assert len(drafting.calls("POST", "/api/v1/appeals")) == 1


def test_long_draft_text_is_trimmed_to_fit():
    draft = {**DRAFT, "text": "Очень длинный текст обращения. " * 100, "proposed_solution": "Решение. " * 50}
    packed = formatting.draft_card_data(draft, DICTIONARIES)
    assert len(packed.encode()) <= 1024
    fields = json.loads(packed)
    assert fields["q"].endswith("…") and fields["s"] == DRAFT["summary"]  # суть режется последней


# ------------------------------------------------------------------ мои обращения


def appeals_page(count: int, total: int) -> dict:
    items = [
        {"id": i, "number": f"A-{i:03}", "type": "suggestion", "status": "in_progress" if i % 2 else "new",
         "summary": f"Обращение номер {i}: длинная суть про склад, заявки и согласования " * 2,
         "created_at": "2026-11-12T10:00:00+05:00", "has_unread": i == 1}
        for i in range(1, count + 1)
    ]
    return {"items": items, "total": total, "page": 1, "page_size": 10}


async def test_my_appeals_come_as_list_widget(harness, backend):
    backend.on("GET", "/api/v1/dictionaries", 200, DICTIONARIES)
    backend.on("GET", "/api/v1/appeals", 200, appeals_page(3, 3))

    await harness.send_text(texts.BTN_MY_APPEALS)

    [widget] = harness.telegram.widgets()
    assert widget.html == widgets.APPEAL_LIST and widget.caption is None
    listing = data(widget)
    assert listing["T"] == 3 and listing["L"] == {"in_progress": "В работе", "new": "Новое"}
    assert listing["i"][0][:3] == ["A-001", "suggestion", "in_progress"]
    assert listing["i"][0][4:] == ["12 ноября", 1]
    [[button]] = widget.reply_markup.inline_keyboard
    assert button.web_app.url == MINI_APP_URL + "/my"


def test_long_appeal_list_fits_chat_data():
    packed = formatting.appeal_list_data(appeals_page(10, 40), DICTIONARIES)
    assert len(packed.encode()) <= 1024
    listing = json.loads(packed)
    assert listing["T"] == 40 and len(listing["i"]) >= 5


# ------------------------------------------------------------------ подписи уведомлений


def test_card_caption_drops_what_the_card_shows():
    text = ("Обращение <b>A-021</b> «Счёт дважды: в 1С и в Битрикс» зарегистрировано.\n"
            "Ответственный: Марат Сейткали\nСрок первого ответа: 13 ноября, 18:00")
    assert formatting.card_caption(text) == "Обращение <b>A-021</b> зарегистрировано."

    status = "Обращение <b>A-021</b> «Счёт» реализовано.\nКомментарий: настроили обмен"
    assert formatting.card_caption(status) == "Обращение <b>A-021</b> реализовано.\nКомментарий: настроили обмен"


async def test_new_message_is_a_card_with_short_caption(harness, backend):
    note = {**STATUS_CHANGED, "kind": "message_received",
            "text": "Новое сообщение по обращению <b>A-021</b> «Счёт дважды» от Марат Сейткали:\nПроверим завтра"}
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [note])

    await deliver_pending(harness.bot, harness.api, harness.settings)

    [widget] = harness.telegram.widgets()
    assert data(widget)["h"] == "Новое сообщение"
    assert widget.caption == "Новое сообщение по обращению <b>A-021</b> от Марат Сейткали:\nПроверим завтра"


async def test_notification_with_reply_button_stays_text(harness, backend):
    note = {**STATUS_CHANGED, "kind": "status_changed",
            "buttons": [{"type": "reply_clarification", "text": "Ответить", "appeal_id": 21, "discussion_id": None}]}
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [note])

    await deliver_pending(harness.bot, harness.api, harness.settings)

    assert harness.telegram.widgets() == []


async def test_widget_rejection_sends_full_text(harness, backend):
    text = "Обращение <b>A-021</b> «Счёт» зарегистрировано.\nОтветственный: Марат Сейткали"
    backend.on("GET", "/api/v1/bot/notifications/pending", 200, [{**STATUS_CHANGED, "kind": "appeal_created", "text": text}])
    harness.telegram.reject_widgets = lambda m: TelegramBadRequest(method=m, message="Bad Request: method not found")

    await deliver_pending(harness.bot, harness.api, harness.settings)

    assert harness.telegram.sent()[0].text == text  # прежний полный текст, со сутью и ответственным


# ------------------------------------------------------------------ скрипты виджетов в node

NODE_STUB = """
const els = {};
global.document = {getElementById: id => (els[id] ||= {innerHTML: '', textContent: '', className: '', style: {}})};
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
        "priority": "high",
        "category": {"id": 3, "name": "Межотдельное взаимодействие"},
        "assignee": {"full_name": "Марат Сейткали"},
        "first_response_due_at": "2026-11-13T18:00:00+05:00",
    }
    dictionaries = {
        "statuses": [{"code": "in_progress", "label": "В работе"}],
        "appeal_types": [{"code": "problem", "label": "Проблема"}],
        "priorities": [{"code": "high", "label": "Высокий"}],
    }
    html = run_widget(widgets.APPEAL_CARD, formatting.appeal_card_data(appeal, dictionaries, "Статус изменён"))["r"][
        "innerHTML"
    ]
    assert "A-021" in html and "В работе" in html and "Марат Сейткали" in html and "13 ноября, 18:00" in html
    assert "&lt;script&gt;" in html and "<script>" not in html
    assert 'class="bg dot s-in_progress"' in html  # бейдж статуса, как .badge--status-* на сайте
    assert '<span class="no">A-021</span>' in html
    assert "Проблема · Межотдельное взаимодействие · приоритет высокий" in html
    assert ">МС</span>" in html  # аватарка с инициалами ответственного
    assert '<span class="on">В работе</span>' in html
    assert 'class="bg on_time"' in html and "В срок · до 13 ноября, 18:00" in html
    assert html.count("background:var(--s-in_progress)") == 3  # новое → рассмотрение → в работе


@needs_node
def test_rejected_card_has_no_progress_bar():
    html = run_widget(widgets.APPEAL_CARD, json.dumps({"n": "A-3", "st": "rejected", "sl": "Отклонено"}))["r"][
        "innerHTML"
    ]
    assert 'class="bg dot s-rejected"' in html and "Готово" not in html


@needs_node
def test_login_code_script_shows_code_and_countdown():
    future = json.dumps({"c": "482913", "e": 4102444800000})
    els = run_widget(widgets.LOGIN_CODE, future)
    assert els["c"]["innerHTML"] == "".join(f"<span>{d}</span>" for d in "482913")  # цифры по ячейкам
    assert els["t"]["textContent"].startswith("Действует ещё")
    assert els["b"]["style"]["width"] == "100%"

    expired = run_widget(widgets.LOGIN_CODE, json.dumps({"c": "482913", "e": 1, "l": 300}))
    assert expired["t"]["textContent"].startswith("Код истёк")
    assert expired["t"]["className"] == "pl overdue"  # цвета .badge--due-overdue сайта
    assert expired["c"]["className"] == "c x" and expired["b"]["style"]["width"] == "0%"


@needs_node
def test_draft_script_renders_fields_and_state():
    draft = {**DRAFT, "category": None, "summary": "Суть <b>", "transcript": "да"}
    html = run_widget(widgets.DRAFT_CARD, formatting.draft_card_data(draft, DICTIONARIES))["r"]["innerHTML"]
    assert "Суть &lt;b&gt;" in html and "Определит администратор" in html and "Расшифровка голосового" in html
    assert "Не отправлен" in html

    sent = run_widget(widgets.DRAFT_CARD, formatting.draft_card_data(DRAFT, DICTIONARIES, "sent", "A-021"))["r"]
    assert "Отправлен · A-021" in sent["innerHTML"] and sent["className"] == "w off"


@needs_node
def test_list_script_renders_rows_and_rest():
    html = run_widget(widgets.APPEAL_LIST, formatting.appeal_list_data(appeals_page(2, 12), DICTIONARIES))["r"][
        "innerHTML"
    ]
    assert html.count('class="r"') == 2 and 'class="rt u"' in html
    assert 'class="bg dot s-in_progress">В работе' in html and "A-001 · 12 ноября" in html
    assert "Ещё 10 — в приложении" in html
