"""Единый источник текущего времени.

Код приложения никогда не вызывает `datetime.now()` напрямую: он берёт `Clock` из контейнера
(`request.app.state.services.clock`, зависимость `get_clock`, `JobContext.clock`).
В тестах подставляется `FrozenClock`, который можно двигать вперёд.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta, timezone, tzinfo
from typing import Annotated, Protocol

from pydantic import PlainSerializer


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


# Ответы API отдают время со смещением системы (контракт: `+05:00`), внутри всё считается в UTC.
_display_tz: tzinfo = timezone(timedelta(hours=5))


def set_display_timezone(tz: tzinfo) -> None:
    global _display_tz
    _display_tz = tz


def _display(moment: datetime) -> str:
    return _require_aware(moment).astimezone(_display_tz).isoformat()


LocalDatetime = Annotated[datetime, PlainSerializer(_display, return_type=str, when_used="json")]
