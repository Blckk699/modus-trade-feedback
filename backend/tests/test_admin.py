"""Настройки администратора (B-14). Истории 64–70: всё только администратору."""

from __future__ import annotations

from datetime import datetime

import httpx
import pytest

from tests.support import TZ, bot_headers

FORM = {"type": "problem", "category_id": 1, "priority": "medium", "text": "Нет назначения оборудования."}


async def admin_call(client: httpx.AsyncClient, headers: dict, method: str, path: str, body=None) -> httpx.Response:
    return await client.request(method, f"/api/v1/admin{path}", headers=headers, json=body)


@pytest.mark.parametrize("who", ["owner", "head_procurement", "employee_sales"])
async def test_only_admin_manages_settings(client, login_as, who) -> None:
    headers = await login_as(who)
    calls = [
        ("POST", "/users", {"telegram_id": 5, "full_name": "Х", "role": "employee"}),
        ("PATCH", "/users/4", {"is_absent": True}),
        ("POST", "/departments", {"name": "Логистика"}),
        ("PATCH", "/categories/1", {"responsible_id": 4}),
        ("GET", "/deadline-rules", None),
        ("PUT", "/deadline-rules", [{"priority": "high", "business_days": 2}]),
        ("GET", "/settings", None),
        ("PATCH", "/settings", {"digest_time": "08:00"}),
    ]
    for method, path, body in calls:
        response = await admin_call(client, headers, method, path, body)
        assert response.status_code == 403, (method, path)


async def test_admin_adds_employee_who_can_then_log_in(client, login_as) -> None:
    """История 64."""
    admin = await login_as("admin")
    created = await admin_call(
        client, admin, "POST", "/users",
        {"telegram_id": 777001, "full_name": "Ирина Волкова", "position": "Специалист по закупкам", "role": "employee", "department_id": 1},
    )
    assert created.status_code == 201, created.text
    assert (created.json()["telegram_id"], created.json()["department"]["name"]) == (777001, "Закупки")
    me = await client.get("/api/v1/me", headers=bot_headers(777001))
    assert me.status_code == 200 and me.json()["full_name"] == "Ирина Волкова"

    duplicate = await admin_call(client, admin, "POST", "/users", {"telegram_id": 777001, "full_name": "Дубль", "role": "employee"})
    assert (duplicate.status_code, duplicate.json()["error"]["code"]) == (409, "conflict")
    bad_department = await admin_call(
        client, admin, "POST", "/users", {"telegram_id": 777002, "full_name": "Х", "role": "employee", "department_id": 99}
    )
    assert bad_department.status_code == 422


async def test_change_role_department_and_disable_access(client, login_as) -> None:
    """История 65: отключённый не входит, его сессии сбрасываются."""
    admin = await login_as("admin")
    session = await login_as("employee_sales")
    moved = await admin_call(client, admin, "PATCH", "/users/8", {"role": "head", "department_id": 2, "position": None})
    assert (moved.json()["role"], moved.json()["department"]["name"], moved.json()["position"]) == ("head", "Бухгалтерия", None)

    disabled = await admin_call(client, admin, "PATCH", "/users/8", {"is_disabled": True})
    assert disabled.json()["is_disabled"] is True
    response = await client.get("/api/v1/me", headers=session)
    assert response.status_code in (401, 403)

    self_disable = await admin_call(client, admin, "PATCH", "/users/2", {"is_disabled": True})
    assert self_disable.status_code == 422


async def test_departments_and_heads(client, login_as) -> None:
    """История 66: руководитель подразделения — тот, кому идёт эскалация и кто видит обращения."""
    admin = await login_as("admin")
    created = await admin_call(client, admin, "POST", "/departments", {"name": "Логистика"})
    assert created.status_code == 201 and created.json()["head"] is None
    assert (await admin_call(client, admin, "POST", "/departments", {"name": "логистика"})).status_code == 409
    assert (await admin_call(client, admin, "PATCH", "/departments/1", {"head_id": 2})).status_code == 422, "не администратор"

    changed = await admin_call(client, admin, "PATCH", "/departments/1", {"head_id": 4})
    assert changed.json()["head"]["full_name"] == "Карина Шаймерденова"
    listing = await client.get("/api/v1/appeals", headers=await login_as("employee_procurement"), params={"scope": "department"})
    assert listing.status_code == 200 and listing.json()["total"] == 3


