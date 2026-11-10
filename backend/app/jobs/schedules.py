"""Расписания периодических задач. Все расчёты — от переданного момента, без системных часов."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, time, timedelta, timezone
from typing import Protocol


class Schedule(Protocol):
    def next_after(self, moment: datetime, tz: timezone) -> datetime:
        """Ближайший момент запуска строго позже `moment` (UTC-aware)."""
        ...

    def describe(self) -> str: ...


@dataclass(frozen=True)
class Every:
    """Раз в интервал: `Every(minutes=10)`."""

    interval: timedelta

    def __init__(self, interval: timedelta | None = None, **kwargs: float) -> None:
        value = (interval or timedelta()) + timedelta(**kwargs)
        if value <= timedelta():
            raise ValueError("Интервал должен быть положительным")
        object.__setattr__(self, "interval", value)

    def next_after(self, moment: datetime, tz: timezone) -> datetime:
        return moment + self.interval

    def describe(self) -> str:
        return f"every {int(self.interval.total_seconds())}s"


@dataclass(frozen=True)
class DailyAt:
    """Каждый день в заданное местное время часового пояса системы: `DailyAt(time(9, 0))`."""

    at: time

    def next_after(self, moment: datetime, tz: timezone) -> datetime:
        local_now = moment.astimezone(tz)
        candidate = datetime.combine(local_now.date(), self.at, tzinfo=tz)
        if candidate <= local_now:
            candidate += timedelta(days=1)
        return candidate.astimezone(moment.tzinfo)

    def describe(self) -> str:
        return f"daily {self.at.strftime('%H:%M')}"
