"""Единый источник текущего времени.

Код приложения никогда не вызывает `datetime.now()` напрямую: он берёт `Clock` из контейнера
(`request.app.state.services.clock`, зависимость `get_clock`, `JobContext.clock`).
В тестах подставляется `FrozenClock`, который можно двигать вперёд.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta, timezone
from typing import Protocol


class Clock(Protocol):
    def now(self) -> datetime:
        """Текущий момент, всегда timezone-aware в UTC."""
        ...


class SystemClock:
    def now(self) -> datetime:
        return datetime.now(UTC)


class FrozenClock:
    """Часы, которые стоят на месте, пока их не сдвинут."""

    def __init__(self, start: datetime) -> None:
        self._now = _require_aware(start).astimezone(UTC)

    def now(self) -> datetime:
        return self._now

    def set(self, moment: datetime) -> None:
        self._now = _require_aware(moment).astimezone(UTC)

    def advance(self, delta: timedelta | None = None, **kwargs: float) -> datetime:
        """`clock.advance(hours=3)` или `clock.advance(timedelta(days=1))`."""
        self._now += (delta or timedelta()) + timedelta(**kwargs)
        return self._now


def local(moment: datetime, tz: timezone) -> datetime:
    """Момент в часовом поясе системы (UTC+5) — для рабочих дней, сводки и текстов."""
    return _require_aware(moment).astimezone(tz)


def _require_aware(moment: datetime) -> datetime:
    if moment.tzinfo is None:
        raise ValueError("Время должно быть с часовым поясом (timezone-aware)")
    return moment
