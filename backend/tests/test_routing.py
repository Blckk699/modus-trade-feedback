"""Маршрутизация и переназначение (B-05). Истории 9, 27, 44, 68, 70.

Часы тестов стоят на понедельнике, 9 ноября 2026, 10:00 по UTC+5.
"""

from __future__ import annotations

from datetime import datetime

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import update

from app.models import Category, DeadlineRule, User
from tests.support import TZ

FORM = {"type": "problem", "category_id": 1, "priority": "medium", "text": "В заявке нет назначения оборудования."}


async def create(client: httpx.AsyncClient, headers: dict, **fields) -> dict:
    response = await client.post("/api/v1/appeals", headers=headers, json={**FORM, **fields})
    assert response.status_code == 201, response.text
    return response.json()


async def set_user(app: FastAPI, seed_key: str, **values) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(User).where(User.seed_key == seed_key).values(**values))


def local(value: str) -> datetime:
    return datetime.fromisoformat(value).astimezone(TZ)


# --- маршрутизация при создании ------------------------------------------------------------------


async def test_new_appeal_goes_to_category_responsible_with_deadline(client, login_as) -> None:
    """История 9: сразу после подачи видны ответственный и срок первого ответа."""
    appeal = await create(client, await login_as("employee_sales"))
    assert appeal["assignee"]["full_name"] == "Олжас Мукашев"
    assert local(appeal["first_response_due_at"]) == datetime(2026, 11, 12, 10, 0, tzinfo=TZ)  # +3 рабочих дня
    assert appeal["due_state"] == "on_time"

    history = (await client.get(f"/api/v1/appeals/{appeal['id']}/history", headers=await login_as("owner"))).json()
    assigned = next(e for e in history if e["kind"] == "assigned")
    assert assigned["new_value"] == "Олжас Мукашев" and "Межотдельное взаимодействие" in assigned["comment"]


@pytest.mark.parametrize(("priority", "due"), [("high", (16, 17)), ("medium", (18, 17)), ("low", (20, 17))])
async def test_deadline_counts_business_days(client, login_as, time_machine, priority, due) -> None:
    """Подача в пятницу 17:00: выходные не считаются."""
    await time_machine.travel_to(datetime(2026, 11, 13, 17, 0, tzinfo=TZ))
    appeal = await create(client, await login_as("employee_sales"), priority=priority)
    day, hour = due
    assert local(appeal["first_response_due_at"]) == datetime(2026, 11, day, hour, 0, tzinfo=TZ)


async def test_weekend_appeal_counts_from_monday_morning(client, login_as, time_machine) -> None:
    await time_machine.travel_to(datetime(2026, 11, 14, 12, 0, tzinfo=TZ))  # суббота
    appeal = await create(client, await login_as("employee_sales"), priority="high")
    assert local(appeal["first_response_due_at"]) == datetime(2026, 11, 17, 9, 0, tzinfo=TZ)


async def test_praise_gets_assignee_without_deadline(client, login_as) -> None:
    appeal = await create(client, await login_as("employee_sales"), type="praise", category_id=16)
    assert appeal["assignee"]["full_name"] == "Майра Жанибекова"
    assert appeal["first_response_due_at"] is None and appeal["due_state"] == "no_deadline"


async def test_absent_responsible_hands_over_to_deputy(app, client, login_as) -> None:
    """История 68."""
    await set_user(app, "head_procurement", is_absent=True)
    appeal = await create(client, await login_as("employee_sales"))
    assert appeal["assignee"]["full_name"] == "Карина Шаймерденова"
    assert appeal["first_response_due_at"] is not None


async def test_no_one_available_goes_to_admin_queue(app, client, login_as) -> None:
    """История 70: ни одно обращение не остаётся без владельца — оно видно администратору."""
    await set_user(app, "head_procurement", is_absent=True)
    no_deputy = await create(client, await login_as("employee_sales"), category_id=2)
    no_category = await create(client, await login_as("employee_sales"), category_id=None)
    for appeal in (no_deputy, no_category):
        assert appeal["assignee"] is None and appeal["first_response_due_at"] is None

    queue = (await client.get("/api/v1/appeals", headers=await login_as("admin"), params={"scope": "unassigned"})).json()
    assert sorted(i["number"] for i in queue["items"]) == sorted([no_deputy["number"], no_category["number"]])


async def test_deadline_rules_come_from_settings(app, client, login_as) -> None:
    """История 69: администратор меняет срок — он применяется к новым обращениям."""
    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(DeadlineRule).where(DeadlineRule.priority == "medium").values(business_days=1))
    appeal = await create(client, await login_as("employee_sales"))
    assert local(appeal["first_response_due_at"]) == datetime(2026, 11, 10, 10, 0, tzinfo=TZ)


# --- переназначение -------------------------------------------------------------------------------


async def reassign(client: httpx.AsyncClient, headers: dict, appeal_id: int, assignee_id: int, reason: str = "Вопрос про IT"):
    return await client.post(
        f"/api/v1/appeals/{appeal_id}/reassign", headers=headers, json={"assignee_id": assignee_id, "reason": reason}
    )


