"""Операции с обращениями: создание, поиск видимого, список с фильтрами, вложения."""

from __future__ import annotations

import uuid
from datetime import datetime, time, timedelta, tzinfo
from pathlib import Path

from fastapi import UploadFile
from sqlalchemy import Select, and_, func, or_, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.appeals import policy, routing
from app.appeals.history import record
from app.appeals.views import Directory, Extras, facts
from app.config import Settings
from app.domain.enums import FINAL_STATUSES, AppealSource, AppealStatus, AppealType, HistoryKind, Role
from app.errors import FileTooLarge, Forbidden, InvalidTransition, NotFound, ValidationFailed
from app.models import Appeal, Attachment, Category, User

SOURCE_LABELS = {AppealSource.FORM: "через форму", AppealSource.BOT: "через бота", AppealSource.MEETING: "на совещании"}


def default_summary(text_value: str, limit: int = 120) -> str:
    words = " ".join(text_value.split())
    if len(words) <= limit:
        return words
    cut = words[:limit].rsplit(" ", 1)[0]
    return cut + "…"


async def create_appeal(
    session: AsyncSession,
    author: User,
    *,
    type: AppealType,
    category_id: int | None,
    priority: str,
    text_value: str,
    summary: str | None,
    proposed_solution: str | None,
    source: AppealSource,
    forwarded_from: str | None,
    now: datetime,
    tz: tzinfo,
) -> Appeal:
    """Регистрирует обращение в статусе «Новое» и сразу маршрутизирует: ответственный и срок."""
    if category_id is not None:
        category = await session.get(Category, category_id)
        if category is None or not category.is_active:
            raise ValidationFailed(
                "Такой категории нет", details={"fields": [{"field": "category_id", "message": "Неизвестная категория"}]}
            )
    appeal_id = await session.scalar(text("SELECT nextval(pg_get_serial_sequence('appeals', 'id'))"))
    appeal = Appeal(
        id=appeal_id,
        number=f"A-{appeal_id:03d}",
        type=type,
        category_id=category_id,
        priority=priority,
        status="new",
        author_id=author.id,
        assignee_id=None,
        text=text_value.strip(),
        summary=(summary or "").strip() or default_summary(text_value),
        proposed_solution=(proposed_solution or "").strip() or None,
        source=source,
        forwarded_from=(forwarded_from or "").strip() or None,
        escalation_level=0,
        created_at=now,
        updated_at=now,
    )
    session.add(appeal)
    await session.flush()
    record(session, appeal, HistoryKind.CREATED, now, author.id, comment=f"Подано {SOURCE_LABELS[source]}")
    await routing.route_new_appeal(session, appeal, now, tz)
    return appeal


async def reassign(
    session: AsyncSession, appeal: Appeal, actor: User, assignee_id: int, reason: str, now: datetime, tz: tzinfo
) -> None:
    """Переназначение с причиной: руководитель (в своём подразделении), администратор, собственник.
    Срок первого ответа отсчитывается заново."""
    directory = await Directory.load(session)
    extras = await Extras.load(session, actor, [appeal])
    rel = policy.relations(actor, facts(appeal, directory, extras))
    if not policy.can_reassign(rel):
        raise Forbidden("Переназначить ответственного могут руководитель, администратор и собственник")
    if AppealStatus(appeal.status).is_final:
        raise InvalidTransition(
            "Завершённое обращение не переназначается",
            details={"action": "reassign", "status": appeal.status, "allowed_actions": []},
        )
    assignee = await session.get(User, assignee_id)
    if assignee is None or assignee.is_disabled:
        raise ValidationFailed(
            "Такого сотрудника нет или доступ отключён",
            details={"fields": [{"field": "assignee_id", "message": "Выберите действующего сотрудника"}]},
        )
    if assignee.id == appeal.assignee_id:
        raise ValidationFailed(
            "Этот сотрудник уже ответственный",
            details={"fields": [{"field": "assignee_id", "message": "Выберите другого сотрудника"}]},
        )
    kind = HistoryKind.REASSIGNED if appeal.assignee_id else HistoryKind.ASSIGNED
    await routing.assign(session, appeal, assignee, now, tz, actor_id=actor.id, reason=reason.strip(), kind=kind)


async def get_visible(session: AsyncSession, appeal_id: int, user: User, *, full: bool = True) -> Appeal:
    """Обращение, которое пользователь видит. Нет такого — 404, не видит — 403.

    `full=True` требует полный доступ: участник склеенного повтора видит только карточку.
    """
    appeal = await session.get(Appeal, appeal_id)
    if appeal is None:
        raise NotFound("Обращение не найдено")
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    rel = policy.relations(user, facts(appeal, directory, extras))
    if not rel or (full and not policy.full_access(rel)):
        raise Forbidden("Это обращение вам недоступно")
    return appeal


