"""Исполнитель фоновых задач: очередь в Postgres + цикл внутри процесса API.

Один шаг (`tick`) делает три вещи при текущем времени из `Clock`:
1. возвращает в очередь задачи, «застрявшие» в running после падения процесса;
2. ставит в очередь созревшие периодические задачи;
3. выполняет все разовые задачи с `run_at <= now`.

В проде `run_forever` вызывает `tick` раз в JOBS_POLL_SECONDS. В тестах воркер выключен,
а тест двигает часы и вызывает `tick` сам — синхронно и детерминированно.
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.config import Settings
from app.container import Services
from app.jobs.models import Job, JobStatus, PeriodicTask
from app.jobs.registry import JobContext, JobRegistry

log = logging.getLogger(__name__)

STALE_RUNNING_AFTER = timedelta(minutes=30)
MAX_JOBS_PER_TICK = 500


def retry_delay(attempt: int) -> timedelta:
    """Пауза перед повтором упавшей задачи: 1, 2, 4… минут."""
    return timedelta(minutes=2 ** max(attempt - 1, 0))


async def enqueue(
    session: AsyncSession,
    kind: str,
    payload: dict[str, Any] | None = None,
    *,
    run_at: datetime,
    dedup_key: str | None = None,
    max_attempts: int = 3,
) -> int | None:
    """Ставит разовую задачу в очередь в рамках текущей транзакции.

    `run_at` обязателен: берите его из часов (`clock.now()` — «как можно скорее»), а не из базы,
    иначе в тестах с замороженным временем задача не созреет. Возвращает id задачи или None,
    если задача с таким `dedup_key` уже есть.
    """
    stmt = (
        insert(Job)
        .values(
            kind=kind,
            payload=payload or {},
            status=JobStatus.PENDING,
            run_at=run_at,
            attempts=0,
            max_attempts=max_attempts,
            dedup_key=dedup_key,
            created_at=run_at,
        )
        .on_conflict_do_nothing(index_elements=[Job.dedup_key])
        .returning(Job.id)
    )
    return (await session.execute(stmt)).scalar_one_or_none()


class JobRunner:
    def __init__(
        self,
        registry: JobRegistry,
        sessionmaker: async_sessionmaker[AsyncSession],
        services: Services,
        settings: Settings,
    ) -> None:
        self.registry = registry
        self.sessionmaker = sessionmaker
        self.services = services
        self.settings = settings

    def now(self) -> datetime:
        return self.services.clock.now()

    async def tick(self) -> int:
        """Один шаг воркера. Возвращает число выполненных (успешно или нет) задач."""
        now = self.now()
        await self.requeue_stale(now)
        await self.schedule_periodic(now)
        return await self.run_due()

    async def requeue_stale(self, now: datetime) -> None:
        async with self.sessionmaker() as session, session.begin():
            await session.execute(
                update(Job)
                .where(Job.status == JobStatus.RUNNING, Job.started_at < now - STALE_RUNNING_AFTER)
                .values(status=JobStatus.PENDING, run_at=now)
            )

    async def schedule_periodic(self, now: datetime) -> None:
        tz = self.settings.tz
        for spec in self.registry.periodic_specs.values():
            schedule = spec.resolve(self.settings)
            schedule_key = f"{schedule.describe()} {tz.tzname(None)}"
            async with self.sessionmaker() as session, session.begin():
                row = await session.get(PeriodicTask, spec.name, with_for_update=True)
                if row is None:
                    await session.execute(
                        insert(PeriodicTask)
                        .values(name=spec.name, schedule=schedule_key, next_run_at=schedule.next_after(now, tz))
                        .on_conflict_do_nothing(index_elements=[PeriodicTask.name])
                    )
                    continue
                if row.schedule != schedule_key:
                    row.schedule = schedule_key
                    row.next_run_at = schedule.next_after(now, tz)
                    continue
                if row.next_run_at > now:
                    continue
                # Ключ от двойной постановки, если два процесса дошли сюда одновременно.
                await enqueue(
                    session,
                    spec.name,
                    {"scheduled_for": row.next_run_at.isoformat()},
                    run_at=row.next_run_at,
                    dedup_key=f"periodic:{spec.name}:{row.next_run_at.isoformat()}",
                )
                row.last_run_at = now
                # Пропущенные запуски (сервер лежал) не догоняем: следующий — от текущего момента.
                row.next_run_at = schedule.next_after(now, tz)

    async def run_due(self) -> int:
        """Выполняет все задачи, созревшие к текущему времени часов. Возвращает их число."""
        processed = 0
        while processed < MAX_JOBS_PER_TICK:
            claimed = await self._claim(self.now())
            if claimed is None:
                break
            await self._execute(*claimed)
            processed += 1
        return processed

    async def _claim(self, now: datetime) -> tuple[int, str, dict[str, Any], int, int] | None:
        async with self.sessionmaker() as session, session.begin():
            job = (
                await session.execute(
                    select(Job)
                    .where(Job.status == JobStatus.PENDING, Job.run_at <= now)
                    .order_by(Job.run_at, Job.id)
                    .limit(1)
                    .with_for_update(skip_locked=True)
                )
            ).scalar_one_or_none()
            if job is None:
                return None
            job.status = JobStatus.RUNNING
            job.attempts += 1
            job.started_at = now
            return job.id, job.kind, dict(job.payload), job.attempts, job.max_attempts

    async def _execute(self, job_id: int, kind: str, payload: dict[str, Any], attempt: int, max_attempts: int) -> None:
        handler = self.registry.handlers.get(kind)
        try:
            if handler is None:
                raise LookupError(f"Нет обработчика для задачи {kind!r}")
            async with self.sessionmaker() as session:
                ctx = JobContext(session, self.services, self.settings, job_id, kind, attempt)
                await handler(ctx, payload)
                await session.execute(
                    update(Job)
                    .where(Job.id == job_id)
                    .values(status=JobStatus.DONE, finished_at=self.now(), last_error=None)
                )
                await session.commit()
        except Exception as exc:  # noqa: BLE001 — любая ошибка обработчика уходит в повтор
            log.exception("Задача %s #%s упала (попытка %s)", kind, job_id, attempt)
            now = self.now()
            final = handler is None or attempt >= max_attempts
            async with self.sessionmaker() as session, session.begin():
                await session.execute(
                    update(Job)
                    .where(Job.id == job_id)
                    .values(
                        status=JobStatus.FAILED if final else JobStatus.PENDING,
                        run_at=now + retry_delay(attempt),
                        finished_at=now if final else None,
                        last_error=f"{type(exc).__name__}: {exc}"[:2000],
                    )
                )

    async def run_forever(self, poll_seconds: float) -> None:
        log.info("Воркер фоновых задач запущен, опрос раз в %s с", poll_seconds)
        while True:
            try:
                await self.tick()
            except asyncio.CancelledError:
                raise
            except Exception:  # noqa: BLE001 — воркер не должен умирать из-за сбоя базы
                log.exception("Сбой шага воркера фоновых задач")
            await asyncio.sleep(poll_seconds)
