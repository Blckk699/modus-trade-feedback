"""Жизненный цикл обращения: переходы статусов, решения, приватная переписка (SPEC.md, «Жизненный цикл»).

Разрешены только переходы диаграммы спеки. Действие без прав — 403, действие в неподходящем
статусе — 409 `invalid_transition` с перечнем доступных действий. Всё пишется в историю.
"""

from __future__ import annotations

from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.appeals import policy
from app.appeals.history import record
from app.appeals.views import Directory, Extras, facts
from app.domain.enums import AppealAction, AppealStatus, AppealType, ClosedReason, HistoryKind
from app.errors import Forbidden, InvalidTransition
from app.models import Appeal, Message, User
from app.notifications import service as notify

STATUS_LABELS = {
    AppealStatus.NEW: "Новое",
    AppealStatus.IN_REVIEW: "На рассмотрении",
    AppealStatus.AWAITING_INFO: "Ожидает уточнения",
    AppealStatus.IN_PROGRESS: "В работе",
    AppealStatus.IMPLEMENTED: "Реализовано",
    AppealStatus.REJECTED: "Отклонено",
    AppealStatus.CLOSED: "Закрыто",
}


async def _check(session: AsyncSession, appeal: Appeal, user: User, action: AppealAction, *, who: str) -> list[str]:
    """Проверяет, что действие доступно. Возвращает отношения пользователя к обращению."""
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    f = facts(appeal, directory, extras)
    rel = policy.relations(user, f)
    allowed = policy.allowed_actions(user, f)
    if action in allowed:
        return rel
    actor_ok = {
        "process": policy.can_process(rel),
        "author": policy.ViewerRelation.AUTHOR in rel,
        "message": policy.can_read_messages(rel),
    }[who]
    if not actor_ok:
        raise Forbidden("Это действие вам недоступно")
    if action == AppealAction.ACCEPT_FEEDBACK and appeal.type != AppealType.PRAISE:
        message = "«Принять» есть только у положительного отзыва"
    elif action == AppealAction.TAKE and appeal.type == AppealType.PRAISE:
        message = "Положительный отзыв принимается одним действием «Принять»"
    else:
        message = f"Из статуса «{STATUS_LABELS[AppealStatus(appeal.status)]}» это действие недоступно"
    raise InvalidTransition(message, details={"action": action, "status": appeal.status, "allowed_actions": allowed})


def _move(appeal: Appeal, to: AppealStatus, actor: User, now: datetime, session: AsyncSession, comment: str | None = None) -> None:
    old = appeal.status
    appeal.status = to
    record(session, appeal, HistoryKind.STATUS_CHANGED, now, actor.id, field="status", old_value=old, new_value=to, comment=comment)


def _first_response(appeal: Appeal, now: datetime) -> None:
    if appeal.first_response_at is None:
        appeal.first_response_at = now


def _message(session: AsyncSession, appeal: Appeal, author: User, text: str, now: datetime, *, question: bool = False) -> Message:
    message = Message(appeal_id=appeal.id, author_id=author.id, text=text.strip(), is_clarification_question=question, created_at=now)
    session.add(message)
    return message


async def take(session: AsyncSession, appeal: Appeal, user: User, now: datetime, comment: str | None) -> None:
    await _check(session, appeal, user, AppealAction.TAKE, who="process")
    _first_response(appeal, now)
    if comment and comment.strip():
        _message(session, appeal, user, comment, now)
    _move(appeal, AppealStatus.IN_REVIEW, user, now, session)
    await notify.status_changed(session, appeal, user.id, now)


async def request_info(session: AsyncSession, appeal: Appeal, user: User, now: datetime, question: str) -> None:
    await _check(session, appeal, user, AppealAction.REQUEST_INFO, who="process")
    _first_response(appeal, now)
    _message(session, appeal, user, question, now, question=True)
    record(session, appeal, HistoryKind.CLARIFICATION_REQUESTED, now, user.id, comment=question.strip())
    _move(appeal, AppealStatus.AWAITING_INFO, user, now, session)
    await notify.clarification_requested(session, appeal, question.strip(), user.id, now)


async def start_work(session: AsyncSession, appeal: Appeal, user: User, now: datetime, decision: str) -> None:
    await _check(session, appeal, user, AppealAction.START_WORK, who="process")
    appeal.decision = decision.strip()
    _move(appeal, AppealStatus.IN_PROGRESS, user, now, session, appeal.decision)
    await notify.status_changed(session, appeal, user.id, now, appeal.decision)


async def reject(session: AsyncSession, appeal: Appeal, user: User, now: datetime, reason: str) -> None:
    await _check(session, appeal, user, AppealAction.REJECT, who="process")
    appeal.rejection_reason = reason.strip()
    _move(appeal, AppealStatus.REJECTED, user, now, session, appeal.rejection_reason)
    await notify.status_changed(session, appeal, user.id, now, appeal.rejection_reason)


async def implement(
    session: AsyncSession,
    appeal: Appeal,
    user: User,
    now: datetime,
    result: str,
    public_summary: str | None,
    public_result: str | None,
) -> None:
    await _check(session, appeal, user, AppealAction.IMPLEMENT, who="process")
    appeal.result = result.strip()
    appeal.public_summary = (public_summary or "").strip() or appeal.public_summary
    appeal.public_result = (public_result or "").strip() or None
    appeal.implemented_at = now
    _move(appeal, AppealStatus.IMPLEMENTED, user, now, session, appeal.result)
    await notify.status_changed(session, appeal, user.id, now, appeal.public_result or appeal.result)


async def accept_feedback(session: AsyncSession, appeal: Appeal, user: User, now: datetime, comment: str | None) -> None:
    await _check(session, appeal, user, AppealAction.ACCEPT_FEEDBACK, who="process")
    _first_response(appeal, now)
    if comment and comment.strip():
        _message(session, appeal, user, comment, now)
    appeal.closed_reason = ClosedReason.FEEDBACK_ACCEPTED
    _move(appeal, AppealStatus.CLOSED, user, now, session, "Положительный отзыв принят")
    await notify.status_changed(session, appeal, user.id, now)


async def ensure_can_read_messages(session: AsyncSession, appeal: Appeal, user: User) -> None:
    directory = await Directory.load(session)
    extras = await Extras.load(session, user, [appeal])
    if not policy.can_read_messages(policy.relations(user, facts(appeal, directory, extras))):
        raise Forbidden("Приватная переписка доступна автору, ответственному, руководителю и собственнику")


async def post_message(session: AsyncSession, appeal: Appeal, user: User, now: datetime, text: str) -> Message:
    """Сообщение в приватную переписку. Ответ автора на уточняющий вопрос возвращает обращение
    в «На рассмотрении». Первое сообщение ответственного фиксирует время первого ответа."""
    if appeal.status == AppealStatus.AWAITING_INFO and appeal.author_id == user.id:
        await _check(session, appeal, user, AppealAction.REPLY_CLARIFICATION, who="author")
        message = _message(session, appeal, user, text, now)
        record(session, appeal, HistoryKind.CLARIFICATION_ANSWERED, now, user.id, comment=text.strip())
        _move(appeal, AppealStatus.IN_REVIEW, user, now, session)
        await notify.clarification_answered(session, appeal, text.strip(), user.id, now)
        return message
    rel = await _check(session, appeal, user, AppealAction.SEND_MESSAGE, who="message")
    if policy.can_process(rel) and appeal.author_id != user.id:
        _first_response(appeal, now)
    message = _message(session, appeal, user, text, now)
    appeal.updated_at = now
    await notify.message_received(session, appeal, user, text.strip(), now)
    return message
