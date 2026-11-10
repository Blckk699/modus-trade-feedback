"""Режим «совещание» (B-12, истории 48–51, 62; SPEC.md, «Режим „совещание“»).

Запись обрабатывается в фоне: клиент сразу получает `processing` и опрашивает состояние.
Обращение создаётся только после подтверждения черновика и идёт по обычной маршрутизации.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Annotated, Any

from fastapi import APIRouter, Body, File, Form, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import ClockDep, CurrentUserDep, SessionDep, SettingsDep
from app.api.schemas import CategoryRef, UserBrief
from app.appeals import service
from app.appeals.schemas import AppealOut, AppealRef
from app.appeals.views import Directory, appeal_out, appeal_ref
from app.config import Settings
from app.domain.enums import AppealSource, AppealType, MeetingDraftStatus, MeetingStatus, Priority, Role
from app.errors import AppError, Conflict, ExternalServiceError, FileTooLarge, Forbidden, NotFound, ValidationFailed
from app.jobs.registry import JobContext, registry
from app.jobs.runner import enqueue
from app.models import Appeal, Category, Meeting, MeetingDraft, User

log = logging.getLogger(__name__)

router = APIRouter(tags=["meetings"])

MAX_MEETING_BYTES = 200 * 1024 * 1024
PROCESS_JOB = "meetings.process"
PROCESS_ATTEMPTS = 3
EMPTY_RECORDING = "В записи не удалось разобрать речь."
PROCESSING_FAILED = "Не удалось обработать запись. Попробуйте загрузить её ещё раз."

NonBlank = Annotated[str, Field(min_length=1, max_length=20_000, pattern=r"\S")]
ShortNonBlank = Annotated[str, Field(min_length=1, max_length=500, pattern=r"\S")]


class MeetingBriefOut(BaseModel):
    id: int
    title: str
    status: MeetingStatus
    drafts_total: int
    drafts_pending: int
    uploaded_by: UserBrief
    created_at: datetime


class MeetingDraftOut(BaseModel):
    id: int
    meeting_id: int
    status: MeetingDraftStatus
    type: AppealType
    category: CategoryRef | None
    priority: Priority
    summary: str
    text: str
    proposed_solution: str | None
    quote: str
    author: UserBrief | None
    appeal: AppealRef | None


class MeetingOut(BaseModel):
    id: int
    title: str
    status: MeetingStatus
    error: str | None
    transcript: str | None
    uploaded_by: UserBrief
    drafts: list[MeetingDraftOut]
    created_at: datetime


class MeetingDraftUpdate(BaseModel):
    type: AppealType | None = None
    category_id: int | None = None
    priority: Priority | None = None
    summary: ShortNonBlank | None = None
    text: NonBlank | None = None
    proposed_solution: str | None = Field(default=None, max_length=20_000)
    author_id: int | None = None


def _storage_path(settings: Settings, key: str) -> Path:
    return Path(settings.attachments_dir) / key


def _require_uploader_role(user: User) -> None:
    if user.role not in (Role.HEAD, Role.OWNER):
        raise Forbidden("Записи совещаний загружают руководитель и собственник")


async def _own_meeting(session: AsyncSession, meeting_id: int, user: User) -> Meeting:
    meeting = await session.get(Meeting, meeting_id)
    if meeting is None:
        raise NotFound("Совещание не найдено")
    if meeting.uploaded_by_id != user.id:
        raise Forbidden("Запись доступна только тому, кто её загрузил")
    return meeting


async def _own_draft(session: AsyncSession, meeting_id: int, draft_id: int, user: User) -> tuple[Meeting, MeetingDraft]:
    """Черновик загрузившего. Строка блокируется, чтобы двойное подтверждение не создало два обращения."""
    meeting = await _own_meeting(session, meeting_id, user)
    draft = await session.get(MeetingDraft, draft_id, with_for_update=True, populate_existing=True)
    if draft is None or draft.meeting_id != meeting.id:
        raise NotFound("Черновик не найден")
    if draft.status != MeetingDraftStatus.PENDING:
        raise Conflict("Этот черновик уже обработан")
    return meeting, draft


def _field_error(field: str, message: str) -> ValidationFailed:
    return ValidationFailed(details={"fields": [{"field": field, "message": message}]})


async def _apply(session: AsyncSession, draft: MeetingDraft, body: MeetingDraftUpdate) -> None:
    data = body.model_dump(exclude_unset=True)
    if data.get("category_id") is not None:
        category = await session.get(Category, data["category_id"])
        if category is None or not category.is_active:
            raise _field_error("category_id", "Неизвестная категория")
    if data.get("author_id") is not None:
        author = await session.get(User, data["author_id"])
        if author is None or author.is_disabled:
            raise _field_error("author_id", "Выберите действующего сотрудника")
    for key in ("type", "priority", "summary", "text"):
        if data.get(key) is not None:
            setattr(draft, key, data[key].strip() if key in ("summary", "text") else data[key])
    for key in ("category_id", "author_id"):
        if key in data:
            setattr(draft, key, data[key])
    if "proposed_solution" in data:
        draft.proposed_solution = (data["proposed_solution"] or "").strip() or None


def _draft_out(draft: MeetingDraft, directory: Directory, appeals: dict[int, Appeal]) -> MeetingDraftOut:
    appeal = appeals.get(draft.appeal_id) if draft.appeal_id else None
    return MeetingDraftOut(
        id=draft.id,
        meeting_id=draft.meeting_id,
        status=draft.status,
        type=draft.type,
        category=directory.category_ref(draft.category_id),
        priority=draft.priority,
        summary=draft.summary,
        text=draft.text,
        proposed_solution=draft.proposed_solution,
        quote=draft.quote,
        author=directory.user_brief(draft.author_id),
        appeal=appeal_ref(appeal) if appeal else None,
    )


async def _meeting_out(session: AsyncSession, meeting: Meeting) -> MeetingOut:
    directory = await Directory.load(session)
    drafts = (await session.scalars(select(MeetingDraft).where(MeetingDraft.meeting_id == meeting.id).order_by(MeetingDraft.id))).all()
    appeal_ids = [d.appeal_id for d in drafts if d.appeal_id]
    appeals = {a.id: a for a in await session.scalars(select(Appeal).where(Appeal.id.in_(appeal_ids)))} if appeal_ids else {}
    return MeetingOut(
        id=meeting.id,
        title=meeting.title,
        status=meeting.status,
        error=meeting.error,
        transcript=meeting.transcript,
        uploaded_by=directory.user_brief(meeting.uploaded_by_id),
        drafts=[_draft_out(d, directory, appeals) for d in drafts],
        created_at=meeting.created_at,
    )


@router.get("/meetings", response_model=list[MeetingBriefOut], summary="Совещания, загруженные пользователем")
async def list_meetings(user: CurrentUserDep, session: SessionDep) -> list[MeetingBriefOut]:
    _require_uploader_role(user)
    directory = await Directory.load(session)
    pending = func.sum(case((MeetingDraft.status == MeetingDraftStatus.PENDING, 1), else_=0))
    counts = {
        meeting_id: (total, waiting)
        for meeting_id, total, waiting in (
            await session.execute(
                select(MeetingDraft.meeting_id, func.count(), pending).group_by(MeetingDraft.meeting_id)
            )
        ).all()
    }
    rows = await session.scalars(
        select(Meeting).where(Meeting.uploaded_by_id == user.id).order_by(Meeting.created_at.desc(), Meeting.id.desc())
    )
    return [
        MeetingBriefOut(
            id=m.id,
            title=m.title,
            status=m.status,
            drafts_total=counts.get(m.id, (0, 0))[0],
            drafts_pending=counts.get(m.id, (0, 0))[1],
            uploaded_by=directory.user_brief(m.uploaded_by_id),
            created_at=m.created_at,
        )
        for m in rows
    ]


@router.post("/meetings", response_model=MeetingOut, status_code=202, summary="Загрузить аудиозапись совещания")
async def upload_meeting(
    file: Annotated[UploadFile, File()],
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
    title: Annotated[str | None, Form(max_length=300)] = None,
) -> MeetingOut:
    _require_uploader_role(user)
    now = clock.now()
    key = f"meetings/{uuid.uuid4().hex}"
    path = _storage_path(settings, key)
    path.parent.mkdir(parents=True, exist_ok=True)
    size = 0
    try:
        with path.open("wb") as out:
            while chunk := await file.read(1024 * 1024):
                size += len(chunk)
                if size > MAX_MEETING_BYTES:
                    raise FileTooLarge("Запись больше 200 МБ.", details={"max_bytes": MAX_MEETING_BYTES})
                out.write(chunk)
        if size == 0:
            raise AppError("Файл записи пустой.", code="audio_empty", status_code=422)
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    filename = (file.filename or "запись")[:300]
    meeting = Meeting(
        title=(title or "").strip() or filename,
        status=MeetingStatus.PROCESSING,
        filename=filename,
        content_type=(file.content_type or "application/octet-stream")[:150],
        storage_key=key,
        uploaded_by_id=user.id,
        created_at=now,
    )
    session.add(meeting)
    await session.flush()
    await enqueue(session, PROCESS_JOB, {"meeting_id": meeting.id}, run_at=now, dedup_key=f"meeting:{meeting.id}", max_attempts=PROCESS_ATTEMPTS)
    return await _meeting_out(session, meeting)


@router.get("/meetings/{meeting_id}", response_model=MeetingOut, summary="Совещание: состояние, расшифровка, черновики")
async def get_meeting(meeting_id: int, user: CurrentUserDep, session: SessionDep) -> MeetingOut:
    return await _meeting_out(session, await _own_meeting(session, meeting_id, user))


@router.patch("/meetings/{meeting_id}/drafts/{draft_id}", response_model=MeetingDraftOut, summary="Поправить черновик")
async def update_draft(meeting_id: int, draft_id: int, body: MeetingDraftUpdate, user: CurrentUserDep, session: SessionDep) -> MeetingDraftOut:
    _, draft = await _own_draft(session, meeting_id, draft_id, user)
    await _apply(session, draft, body)
    await session.flush()
    return _draft_out(draft, await Directory.load(session), {})


@router.post("/meetings/{meeting_id}/drafts/{draft_id}/confirm", response_model=AppealOut, status_code=201, summary="Подтвердить черновик")
async def confirm_draft(
    meeting_id: int,
    draft_id: int,
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
    body: Annotated[MeetingDraftUpdate | None, Body()] = None,
) -> AppealOut:
    now = clock.now()
    meeting, draft = await _own_draft(session, meeting_id, draft_id, user)
    if body is not None:
        await _apply(session, draft, body)
    author = await session.get(User, draft.author_id or meeting.uploaded_by_id)
    if author is None or author.is_disabled:
        raise _field_error("author_id", "Выберите действующего сотрудника")
    appeal = await service.create_appeal(
        session,
        author,
        type=draft.type,
        category_id=draft.category_id,
        priority=draft.priority,
        text_value=draft.text,
        summary=draft.summary,
        proposed_solution=draft.proposed_solution,
        source=AppealSource.MEETING,
        forwarded_from=None,
        now=now,
        tz=settings.tz,
    )
    draft.status = MeetingDraftStatus.CONFIRMED
    draft.appeal_id = appeal.id
    return await appeal_out(session, appeal, user, now)


@router.post("/meetings/{meeting_id}/drafts/{draft_id}/discard", response_model=MeetingDraftOut, summary="Отбросить черновик")
async def discard_draft(meeting_id: int, draft_id: int, user: CurrentUserDep, session: SessionDep) -> MeetingDraftOut:
    _, draft = await _own_draft(session, meeting_id, draft_id, user)
    draft.status = MeetingDraftStatus.DISCARDED
    await session.flush()
    return _draft_out(draft, await Directory.load(session), {})


async def _process(ctx: JobContext, meeting: Meeting) -> None:
    audio = await asyncio.to_thread(_storage_path(ctx.settings, meeting.storage_key).read_bytes)
    transcript = await ctx.services.speech.transcribe(audio, filename=meeting.filename, content_type=meeting.content_type, diarize=True)
    categories = {c.name: c.id for c in await ctx.session.scalars(select(Category).where(Category.is_active))}
    drafts = await ctx.services.claude.extract_meeting_drafts(transcript.text, list(categories))
    now = ctx.now()
    for item in drafts:
        ctx.session.add(
            MeetingDraft(
                meeting_id=meeting.id,
                status=MeetingDraftStatus.PENDING,
                type=item.type,
                category_id=categories.get(item.category) if item.category else None,
                priority=item.priority,
                summary=item.summary[:500],
                text=f"{item.summary}\n\nЦитата из совещания: {item.quote}",
                proposed_solution=item.proposed_solution,
                quote=item.quote,
                created_at=now,
            )
        )
    meeting.transcript = transcript.text
    meeting.status = MeetingStatus.READY


@registry.job(PROCESS_JOB, stale_after=timedelta(hours=2))
async def process_meeting(ctx: JobContext, payload: dict[str, Any]) -> None:
    """Расшифровка и черновики. Сбой сервиса повторяется, после последней попытки запись — `failed`."""
    meeting = await ctx.session.get(Meeting, payload["meeting_id"])
    if meeting is None or meeting.status != MeetingStatus.PROCESSING:
        return
    try:
        await _process(ctx, meeting)
    except Exception as exc:
        empty = isinstance(exc, ExternalServiceError) and exc.code == "speech_empty"
        if not (empty or isinstance(exc, OSError) or ctx.attempt >= PROCESS_ATTEMPTS):
            raise
        # Запись не должна остаться «обрабатывается» навсегда, а частичный результат — сохраниться.
        log.exception("Запись совещания #%s не обработана", payload["meeting_id"])
        await ctx.session.rollback()
        meeting = await ctx.session.get(Meeting, payload["meeting_id"])
        meeting.status, meeting.error = MeetingStatus.FAILED, EMPTY_RECORDING if empty else PROCESSING_FAILED
