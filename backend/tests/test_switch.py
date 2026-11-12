"""Демо-переключатель ролей: связанные аккаунты и смена сессии (B-22)."""

from __future__ import annotations

import json
from datetime import datetime, timedelta

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import func, select

from app.models import AccountSwitch, User
from app.seed import AccountsFileError, SwitchMember, apply_switch_group, data, load_accounts, load_switch_group
from tests.support import bot_headers, telegram_id_of

KNOWN_KEYS = {u.key for u in data.USERS}
GROUP_KEYS = ["owner", "admin", "head_procurement", "employee_procurement"]
PERSON = "person@company.kz"
OWNER, ADMIN, HEAD, EMPLOYEE, SALES = 1, 2, 3, 4, 8


async def link(app: FastAPI, *members: SwitchMember) -> tuple[int, int]:
    async with app.state.sessionmaker() as session, session.begin():
        return await apply_switch_group(session, list(members))


def keys(*names: str) -> list[SwitchMember]:
    return [SwitchMember("key", name) for name in names]


async def me(client: httpx.AsyncClient, headers: dict) -> dict:
    return (await client.get("/api/v1/me", headers=headers)).json()


async def switch(client: httpx.AsyncClient, headers: dict, user_id: int) -> httpx.Response:
    return await client.post("/api/v1/auth/switch", headers=headers, json={"user_id": user_id})


def bearer(response: httpx.Response) -> dict:
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def test_without_setting_there_is_no_switcher(client, demo, login_as) -> None:
    employee = await login_as("employee_procurement")
    assert (await me(client, employee))["switch_targets"] == []
    assert (await switch(client, employee, OWNER)).status_code == 403


async def test_group_members_see_each_other(client, app, demo, login_as) -> None:
    assert await link(app, *keys(*GROUP_KEYS)) == (4, 0)
    targets = (await me(client, await login_as("employee_procurement")))["switch_targets"]
    assert [(t["id"], t["role"]) for t in targets] == [(OWNER, "owner"), (ADMIN, "admin"), (HEAD, "head")]
    assert targets[2]["department"]["name"] == "Закупки"
    assert (await me(client, await login_as("employee_sales")))["switch_targets"] == []


async def test_switch_gives_session_with_exactly_the_target_rights(client, app, demo, login_as) -> None:
    """Права не смешиваются: под каждой ролью ровно её права, прежняя сессия остаётся прежним пользователем."""
    await link(app, *keys(*GROUP_KEYS))
    employee = await login_as("employee_procurement")

    as_owner = await switch(client, employee, OWNER)
    assert (as_owner.status_code, as_owner.json()["user"]["role"]) == (200, "owner")
    owner = bearer(as_owner)
    assert (await me(client, owner))["permissions"]["analytics_scope"] == "company"
    assert (await client.get("/api/v1/analytics/summary", headers=owner)).status_code == 200
    assert (await client.get("/api/v1/analytics/summary", headers=employee)).status_code == 403
    assert (await me(client, employee))["id"] == EMPLOYEE

    as_admin = await switch(client, owner, ADMIN)
    admin = bearer(as_admin)
    assert (await client.get("/api/v1/admin/settings", headers=admin)).status_code == 200
    assert (await client.get("/api/v1/appeals/1/messages", headers=admin)).status_code == 403  # администратор переписку не видит

    back = await switch(client, admin, EMPLOYEE)
    assert (back.status_code, back.json()["user"]["id"]) == (200, EMPLOYEE)


async def test_switch_outside_group_is_forbidden(client, app, demo, login_as) -> None:
    await link(app, *keys(*GROUP_KEYS))
    employee = await login_as("employee_procurement")
    for user_id in (SALES, EMPLOYEE, 9999):
        response = await switch(client, employee, user_id)
        assert (response.status_code, response.json()["error"]["code"]) == (403, "forbidden"), user_id
    outsider = await login_as("employee_sales")
    assert (await switch(client, outsider, OWNER)).status_code == 403


async def test_bot_cannot_switch(client, app, demo) -> None:
    await link(app, *keys(*GROUP_KEYS))
    response = await switch(client, bot_headers(telegram_id_of("employee_procurement")), OWNER)
    assert response.status_code == 403


