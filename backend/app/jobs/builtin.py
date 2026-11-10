"""Образцовая периодическая задача механизма: чистка старых выполненных задач.

Шаблон для B-07 (эскалация) и B-13 (сводка):

    @registry.periodic("escalation.check", lambda s: Every(minutes=s.escalation_interval_minutes))
    async def check_escalation(ctx: JobContext, payload: dict) -> None:
        now = ctx.now()
        ...  # работа через ctx.session и ctx.services; коммит сделает механизм

    @registry.periodic("digest.send", lambda s: DailyAt(s.digest_time))
    async def send_digest(ctx: JobContext, payload: dict) -> None: ...
"""

from __future__ import annotations

from datetime import time, timedelta
from typing import Any

from sqlalchemy import delete

from app.jobs.models import Job, JobStatus
from app.jobs.registry import JobContext, registry
from app.jobs.schedules import DailyAt

KEEP_FINISHED_FOR = timedelta(days=7)


@registry.periodic("jobs.cleanup", DailyAt(time(3, 0)))
async def cleanup_finished_jobs(ctx: JobContext, payload: dict[str, Any]) -> None:
    """Раз в сутки (03:00 по времени системы) удаляет выполненные задачи старше недели.
    Упавшие (failed) не трогаем: они нужны для разбора."""
    await ctx.session.execute(
        delete(Job).where(Job.status == JobStatus.DONE, Job.finished_at < ctx.now() - KEEP_FINISHED_FOR)
    )
