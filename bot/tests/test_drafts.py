"""T-02: подача обращения текстом и пересылкой."""

import json

import pytest
from aiogram.methods import EditMessageReplyMarkup, EditMessageText

from app import texts
from tests.support import employee

USER = 100000004

DICTIONARIES = {
    "appeal_types": [
        {"code": "problem", "label": "Проблема"},
        {"code": "suggestion", "label": "Предложение"},
        {"code": "praise", "label": "Положительный отзыв"},
    ],
    "priorities": [
        {"code": "high", "label": "Высокий"},
        {"code": "medium", "label": "Средний"},
        {"code": "low", "label": "Низкий"},
    ],
}
DRAFT = {
    "type": "problem",
    "category": {"id": 1, "name": "Межотдельное взаимодействие"},
    "priority": "medium",
    "summary": "В заявках на камеры не указаны объект и разрешение",
    "text": "Опять в заявке на камеры не написали, для какого объекта",
    "proposed_solution": "Сделать поля обязательными",
    "transcript": None,
}
CATEGORIES = [
    {"id": 1, "name": "Межотдельное взаимодействие", "department": {"id": 1, "name": "Закупки"},
     "responsible": None, "deputy": None, "is_active": True},
    {"id": 7, "name": "Интеграции и IT", "department": {"id": 6, "name": "IT"},
     "responsible": None, "deputy": None, "is_active": True},
]
CREATED = {
    "id": 21,
    "number": "A-021",
    "assignee": {"id": 3, "full_name": "Марат Сейткали", "role": "head", "department": None},
    "first_response_due_at": "2026-11-13T18:00:00+05:00",
}



@pytest.fixture(autouse=True)
def text_cards(harness):
    """Здесь проверяется логика черновика на текстовой карточке; карточка-виджет — в test_widgets.py."""
    harness.settings.widgets_enabled = False
@pytest.fixture
def backend(harness):
    b = harness.backend
    b.on("GET", "/api/v1/me", 200, employee(USER))
    b.on("GET", "/api/v1/dictionaries", 200, DICTIONARIES)
    b.on("POST", "/api/v1/drafts/text", 200, DRAFT)
    b.on("GET", "/api/v1/categories", 200, CATEGORIES)
    b.on("POST", "/api/v1/appeals", 201, CREATED)
    return b


def body(request) -> dict:
    return json.loads(request.content)


async def test_text_becomes_draft_card(harness, backend):
    await harness.send_text("Опять в заявке на камеры не написали, для какого объекта")

    [request] = backend.calls("POST", "/api/v1/drafts/text")
    assert body(request) == {"text": "Опять в заявке на камеры не написали, для какого объекта", "forwarded_from": None}
    [card] = harness.telegram.sent()
    assert "<b>Тип:</b> Проблема" in card.text
    assert "<b>Категория:</b> Межотдельное взаимодействие" in card.text
    assert "<b>Приоритет:</b> Средний" in card.text
    assert "<b>Суть:</b> В заявках на камеры не указаны объект и разрешение" in card.text
    captions = [b.text for row in card.reply_markup.inline_keyboard for b in row]
    assert captions == [
        texts.BTN_DRAFT_SEND, texts.BTN_DRAFT_TYPE, texts.BTN_DRAFT_CATEGORY, texts.BTN_DRAFT_PRIORITY,
        texts.BTN_DRAFT_TEXT, texts.BTN_DRAFT_SUMMARY, texts.BTN_DRAFT_CANCEL,
    ]


async def test_forwarded_message_keeps_its_origin(harness, backend):
    await harness.send_forward("Где назначение изделия?", chat_title="Закупки — продажи")

    [request] = backend.calls("POST", "/api/v1/drafts/text")
    assert body(request) == {"text": "Где назначение изделия?", "forwarded_from": "Закупки — продажи"}
    [card] = harness.telegram.sent()
    assert "<b>Переслано из:</b> Закупки — продажи" in card.text

    await harness.press(card, texts.BTN_DRAFT_SEND)

    [create] = backend.calls("POST", "/api/v1/appeals")
    assert body(create)["forwarded_from"] == "Закупки — продажи"


async def test_confirm_creates_appeal_and_reports_number_assignee_due(harness, backend):
    await harness.send_text("Опять в заявке на камеры не написали")
    [card] = harness.telegram.sent()

    await harness.press(card, texts.BTN_DRAFT_SEND)

    [request] = backend.calls("POST", "/api/v1/appeals")
    assert body(request) == {
        "type": "problem",
        "category_id": 1,
        "priority": "medium",
        "text": DRAFT["text"],
        "summary": DRAFT["summary"],
        "proposed_solution": DRAFT["proposed_solution"],
        "source": "bot",
        "forwarded_from": None,
    }
    confirmation = harness.telegram.sent()[-1]  # без виджетов — прежний полный текст
    assert "<b>A-021</b>" in confirmation.text
    assert "Марат Сейткали" in confirmation.text
    assert "13 ноября, 18:00" in confirmation.text
    # Кнопки с карточки убраны, повторно отправить нельзя.
    assert harness.telegram.of_type(EditMessageReplyMarkup)[-1].reply_markup is None


