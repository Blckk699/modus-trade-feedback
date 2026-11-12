"""Черновик обращения из текста и голоса (B-09). Истории 1–5. Claude и ElevenLabs — фейки."""

from __future__ import annotations

import pytest
from fastapi import FastAPI
from sqlalchemy import func, select

from app.adapters.claude import AppealDraft
from app.models import Appeal
from tests.support import bot_headers, telegram_id_of

MESSAGE = "Опять в заявке на камеры не написали объект и разрешение, третий раз переспрашиваю у продаж"


async def appeals_count(app: FastAPI) -> int:
    async with app.state.sessionmaker() as session:
        return await session.scalar(select(func.count()).select_from(Appeal))


def set_draft(fake_claude, category: str | None = "Межотдельное взаимодействие") -> None:
    fake_claude.draft = AppealDraft(
        type="problem",
        category=category,
        priority="high",
        summary="В заявках на камеры нет объекта и разрешения",
        proposed_solution="Сделать поля обязательными",
    )


async def test_text_becomes_draft_without_creating_appeal(app, client, demo, fake_claude) -> None:
    """Истории 1, 3, 4: бот присылает текст или пересылку — получает черновик, обращения ещё нет."""
    set_draft(fake_claude)
    before = await appeals_count(app)
    headers = bot_headers(telegram_id_of("employee_procurement"))
    response = await client.post("/api/v1/drafts/text", headers=headers, json={"text": MESSAGE, "forwarded_from": "Чат закупок"})
    assert response.status_code == 200, response.text
    draft = response.json()
    assert draft == {
        "type": "problem",
        "category": {"id": 1, "name": "Межотдельное взаимодействие"},
        "priority": "high",
        "summary": "В заявках на камеры нет объекта и разрешения",
        "text": MESSAGE,
        "proposed_solution": "Сделать поля обязательными",
        "transcript": None,
    }
    assert await appeals_count(app) == before
    call = fake_claude.calls_to("draft_appeal")[0]
    assert call.args["text"] == MESSAGE and len(call.args["categories"]) == 18


async def test_author_edits_draft_then_confirms(app, client, demo, fake_claude) -> None:
    """История 5: любое поле черновика правится перед отправкой."""
    set_draft(fake_claude)
    headers = bot_headers(telegram_id_of("employee_procurement"))
    draft = (await client.post("/api/v1/drafts/text", headers=headers, json={"text": MESSAGE})).json()
    confirmed = await client.post(
        "/api/v1/appeals",
        headers=headers,
        json={
            "type": "suggestion",
            "category_id": 2,
            "priority": "medium",
            "text": draft["text"],
            "summary": "Своя формулировка",
            "proposed_solution": draft["proposed_solution"],
            "source": "bot",
            "forwarded_from": "Чат закупок",
        },
    )
    assert confirmed.status_code == 201
    body = confirmed.json()
    assert (body["type"], body["category"]["id"], body["summary"], body["source"]) == ("suggestion", 2, "Своя формулировка", "bot")


async def test_unknown_category_from_model_is_left_empty(client, login_as, fake_claude) -> None:
    set_draft(fake_claude, category="Нет такой")
    draft = (await client.post("/api/v1/drafts/text", headers=await login_as("employee_sales"), json={"text": MESSAGE})).json()
    assert draft["category"] is None


async def test_voice_is_transcribed_into_same_draft(client, demo, fake_claude, fake_speech) -> None:
    """История 2: расшифровка возвращается и в тексте, и отдельно — для проверки автором."""
    set_draft(fake_claude)
    fake_speech.text = "Счёт сначала забиваю в 1С, потом руками в Битрикс"
    response = await client.post(
        "/api/v1/drafts/voice",
        headers=bot_headers(telegram_id_of("employee_accounting")),
        files={"file": ("voice.ogg", b"OggS-fake-audio", "audio/ogg")},
        data={"duration_seconds": "12"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["text"] == body["transcript"] == fake_speech.text
    assert fake_speech.calls_to("transcribe")[0].args["content_type"] == "audio/ogg"
    assert fake_claude.calls_to("draft_appeal")[0].args["text"] == fake_speech.text


async def test_ai_failure_returns_clear_error_and_form_still_works(app, client, login_as, fake_claude, fake_speech) -> None:
    headers = await login_as("employee_sales")
    fake_claude.fail = True
    response = await client.post("/api/v1/drafts/text", headers=headers, json={"text": MESSAGE})
    assert (response.status_code, response.json()["error"]["code"]) == (503, "ai_unavailable")
    assert "форму" in response.json()["error"]["message"]

    fake_claude.fail = False
    fake_speech.fail = True
    voice = await client.post("/api/v1/drafts/voice", headers=headers, files={"file": ("v.ogg", b"x", "audio/ogg")})
    assert (voice.status_code, voice.json()["error"]["code"]) == (503, "ai_unavailable")

    fake_claude.fail = True
    form = await client.post(
        "/api/v1/appeals", headers=headers, json={"type": "problem", "category_id": 1, "priority": "low", "text": MESSAGE}
    )
    assert form.status_code == 201, "форма не зависит от AI-сервисов"


async def test_voice_validation(client, login_as) -> None:
    headers = await login_as("employee_sales")
    empty = await client.post("/api/v1/drafts/voice", headers=headers, files={"file": ("v.ogg", b"", "audio/ogg")})
    assert (empty.status_code, empty.json()["error"]["code"]) == (422, "audio_empty")
    long = await client.post(
        "/api/v1/drafts/voice", headers=headers, files={"file": ("v.ogg", b"x", "audio/ogg")}, data={"duration_seconds": "301"}
    )
    assert (long.status_code, long.json()["error"]["code"]) == (422, "audio_too_long")
    blank = await client.post("/api/v1/drafts/text", headers=headers, json={"text": "   "})
    assert blank.status_code == 422


@pytest.mark.parametrize("written", ["межотдельное взаимодействие", "«Межотдельное взаимодействие»", "  Межотдельное  взаимодействие. "])
async def test_category_from_model_is_matched_loosely(client, login_as, fake_claude, written) -> None:
    """Модель пишет категорию не буква в букву: регистр, кавычки и пробелы не должны терять её."""
    set_draft(fake_claude, category=written)
    response = await client.post("/api/v1/drafts/text", headers=await login_as("employee_sales"), json={"text": "Нет назначения"})
    assert response.json()["category"] == {"id": 1, "name": "Межотдельное взаимодействие"}
