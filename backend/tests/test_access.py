"""Заявки на доступ и приглашения (B-18, истории 71–74)."""

from __future__ import annotations

import json
from datetime import timedelta

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import select, update

from app.auth.telegram import sign_login_widget, sign_mini_app
from app.models import Notification, User
from tests.support import TimeMachine, bot_headers, telegram_id_of

BOT_TOKEN = "123456:TEST-BOT-TOKEN"
STRANGER = 555_000_001
OTHER_STRANGER = 555_000_002
BOT_KEY = {"X-Service-Key": "test-service-key"}


@pytest.fixture(autouse=True)
def bot_token(app: FastAPI) -> None:
    app.state.settings.telegram_bot_token = BOT_TOKEN


def init_data(telegram_id: int, time_machine: TimeMachine) -> str:
    user = json.dumps({"id": telegram_id, "first_name": "Сергей", "last_name": "Ким", "username": "sergey_kim"})
    return sign_mini_app({"auth_date": str(int(time_machine.now.timestamp())), "user": user}, BOT_TOKEN)


def widget(telegram_id: int, time_machine: TimeMachine) -> dict:
    fields = {"id": telegram_id, "first_name": "Сергей", "last_name": "Ким", "auth_date": int(time_machine.now.timestamp())}
    return sign_login_widget(fields, BOT_TOKEN)


async def submit(client: httpx.AsyncClient, telegram_id: int = STRANGER, **body) -> httpx.Response:
    payload = {"full_name": "Сергей Ким", "department_id": None, "comment": "Менеджер по продажам", **body}
    return await client.post("/api/v1/access-requests", json=payload, headers=bot_headers(telegram_id))


async def department_id(client: httpx.AsyncClient, name: str) -> int:
    departments = (await client.get("/api/v1/access-requests/departments")).json()
    return next(d["id"] for d in departments if d["name"] == name)


async def notifications(app: FastAPI, kind: str) -> list[Notification]:
    async with app.state.sessionmaker() as session:
        rows = await session.execute(select(Notification).where(Notification.kind == kind).order_by(Notification.id))
        return list(rows.scalars())


async def user_ids_with_role(app: FastAPI, *roles: str) -> set[int]:
    async with app.state.sessionmaker() as session:
        return set((await session.execute(select(User.id).where(User.role.in_(roles)))).scalars())


async def pending_request_id(client: httpx.AsyncClient, headers: dict) -> int:
    page = (await client.get("/api/v1/admin/access-requests?status=pending", headers=headers)).json()
    return page["items"][0]["id"]


# --- подача заявки (история 71) ---------------------------------------------------------------------


async def test_stranger_submits_request_from_bot_and_managers_are_notified(client, app, demo) -> None:
    sales = await department_id(client, "Продажи")
    response = await submit(client, department_id=sales, telegram_username="sergey_kim")
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "pending"
    assert body["department"] == {"id": sales, "name": "Продажи"}
    assert body["telegram_username"] == "sergey_kim"

    sent = await notifications(app, "access_request_created")
    assert {n.user_id for n in sent} == await user_ids_with_role(app, "admin", "owner")
    assert all(n.path == "/settings/access-requests" for n in sent)
    assert sent[0].buttons[0]["type"] == "open_access_requests"


async def test_resubmission_updates_the_single_pending_request(client, app, demo) -> None:
    first = (await submit(client, comment="Первая версия")).json()
    again = await submit(client, comment="Уточнил должность")
    assert again.status_code == 200
    assert again.json()["id"] == first["id"]
    assert again.json()["comment"] == "Уточнил должность"
    managers = await user_ids_with_role(app, "admin", "owner")
    assert len(await notifications(app, "access_request_created")) == len(managers)


async def test_mini_app_and_web_submit_with_signed_telegram_data(client, demo, time_machine) -> None:
    mini = await client.post(
        "/api/v1/access-requests",
        json={"init_data": init_data(STRANGER, time_machine), "full_name": "Сергей Ким"},
    )
    assert mini.status_code == 201
    assert mini.json()["telegram_username"] == "sergey_kim"

    web = await client.post(
        "/api/v1/access-requests",
        json={"telegram_login": widget(OTHER_STRANGER, time_machine), "full_name": "Олег Петров"},
    )
    assert web.status_code == 201

    forged = {**widget(OTHER_STRANGER, time_machine), "first_name": "Подделка"}
    response = await client.post("/api/v1/access-requests", json={"telegram_login": forged, "full_name": "X"})
    assert (response.status_code, response.json()["error"]["code"]) == (401, "invalid_telegram_auth")


