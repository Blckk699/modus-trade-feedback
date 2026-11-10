"""Эскалация просроченного первого ответа (SPEC.md, «Сроки и эскалация»).

Три шага с интервалом в рабочий день, отсчёт — от срока первого ответа:
1. срок истёк — напоминание ответственному;
2. ещё через рабочий день — уведомление руководителю подразделения обращения;
3. ещё через рабочий день — обращение «Зависло» (блок в сводке собственника, B-13).

Эскалируются только обращения без первого ответа, с ответственным и сроком, не в финальном статусе.
У положительных отзывов срока нет — они не эскалируются. Сделанный шаг не повторяется: уровень
хранится в `Appeal.escalation_level`, переназначение до первого ответа сбрасывает его в 0.
"""

from __future__ import annotations

from datetime import datetime, tzinfo
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.appeals.history import record
from app.domain.business_days import add_business_days
from app.domain.enums import FINAL_STATUSES, AppealType, HistoryKind
from app.jobs.registry import JobContext, registry
from app.jobs.schedules import Every
from app.models import Appeal, Category, Department
from app.notifications import service as notify

STEP_COMMENTS = {
    1: "Срок первого ответа истёк — напоминание ответственному",
    2: "Ответа нет рабочий день после срока — уведомлён руководитель подразделения",
    3: "Ответа нет два рабочих дня после срока — обращение зависло",
}


def due_level(due: datetime, now: datetime, tz: tzinfo) -> int:
    """Какой шаг эскалации положен к моменту `now`: 0 — срок не истёк, дальше по рабочему дню на шаг."""
    level = 0
    while level < 3 and add_business_days(due, level, tz) <= now:
        level += 1
    return level


async def _department_head(session: AsyncSession, appeal: Appeal) -> int | None:
    if appeal.category_id is None:
        return None
    category = await session.get(Category, appeal.category_id)
    department = await session.get(Department, category.department_id) if category else None
    return department.head_id if department else None


async def escalate(session: AsyncSession, now: datetime, tz: tzinfo) -> int:
    """Выполняет созревшие шаги эскалации. Возвращает число выполненных шагов."""
    appeals = (
        await session.execute(
            select(Appeal)
            .where(
                Appeal.first_response_at.is_(None),
                Appeal.first_response_due_at.is_not(None),
                Appeal.first_response_due_at <= now,
                Appeal.assignee_id.is_not(None),
                Appeal.type != AppealType.PRAISE,
                Appeal.status.notin_(list(FINAL_STATUSES)),
                Appeal.escalation_level < 3,
            )
            .order_by(Appeal.id)
            .with_for_update(skip_locked=True)
        )
    ).scalars().all()
    steps = 0
    for appeal in appeals:
        target = due_level(appeal.first_response_due_at, now, tz)
        while appeal.escalation_level < target:
            step = appeal.escalation_level + 1
            if step == 1:
                await notify.deadline_reminder(session, appeal, now, tz)
            elif step == 2:
                head_id = await _department_head(session, appeal)
                if head_id is not None and head_id != appeal.assignee_id:
                    await notify.escalation_head(session, appeal, head_id, now)
            appeal.escalation_level = step
            record(
                session, appeal, HistoryKind.ESCALATED, now, None,
                field="escalation_level", old_value=step - 1, new_value=step, comment=STEP_COMMENTS[step],
            )
            steps += 1
    return steps


@registry.periodic("escalation.check", lambda s: Every(minutes=s.escalation_interval_minutes))
async def check_escalation(ctx: JobContext, payload: dict[str, Any]) -> None:
    await escalate(ctx.session, ctx.now(), ctx.settings.tz)
