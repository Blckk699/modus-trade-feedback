"""Создание уведомлений. Каждое событие, о котором должен узнать пользователь, становится записью
в `notifications`: бот забирает её и доставляет в Telegram, клиенты показывают счётчик непрочитанного.

Уведомление создаётся в той же транзакции, что и событие. Автор действия уведомление о своём же
действии не получает.
"""

from __future__ import annotations

from collections.abc import Iterable
from datetime import datetime
from html import escape

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.enums import AppealStatus, NotificationKind
from app.models import Appeal, AppealParticipant, Notification, User

STATUS_TEXT = {
    AppealStatus.IN_REVIEW: "взято на рассмотрение",
    AppealStatus.AWAITING_INFO: "ожидает вашего уточнения",
    AppealStatus.IN_PROGRESS: "в работе",
    AppealStatus.IMPLEMENTED: "реализовано",
    AppealStatus.REJECTED: "отклонено",
    AppealStatus.CLOSED: "закрыто",
}


def open_button(appeal: Appeal) -> dict:
    return {"type": "open_appeal", "text": "Открыть обращение", "appeal_id": appeal.id, "discussion_id": None}


def _title(appeal: Appeal) -> str:
    summary = f" «{escape(appeal.summary)}»" if appeal.summary else ""
    return f"<b>{escape(appeal.number)}</b>{summary}"


def _local(moment: datetime | None, tz) -> str:
    return moment.astimezone(tz).strftime("%d.%m %H:%M") if moment else "—"


def add(
    session: AsyncSession,
    user_id: int,
    kind: NotificationKind,
    text: str,
    now: datetime,
    *,
    appeal: Appeal | None = None,
    path: str | None = None,
    buttons: list[dict] | None = None,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        kind=kind,
        text=text,
        appeal_id=appeal.id if appeal else None,
        path=path if path is not None else (f"/appeals/{appeal.id}" if appeal else None),
        buttons=buttons if buttons is not None else ([open_button(appeal)] if appeal else []),
        next_attempt_at=now,
        attempts=0,
        failed_permanently=False,
        created_at=now,
    )
    session.add(notification)
    return notification


async def participants(session: AsyncSession, appeal: Appeal) -> list[int]:
    rows = await session.execute(select(AppealParticipant.user_id).where(AppealParticipant.appeal_id == appeal.id))
    return list(rows.scalars())


def _recipients(ids: Iterable[int | None], actor_id: int | None) -> list[int]:
    seen: list[int] = []
    for uid in ids:
        if uid is not None and uid != actor_id and uid not in seen:
            seen.append(uid)
    return seen


# --- события ---------------------------------------------------------------------------------------


async def appeal_created(session: AsyncSession, appeal: Appeal, now: datetime, tz) -> None:
    """Автору бота/формы: номер, ответственный и срок первого ответа (история 9)."""
    assignee = await session.get(User, appeal.assignee_id) if appeal.assignee_id else None
    who = escape(assignee.full_name) if assignee else "будет назначен администратором"
    due = f"\nСрок первого ответа: {_local(appeal.first_response_due_at, tz)}" if appeal.first_response_due_at else ""
    add(session, appeal.author_id, NotificationKind.APPEAL_CREATED,
        f"Обращение {_title(appeal)} зарегистрировано.\nОтветственный: {who}{due}", now, appeal=appeal)


async def appeal_assigned(session: AsyncSession, appeal: Appeal, assignee_id: int, actor_id: int | None, now: datetime, tz) -> None:
    """Ответственному: новое назначение, в том числе после переназначения (история 25)."""
    if assignee_id == actor_id:
        return
    due = f"\nСрок первого ответа: {_local(appeal.first_response_due_at, tz)}" if appeal.first_response_due_at else ""
    add(session, assignee_id, NotificationKind.APPEAL_ASSIGNED, f"Вам назначено обращение {_title(appeal)}.{due}", now, appeal=appeal)