async def test_identity_is_required_and_only_one_way(client, demo, time_machine) -> None:
    nobody = await client.post("/api/v1/access-requests", json={"full_name": "Без данных"})
    assert (nobody.status_code, nobody.json()["error"]["code"]) == (401, "unauthorized")

    both = await client.post(
        "/api/v1/access-requests",
        json={
            "full_name": "Двое",
            "init_data": init_data(STRANGER, time_machine),
            "telegram_login": widget(STRANGER, time_machine),
        },
    )
    assert both.status_code == 422

    bot_and_body = await client.post(
        "/api/v1/access-requests",
        json={"full_name": "Бот", "init_data": init_data(STRANGER, time_machine)},
        headers=bot_headers(STRANGER),
    )
    assert bot_and_body.status_code == 422


async def test_registered_user_cannot_apply_and_disabled_user_is_told_so(client, app, demo) -> None:
    employee = telegram_id_of("employee_procurement")
    response = await submit(client, employee)
    assert (response.status_code, response.json()["error"]["code"]) == (409, "already_registered")

    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(User).where(User.telegram_id == employee).values(is_disabled=True))
    response = await submit(client, employee)
    assert (response.status_code, response.json()["error"]["code"]) == (403, "user_disabled")

    status = await client.post("/api/v1/access-requests/mine", json={}, headers=bot_headers(employee))
    assert status.json() == {"state": "disabled", "request": None}


async def test_submission_rate_is_limited_per_account(client, demo, time_machine) -> None:
    for _ in range(5):
        assert (await submit(client)).status_code in (200, 201)
    response = await submit(client)
    assert (response.status_code, response.json()["error"]["code"]) == (429, "too_many_requests")
    assert (await submit(client, OTHER_STRANGER)).status_code == 201

    await time_machine.advance(hours=1, minutes=1)
    assert (await submit(client)).status_code == 200


async def test_mine_shows_what_to_render(client, demo, time_machine) -> None:
    mine = await client.post("/api/v1/access-requests/mine", json={"init_data": init_data(STRANGER, time_machine)})
    assert mine.json() == {"state": "none", "request": None}

    await submit(client)
    mine = await client.post("/api/v1/access-requests/mine", json={}, headers=bot_headers(STRANGER))
    assert mine.json()["state"] == "pending"
    assert mine.json()["request"]["full_name"] == "Сергей Ким"


# --- рассмотрение (история 72) -----------------------------------------------------------------------


async def test_approval_creates_user_with_assigned_role_and_notifies_applicant(client, app, demo, login_as) -> None:
    sales = await department_id(client, "Продажи")
    it = await department_id(client, "IT")
    await submit(client, department_id=sales)
    admin = await login_as("admin")
    request_id = await pending_request_id(client, admin)

    response = await client.post(
        f"/api/v1/admin/access-requests/{request_id}/approve",
        json={"role": "head", "department_id": it, "position": "Руководитель IT"},
        headers=admin,
    )
    assert response.status_code == 200
    body = response.json()
    assert (body["status"], body["assigned_role"], body["assigned_department"]["name"]) == ("approved", "head", "IT")
    assert body["decided_by"]["role"] == "admin" and body["decided_at"]

    me = (await client.get("/api/v1/me", headers=bot_headers(STRANGER))).json()
    assert me["id"] == body["user_id"]
    assert (me["full_name"], me["role"], me["department"]["name"], me["position"]) == (
        "Сергей Ким", "head", "IT", "Руководитель IT",
    )

    [approved] = await notifications(app, "access_request_approved")
    assert approved.user_id == body["user_id"]

    again = await client.post(f"/api/v1/admin/access-requests/{request_id}/approve", json={}, headers=admin)
    assert (again.status_code, again.json()["error"]["code"]) == (409, "conflict")


async def test_approval_defaults_to_employee_in_requested_department(client, demo, login_as) -> None:
    sales = await department_id(client, "Продажи")
    await submit(client, department_id=sales)
    owner = await login_as("owner")
    request_id = await pending_request_id(client, owner)
    body = (await client.post(f"/api/v1/admin/access-requests/{request_id}/approve", json={}, headers=owner)).json()
    assert (body["assigned_role"], body["assigned_department"]["name"]) == ("employee", "Продажи")


async def test_owner_role_is_never_granted(client, demo, login_as) -> None:
    await submit(client)
    admin = await login_as("admin")
    request_id = await pending_request_id(client, admin)
    response = await client.post(
        f"/api/v1/admin/access-requests/{request_id}/approve", json={"role": "owner"}, headers=admin
    )
    assert (response.status_code, response.json()["error"]["code"]) == (422, "validation_error")
    invite = await client.post("/api/v1/admin/invites", json={"role": "owner"}, headers=admin)
    assert invite.status_code == 422


