"""Уведомления: список и счётчик непрочитанного для клиентов, очередь доставки для бота."""

from __future__ import annotations

from datetime import timedelta
from typing import Annotated

from fastapi import APIRouter, Query, Response
from pydantic import BaseModel, Field
from sqlalchemy import and_, func, or_, select, update

from app.api.deps import BotKeyDep, ClockDep, CurrentUserDep, SessionDep
from app.appeals.schemas import AppealRef
from app.appeals.views import appeal_ref
from app.clock import LocalDatetime
from app.errors import NotFound
from app.models import Appeal, Notification, User

router = APIRouter(tags=["notifications"])

MAX_RETRY_DELAY = timedelta(hours=1)
# После стольких неудачных попыток уведомление считается недоставленным и больше не выдаётся.
MAX_ATTEMPTS = 20
# Неотправленное старше этого бот не получает: после привязки Telegram не придёт хвост за месяц.
PENDING_MAX_AGE = timedelta(days=2)


class NotificationButton(BaseModel):
    type: str
    text: str
    appeal_id: int | None = None
    discussion_id: int | None = None


class NotificationOut(BaseModel):
    id: int
    kind: str
    text: str
    appeal: AppealRef | None
    path: str | None
    buttons: list[NotificationButton]
    is_read: bool
    created_at: LocalDatetime


class NotificationPage(BaseModel):
    items: list[NotificationOut]
    total: int
    page: int
    page_size: int


class Recipient(BaseModel):
    user_id: int | None
    telegram_id: int


class BotNotificationOut(NotificationOut):
    recipient: Recipient
    attempts: int


class UnreadCount(BaseModel):
    count: int


class MarkReadIn(BaseModel):
    all: bool = False
    appeal_id: int | None = None
    ids: list[int] | None = None


class AckIn(BaseModel):
    telegram_message_id: int | None = None


class FailIn(BaseModel):
    error: str | None = Field(default=None, max_length=2000)
    permanent: bool = False


async def _appeals(session, notifications: list[Notification]) -> dict[int, Appeal]:
    ids = {n.appeal_id for n in notifications if n.appeal_id}
    if not ids:
        return {}
    return {a.id: a for a in (await session.execute(select(Appeal).where(Appeal.id.in_(ids)))).scalars()}


def _out(n: Notification, appeals: dict[int, Appeal]) -> dict:
    appeal = appeals.get(n.appeal_id) if n.appeal_id else None
    return dict(
        id=n.id,
        kind=n.kind,
        text=n.text,
        appeal=appeal_ref(appeal) if appeal else None,
        path=n.path,
        buttons=n.buttons or [],
        is_read=n.read_at is not None,
        created_at=n.created_at,
    )


async def _unread(session, user_id: int) -> int:
    return await session.scalar(
        select(func.count()).select_from(Notification).where(Notification.user_id == user_id, Notification.read_at.is_(None))
    ) or 0


# --- клиенты ---------------------------------------------------------------------------------------


@router.get("/notifications", response_model=NotificationPage, summary="Уведомления пользователя")
async def list_notifications(
    user: CurrentUserDep,
    session: SessionDep,
    unread_only: bool = False,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=200)] = 50,
) -> NotificationPage:
    query = select(Notification).where(Notification.user_id == user.id)
    if unread_only:
        query = query.where(Notification.read_at.is_(None))
    total = await session.scalar(select(func.count()).select_from(query.subquery()))
    rows = (
        await session.execute(query.order_by(Notification.created_at.desc(), Notification.id.desc()).offset((page - 1) * page_size).limit(page_size))
    ).scalars().all()
    appeals = await _appeals(session, rows)
    return NotificationPage(items=[NotificationOut(**_out(n, appeals)) for n in rows], total=total or 0, page=page, page_size=page_size)


@router.get("/notifications/unread-count", response_model=UnreadCount, summary="Счётчик непрочитанного")
async def unread_count(user: CurrentUserDep, session: SessionDep) -> UnreadCount:
    return UnreadCount(count=await _unread(session, user.id))


