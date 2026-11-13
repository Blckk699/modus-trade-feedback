"""«Напомнить ответственному» (B-25 п.5).

A-001: «Новое», первого ответа нет, ответственный — руководитель закупок Олжас Мукашев (id 3).
A-007: «Новое», ответственный — Станислав Цой (id 13), подразделение IT.
"""

from __future__ import annotations

import httpx
import pytest

A_001, A_002, A_007 = 1, 2, 7


async def nudge(client: httpx.AsyncClient, headers: dict, appeal: int = A_007) -> httpx.Response:
    return await client.post(f"/api/v1/appeals/{appeal}/nudge", headers=headers)


async def kinds(client: httpx.AsyncClient, headers: dict) -> list[str]:
    items = (await client.get("/api/v1/notifications?page_size=200", headers=headers)).json()["items"]
    return [n["kind"] for n in items]


async def assignee_headers(client, login_as, appeal: int) -> dict:
    from app.seed import data

    target = (await client.get(f"/api/v1/appeals/{appeal}", headers=await login_as("owner"))).json()["assignee"]["id"]
    for user in data.USERS:
        headers = await login_as(user.key)
        if (await client.get("/api/v1/me", headers=headers)).json()["id"] == target:
            return headers
    raise AssertionError("ответственный не найден среди демо-пользователей")


async def test_owner_nudges_assignee(client, login_as) -> None:
    owner = await login_as("owner")
    assignee = await assignee_headers(client, login_as, A_007)
    card = (await client.get(f"/api/v1/appeals/{A_007}", headers=owner)).json()
    assert card["first_response_at"] is None and "nudge" in card["allowed_actions"]
    before = (await kinds(client, assignee)).count("nudge")

    response = await nudge(client, owner)
    assert response.status_code == 200, response.text
    after = response.json()
    assert (after["status"], after["assignee"]["id"], after["first_response_due_at"]) == (
        card["status"], card["assignee"]["id"], card["first_response_due_at"]
    ), "напоминание ничего не меняет в обращении"

    assert (await kinds(client, assignee)).count("nudge") == before + 1
    note = next(
        n for n in (await client.get("/api/v1/notifications?page_size=200", headers=assignee)).json()["items"] if n["kind"] == "nudge"
    )
    assert "просит ответить" in note["text"] and note["path"] == f"/appeals/{A_007}"
    history = (await client.get(f"/api/v1/appeals/{A_007}/history", headers=owner)).json()
    assert (history[-1]["kind"], history[-1]["new_value"]) == ("nudged", card["assignee"]["full_name"])


async def test_not_more_often_than_once_in_four_hours(client, login_as, time_machine) -> None:
    owner = await login_as("owner")
    assert (await nudge(client, owner)).status_code == 200
    again = await nudge(client, owner)
    error = again.json()["error"]
    assert (again.status_code, error["code"]) == (429, "too_many_requests")
    assert error["details"]["next_allowed_at"] and "после" in error["message"]

    await time_machine.advance(hours=3, minutes=59)
    assert (await nudge(client, owner)).status_code == 429
    await time_machine.advance(minutes=2)
    assert (await nudge(client, owner)).status_code == 200


@pytest.mark.parametrize("who", ["admin", "employee_sales", "head_sales"])
async def test_others_cannot_nudge(client, login_as, who) -> None:
    """Администратор, посторонний сотрудник и руководитель чужого подразделения — нет."""
    headers = await login_as(who)
    card = await client.get(f"/api/v1/appeals/{A_007}", headers=headers)
    if card.status_code == 200:
        assert "nudge" not in card.json()["allowed_actions"]
    assert (await nudge(client, headers)).status_code == 403


async def test_assignee_and_author_cannot_nudge(client, login_as) -> None:
    assignee = await assignee_headers(client, login_as, A_007)
    assert (await nudge(client, assignee)).status_code == 403


async def test_nudge_is_only_for_unanswered_appeals_with_an_assignee(client, login_as) -> None:
    owner = await login_as("owner")
    # Руководитель закупок сам ответственный по A-001: напоминать себе нельзя.
    head = await login_as("head_procurement")
    own = await nudge(client, head, A_001)
    assert (own.status_code, own.json()["error"]["code"]) == (409, "invalid_transition")
    assert "nudge" not in (await client.get(f"/api/v1/appeals/{A_001}", headers=head)).json()["allowed_actions"]

    # После первого ответа напоминать не о чем.
    assert (await client.post(f"/api/v1/appeals/{A_007}/take", headers=owner, json={})).status_code == 200
    answered = await nudge(client, owner)
    assert (answered.status_code, answered.json()["error"]["code"]) == (409, "invalid_transition")
    assert "nudge" not in (await client.get(f"/api/v1/appeals/{A_007}", headers=owner)).json()["allowed_actions"]

    # Без ответственного — сначала назначить.
    created = await client.post(
        "/api/v1/appeals",
        headers=await login_as("employee_sales"),
        json={"type": "problem", "category_id": None, "priority": "medium", "text": "Не знаю, к кому обратиться."},
    )
    assert created.json()["assignee"] is None
    unassigned = await nudge(client, owner, created.json()["id"])
    assert unassigned.status_code == 409 and "ответственного" in unassigned.json()["error"]["message"]
