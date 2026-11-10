"""Реестр обработчиков фоновых задач.

Разовая задача:

    @registry.job("meetings.process")
    async def process_meeting(ctx: JobContext, payload: dict) -> None: ...

Периодическая (обработчик + расписание; расписание может зависеть от настроек):

    @registry.periodic("digest.send", lambda s: DailyAt(s.digest_time))
    async def send_digest(ctx: JobContext, payload: dict) -> None: ...

Модуль с обработчиками нужно один раз импортировать в `app/jobs/catalog.py`.
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from datetime import datetime
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

    def job(self, kind: str) -> Callable[[Handler], Handler]:
        def decorator(handler: Handler) -> Handler:
            if kind in self.handlers:
                raise ValueError(f"Обработчик задачи {kind!r} уже зарегистрирован")
            self.handlers[kind] = handler
            return handler

        return decorator

    def periodic(self, name: str, schedule: ScheduleFactory) -> Callable[[Handler], Handler]:
        def decorator(handler: Handler) -> Handler:
            self.job(name)(handler)
            self.periodic_specs[name] = PeriodicSpec(name, schedule)
            return handler

        return decorator

    def copy(self) -> JobRegistry:
        return JobRegistry(dict(self.handlers), dict(self.periodic_specs))


# Общий реестр приложения: модули регистрируют в нём обработчики при импорте.
registry = JobRegistry()