async def test_head_reassigns_with_reason_and_deadline_restarts(client, login_as) -> None:
    """История 44: переназначение с причиной, срок отсчитывается заново, всё в истории."""
    head = await login_as("head_procurement")
    response = await reassign(client, head, 1, 13, "Нужна оценка IT")  # A-001 -> Станислав Цой
    assert response.status_code == 200, response.text
    appeal = response.json()
    assert appeal["assignee"]["full_name"] == "Станислав Цой"
    assert local(appeal["first_response_due_at"]) == datetime(2026, 11, 12, 10, 0, tzinfo=TZ)
    assert (appeal["due_state"], appeal["escalation_level"]) == ("on_time", 0)

    history = (await client.get("/api/v1/appeals/1/history", headers=head)).json()
    event = next(e for e in history if e["kind"] == "reassigned")
    assert (event["old_value"], event["new_value"], event["comment"]) == ("Олжас Мукашев", "Станислав Цой", "Нужна оценка IT")
    assert event["actor"]["full_name"] == "Олжас Мукашев"
    assert history[-1]["kind"] == "deadline_set"

    it_queue = (await client.get("/api/v1/appeals", headers=await login_as("employee_it"), params={"scope": "assigned"})).json()
    assert "A-001" in [i["number"] for i in it_queue["items"]]


@pytest.mark.parametrize("who", ["employee_procurement", "employee_it", "head_sales"])
async def test_employee_assignee_and_other_head_cannot_reassign(client, login_as, who) -> None:
    """Сотрудник (автор A-001), ответственный (A-007) и руководитель чужого подразделения."""
    appeal_id = 7 if who == "employee_it" else 1
    response = await reassign(client, await login_as(who), appeal_id, 3)
    assert response.status_code == 403


@pytest.mark.parametrize("who", ["admin", "owner"])
async def test_admin_and_owner_reassign_any_appeal(client, login_as, who) -> None:
    response = await reassign(client, await login_as(who), 7, 19, "Передать руководителю IT")
    assert response.status_code == 200
    assert response.json()["assignee"]["full_name"] == "Евгений Ткач"


async def test_admin_assigns_from_unassigned_queue(client, login_as) -> None:
    appeal = await create(client, await login_as("employee_sales"), category_id=None)
    response = await reassign(client, await login_as("admin"), appeal["id"], 7, "Вопрос продаж")
    assert response.status_code == 200
    assert response.json()["assignee"]["full_name"] == "Денис Пак"
    assert response.json()["first_response_due_at"] is not None
    history = (await client.get(f"/api/v1/appeals/{appeal['id']}/history", headers=await login_as("admin"))).json()
    assert [e["kind"] for e in history][-2:] == ["assigned", "deadline_set"]


async def test_reassign_validation(app, client, login_as) -> None:
    owner = await login_as("owner")
    assert (await reassign(client, owner, 1, 13, "   ")).status_code == 422, "причина обязательна"
    assert (await reassign(client, owner, 1, 3)).status_code == 422, "уже ответственный"
    await set_user(app, "employee_it", is_disabled=True)
    assert (await reassign(client, owner, 1, 13)).status_code == 422, "отключённому не назначить"
    final = await reassign(client, owner, 17, 3)
    assert (final.status_code, final.json()["error"]["code"]) == (409, "invalid_transition")


# --- правки по ревью ---------------------------------------------------------------------------------


async def test_admin_cannot_be_assignee(app, client, login_as) -> None:
    """Администратор не видит статусы и переписку по матрице — ответственным его не назначить."""
    response = await reassign(client, await login_as("owner"), 1, 2, "Пусть разберётся администратор")
    assert (response.status_code, response.json()["error"]["code"]) == (422, "validation_error")
    assert response.json()["error"]["details"]["fields"][0]["field"] == "assignee_id"

    # Если администратор оказался ответственным или заместителем категории, правило его пропускает.
    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(Category).where(Category.id == 1).values(responsible_id=2, deputy_id=None))
    appeal = await create(client, await login_as("employee_sales"))
    assert appeal["assignee"] is None, "в очередь нераспределённых, а не администратору"


async def test_reassigning_answered_appeal_keeps_its_deadline(client, login_as, time_machine) -> None:
    """A-002 уже на рассмотрении: первый ответ дан, срок не сбрасывается, история без нового срока."""
    owner = await login_as("owner")
    before = (await client.get("/api/v1/appeals/2", headers=owner)).json()
    await time_machine.advance(days=2)
    after = (await reassign(client, owner, 2, 13, "Нужна оценка IT")).json()
    assert after["assignee"]["full_name"] == "Станислав Цой"
    assert after["first_response_due_at"] == before["first_response_due_at"]
    assert after["first_response_at"] == before["first_response_at"] and after["due_state"] == "answered"
    history = (await client.get("/api/v1/appeals/2/history", headers=owner)).json()
    assert history[-1]["kind"] == "reassigned"