async def test_rejection_reaches_applicant_who_is_not_a_user_and_allows_new_request(client, app, demo, login_as) -> None:
    await submit(client)
    admin = await login_as("admin")
    request_id = await pending_request_id(client, admin)
    response = await client.post(
        f"/api/v1/admin/access-requests/{request_id}/reject", json={"reason": "Обратитесь к руководителю"}, headers=admin
    )
    assert (response.json()["status"], response.json()["reject_reason"]) == ("rejected", "Обратитесь к руководителю")

    pending = (await client.get("/api/v1/bot/notifications/pending", headers=BOT_KEY)).json()
    [rejected] = [n for n in pending if n["kind"] == "access_request_rejected"]
    assert rejected["recipient"] == {"user_id": None, "telegram_id": STRANGER}
    assert "Обратитесь к руководителю" in rejected["text"]

    mine = (await client.post("/api/v1/access-requests/mine", json={}, headers=bot_headers(STRANGER))).json()
    assert mine["state"] == "rejected"
    assert (await submit(client)).status_code == 201


@pytest.mark.parametrize("who", ["employee", "head"])
async def test_only_admin_and_owner_manage_access(client, demo, login_as, who) -> None:
    await submit(client)
    headers = await login_as(who)
    me = (await client.get("/api/v1/me", headers=headers)).json()
    assert me["permissions"]["can_manage_access"] is False
    for method, url, body in [
        ("GET", "/api/v1/admin/access-requests", None),
        ("POST", "/api/v1/admin/access-requests/1/approve", {}),
        ("POST", "/api/v1/admin/access-requests/1/reject", {}),
        ("GET", "/api/v1/admin/invites", None),
        ("POST", "/api/v1/admin/invites", {"role": "employee"}),
        ("POST", "/api/v1/admin/invites/1/revoke", None),
    ]:
        response = await client.request(method, url, json=body, headers=headers)
        assert response.status_code == 403, (method, url)


@pytest.mark.parametrize("who", ["admin", "owner"])
async def test_admin_and_owner_see_the_access_tab(client, demo, login_as, who) -> None:
    me = (await client.get("/api/v1/me", headers=await login_as(who))).json()
    assert me["permissions"]["can_manage_access"] is True


# --- приглашения (истории 73–74) ------------------------------------------------------------------


