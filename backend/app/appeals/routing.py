"""Маршрутизация: кому назначить обращение и какой у него срок первого ответа (SPEC.md, «Маршрутизация»).

- Ответственного назначает правило категории, не модель.
- Ответственный отмечен отсутствующим (или отключён) — обращение получает заместитель.
- Нет обоих или категория не определена — обращение попадает в очередь администратора.
- Срок первого ответа назначается вместе с ответственным: N рабочих дней по приоритету из настроек.
  У положительного отзыва срока нет.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, tzinfo

from sqlalchemy.ext.asyncio import AsyncSession

from app.appeals.history import record
from app.domain.business_days import add_business_days
from app.domain.enums import AppealType, HistoryKind
from app.models import Appeal, Category, DeadlineRule, User
from app.notifications import service as notify

DEFAULT_RULES = {"high": 1, "medium": 3, "low": 5}


@dataclass(frozen=True)
class Route:
    assignee: User | None
    reason: str


def _available(user: User | None) -> bool:
    return user is not None and not user.is_absent and not user.is_disabled


async def choose_assignee(session: AsyncSession, category_id: int | None) -> Route:
    category = await session.get(Category, category_id) if category_id is not None else None
    if category is None:
        return Route(None, "Категория не определена — в очереди администратора")
    responsible = await session.get(User, category.responsible_id) if category.responsible_id else None
    deputy = await session.get(User, category.deputy_id) if category.deputy_id else None
    if _available(responsible):
        return Route(responsible, f"По правилу категории «{category.name}»")
    if _available(deputy):
        why = "отсутствует" if responsible is not None else "не назначен"
        return Route(deputy, f"Заместитель по категории «{category.name}»: ответственный {why}")
    return Route(None, f"У категории «{category.name}» нет доступного ответственного и заместителя — в очереди администратора")


async def first_response_deadline(session: AsyncSession, appeal: Appeal, start: datetime, tz: tzinfo) -> datetime | None:
    if appeal.type == AppealType.PRAISE:
        return None
    rule = await session.get(DeadlineRule, appeal.priority)
    days = rule.business_days if rule else DEFAULT_RULES[appeal.priority]
    return add_business_days(start, days, tz)


async def assign(
    session: AsyncSession,
    appeal: Appeal,
    assignee: User | None,
    now: datetime,
    tz: tzinfo,
    *,
    actor_id: int | None,
    reason: str,
    kind: HistoryKind,
) -> None:
    """Назначает ответственного и заново отсчитывает срок первого ответа; всё пишет в историю."""
    old = await session.get(User, appeal.assignee_id) if appeal.assignee_id else None
    appeal.assignee_id = assignee.id if assignee else None
    appeal.first_response_due_at = await first_response_deadline(session, appeal, now, tz) if assignee else None
    appeal.escalation_level = 0
    record(
        session,
        appeal,
        kind,
        now,
        actor_id,
        field="assignee",
        old_value=old.full_name if old else None,
        new_value=assignee.full_name if assignee else None,
        comment=reason,
    )
    if assignee is not None:
        await notify.appeal_assigned(session, appeal, assignee.id, actor_id, now, tz)
    if appeal.first_response_due_at is not None:
        record(
            session,
            appeal,
            HistoryKind.DEADLINE_SET,
            now,
            None,
            field="first_response_due_at",
            new_value=appeal.first_response_due_at.isoformat(),
        )


async def route_new_appeal(session: AsyncSession, appeal: Appeal, now: datetime, tz: tzinfo) -> None:
    route = await choose_assignee(session, appeal.category_id)
    await assign(session, appeal, route.assignee, now, tz, actor_id=None, reason=route.reason, kind=HistoryKind.ASSIGNED)
    if appeal.source != "bot":  # бот сам отвечает автору номером и сроком — без дубля
        await notify.appeal_created(session, appeal, now, tz)
