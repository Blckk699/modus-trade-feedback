"""Сроки первого ответа и эскалация (B-07). Истории 27, 40, 45, 57.

Часы стоят на понедельнике, 9 ноября 2026, 10:00 по UTC+5. Категория 7 «Интеграции и IT»:
ответственный — Станислав Цой (id 13), руководитель подразделения IT — Евгений Ткач (id 19).
Воркер срабатывает каждые 10 минут, как на сервере.
"""

from __future__ import annotations

from datetime import datetime, timedelta

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import func, select

from app.models import Appeal, HistoryEvent, Notification
from tests.support import TZ, TimeMachine

TICK = timedelta(minutes=10)
IT_PROBLEM = {"type": "problem", "category_id": 7, "priority": "high", "text": "1С и Битрикс не синхронизируются."}


async def create(client: httpx.AsyncClient, headers: dict, **fields) -> dict:
    response = await client.post("/api/v1/appeals", headers=headers, json={**IT_PROBLEM, **fields})
    assert response.status_code == 201, response.text
    return response.json()


async def kinds(app: FastAPI, user_id: int) -> list[str]:
    async with app.state.sessionmaker() as session:
        rows = await session.execute(
            select(Notification.kind).where(Notification.user_id == user_id, Notification.kind != "digest").order_by(Notification.id)
        )
        return list(rows.scalars())


async def level(app: FastAPI, appeal_id: int) -> int:
    async with app.state.sessionmaker() as session:
        return (await session.get(Appeal, appeal_id)).escalation_level


async def go(time_machine: TimeMachine, moment: datetime) -> None:
    await time_machine.travel_to(moment)  # один шаг воркера в конечной точке
    await time_machine.run_due()


async def run_until(time_machine: TimeMachine, moment: datetime) -> None:
    await time_machine.advance(moment - time_machine.now, step=TICK)


@pytest.fixture(autouse=True)
async def worker_schedule(time_machine: TimeMachine) -> None:
    """Первый проход воркера регистрирует расписание периодических задач, как при старте сервера."""
    await time_machine.run_due()


def at(day: int, hour: int = 10, minute: int = 0) -> datetime:
    return datetime(2026, 11, day, hour, minute, tzinfo=TZ)


async def test_three_steps_one_business_day_apart(app, client, login_as, time_machine) -> None:
    """Срок высокого приоритета — вторник 10:00. Напоминание, руководитель, «Зависло»."""
    appeal = await create(client, await login_as("employee_accounting"))
    assignee_before = await kinds(app, 13)

    await run_until(time_machine, at(10, 9, 50))
    assert await level(app, appeal["id"]) == 0

    await run_until(time_machine, at(10, 10, 10))
    assert await level(app, appeal["id"]) == 1
    assert (await kinds(app, 13))[len(assignee_before):] == ["deadline_reminder"]  # история 40

    await run_until(time_machine, at(11, 9, 50))
    assert await level(app, appeal["id"]) == 1, "шаг не повторяется и следующий ещё не наступил"
    assert (await kinds(app, 13)).count("deadline_reminder") == 1

    await run_until(time_machine, at(11, 10, 10))
    assert await level(app, appeal["id"]) == 2
    assert await kinds(app, 19) == ["escalation_head"]  # история 45

    await run_until(time_machine, at(12, 10, 10))
    assert await level(app, appeal["id"]) == 3  # история 57: «Зависло» для сводки собственника

    await run_until(time_machine, at(16, 12))
    assert await level(app, appeal["id"]) == 3
    async with app.state.sessionmaker() as session:
        steps = await session.scalar(
            select(func.count()).select_from(HistoryEvent).where(
                HistoryEvent.appeal_id == appeal["id"], HistoryEvent.kind == "escalated"
            )
        )
    assert steps == 3
    owner = await login_as("owner")
    card = (await client.get(f"/api/v1/appeals/{appeal['id']}", headers=owner)).json()
    assert (card["due_state"], card["escalation_level"]) == ("overdue", 3)


async def test_steps_skip_weekend(app, client, login_as, time_machine) -> None:
    """Подача в четверг: срок — пятница 10:00, руководитель — понедельник, не суббота."""
    await go(time_machine, at(12, 10))
    appeal = await create(client, await login_as("employee_accounting"))
    await go(time_machine, at(13, 10, 5))
    assert await level(app, appeal["id"]) == 1
    await go(time_machine, at(15, 12))  # воскресенье
    assert await level(app, appeal["id"]) == 1
    await go(time_machine, at(16, 10, 5))
    assert await level(app, appeal["id"]) == 2


async def test_praise_is_never_escalated(app, client, login_as, time_machine) -> None:
    praise = await create(client, await login_as("employee_accounting"), type="praise")
    await go(time_machine, at(20, 12))
    assert await level(app, praise["id"]) == 0
    assert "deadline_reminder" not in await kinds(app, 13)


async def test_first_response_stops_escalation(app, client, login_as, time_machine) -> None:
    appeal = await create(client, await login_as("employee_accounting"))
    await go(time_machine, at(10, 10, 5))
    assert await level(app, appeal["id"]) == 1
    await client.post(f"/api/v1/appeals/{appeal['id']}/take", headers=await login_as("employee_it"))
    await go(time_machine, at(13, 12))
    assert await level(app, appeal["id"]) == 1
    assert await kinds(app, 19) == []


async def test_reassignment_before_answer_restarts_deadline_and_steps(app, client, login_as, time_machine) -> None:
    """Истории 27, 44: новый ответственный получает свой срок, эскалация начинается заново."""
    appeal = await create(client, await login_as("employee_accounting"))
    await go(time_machine, at(10, 10, 5))
    assert await level(app, appeal["id"]) == 1
    moved = await client.post(
        f"/api/v1/appeals/{appeal['id']}/reassign",
        headers=await login_as("head_it"),
        json={"assignee_id": 19, "reason": "Беру сам"},
    )
    assert moved.json()["escalation_level"] == 0
    assert datetime.fromisoformat(moved.json()["first_response_due_at"]) == at(11, 10, 5)
    await go(time_machine, at(11, 10))
    assert await level(app, appeal["id"]) == 0


async def test_seeded_overdue_appeals_are_not_escalated_twice(app, demo, time_machine) -> None:
    """Сид уже выставил шаги просроченным обращениям — первый проход воркера их не дублирует."""
    await time_machine.run_due()
    await time_machine.advance(minutes=10)
    async with app.state.sessionmaker() as session:
        new_steps = await session.scalar(
            select(func.count()).select_from(HistoryEvent).where(HistoryEvent.kind == "escalated")
        )
        reminders = await session.scalar(
            select(func.count()).select_from(Notification).where(Notification.kind == "deadline_reminder")
        )
    assert (new_steps, reminders) == (0, 0)