async def test_category_rules_drive_routing(client, login_as) -> None:
    """Истории 67, 68: ответственный и заместитель категории, отсутствие."""
    admin = await login_as("admin")
    for body in ({"responsible_id": 2}, {"deputy_id": 2}, {"responsible_id": 4, "deputy_id": 4}):
        response = await admin_call(client, admin, "PATCH", "/categories/1", body)
        assert response.status_code == 422, body

    changed = await admin_call(client, admin, "PATCH", "/categories/1", {"responsible_id": 13, "deputy_id": 4})
    assert (changed.json()["responsible"]["full_name"], changed.json()["deputy"]["full_name"]) == ("Станислав Цой", "Карина Шаймерденова")
    employee = await login_as("employee_sales")
    first = (await client.post("/api/v1/appeals", headers=employee, json=FORM)).json()
    assert first["assignee"]["full_name"] == "Станислав Цой"

    await admin_call(client, admin, "PATCH", "/users/13", {"is_absent": True})
    second = (await client.post("/api/v1/appeals", headers=employee, json=FORM)).json()
    assert second["assignee"]["full_name"] == "Карина Шаймерденова"


async def test_new_and_inactive_categories(client, login_as) -> None:
    admin = await login_as("admin")
    created = await admin_call(
        client, admin, "POST", "/categories", {"name": "Склад", "department_id": 1, "responsible_id": 3, "deputy_id": 2}
    )
    assert created.status_code == 422
    created = await admin_call(client, admin, "POST", "/categories", {"name": "Склад", "department_id": 1, "responsible_id": 3})
    assert created.status_code == 201
    category_id = created.json()["id"]

    await admin_call(client, admin, "PATCH", f"/categories/{category_id}", {"is_active": False})
    employee = await login_as("employee_sales")
    names = [c["name"] for c in (await client.get("/api/v1/categories", headers=employee)).json()]
    assert "Склад" not in names
    rejected = await client.post("/api/v1/appeals", headers=employee, json={**FORM, "category_id": category_id})
    assert rejected.status_code == 422


async def test_deadline_rules_apply_to_new_appeals(client, login_as) -> None:
    """История 69. Часы — понедельник 10:00."""
    admin = await login_as("admin")
    assert (await admin_call(client, admin, "GET", "/deadline-rules")).json() == [
        {"priority": "high", "business_days": 1},
        {"priority": "medium", "business_days": 3},
        {"priority": "low", "business_days": 5},
    ]
    for body in ([{"priority": "high", "business_days": 0}], [{"priority": "high", "business_days": 2}] * 2, []):
        assert (await admin_call(client, admin, "PUT", "/deadline-rules", body)).status_code == 422, body

    updated = await admin_call(client, admin, "PUT", "/deadline-rules", [{"priority": "medium", "business_days": 2}])
    assert updated.json()[1] == {"priority": "medium", "business_days": 2}
    appeal = (await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json=FORM)).json()
    assert datetime.fromisoformat(appeal["first_response_due_at"]) == datetime(2026, 11, 11, 10, 0, tzinfo=TZ)


async def test_digest_time_setting(client, login_as) -> None:
    admin = await login_as("admin")
    assert (await admin_call(client, admin, "GET", "/settings")).json() == {"digest_time": "09:00", "timezone": "+05:00"}
    assert (await admin_call(client, admin, "PATCH", "/settings", {"digest_time": "25:00"})).status_code == 422
    assert (await admin_call(client, admin, "PATCH", "/settings", {"digest_time": "08:30"})).json()["digest_time"] == "08:30"


async def test_unassigned_queue_and_manual_assignment(client, login_as) -> None:
    """История 70."""
    appeal = (await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json={**FORM, "category_id": None})).json()
    admin = await login_as("admin")
    queue = (await client.get("/api/v1/appeals", headers=admin, params={"scope": "unassigned"})).json()
    assert [i["number"] for i in queue["items"]] == [appeal["number"]]
    await client.post(f"/api/v1/appeals/{appeal['id']}/reassign", headers=admin, json={"assignee_id": 7, "reason": "Продажи"})
    assert (await client.get("/api/v1/appeals", headers=admin, params={"scope": "unassigned"})).json()["total"] == 0