def _local_day_bounds(now: datetime, tz: tzinfo, days: int = 1, *, from_monday: bool = False) -> tuple[datetime, datetime]:
    local = now.astimezone(tz)
    start_day = local.date() - timedelta(days=local.weekday() if from_monday else 0)
    start = datetime.combine(start_day, time(0, 0), tzinfo=tz)
    return start, start + timedelta(days=days)


def list_query(
    user: User,
    *,
    scope: str,
    statuses: list[str],
    type: str | None,
    priority: str | None,
    category_id: int | None,
    department_id: int | None,
    due: str | None,
    q: str | None,
    now: datetime,
    tz: tzinfo,
    headed_ids: set[int],
) -> Select:
    query = select(Appeal).where(policy.visible_filter(user))
    if scope == "mine":
        from app.models import AppealParticipant

        mine = select(AppealParticipant.appeal_id).where(AppealParticipant.user_id == user.id)
        query = query.where(or_(Appeal.author_id == user.id, Appeal.id.in_(mine)))
    elif scope == "assigned":
        query = query.where(Appeal.assignee_id == user.id)
    elif scope == "department":
        if not headed_ids:
            raise Forbidden("Обращения подразделения видит его руководитель")
        query = query.where(Appeal.category_id.in_(select(Category.id).where(Category.department_id.in_(headed_ids))))
    elif scope == "unassigned":
        if user.role not in (Role.ADMIN, Role.OWNER):
            raise Forbidden("Очередь нераспределённых доступна администратору")
        query = query.where(Appeal.assignee_id.is_(None), Appeal.status.notin_(list(FINAL_STATUSES)))

    if statuses:
        query = query.where(Appeal.status.in_(statuses))
    if type:
        query = query.where(Appeal.type == type)
    if priority:
        query = query.where(Appeal.priority == priority)
    if category_id is not None:
        query = query.where(Appeal.category_id == category_id)
    if department_id is not None:
        query = query.where(Appeal.category_id.in_(select(Category.id).where(Category.department_id == department_id)))

    waiting = and_(
        Appeal.first_response_at.is_(None),
        Appeal.first_response_due_at.is_not(None),
        Appeal.status.notin_(list(FINAL_STATUSES)),
    )
    if due == "overdue":
        query = query.where(waiting, Appeal.first_response_due_at <= now)
    elif due == "due_today":
        start, end = _local_day_bounds(now, tz)
        query = query.where(waiting, Appeal.first_response_due_at >= start, Appeal.first_response_due_at < end)
    elif due == "due_week":
        start, end = _local_day_bounds(now, tz, 7, from_monday=True)
        query = query.where(waiting, Appeal.first_response_due_at >= start, Appeal.first_response_due_at < end)
    elif due == "no_deadline":
        query = query.where(Appeal.first_response_due_at.is_(None))

    if q and q.strip():
        pattern = f"%{q.strip()}%"
        # По тексту ищем только среди обращений, видимых полностью: участник склеенного повтора
        # не должен находить основное обращение по словам скрытого от него текста.
        in_text = and_(Appeal.text.ilike(pattern), policy.full_visible_filter(user))
        query = query.where(or_(Appeal.number.ilike(pattern), Appeal.summary.ilike(pattern), in_text))
    return query


async def save_attachment(
    session: AsyncSession, appeal: Appeal, user: User, upload: UploadFile, settings: Settings, now: datetime
) -> Attachment:
    directory = Path(settings.attachments_dir) / str(appeal.id)
    directory.mkdir(parents=True, exist_ok=True)
    storage_name = uuid.uuid4().hex
    path = directory / storage_name
    size = 0
    try:
        with path.open("wb") as out:
            while chunk := await upload.read(1024 * 1024):
                size += len(chunk)
                if size > settings.attachment_max_bytes:
                    raise FileTooLarge(
                        f"Файл больше {settings.attachment_max_bytes // (1024 * 1024)} МБ.",
                        details={"max_bytes": settings.attachment_max_bytes},
                    )
                out.write(chunk)
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    attachment = Attachment(
        appeal_id=appeal.id,
        filename=(upload.filename or "файл")[:300],
        content_type=(upload.content_type or "application/octet-stream")[:150],
        size_bytes=size,
        storage_key=f"{appeal.id}/{storage_name}",
        uploaded_by_id=user.id,
        created_at=now,
    )
    session.add(attachment)
    await session.flush()
    record(session, appeal, HistoryKind.ATTACHMENT_ADDED, now, user.id, new_value=attachment.filename)
    return attachment


def count_query(query: Select) -> Select:
    return select(func.count()).select_from(query.order_by(None).subquery())
