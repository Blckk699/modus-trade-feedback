"""Реальные адаптеры против поддельного HTTP (httpx.MockTransport): формат запросов,
разбор ответов, ошибки без утечки секретов. Сеть не используется."""

from __future__ import annotations

import json
import logging
from datetime import datetime
from types import SimpleNamespace

import httpx
import pytest

from app.adapters.bitrix import Bitrix24Webhook
from app.adapters.claude import AnthropicClaude, AppealDraft, DuplicateCandidate, DuplicateMatch
from app.adapters.speech import ElevenLabsScribe
from app.adapters.telegram import TelegramBotApi
from app.errors import ExternalServiceError
from tests.support import TZ

BOT_TOKEN = "123456:fake-token-for-tests"
WEBHOOK = "https://modus-test.bitrix24.kz/rest/1/fakewebhooksecret"


async def test_telegram_sends_message() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json={"ok": True, "result": {"message_id": 77}})

    bot = TelegramBotApi(BOT_TOKEN, transport=httpx.MockTransport(handler))
    assert await bot.send_message(500100, "Привет") == 77
    assert seen[0].url.path == f"/bot{BOT_TOKEN}/sendMessage"
    assert json.loads(seen[0].content) == {"chat_id": 500100, "text": "Привет"}


async def test_telegram_error_does_not_leak_token(caplog: pytest.LogCaptureFixture) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError(f"cannot connect to {request.url}")

    bot = TelegramBotApi(BOT_TOKEN, transport=httpx.MockTransport(handler))
    with caplog.at_level(logging.DEBUG), pytest.raises(ExternalServiceError) as exc_info:
        await bot.send_message(1, "x")

    assert exc_info.value.code == "telegram_unavailable"
    assert exc_info.value.__cause__ is None
    assert BOT_TOKEN not in caplog.text
    assert BOT_TOKEN not in str(exc_info.value)


async def test_bitrix_creates_task_and_builds_link() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json={"result": {"task": {"id": "321", "title": "x"}}})

    bitrix = Bitrix24Webhook(WEBHOOK, responsible_id=5, transport=httpx.MockTransport(handler))
    task = await bitrix.create_task(
        title="A-001: сломан кондиционер", description="Текст обращения", deadline=datetime(2026, 11, 12, 18, 0, tzinfo=TZ)
    )

    assert task.id == "321"
    assert task.url == "https://modus-test.bitrix24.kz/company/personal/user/5/tasks/task/view/321/"
    assert str(seen[0].url) == f"{WEBHOOK}/tasks.task.add.json"
    fields = json.loads(seen[0].content)["fields"]
    assert fields == {
        "TITLE": "A-001: сломан кондиционер",
        "DESCRIPTION": "Текст обращения",
        "RESPONSIBLE_ID": 5,
        "DEADLINE": "2026-11-12T18:00:00+05:00",
    }


async def test_bitrix_portal_error_is_reported() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(400, json={"error": "ERROR_CORE", "error_description": "Не указан ответственный"})

    bitrix = Bitrix24Webhook(WEBHOOK, transport=httpx.MockTransport(handler))
    with pytest.raises(ExternalServiceError) as exc_info:
        await bitrix.create_task(title="t", description="d", deadline=None)

    assert exc_info.value.code == "bitrix_error"
    assert "fakewebhooksecret" not in json.dumps(exc_info.value.details)


async def test_scribe_transcribes_audio() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, json={"text": " Проблема со складом. ", "language_code": "rus"})

    scribe = ElevenLabsScribe("xi-key", transport=httpx.MockTransport(handler))
    transcript = await scribe.transcribe(b"OggS...", filename="voice.ogg", content_type="audio/ogg")

    assert transcript.text == "Проблема со складом."
    assert seen[0].headers["xi-api-key"] == "xi-key"
    body = seen[0].content
    assert b'name="model_id"' in body and b"scribe_v1" in body
    assert b'filename="voice.ogg"' in body


@pytest.mark.parametrize(
    "adapter",
    [
        lambda: TelegramBotApi("").send_message(1, "x"),
        lambda: Bitrix24Webhook("").create_task(title="t", description="d", deadline=None),
        lambda: ElevenLabsScribe("").transcribe(b"x", filename="a.ogg", content_type="audio/ogg"),
        lambda: AnthropicClaude("", "claude-sonnet-5-5").draft_appeal("текст", []),
    ],
)
async def test_unconfigured_service_gives_clear_error(adapter) -> None:
    with pytest.raises(ExternalServiceError) as exc_info:
        await adapter()
    assert "не задан" in exc_info.value.message


class _FakeMessages:
    def __init__(self, parsed, stop_reason: str = "end_turn") -> None:
        self.parsed = parsed
        self.stop_reason = stop_reason
        self.requests: list[dict] = []

    async def parse(self, **kwargs):
        self.requests.append(kwargs)
        return SimpleNamespace(parsed_output=self.parsed, stop_reason=self.stop_reason)


def _claude_with(messages: _FakeMessages) -> AnthropicClaude:
    return AnthropicClaude("key", "claude-sonnet-5-5", client=SimpleNamespace(messages=messages))  # type: ignore[arg-type]


async def test_claude_draft_keeps_only_known_categories() -> None:
    messages = _FakeMessages(
        AppealDraft(type="problem", category="Выдуманная", priority="high", summary="Нет связи", proposed_solution=None)
    )
    draft = await _claude_with(messages).draft_appeal("Нет интернета на складе", ["IT", "Склад"])

    assert draft.category is None
    request = messages.requests[0]
    assert request["model"] == "claude-sonnet-5-5"
    assert request["output_format"] is AppealDraft
    assert "IT; Склад" in request["messages"][0]["content"]


async def test_claude_duplicates_are_limited_to_candidates() -> None:
    parsed = SimpleNamespace(matches=[DuplicateMatch(id="A-003", reason="то же"), DuplicateMatch(id="A-999", reason="?")])
    claude = _claude_with(_FakeMessages(parsed))
    matches = await claude.find_duplicates("текст", [DuplicateCandidate(id="A-003", text="кондиционер")])
    assert [m.id for m in matches] == ["A-003"]


async def test_claude_refusal_becomes_service_error() -> None:
    claude = _claude_with(_FakeMessages(None, stop_reason="refusal"))
    with pytest.raises(ExternalServiceError) as exc_info:
        await claude.draft_appeal("текст", [])
    assert exc_info.value.code == "ai_unavailable"