async def test_assignee_becoming_admin_keeps_no_appeal_access(client, login_as) -> None:
    """Матрица доступа: администратор не ответственный и не видит приватную переписку (история 65)."""
    admin = await login_as("admin")
    head = await login_as("head_procurement")
    pm_id = 17  # employee_pm: не закреплён за категориями и не руководит подразделением
    assigned = await client.post(
        "/api/v1/appeals/2/reassign", headers=head, json={"assignee_id": pm_id, "reason": "Нужна оценка проекта"}
    )
    assert assigned.status_code == 200

    blocked = await admin_call(client, admin, "PATCH", f"/users/{pm_id}", {"role": "admin"})
    assert blocked.status_code == 422
    assert "открытые обращения" in blocked.text

    rejected = await client.post("/api/v1/appeals/2/reject", headers=head, json={"reason": "Вне плана"})
    assert rejected.json()["status"] == "rejected"
    former = await login_as("employee_pm")
    assert (await client.get("/api/v1/appeals/2/messages", headers=former)).status_code == 200

    promoted = await admin_call(client, admin, "PATCH", f"/users/{pm_id}", {"role": "admin"})
    assert promoted.json()["role"] == "admin"
    assert (await client.get("/api/v1/appeals/2/messages", headers=former)).status_code == 403


async def test_first_assignment_needs_no_reason_but_change_does(client, login_as) -> None:
    """Причина обязательна только при смене ответственного (истории 44 и 70)."""
    sender = await login_as("employee_sales")
    appeal = (await client.post("/api/v1/appeals", headers=sender, json={**FORM, "category_id": None})).json()
    assert appeal["assignee"] is None
    admin = await login_as("admin")
    url = f"/api/v1/appeals/{appeal['id']}/reassign"

    first = await client.post(url, headers=admin, json={"assignee_id": 7})
    assert (first.status_code, first.json()["assignee"]["id"]) == (200, 7)
    history = (await client.get(f"/api/v1/appeals/{appeal['id']}/history", headers=await login_as("owner"))).json()
    assigned = [e for e in history if e["kind"] == "assigned"][-1]
    assert (assigned["new_value"] is not None, assigned["comment"]) == (True, None)

    for body in ({"assignee_id": 17}, {"assignee_id": 17, "reason": None}, {"assignee_id": 17, "reason": "   "}):
        refused = await client.post(url, headers=admin, json=body)
        assert refused.status_code == 422, body
        assert refused.json()["error"]["details"]["fields"][0]["field"] == "reason"
    changed = await client.post(url, headers=admin, json={"assignee_id": 17, "reason": "Вопрос к проектному офису"})
    assert (changed.status_code, changed.json()["assignee"]["id"]) == (200, 17)


async def test_category_without_appeals_can_be_deleted(client, login_as) -> None:
    """B-25 п.7: пустую категорию удаляют, категорию с обращениями — только выключают."""
    admin = await login_as("admin")
    created = await admin_call(client, admin, "POST", "/categories", {"name": "Временная", "department_id": 1, "responsible_id": 3})
    assert created.status_code == 201, created.text
    category_id = created.json()["id"]
    assert (await admin_call(client, await login_as("owner"), "DELETE", f"/categories/{category_id}")).status_code == 403

    deleted = await admin_call(client, admin, "DELETE", f"/categories/{category_id}")
    assert (deleted.status_code, deleted.content) == (204, b"")
    listed = (await client.get("/api/v1/categories", headers=admin, params={"include_inactive": True})).json()
    assert category_id not in [c["id"] for c in listed]
    assert (await admin_call(client, admin, "DELETE", f"/categories/{category_id}")).status_code == 404

    busy = await admin_call(client, admin, "DELETE", "/categories/1")
    error = busy.json()["error"]
    assert (busy.status_code, error["code"], error["details"]["reason"]) == (409, "conflict", "category_has_appeals")
    assert error["details"]["appeals_count"] >= 1
    assert 1 in [c["id"] for c in (await client.get("/api/v1/categories", headers=admin)).json()]