async def status_changed(session: AsyncSession, appeal: Appeal, actor_id: int | None, now: datetime, detail: str | None = None) -> None:
    """Автору и участникам склеенных повторов — при каждой смене статуса (истории 12, 19)."""
    status = AppealStatus(appeal.status)
    text = f"Обращение {_title(appeal)} {STATUS_TEXT.get(status, status)}."
    if detail:
        label = {AppealStatus.REJECTED: "Причина", AppealStatus.IMPLEMENTED: "Результат", AppealStatus.IN_PROGRESS: "Решение"}.get(status)
        if label:
            text += f"\n{label}: {escape(detail)}"
    for uid in _recipients([appeal.author_id, *await participants(session, appeal)], actor_id):
        add(session, uid, NotificationKind.STATUS_CHANGED, text, now, appeal=appeal)


async def clarification_requested(session: AsyncSession, appeal: Appeal, question: str, actor_id: int, now: datetime) -> None:
    """Автору: уточняющий вопрос с кнопкой «Ответить» — ответ уходит прямо из бота (история 13)."""
    if appeal.author_id == actor_id:
        return
    add(
        session,
        appeal.author_id,
        NotificationKind.CLARIFICATION_REQUESTED,
        f"По обращению {_title(appeal)} вопрос от ответственного:\n{escape(question)}",
        now,
        appeal=appeal,
        buttons=[
            {"type": "reply_clarification", "text": "Ответить", "appeal_id": appeal.id, "discussion_id": None},
            open_button(appeal),
        ],
    )


async def clarification_answered(session: AsyncSession, appeal: Appeal, answer: str, actor_id: int, now: datetime) -> None:
    if appeal.assignee_id is None:
        return
    for uid in _recipients([appeal.assignee_id], actor_id):
        add(session, uid, NotificationKind.CLARIFICATION_ANSWERED,
            f"Автор ответил на уточнение по обращению {_title(appeal)}:\n{escape(answer)}", now, appeal=appeal)


async def message_received(session: AsyncSession, appeal: Appeal, author: User, text: str, now: datetime) -> None:
    """Новое сообщение в переписке: автору — от ответственной стороны, ответственному — от автора."""
    target = appeal.assignee_id if author.id == appeal.author_id else appeal.author_id
    for uid in _recipients([target], author.id):
        add(session, uid, NotificationKind.MESSAGE_RECEIVED,
            f"Новое сообщение по обращению {_title(appeal)} от {escape(author.full_name)}:\n{escape(text)}", now, appeal=appeal)


async def deadline_reminder(session: AsyncSession, appeal: Appeal, now: datetime, tz) -> None:
    """Эскалация, шаг 1: ответственному — срок первого ответа истёк (история 40)."""
    if appeal.assignee_id is None:
        return
    add(session, appeal.assignee_id, NotificationKind.DEADLINE_REMINDER,
        f"Истёк срок первого ответа по обращению {_title(appeal)} ({_local(appeal.first_response_due_at, tz)}). "
        "Ответьте автору, иначе обращение уйдёт руководителю.", now, appeal=appeal)


async def escalation_head(session: AsyncSession, appeal: Appeal, head_id: int, now: datetime) -> None:
    """Эскалация, шаг 2: руководителю подразделения — ответственный не ответил в срок (история 45)."""
    assignee = await session.get(User, appeal.assignee_id) if appeal.assignee_id else None
    who = escape(assignee.full_name) if assignee else "ответственный"
    add(session, head_id, NotificationKind.ESCALATION_HEAD,
        f"{who} не ответил в срок по обращению {_title(appeal)}. Можно ответить самому или переназначить.", now, appeal=appeal)


async def name_consent_request(session: AsyncSession, appeal: Appeal, discussion_id: int, now: datetime) -> None:
    """Автору при выносе на обсуждение: показывать ли имя (история 18)."""
    add(
        session,
        appeal.author_id,
        NotificationKind.NAME_CONSENT_REQUEST,
        f"Ваше обращение {_title(appeal)} вынесено на общее обсуждение.\n"
        "Показывать ваше имя? Без согласия будет указано только подразделение.",
        now,
        appeal=appeal,
        path=f"/discussions/{discussion_id}",
        buttons=[
            {"type": "name_consent_show", "text": "Показать имя", "appeal_id": appeal.id, "discussion_id": discussion_id},
            {"type": "name_consent_hide", "text": "Скрыть", "appeal_id": appeal.id, "discussion_id": discussion_id},
        ],
    )