@router.post("/notifications/read", response_model=UnreadCount, summary="Отметить прочитанным")
async def mark_read(body: MarkReadIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep) -> UnreadCount:
    conditions = []
    if body.all:
        conditions.append(Notification.id.is_not(None))
    if body.appeal_id is not None:
        conditions.append(Notification.appeal_id == body.appeal_id)
    if body.ids:
        conditions.append(Notification.id.in_(body.ids))
    if conditions:
        await session.execute(
            update(Notification)
            .where(Notification.user_id == user.id, Notification.read_at.is_(None), or_(*conditions))
            .values(read_at=clock.now())
        )
    return UnreadCount(count=await _unread(session, user.id))


# --- бот -------------------------------------------------------------------------------------------


@router.get("/bot/notifications/pending", response_model=list[BotNotificationOut], tags=["bot"], summary="Очередь для бота")
async def pending(_: BotKeyDep, session: SessionDep, clock: ClockDep, limit: Annotated[int, Query(ge=1, le=200)] = 50) -> list[BotNotificationOut]:
    """Неподтверждённые уведомления, у которых пришло время попытки. Получатели без Telegram пропускаются."""
    rows = (
        await session.execute(
            select(Notification, func.coalesce(User.telegram_id, Notification.telegram_id))
            .outerjoin(User, User.id == Notification.user_id)
            .where(
                Notification.delivered_at.is_(None),
                Notification.failed_permanently.is_(False),
                Notification.next_attempt_at <= clock.now(),
                Notification.created_at > clock.now() - PENDING_MAX_AGE,
                # Пользователю — если у него есть Telegram и доступ не отключён;
                # незаведённому заявителю (user_id пуст) — по telegram_id уведомления.
                or_(
                    and_(User.id.is_not(None), User.telegram_id.is_not(None), User.is_disabled.is_(False)),
                    and_(Notification.user_id.is_(None), Notification.telegram_id.is_not(None)),
                ),
            )
            .order_by(Notification.id)
            .limit(limit)
        )
    ).all()
    appeals = await _appeals(session, [n for n, _ in rows])
    return [
        BotNotificationOut(
            **_out(n, appeals), recipient=Recipient(user_id=n.user_id, telegram_id=telegram_id), attempts=n.attempts
        )
        for n, telegram_id in rows
    ]


async def _bot_notification(session, notification_id: int) -> Notification:
    notification = await session.get(Notification, notification_id, with_for_update=True)
    if notification is None:
        raise NotFound("Уведомление не найдено")
    return notification


@router.post("/bot/notifications/{notification_id}/ack", status_code=204, tags=["bot"], summary="Доставка подтверждена")
async def ack(notification_id: int, _: BotKeyDep, session: SessionDep, clock: ClockDep, body: AckIn | None = None) -> Response:
    notification = await _bot_notification(session, notification_id)
    if notification.delivered_at is None:
        notification.delivered_at = clock.now()
        notification.attempts += 1
        notification.telegram_message_id = body.telegram_message_id if body else None
    return Response(status_code=204)


@router.post("/bot/notifications/{notification_id}/fail", status_code=204, tags=["bot"], summary="Доставка не удалась")
async def fail(notification_id: int, _: BotKeyDep, session: SessionDep, clock: ClockDep, body: FailIn | None = None) -> Response:
    notification = await _bot_notification(session, notification_id)
    if notification.delivered_at is not None:
        return Response(status_code=204)
    body = body or FailIn()
    notification.attempts += 1
    notification.last_error = body.error
    if body.permanent:
        notification.failed_permanently = True
    else:
        if notification.attempts >= MAX_ATTEMPTS:
            notification.failed_permanently = True
        # Показатель ограничен до построения timedelta: 2**N минут переполнились бы на десятках попыток.
        delay = min(timedelta(minutes=2 ** min(notification.attempts - 1, 6)), MAX_RETRY_DELAY)
        notification.next_attempt_at = clock.now() + delay
    return Response(status_code=204)
