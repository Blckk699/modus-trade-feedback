"""Задача в Битрикс24 из обращения (B-15). История 39. Битрикс24 — фейк на границе адаптера.

Сид: A-002 «На рассмотрении» (ответственный — Олжас Мукашев), A-001 «Новое», A-017 «Отклонено».
"""

from __future__ import annotations

import pytest


async def create(client, headers, appeal_id: int = 2):
    return await client.post(f"/api/v1/appeals/{appeal_id}/bitrix-task", headers=headers)


async def test_task_is_created_once_and_link_is_saved(client, login_as, fake_bitrix) -> None:
    head = await login_as("head_procurement")
    first = await create(client, head)
    assert first.status_code == 201, first.text
    assert first.json()["url"].startswith("https://") and first.json()["task_id"] == "1001"

    task = fake_bitrix.tasks[0]
    assert task.title.startswith("A-002") and "поставщиками" in task.description

    again = await create(client, head)
    assert (again.status_code, again.json()["task_id"]) == (200, "1001"), "повторное нажатие не создаёт вторую задачу"
    assert len(fake_bitrix.tasks) == 1

    card = (await client.get("/api/v1/appeals/2", headers=head)).json()
    assert card["bitrix_task"]["url"] == first.json()["url"]
    assert "create_bitrix_task" not in card["allowed_actions"]
    history = (await client.get("/api/v1/appeals/2/history", headers=head)).json()
    assert history[-1]["kind"] == "bitrix_task_created"


@pytest.mark.parametrize(("who", "status"), [("owner", 201), ("employee_procurement", 403), ("admin", 403)])
async def test_who_can_create_task(client, login_as, who, status) -> None:
    """Ответственный, руководитель, собственник — да; автор и администратор — нет."""
    assert (await create(client, await login_as(who))).status_code == status


async def test_wrong_status_is_rejected(client, login_as, fake_bitrix) -> None:
    assert (await create(client, await login_as("head_admin_office"), 17)).status_code == 409
    assert fake_bitrix.tasks == []


async def test_portal_error_leaves_appeal_unchanged(client, login_as, fake_bitrix) -> None:
    head = await login_as("head_procurement")
    fake_bitrix.fail = True
    response = await create(client, head)
    assert (response.status_code, response.json()["error"]["code"]) == (502, "bitrix_unavailable")
    card = (await client.get("/api/v1/appeals/2", headers=head)).json()
    assert card["bitrix_task"] is None and "create_bitrix_task" in card["allowed_actions"]
    fake_bitrix.fail = False
    assert (await create(client, head)).status_code == 201


async def test_task_can_be_created_from_a_new_appeal(client, login_as, fake_bitrix) -> None:
    """A-001 в статусе «Новое»: задачу заводят сразу, брать обращение для этого не нужно."""
    head = await login_as("head_procurement")
    card = (await client.get("/api/v1/appeals/1", headers=head)).json()
    assert card["status"] == "new" and "create_bitrix_task" in card["allowed_actions"]
    assert (await create(client, head, 1)).status_code == 201
    card = (await client.get("/api/v1/appeals/1", headers=head)).json()
    assert card["status"] == "new", "создание задачи статус не меняет"
    assert card["bitrix_task"] is not None and "create_bitrix_task" not in card["allowed_actions"]
    assert len(fake_bitrix.tasks) == 1
