"""Рабочие дни: понедельник–пятница по UTC+5, праздники не учитываются."""

from __future__ import annotations

from datetime import datetime

from app.domain.business_days import add_business_days, business_days_between, subtract_business_days
from tests.support import TZ


def at(day: int, hour: int = 10) -> datetime:
    return datetime(2026, 11, day, hour, 0, tzinfo=TZ)  # 9 ноября 2026 — понедельник


def test_add_skips_weekend() -> None:
    assert add_business_days(at(12), 1, TZ) == at(13)  # чт -> пт
    assert add_business_days(at(13), 1, TZ) == at(16)  # пт -> пн
    assert add_business_days(at(11), 3, TZ) == at(16)  # ср + 3 -> пн


def test_weekend_start_counts_from_monday_morning() -> None:
    assert add_business_days(at(14, 15), 1, TZ) == at(17, 9)  # сб 15:00 -> пн 09:00 + 1 -> вт 09:00


def test_subtract_lands_on_business_day() -> None:
    assert subtract_business_days(at(16), 1, TZ) == at(13)  # пн - 1 -> пт
    assert subtract_business_days(at(15), 0, TZ) == at(13)  # вс -> пт
    assert subtract_business_days(at(14), 5, TZ) == at(6)  # сб -> пт 13.11 - 5 -> пт 6.11


def test_business_days_between() -> None:
    assert business_days_between(at(13), at(16), TZ) == 1
    assert business_days_between(at(9), at(13, 9), TZ) == 3
    assert business_days_between(at(13), at(12), TZ) == 0
