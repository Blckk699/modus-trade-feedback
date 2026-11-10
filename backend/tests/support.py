"""Помощники тестов, которые импортируют и фикстуры, и сами тесты."""

from __future__ import annotations

from datetime import datetime, timedelta

from app.clock import FrozenClock
from app.config import parse_utc_offset
from app.jobs.runner import JobRunner

# Часовой пояс системы по спеке.
TZ = parse_utc_offset("+05:00")


class TimeMachine:
    """«Прокрутить время и выполнить созревшие задачи» без реального ожидания."""

    def __init__(self, clock: FrozenClock, jobs: JobRunner) -> None:
        self.clock = clock
        self.jobs = jobs

    @property
    def now(self) -> datetime:
        return self.clock.now()

    async def run_due(self) -> int:
        """Один шаг воркера в текущий момент."""
        return await self.jobs.tick()

    async def advance(self, delta: timedelta | None = None, *, step: timedelta | None = None, **kwargs: float) -> int:
        """Сдвигает часы на `delta` и выполняет созревшие задачи.

        Без `step` воркер срабатывает один раз в конечной точке. С `step` — на каждом шаге,
        как настоящий воркер: например, `advance(days=3, step=timedelta(hours=1))`.
        Возвращает число выполненных задач.
        """
        total = (delta or timedelta()) + timedelta(**kwargs)
        target = self.clock.now() + total
        processed = 0
        if step is not None:
            while self.clock.now() + step < target:
                self.clock.advance(step)
                processed += await self.jobs.tick()
        self.clock.set(target)
        processed += await self.jobs.tick()
        return processed

    async def travel_to(self, moment: datetime) -> int:
        return await self.advance(moment - self.clock.now())


# Telegram ID демо-пользователей в тестах: 100000000 + порядковый номер в app/seed/data.py.
def telegram_id_of(seed_key: str) -> int:
    from app.seed import data

    keys = [u.key for u in data.USERS]
    return 100_000_001 + keys.index(seed_key)


def bot_headers(telegram_id: int, service_key: str = "test-service-key") -> dict[str, str]:
    """Заголовки бота, действующего от имени пользователя с этим Telegram ID."""
    return {"X-Service-Key": service_key, "X-Telegram-Id": str(telegram_id)}
