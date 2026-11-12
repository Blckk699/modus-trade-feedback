"""Фейки внешних сервисов для тестов.

Каждый фейк возвращает заранее заданный ответ, запоминает вызовы и умеет «сломаться»:

    fake_claude.draft = AppealDraft(...)      # что вернуть
    fake_claude.fail = True                   # следующий вызов — ExternalServiceError
    assert fake_claude.calls[0].method == "draft_appeal"
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from app.adapters.bitrix import BitrixTask
from app.adapters.bitrix_oauth import BitrixProfile
from app.adapters.claude import AppealDraft, DuplicateCandidate, DuplicateMatch, MeetingDraft
from app.adapters.speech import Transcript
from app.errors import ExternalServiceError, InvalidBitrixAuth


@dataclass
class Call:
    method: str
    args: dict[str, Any]


class _Fake:
    service_code = "external_service_unavailable"

    def __init__(self) -> None:
        self.calls: list[Call] = []
        self.fail = False

    def _record(self, method: str, **args: Any) -> None:
        self.calls.append(Call(method, args))
        if self.fail:
            raise ExternalServiceError("Внешний сервис недоступен (фейк)", code=self.service_code)

    def calls_to(self, method: str) -> list[Call]:
        return [c for c in self.calls if c.method == method]


class FakeClaude(_Fake):
    service_code = "ai_unavailable"

    def __init__(self) -> None:
        super().__init__()
        self.draft = AppealDraft(
            type="problem", category=None, priority="medium", summary="Черновик из фейка", proposed_solution=None
        )
        self.duplicates: list[DuplicateMatch] = []
        self.meeting_drafts: list[MeetingDraft] = []
        self.digest_text = "Сводка из фейка"

    async def draft_appeal(self, text: str, categories: list[str]) -> AppealDraft:
        self._record("draft_appeal", text=text, categories=categories)
        return self.draft

    async def find_duplicates(self, text: str, candidates: list[DuplicateCandidate]) -> list[DuplicateMatch]:
        self._record("find_duplicates", text=text, candidates=candidates)
        known = {c.id for c in candidates}
        return [m for m in self.duplicates if m.id in known]

    async def extract_meeting_drafts(self, transcript: str, categories: list[str]) -> list[MeetingDraft]:
        self._record("extract_meeting_drafts", transcript=transcript, categories=categories)
        return list(self.meeting_drafts)

    async def write_digest(self, facts: str) -> str:
        self._record("write_digest", facts=facts)
        return self.digest_text


class FakeSpeech(_Fake):
    service_code = "speech_unavailable"

    def __init__(self) -> None:
        super().__init__()
        self.text = "Расшифровка из фейка"

    async def transcribe(
        self, audio: bytes, *, filename: str, content_type: str, diarize: bool = False
    ) -> Transcript:
        self._record("transcribe", size=len(audio), filename=filename, content_type=content_type, diarize=diarize)
        return Transcript(text=self.text, language_code="rus")


@dataclass
class SentMessage:
    chat_id: int
    text: str
    message_id: int


class FakeTelegram(_Fake):
    service_code = "telegram_unavailable"

    def __init__(self) -> None:
        super().__init__()
        self.sent: list[SentMessage] = []

    async def send_message(self, chat_id: int, text: str) -> int:
        self._record("send_message", chat_id=chat_id, text=text)
        message = SentMessage(chat_id, text, message_id=len(self.sent) + 1)
        self.sent.append(message)
        return message.message_id


@dataclass
class CreatedTask:
    title: str
    description: str
    deadline: datetime | None
    task: BitrixTask = field(repr=False)


class FakeBitrix(_Fake):
    service_code = "bitrix_unavailable"

    def __init__(self) -> None:
        super().__init__()
        self.tasks: list[CreatedTask] = []

    async def create_task(self, *, title: str, description: str, deadline: datetime | None) -> BitrixTask:
        self._record("create_task", title=title, description=description, deadline=deadline)
        task_id = str(1000 + len(self.tasks) + 1)
        task = BitrixTask(id=task_id, url=f"https://modus-test.bitrix24.kz/company/personal/user/1/tasks/task/view/{task_id}/")
        self.tasks.append(CreatedTask(title, description, deadline, task))
        return task


class FakeBitrixOAuth(_Fake):
    """Портал при входе: `profile` — кто вошёл, `reject = True` — портал отклонил код, `fail = True` — не ответил."""

    service_code = "bitrix_unavailable"

    def __init__(self) -> None:
        super().__init__()
        self.reject = False
        self.profile = BitrixProfile(
            id=501, email="portal.user@company.kz", first_name="Пётр", last_name="Портальный", position="Логист"
        )

    async def current_user(self, code: str) -> BitrixProfile:
        self._record("current_user", code=code)
        if self.reject:
            raise InvalidBitrixAuth()
        return self.profile
