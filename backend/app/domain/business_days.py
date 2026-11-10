"""Рабочие дни: понедельник–пятница в часовом поясе системы, праздники не учитываются (SPEC.md).

Срок первого ответа — момент создания плюс N рабочих дней с тем же временем суток.
Если обращение создано в выходной, отсчёт идёт от понедельника, 09:00.
"""

from __future__ import annotations

from datetime import datetime, time, timedelta, tzinfo

WORKDAY_START = time(9, 0)


def is_business_day(moment: datetime) -> bool:
    return moment.weekday() < 5


def _next_business_morning(local: datetime) -> datetime:
    day = local
    while not is_business_day(day):
        day += timedelta(days=1)
    return day.replace(hour=WORKDAY_START.hour, minute=WORKDAY_START.minute, second=0, microsecond=0)


def add_business_days(start: datetime, days: int, tz: tzinfo) -> datetime:
    """`start` + `days` рабочих дней. Результат — в часовом поясе системы."""
    local = start.astimezone(tz)
    if not is_business_day(local):
        local = _next_business_morning(local)
    added = 0
    while added < days:
        local += timedelta(days=1)
        if is_business_day(local):
            added += 1
    return local


def subtract_business_days(end: datetime, days: int, tz: tzinfo) -> datetime:
    """Момент на `days` рабочих дней раньше `end`, всегда в рабочий день, то же время суток."""
    local = end.astimezone(tz)
    while not is_business_day(local):
        local -= timedelta(days=1)
    removed = 0
    while removed < days:
        local -= timedelta(days=1)
        if is_business_day(local):
            removed += 1
    return local


def business_days_between(start: datetime, end: datetime, tz: tzinfo) -> int:
    """Сколько целых рабочих дней прошло от `start` до `end` (0, если `end` раньше)."""
    if end <= start:
        return 0
    count = 0
    while add_business_days(start, count + 1, tz) <= end:
        count += 1
    return count
