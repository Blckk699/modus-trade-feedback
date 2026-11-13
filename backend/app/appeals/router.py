"""Маршруты обращений: список, создание, карточка, история, вложения."""

from __future__ import annotations

from pathlib import Path
from typing import Annotated, Literal

from fastapi import APIRouter, File, Query, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import ClockDep, CurrentUserDep, SessionDep, SettingsDep
from app.appeals import policy, service
from app.appeals.previews import build_preview, has_preview
from app.appeals.schemas import AppealCreate, AppealOut, AppealPage, AttachmentOut, HistoryEventOut
from app.appeals.views import Directory, Extras, appeal_out, attachment_out, facts, list_item
from app.domain.enums import AppealAction, AppealSource, AppealStatus, AppealType, Priority
from app.errors import Forbidden, NotFound
from app.models import Appeal, Attachment, HistoryEvent

router = APIRouter(tags=["appeals"])

SORTS = {
    "created_desc": (Appeal.created_at.desc(), Appeal.id.desc()),
    "created_asc": (Appeal.created_at.asc(), Appeal.id.asc()),
    # Очередь ответственного: ближайший срок первым, без срока — в конце.
    "due_asc": (Appeal.first_response_due_at.asc().nulls_last(), Appeal.created_at.asc()),
}


@router.get("/appeals", response_model=AppealPage, summary="Список обращений, которые видит пользователь")
async def list_appeals(
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
    scope: Literal["all", "mine", "assigned", "department", "unassigned"] = "all",
    status: Annotated[list[AppealStatus] | None, Query()] = None,
    type: AppealType | None = None,
    priority: Priority | None = None,
    category_id: int | None = None,
    department_id: int | None = None,
    due: Literal["overdue", "due_today", "due_week", "no_deadline"] | None = None,
    q: str | None = None,
    sort: Literal["created_desc", "created_asc", "due_asc"] = "created_desc",
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=200)] = 50,
) -> AppealPage:
    now = clock.now()
    query = service.list_query(
        user,
        scope=scope,
        statuses=[s.value for s in status or []],
        type=type,
        priority=priority,
        category_id=category_id,
        department_id=department_id,
        due=due,
        q=q,
        now=now,
        tz=settings.tz,
        headed_ids=set((await session.execute(policy.headed_departments(user))).scalars()),
    )
    total = await session.scalar(service.count_query(query))
    rows = (
        await session.execute(query.order_by(*SORTS[sort]).offset((page - 1) * page_size).limit(page_size))
    ).scalars().all()
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, rows)
    items = [list_item(a, user, directory, extras, now) for a in rows]
    return AppealPage(items=items, total=total or 0, page=page, page_size=page_size)