async def create_invite(client: httpx.AsyncClient, headers: dict, **body) -> dict:
    response = await client.post("/api/v1/admin/invites", json={"role": "employee", **body}, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def accept_by_bot(client: httpx.AsyncClient, token: str, telegram_id: int = STRANGER) -> httpx.Response:
    return await client.post(
        "/api/v1/invites/accept",
        json={"token": token, "full_name": "Сергей Ким", "telegram_username": "sergey_kim"},
        headers=bot_headers(telegram_id),
    )


async def test_invite_creates_user_at_once_and_token_is_shown_once(client, demo, login_as) -> None:
    admin = await login_as("admin")
    sales = await department_id(client, "Продажи")
    invite = await create_invite(client, admin, department_id=sales, full_name="Сергей Ким")
    token = invite["token"]
    assert invite["bot_link"] == f"https://t.me/modus_feedback_bot?start=inv_{token}"
    assert invite["web_link"].endswith(f"/invite/{token}")
    assert len(f"inv_{token}") <= 64  # предел параметра start у Telegram
    assert (invite["state"], invite["max_uses"], invite["used_count"]) == ("active", 1, 0)
    assert invite["expires_at"].startswith("2026-11-")

    listed = (await client.get("/api/v1/admin/invites", headers=admin)).json()
    assert "token" not in listed[0] and listed[0]["created_by"]["role"] == "admin"

    preview = (await client.get(f"/api/v1/invites/{token}")).json()
    assert (preview["role"], preview["department"]["name"]) == ("employee", "Продажи")

    response = await accept_by_bot(client, token)
    assert response.status_code == 200
    body = response.json()
    assert (body["created"], body["session"]) == (True, None)
    assert (body["user"]["role"], body["user"]["department"]["name"]) == ("employee", "Продажи")
    assert (await client.get("/api/v1/me", headers=bot_headers(STRANGER))).status_code == 200

    listed = (await client.get("/api/v1/admin/invites", headers=admin)).json()
    assert (listed[0]["state"], listed[0]["used_count"]) == ("exhausted", 1)


async def test_web_accept_gives_a_session(client, demo, login_as, time_machine) -> None:
    invite = await create_invite(client, await login_as("owner"), role="head")
    response = await client.post(
        "/api/v1/invites/accept", json={"token": invite["token"], "telegram_login": widget(STRANGER, time_machine)}
    )
    body = response.json()
    assert (body["created"], body["user"]["full_name"], body["user"]["role"]) == (True, "Сергей Ким", "head")
    me = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {body['session']['access_token']}"})
    assert me.json()["id"] == body["user"]["id"]


async def test_exhausted_invite_is_invalid(client, demo, login_as) -> None:
    invite = await create_invite(client, await login_as("admin"))
    assert (await accept_by_bot(client, invite["token"])).status_code == 200
    response = await accept_by_bot(client, invite["token"], OTHER_STRANGER)
    assert (response.status_code, response.json()["error"]["code"]) == (410, "invite_invalid")
    assert (await client.get(f"/api/v1/invites/{invite['token']}")).status_code == 410


async def test_expired_invite_is_invalid(client, demo, login_as, time_machine) -> None:
    admin = await login_as("admin")
    invite = await create_invite(client, admin, expires_in_days=2, max_uses=10)
    await time_machine.advance(days=2, minutes=1)
    response = await accept_by_bot(client, invite["token"])
    assert (response.status_code, response.json()["error"]["code"]) == (410, "invite_invalid")
    listed = (await client.get("/api/v1/admin/invites", headers=admin)).json()
    assert listed[0]["state"] == "expired"
    assert (await client.get("/api/v1/admin/invites?include_inactive=false", headers=admin)).json() == []


async def test_revoked_invite_is_invalid(client, demo, login_as) -> None:
    admin = await login_as("admin")
    invite = await create_invite(client, admin, max_uses=5)
    revoked = (await client.post(f"/api/v1/admin/invites/{invite['id']}/revoke", headers=admin)).json()
    assert revoked["state"] == "revoked" and revoked["revoked_at"]
    again = (await client.post(f"/api/v1/admin/invites/{invite['id']}/revoke", headers=admin)).json()
    assert again["revoked_at"] == revoked["revoked_at"]

    response = await accept_by_bot(client, invite["token"])
    assert (response.status_code, response.json()["error"]["code"]) == (410, "invite_invalid")
    assert (await accept_by_bot(client, "no-such-token")).status_code == 410


async def test_existing_user_changes_nothing_by_invite(client, demo, login_as) -> None:
    admin = await login_as("admin")
    invite = await create_invite(client, admin, role="admin")
    employee = telegram_id_of("employee_procurement")
    body = (await accept_by_bot(client, invite["token"], employee)).json()
    assert (body["created"], body["user"]["role"]) == (False, "employee")
    listed = (await client.get("/api/v1/admin/invites", headers=admin)).json()
    assert (listed[0]["state"], listed[0]["used_count"]) == ("active", 0)


async def test_invite_closes_pending_request_of_the_same_account(client, demo, login_as) -> None:
    await submit(client)
    admin = await login_as("admin")
    invite = await create_invite(client, admin)
    user_id = (await accept_by_bot(client, invite["token"])).json()["user"]["id"]
    page = (await client.get("/api/v1/admin/access-requests", headers=admin)).json()
    assert (page["items"][0]["status"], page["items"][0]["user_id"]) == ("approved", user_id)


async def test_invite_lasts_seven_days_by_default(client, demo, login_as, time_machine) -> None:
    invite = await create_invite(client, await login_as("admin"))
    await time_machine.advance(timedelta(days=6, hours=23))
    assert (await client.get(f"/api/v1/invites/{invite['token']}")).status_code == 200
    await time_machine.advance(hours=2)
    assert (await client.get(f"/api/v1/invites/{invite['token']}")).status_code == 410


async def test_invite_token_guessing_is_rate_limited(client, demo, login_as, time_machine) -> None:
    """Токен виден в путях и логах — перебор ограничен: 10 неудач за 15 минут с адреса, у бота — с Telegram ID."""
    invite = await create_invite(client, await login_as("admin"))
    for i in range(10):
        assert (await client.get(f"/api/v1/invites/guess-{i}")).status_code == 410
    blocked = await client.get(f"/api/v1/invites/{invite['token']}")
    assert (blocked.status_code, blocked.json()["error"]["code"]) == (429, "too_many_requests")

    # Бот считается по Telegram ID пользователя, а не по своему адресу.
    for i in range(10):
        assert (await accept_by_bot(client, f"guess-{i}")).status_code == 410
    assert (await accept_by_bot(client, invite["token"])).status_code == 429
    assert (await accept_by_bot(client, invite["token"], OTHER_STRANGER)).status_code == 200

    await time_machine.advance(minutes=16)
    assert (await client.get(f"/api/v1/invites/{invite['token']}")).status_code == 410  # уже исчерпано, но не 429


async def test_invite_links_come_from_settings(client, app, demo, login_as) -> None:
    app.state.settings.telegram_bot_username = "other_bot"
    app.state.settings.public_web_url = "https://modus.test/"
    invite = await create_invite(client, await login_as("owner"))
    assert invite["bot_link"] == f"https://t.me/other_bot?start=inv_{invite['token']}"
    assert invite["web_link"] == f"https://modus.test/invite/{invite['token']}"
    assert len(invite["token"]) >= 22  # не меньше 128 бит в base64url