async def test_has_password_is_shown_to_admin_and_owner_of_the_account(client, login_as) -> None:
    """B-25 п.8: сброс пароля предлагают только тем, у кого пароль есть."""
    admin = await login_as("admin")
    sales = await login_as("employee_sales")
    me = (await client.get("/api/v1/me", headers=sales)).json()
    users = (await client.get("/api/v1/users", headers=admin)).json()
    assert all(u["has_password"] is False for u in users), "демо-сотрудники входят через Telegram, пароля у них нет"

    done = await client.put(
        "/api/v1/me/credentials", headers=sales, json={"email": "kim@company.kz", "new_password": "nadezhnyi-parol-2026"}
    )
    assert done.status_code == 200
    by_id = {u["id"]: u for u in (await client.get("/api/v1/users", headers=admin)).json()}
    assert by_id[me["id"]]["has_password"] is True
    assert sum(u["has_password"] for u in by_id.values()) == 1

    # Коллегам чужой признак не показывается, свой — виден.
    for user in (await client.get("/api/v1/users", headers=sales)).json():
        assert user["has_password"] is (True if user["id"] == me["id"] else None)


async def test_category_can_be_set_while_assigning(client, login_as) -> None:
    """Обращению без категории администратор задаёт и ответственного, и категорию."""
    created = await client.post("/api/v1/appeals", headers=await login_as("employee_sales"), json={**FORM, "category_id": None})
    appeal = created.json()
    assert (appeal["category"], appeal["assignee"]) == (None, None)
    admin = await login_as("admin")
    url = f"/api/v1/appeals/{appeal['id']}/reassign"

    bad = await client.post(url, headers=admin, json={"assignee_id": 7, "category_id": 9999})
    assert (bad.status_code, bad.json()["error"]["details"]["fields"][0]["field"]) == (422, "category_id")

    done = await client.post(url, headers=admin, json={"assignee_id": 7, "category_id": 9})
    body = done.json()
    assert (done.status_code, body["assignee"]["id"], body["category"]["id"]) == (200, 7, 9)
    assert body["department"] is not None, "подразделение берётся из категории"
    history = (await client.get(f"/api/v1/appeals/{appeal['id']}/history", headers=await login_as("owner"))).json()
    changed = [e for e in history if e["kind"] == "field_changed" and e["field"] == "category"]
    assert [(e["old_value"], e["new_value"]) for e in changed] == [(None, body["category"]["name"])]

    # Тот же ответственный и другая категория — меняется только категория, причина не нужна.
    only_category = await client.post(url, headers=admin, json={"assignee_id": 7, "category_id": 1})
    after = only_category.json()
    assert (only_category.status_code, after["assignee"]["id"], after["category"]["id"]) == (200, 7, 1)
    assert after["first_response_due_at"] == body["first_response_due_at"]
    same = await client.post(url, headers=admin, json={"assignee_id": 7, "category_id": 1})
    assert same.status_code == 422, "ни ответственный, ни категория не меняются"


async def test_head_cannot_move_appeal_to_another_department_by_category(client, login_as) -> None:
    """Руководитель закупок меняет категорию только внутри закупок; собственник — любую."""
    head = await login_as("head_procurement")
    card = (await client.get("/api/v1/appeals/1", headers=head)).json()
    assignee, own = card["assignee"]["id"], card["category"]["id"]
    categories = (await client.get("/api/v1/categories", headers=head)).json()
    mine = next(c["id"] for c in categories if c["department"]["name"] == "Закупки" and c["id"] != own)
    foreign = next(c["id"] for c in categories if c["department"]["name"] != "Закупки")
    url = "/api/v1/appeals/1/reassign"

    refused = await client.post(url, headers=head, json={"assignee_id": assignee, "category_id": foreign})
    assert (refused.status_code, refused.json()["error"]["details"]["fields"][0]["field"]) == (422, "category_id")
    assert (await client.get("/api/v1/appeals/1", headers=head)).json()["category"]["id"] == own

    allowed = await client.post(url, headers=head, json={"assignee_id": assignee, "category_id": mine})
    assert (allowed.status_code, allowed.json()["category"]["id"]) == (200, mine)
    by_owner = await client.post(url, headers=await login_as("owner"), json={"assignee_id": assignee, "category_id": foreign})
    assert (by_owner.status_code, by_owner.json()["category"]["id"]) == (200, foreign)