@router.post("/appeals", response_model=AppealOut, status_code=201, summary="Создать обращение")
async def create_appeal(
    body: AppealCreate, user: CurrentUserDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> AppealOut:
    now = clock.now()
    appeal = await service.create_appeal(
        session,
        user,
        type=body.type,
        category_id=body.category_id,
        priority=body.priority,
        text_value=body.text,
        summary=body.summary,
        proposed_solution=body.proposed_solution,
        source=AppealSource(body.source),
        forwarded_from=body.forwarded_from,
        now=now,
        tz=settings.tz,
    )
    return await appeal_out(session, appeal, user, now)


@router.get("/appeals/{appeal_id}", response_model=AppealOut, summary="Карточка обращения")
async def get_appeal(appeal_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user, full=False)
    return await appeal_out(session, appeal, user, clock.now())


class ReassignIn(BaseModel):
    assignee_id: int
    # Обязательна при смене ответственного; при первом назначении её можно не передавать.
    reason: str | None = Field(default=None, max_length=2000)
    # Заодно задать или сменить категорию — например, обращению из очереди «Без ответственного».
    category_id: int | None = None


@router.post("/appeals/{appeal_id}/reassign", response_model=AppealOut, summary="Переназначить ответственного")
async def reassign_appeal(
    appeal_id: int, body: ReassignIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> AppealOut:
    appeal = await service.get_visible(session, appeal_id, user, lock=True)
    now = clock.now()
    await service.reassign(session, appeal, user, body.assignee_id, body.reason, now, settings.tz, category_id=body.category_id)
    return await appeal_out(session, appeal, user, now)


@router.get("/appeals/{appeal_id}/history", response_model=list[HistoryEventOut], summary="История обращения")
async def get_history(appeal_id: int, user: CurrentUserDep, session: SessionDep) -> list[HistoryEventOut]:
    await service.get_visible(session, appeal_id, user)
    directory = await Directory.load(session)
    events = await session.execute(
        select(HistoryEvent).where(HistoryEvent.appeal_id == appeal_id).order_by(HistoryEvent.created_at, HistoryEvent.id)
    )
    return [
        HistoryEventOut(
            id=e.id,
            appeal_id=e.appeal_id,
            kind=e.kind,
            actor=directory.user_brief(e.actor_id),
            field=e.field,
            old_value=e.old_value,
            new_value=e.new_value,
            comment=e.comment,
            created_at=e.created_at,
        )
        for e in events.scalars()
    ]


@router.get("/appeals/{appeal_id}/attachments", response_model=list[AttachmentOut], summary="Вложения обращения")
async def list_attachments(appeal_id: int, user: CurrentUserDep, session: SessionDep) -> list[AttachmentOut]:
    appeal = await service.get_visible(session, appeal_id, user)
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    rows = await session.execute(select(Attachment).where(Attachment.appeal_id == appeal_id).order_by(Attachment.id))
    return [attachment_out(a, directory, user, facts(appeal, directory, extras)) for a in rows.scalars()]


@router.post(
    "/appeals/{appeal_id}/attachments", response_model=AttachmentOut, status_code=201, summary="Приложить файл"
)
async def upload_attachment(
    appeal_id: int,
    file: Annotated[UploadFile, File()],
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
) -> AttachmentOut:
    appeal = await service.get_visible(session, appeal_id, user, lock=True)
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    appeal_facts = facts(appeal, directory, extras)
    if AppealAction.UPLOAD_ATTACHMENT not in policy.allowed_actions(user, appeal_facts):
        raise Forbidden("Приложить файл могут автор и ответственный, пока обращение не закрыто")
    attachment = await service.save_attachment(session, appeal, user, file, settings, clock.now())
    return attachment_out(attachment, directory, user, appeal_facts)


@router.get("/attachments/{attachment_id}", summary="Скачать файл или его уменьшенную копию", response_class=FileResponse)
async def download_attachment(
    attachment_id: int, user: CurrentUserDep, session: SessionDep, settings: SettingsDep, preview: bool = False
) -> FileResponse:
    attachment = await session.get(Attachment, attachment_id)
    if attachment is None:
        raise NotFound("Файл не найден")
    await service.get_visible(session, attachment.appeal_id, user)
    path = Path(settings.attachments_dir) / attachment.storage_key
    if not path.is_file():
        raise NotFound("Файл не найден в хранилище")
    if preview:
        small = await run_in_threadpool(build_preview, path) if has_preview(attachment.content_type) else None
        if small is None:
            raise NotFound("У этого файла нет уменьшенной копии")
        # Копия не меняется, пока жив файл; отдаётся только вошедшему пользователю.
        return FileResponse(small, media_type="image/jpeg", headers={"Cache-Control": "private, max-age=86400"})
    return FileResponse(path, media_type=attachment.content_type, filename=attachment.filename)


@router.delete("/attachments/{attachment_id}", status_code=204, summary="Удалить файл")
async def delete_attachment(
    attachment_id: int, user: CurrentUserDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> None:
    attachment = await session.get(Attachment, attachment_id)
    if attachment is None:
        raise NotFound("Файл не найден")
    appeal = await service.get_visible(session, attachment.appeal_id, user, lock=True)
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    appeal_facts = facts(appeal, directory, extras)
    allowed = policy.can_delete_attachment(
        policy.relations(user, appeal_facts), appeal_facts.status, is_uploader=attachment.uploaded_by_id == user.id
    )
    if not allowed:
        raise Forbidden("Удалить файл могут тот, кто его загрузил, и ответственный, пока обращение не закрыто")
    await service.delete_attachment(session, appeal, attachment, user, settings, clock.now())