async def test_disabled_target_is_hidden_and_refused(client, app, demo, login_as) -> None:
    await link(app, *keys(*GROUP_KEYS))
    await client.patch(f"/api/v1/admin/users/{HEAD}", headers=await login_as("admin"), json={"is_disabled": True})
    employee = await login_as("employee_procurement")
    assert HEAD not in [t["id"] for t in (await me(client, employee))["switch_targets"]]
    response = await switch(client, employee, HEAD)
    assert (response.status_code, response.json()["error"]["code"]) == (403, "user_disabled")


async def test_switch_is_journaled(client, app, demo, login_as) -> None:
    await link(app, *keys(*GROUP_KEYS))
    await switch(client, await login_as("employee_procurement"), OWNER)
    await switch(client, await login_as("employee_procurement"), SALES)  # отказ в журнал не пишется
    async with app.state.sessionmaker() as session:
        rows = (await session.execute(select(AccountSwitch.from_user_id, AccountSwitch.to_user_id))).all()
    assert [tuple(r) for r in rows] == [(EMPLOYEE, OWNER)]


async def test_real_account_joins_by_email_and_relinking_is_idempotent(client, app, demo, login_as) -> None:
    """Аккаунт человека связывается по почте; повторное применение не дублирует и убирает вышедших из списка."""
    admin = await login_as("admin")
    created = await client.post(
        "/api/v1/admin/users", headers=admin, json={"email": PERSON, "full_name": "Александр", "role": "employee"}
    )
    person_id = created.json()["id"]
    members = [*keys(*GROUP_KEYS), SwitchMember("email", PERSON), SwitchMember("email", "nobody@company.kz")]
    assert await link(app, *members) == (5, 1)
    assert await link(app, *members) == (5, 1)
    async with app.state.sessionmaker() as session:
        assert await session.scalar(select(func.count()).select_from(User).where(User.switch_group.is_not(None))) == 5
    assert person_id in [t["id"] for t in (await me(client, await login_as("owner")))["switch_targets"]]

    assert await link(app, *keys("owner", "admin")) == (2, 0)
    assert (await me(client, await login_as("employee_procurement")))["switch_targets"] == []
    assert [t["id"] for t in (await me(client, await login_as("owner")))["switch_targets"]] == [ADMIN]

    assert await link(app, *keys("owner")) == (0, 0)  # один участник — группы нет
    assert (await me(client, await login_as("owner")))["switch_targets"] == []


def test_switch_group_is_read_from_accounts_file(tmp_path) -> None:
    path = tmp_path / "accounts.json"
    path.write_text(
        json.dumps({"owner": 5, "switch_group": ["owner", " admin ", "Person@Company.kz", 777, "owner"]}), encoding="utf-8"
    )
    assert load_accounts(path, KNOWN_KEYS).keys() == {"owner"}
    assert load_switch_group(path, KNOWN_KEYS) == [
        SwitchMember("key", "owner"),
        SwitchMember("key", "admin"),
        SwitchMember("email", PERSON),
        SwitchMember("telegram", 777),
    ]
    assert load_switch_group(tmp_path / "нет.json", KNOWN_KEYS) == []
    path.write_text(json.dumps({"owner": 5}), encoding="utf-8")
    assert load_switch_group(path, KNOWN_KEYS) == []


@pytest.mark.parametrize("group", ["owner", ["no-such-key"], [True], [-5], [{"email": "a@b.kz"}]])
def test_bad_switch_group_is_reported_without_echoing_entries(tmp_path, group) -> None:
    path = tmp_path / "accounts.json"
    path.write_text(json.dumps({"switch_group": group}), encoding="utf-8")
    with pytest.raises(AccountsFileError) as error:
        load_switch_group(path, KNOWN_KEYS)
    assert "no-such-key" not in str(error.value)


async def test_switch_session_is_short_lived(client, app, demo, login_as, time_machine) -> None:
    """Сессия переключателя живёт 12 часов, обычная — как раньше."""
    await link(app, *keys(*GROUP_KEYS))
    employee = await login_as("employee_procurement")
    switched = await switch(client, employee, OWNER)
    lifetime = datetime.fromisoformat(switched.json()["expires_at"]) - time_machine.now
    assert timedelta(hours=11, minutes=59) < lifetime <= timedelta(hours=12)
    owner = bearer(switched)
    await time_machine.advance(hours=12, minutes=1)
    assert (await client.get("/api/v1/me", headers=owner)).status_code == 401
    assert (await client.get("/api/v1/me", headers=employee)).status_code == 200