async def test_change_type_priority_and_category(harness, backend):
    await harness.send_text("Предлагаю сделать календарь обучения")
    [card] = harness.telegram.sent()

    await harness.press(card, texts.BTN_DRAFT_TYPE)
    choice = harness.telegram.of_type(EditMessageReplyMarkup)[-1]
    await harness.press(choice, "Предложение")
    await harness.press(card, texts.BTN_DRAFT_PRIORITY)
    await harness.press(harness.telegram.of_type(EditMessageReplyMarkup)[-1], "Высокий")
    await harness.press(card, texts.BTN_DRAFT_CATEGORY)
    await harness.press(harness.telegram.of_type(EditMessageReplyMarkup)[-1], "Интеграции и IT")

    rendered = harness.telegram.of_type(EditMessageText)[-1]
    assert "<b>Тип:</b> Предложение" in rendered.text
    assert "<b>Приоритет:</b> Высокий" in rendered.text
    assert "<b>Категория:</b> Интеграции и IT" in rendered.text

    await harness.press(card, texts.BTN_DRAFT_SEND)
    [request] = backend.calls("POST", "/api/v1/appeals")
    assert body(request)["type"] == "suggestion"
    assert body(request)["priority"] == "high"
    assert body(request)["category_id"] == 7


async def test_unknown_category_goes_to_admin(harness, backend):
    await harness.send_text("Что-то непонятное")
    [card] = harness.telegram.sent()
    await harness.press(card, texts.BTN_DRAFT_CATEGORY)
    await harness.press(harness.telegram.of_type(EditMessageReplyMarkup)[-1], texts.CATEGORY_UNKNOWN)

    assert "назначит администратор" in harness.telegram.of_type(EditMessageText)[-1].text
    await harness.press(card, texts.BTN_DRAFT_SEND)
    assert body(backend.calls("POST", "/api/v1/appeals")[0])["category_id"] is None


async def test_edit_text_replaces_draft_text(harness, backend):
    await harness.send_text("Черновой текст")
    [card] = harness.telegram.sent()

    await harness.press(card, texts.BTN_DRAFT_TEXT)
    assert harness.telegram.sent()[-1].text == texts.ASK_NEW_TEXT
    await harness.send_text("Исправленный текст обращения")

    new_card = harness.telegram.sent()[-1]
    assert "Исправленный текст обращения" in new_card.text
    assert len(backend.calls("POST", "/api/v1/drafts/text")) == 1  # правка не вызывает разбор заново

    await harness.press(new_card, texts.BTN_DRAFT_SEND)
    assert body(backend.calls("POST", "/api/v1/appeals")[0])["text"] == "Исправленный текст обращения"


async def test_old_card_buttons_do_not_touch_new_draft(harness, backend):
    await harness.send_text("Первое")
    [old_card] = harness.telegram.sent()
    await harness.send_text("Второе")

    await harness.press(old_card, texts.BTN_DRAFT_SEND)

    assert backend.calls("POST", "/api/v1/appeals") == []


async def test_cancel_drops_draft(harness, backend):
    await harness.send_text("Передумал")
    [card] = harness.telegram.sent()

    await harness.press(card, texts.BTN_DRAFT_CANCEL)
    await harness.press(card, texts.BTN_DRAFT_SEND)

    assert harness.telegram.of_type(EditMessageText)[-1].text == texts.DRAFT_CANCELLED
    assert backend.calls("POST", "/api/v1/appeals") == []


async def test_ai_unavailable_offers_mini_app_form(harness, backend):
    message = "Разбор сейчас недоступен. Заполните обращение через форму."
    backend.error("POST", "/api/v1/drafts/text", 503, "ai_unavailable", message)

    await harness.send_text("Текст")

    [reply] = harness.telegram.sent()
    assert reply.text == message
    [[button]] = reply.reply_markup.inline_keyboard
    assert button.text == texts.BTN_OPEN_FORM
    assert button.web_app is not None


async def test_menu_buttons_and_commands_are_not_drafts(harness, backend):
    await harness.send_text(texts.BTN_SUBMIT)
    await harness.send_text("/unknown")

    assert backend.calls("POST", "/api/v1/drafts/text") == []


async def test_draft_card_survives_missing_dictionaries(harness, backend):
    backend.error("GET", "/api/v1/dictionaries", 404, "not_found", "Не найдено.")

    await harness.send_text("Текст обращения")

    [card] = harness.telegram.sent()
    assert "<b>Тип:</b> Проблема" in card.text
    assert "<b>Приоритет:</b> Средний" in card.text
