"""T-03: подача голосовым сообщением."""

import pytest
from aiogram.methods import DeleteMessage

from app import texts
from tests.support import employee
from tests.test_drafts import CREATED, DICTIONARIES

USER = 100000004
TRANSCRIPT = "Счёт сначала забиваю в 1С, потом руками то же самое в Битрикс"
VOICE_DRAFT = {
    "type": "problem",
    "category": {"id": 7, "name": "Интеграции и IT"},
    "priority": "high",
    "summary": "Одни и те же данные вводим вручную в 1С и в Битрикс",
    "text": TRANSCRIPT,
    "proposed_solution": "Оценить синхронизацию счетов",
    "transcript": TRANSCRIPT,
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
    b.on("POST", "/api/v1/drafts/voice", 200, VOICE_DRAFT)
    b.on("POST", "/api/v1/appeals", 201, CREATED)
    return b


async def test_voice_is_sent_for_transcription_and_shows_draft_with_transcript(harness, backend):
    await harness.send_voice(b"OggS-fake-audio", duration=12)

    [request] = backend.calls("POST", "/api/v1/drafts/voice")
    assert request.headers["X-Telegram-Id"] == str(USER)
    assert request.headers["Content-Type"].startswith("multipart/form-data")
    assert b'name="file"; filename="voice.ogg"' in request.content
    assert b"OggS-fake-audio" in request.content
    assert b'name="duration_seconds"\r\n\r\n12\r\n' in request.content

    status, card = harness.telegram.sent()
    assert status.text == texts.VOICE_PROCESSING  # индикатор, пока идёт расшифровка
    [deleted] = harness.telegram.of_type(DeleteMessage)
    assert deleted.message_id == harness.telegram.message_id_of(status)
    assert "Расшифровка голосового" in card.text
    assert TRANSCRIPT in card.text
    assert "<b>Приоритет:</b> Высокий" in card.text


async def test_voice_draft_is_confirmed_like_text(harness, backend):
    await harness.send_voice(b"audio", duration=5)
    card = harness.telegram.sent()[-1]

    await harness.press(card, texts.BTN_DRAFT_SEND)

    [request] = backend.calls("POST", "/api/v1/appeals")
    import json

    sent = json.loads(request.content)
    assert sent["text"] == TRANSCRIPT
    assert sent["source"] == "bot"
    assert "<b>A-021</b>" in harness.telegram.sent()[-1].text


async def test_too_long_voice_is_refused_without_upload(harness, backend):
    await harness.send_voice(b"audio", duration=301)

    assert harness.telegram.sent()[-1].text == texts.VOICE_TOO_LONG
    assert backend.calls("POST", "/api/v1/drafts/voice") == []


@pytest.mark.parametrize(
    ("code", "message"),
    [
        ("audio_empty", "Не удалось разобрать речь. Запишите голосовое ещё раз."),
        ("audio_too_long", "Голосовое длиннее 5 минут."),
    ],
)
async def test_empty_or_long_audio_gets_message_from_api(harness, backend, code, message):
    backend.error("POST", "/api/v1/drafts/voice", 422, code, message)

    await harness.send_voice(b"audio", duration=3)

    assert harness.telegram.sent()[-1].text == message
    assert harness.telegram.of_type(DeleteMessage)  # индикатор убран


async def test_transcription_unavailable_offers_form(harness, backend):
    backend.error("POST", "/api/v1/drafts/voice", 503, "ai_unavailable", "Разбор сейчас недоступен.")

    await harness.send_voice(b"audio", duration=3)

    reply = harness.telegram.sent()[-1]
    assert reply.text == "Разбор сейчас недоступен."
    [[button]] = reply.reply_markup.inline_keyboard
    assert button.text == texts.BTN_OPEN_FORM
