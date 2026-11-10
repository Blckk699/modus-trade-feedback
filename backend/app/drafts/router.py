"""Черновик обращения из текста, пересланного сообщения и голосового (истории 1–5).

Черновик ничего не создаёт и не хранится: автор правит поля и отправляет `POST /appeals` с `source=bot`.
Если Claude или ElevenLabs недоступны — `503 ai_unavailable`, подача через форму работает как прежде.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import ClaudeDep, CurrentUserDep, SessionDep, SpeechDep
from app.api.schemas import CategoryRef
from app.domain.enums import AppealType, Priority
from app.errors import AppError, ExternalServiceError, FileTooLarge
from app.models import Category

router = APIRouter(prefix="/drafts", tags=["drafts"])

MAX_VOICE_BYTES = 20 * 1024 * 1024
MAX_VOICE_SECONDS = 5 * 60


class AiUnavailable(AppError):
    status_code = 503
    code = "ai_unavailable"
    message = "Разбор сейчас недоступен. Заполните обращение через форму."


class TextDraftIn(BaseModel):
    text: str = Field(min_length=1, max_length=20_000, pattern=r"\S")
    forwarded_from: str | None = Field(default=None, max_length=300)


class AppealDraftOut(BaseModel):
    type: AppealType
    category: CategoryRef | None
    priority: Priority
    summary: str
    text: str
    proposed_solution: str | None
    transcript: str | None


async def _draft(session, claude, text: str, transcript: str | None) -> AppealDraftOut:
    categories = (await session.execute(select(Category).where(Category.is_active).order_by(Category.id))).scalars().all()
    try:
        draft = await claude.draft_appeal(text, [c.name for c in categories])
    except ExternalServiceError as exc:
        raise AiUnavailable() from exc
    category = next((c for c in categories if c.name == draft.category), None)
    return AppealDraftOut(
        type=draft.type,
        category=CategoryRef(id=category.id, name=category.name) if category else None,
        priority=draft.priority,
        summary=draft.summary.strip(),
        text=text,
        proposed_solution=(draft.proposed_solution or "").strip() or None,
        transcript=transcript,
    )


@router.post("/text", response_model=AppealDraftOut, summary="Черновик из текста или пересланного сообщения")
async def draft_from_text(body: TextDraftIn, _: CurrentUserDep, session: SessionDep, claude: ClaudeDep) -> AppealDraftOut:
    return await _draft(session, claude, body.text.strip(), None)


@router.post("/voice", response_model=AppealDraftOut, summary="Черновик из голосового сообщения")
async def draft_from_voice(
    file: Annotated[UploadFile, File()],
    _: CurrentUserDep,
    session: SessionDep,
    claude: ClaudeDep,
    speech: SpeechDep,
    duration_seconds: Annotated[int | None, Form(ge=0)] = None,
) -> AppealDraftOut:
    if duration_seconds is not None and duration_seconds > MAX_VOICE_SECONDS:
        raise AppError("Голосовое длиннее 5 минут — разделите его или напишите текстом.", code="audio_too_long", status_code=422)
    audio = await file.read(MAX_VOICE_BYTES + 1)
    if len(audio) > MAX_VOICE_BYTES:
        raise FileTooLarge("Аудио больше 20 МБ.", details={"max_bytes": MAX_VOICE_BYTES})
    if not audio:
        raise AppError("Голосовое пустое.", code="audio_empty", status_code=422)
    try:
        transcript = await speech.transcribe(
            audio, filename=file.filename or "voice.ogg", content_type=file.content_type or "audio/ogg"
        )
    except ExternalServiceError as exc:
        if exc.code == "speech_empty":
            raise AppError("В голосовом не удалось разобрать речь.", code="audio_empty", status_code=422) from exc
        raise AiUnavailable() from exc
    return await _draft(session, claude, transcript.text, transcript.text)
