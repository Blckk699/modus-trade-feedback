"""Реестр обработчиков фоновых задач.

Разовая задача:

    @registry.job("meetings.process", stale_after=timedelta(hours=2))
    async def process_meeting(ctx: JobContext, payload: dict) -> None: ...

`stale_after` — через сколько задачу в статусе running считать зависшей (процесс упал) и вернуть
в очередь. По умолчанию 30 минут; долгим задачам (расшифровка записи совещания) задавайте больше.

Периодическая (обработчик + расписание; расписание может зависеть от настроек):

    @registry.periodic("digest.send", lambda s: DailyAt(s.digest_time))
    async def send_digest(ctx: JobContext, payload: dict) -> None: ...

Модуль с обработчиками нужно один раз импортировать в `app/jobs/catalog.py`.
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.jobs.schedules import Schedule

if TYPE_CHECKING:
    from app.container import Services


@dataclass
class JobContext:
    """Что получает обработчик. Работа с базой — только через `session`: её коммитит механизм
    вместе с отметкой «выполнено», при исключении всё откатывается и задача повторяется."""

    session: AsyncSession
    services: Services
    settings: Settings
    job_id: int
    kind: str
    attempt: int

    def now(self) -> datetime:
        return self.services.clock.now()


DEFAULT_STALE_AFTER = timedelta(minutes=30)

Handler = Callable[[JobContext, dict[str, Any]], Awaitable[None]]
ScheduleFactory = Schedule | Callable[[Settings], Schedule]


@dataclass
class PeriodicSpec:
    name: str
    schedule: ScheduleFactory

    def resolve(self, settings: Settings) -> Schedule:
        return self.schedule(settings) if callable(self.schedule) else self.schedule


@dataclass
class JobRegistry:
    handlers: dict[str, Handler] = field(default_factory=dict)
    periodic_specs: dict[str, PeriodicSpec] = field(default_factory=dict)
    # Нестандартные таймауты зависания по типу задачи; остальные — DEFAULT_STALE_AFTER.
    stale_after: dict[str, timedelta] = field(default_factory=dict)

    def job(self, kind: str, *, stale_after: timedelta | None = None) -> Callable[[Handler], Handler]:
        def decorator(handler: Handler) -> Handler:
            if kind in self.handlers:
                raise ValueError(f"Обработчик задачи {kind!r} уже зарегистрирован")
            self.handlers[kind] = handler
            if stale_after is not None:
                self.stale_after[kind] = stale_after
            return handler

        return decorator

    def periodic(
        self, name: str, schedule: ScheduleFactory, *, stale_after: timedelta | None = None
    ) -> Callable[[Handler], Handler]:
        def decorator(handler: Handler) -> Handler:
            self.job(name, stale_after=stale_after)(handler)
            self.periodic_specs[name] = PeriodicSpec(name, schedule)
            return handler

        return decorator

    def copy(self) -> JobRegistry:
        return JobRegistry(dict(self.handlers), dict(self.periodic_specs), dict(self.stale_after))


# Общий реестр приложения: модули регистрируют в нём обработчики при импорте.
registry = JobRegistry()
