"""Сбор событий для живых обновлений из самой сессии базы.

Источник — те же записи, что и у истории и уведомлений: новая строка истории, сообщения, уведомления,
голос или комментарий. Слушатели смотрят, что сессия записала, и после фиксации отдают это шине.
Так событие нельзя забыть в новом маршруте и нельзя отправить по откатившейся транзакции.
Работает только у сессий, созданных фабрикой приложения (`info["live_hub"]`).
"""

from __future__ import annotations

from sqlalchemy import event, inspect
from sqlalchemy.orm import ORMExecuteState, Session

from app.domain.enums import DiscussionStatus
from app.live.hub import LiveHub, Pending
from app.models import (
    AuthSession,
    Discussion,
    DiscussionComment,
    DiscussionVote,
    HistoryEvent,
    Message,
    Notification,
    User,
)

HUB_KEY = "live_hub"
PENDING_KEY = "live_pending"


def _pending(session: Session) -> Pending | None:
    if session.info.get(HUB_KEY) is None:
        return None
    return session.info.setdefault(PENDING_KEY, Pending())


def _changed(obj: object, attribute: str) -> bool:
    return inspect(obj).attrs[attribute].history.has_changes()


@event.listens_for(Session, "after_flush")
def _collect(session: Session, _context: object) -> None:
    pending = _pending(session)
    if pending is None:
        return
    for obj in session.new:
        if isinstance(obj, HistoryEvent):
            pending.history.append((obj.appeal_id, str(obj.kind)))
        elif isinstance(obj, Message):
            pending.messages.append((obj.appeal_id, obj.id))
        elif isinstance(obj, Notification):
            if obj.user_id is not None:
                pending.notifications.append((obj.user_id, obj.id))
        elif isinstance(obj, Discussion):
            pending.discussions.append((obj.id, "published"))
        elif isinstance(obj, DiscussionVote):
            pending.discussions.append((obj.discussion_id, "vote"))
        elif isinstance(obj, DiscussionComment):
            pending.discussions.append((obj.discussion_id, "comment"))
    for obj in session.dirty:
        if isinstance(obj, Discussion):
            if _changed(obj, "status") and obj.status == DiscussionStatus.CLOSED:
                pending.discussions.append((obj.id, "closed"))
            elif _changed(obj, "author_name_consent"):
                pending.discussions.append((obj.id, "name_consent"))
        elif isinstance(obj, DiscussionVote):
            if _changed(obj, "value"):
                pending.discussions.append((obj.discussion_id, "vote"))
        elif isinstance(obj, User):
            if _changed(obj, "is_disabled") or _changed(obj, "role"):
                pending.sweep = True
        elif isinstance(obj, AuthSession):
            pending.sweep = True
    for obj in session.deleted:
        if isinstance(obj, DiscussionVote):
            pending.discussions.append((obj.discussion_id, "vote"))


@event.listens_for(Session, "do_orm_execute")
def _watch_session_revocation(state: ORMExecuteState) -> None:
    """Сессии закрываются массовым UPDATE (выход, смена и сброс пароля, отключение доступа)."""
    if not (state.is_update or state.is_delete):
        return
    mapper = state.bind_mapper
    if mapper is not None and mapper.class_ in (AuthSession, User):
        pending = _pending(state.session)
        if pending is not None:
            pending.sweep = True


@event.listens_for(Session, "after_commit")
def _publish(session: Session) -> None:
    pending = session.info.pop(PENDING_KEY, None)
    hub: LiveHub | None = session.info.get(HUB_KEY)
    if pending and hub is not None:
        hub.publish(pending)


@event.listens_for(Session, "after_rollback")
def _discard(session: Session) -> None:
    session.info.pop(PENDING_KEY, None)
