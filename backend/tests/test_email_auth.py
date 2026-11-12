"""Вход по почте и паролю, Telegram как SSO (B-20, истории 75–77)."""

from __future__ import annotations

from datetime import timedelta

import httpx
import pytest
from fastapi import FastAPI

from app.auth.telegram import sign_login_widget
from tests.support import TimeMachine

BOT_TOKEN = "123456:TEST-BOT-TOKEN"
EMAIL = "s.kim@company.kz"
PASSWORD = "korova-2026"
SALES = 8  # employee_sales в сиде, вошёл через Telegram


@pytest.fixture(autouse=True)
def bot_token(app: FastAPI) -> None:
    app.state.settings.telegram_bot_token = BOT_TOKEN


def widget(telegram_id: int, time_machine: TimeMachine) -> dict:
    fields = {"id": telegram_id, "first_name": "Сергей", "auth_date": int(time_machine.now.timestamp())}
    return sign_login_widget(fields, BOT_TOKEN)


async def register(client: httpx.AsyncClient, **body) -> httpx.Response:
    payload = {"full_name": "Сергей Ким", "email": EMAIL, "password": PASSWORD, "department_id": 3, "comment": "Продажи"}
    return await client.post("/api/v1/auth/register", json={**payload, **body})


async def login(client: httpx.AsyncClient, email: str = EMAIL, password: str = PASSWORD, **body) -> httpx.Response:
    return await client.post("/api/v1/auth/login", json={"email": email, "password": password, **body})


def bearer(response: httpx.Response) -> dict:
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def approve(client: httpx.AsyncClient, admin: dict, request_id: int, **body) -> httpx.Response:
    return await client.post(f"/api/v1/admin/access-requests/{request_id}/approve", headers=admin, json=body)


async def test_registration_creates_request_and_login_waits_for_approval(client, demo, login_as) -> None:
    """История 75: без приглашения — заявка; до одобрения войти нельзя."""
    created = await register(client)
    body = created.json()
    assert (created.status_code, body["status"], body["session"]) == (201, "pending", None)
    assert (body["request"]["email"], body["request"]["status"]) == (EMAIL, "pending")
    assert PASSWORD not in created.text

    again = await register(client, full_name="Сергей Ким (продажи)")
    assert (again.status_code, again.json()["request"]["id"]) == (200, body["request"]["id"])

    pending = await login(client)
    assert (pending.status_code, pending.json()["error"]["code"]) == (403, "access_request_pending")
    wrong = await login(client, password="neverno-123")
    assert (wrong.status_code, wrong.json()["error"]["code"]) == (401, "invalid_credentials")

    admin = await login_as("admin")
    listed = (await client.get("/api/v1/admin/access-requests", headers=admin)).json()["items"]
    assert listed[0]["email"] == EMAIL
    approved = await approve(client, admin, body["request"]["id"], role="employee")
    assert approved.status_code == 200

    session = await login(client, email="  S.Kim@Company.KZ ")
    me = session.json()["user"]
    assert session.status_code == 200
    assert (me["email"], me["has_password"], me["telegram_linked"], me["role"]) == (EMAIL, True, False, "employee")
    assert (await client.get("/api/v1/me", headers=bearer(session))).status_code == 200


async def test_rejected_request_is_told_on_login(client, demo, login_as) -> None:
    request_id = (await register(client)).json()["request"]["id"]
    admin = await login_as("admin")
    await client.post(f"/api/v1/admin/access-requests/{request_id}/reject", headers=admin, json={"reason": "Не наш сотрудник"})
    response = await login(client)
    assert (response.status_code, response.json()["error"]["code"]) == (403, "access_request_rejected")
    assert response.json()["error"]["details"]["reason"] == "Не наш сотрудник"


async def test_invite_registration_gives_access_at_once(client, demo, login_as) -> None:
    """Приглашение по почте: сразу пользователь с ролью и подразделением приглашения."""
    admin = await login_as("admin")
    invite = (await client.post("/api/v1/admin/invites", headers=admin, json={"role": "head", "department_id": 2})).json()
    response = await register(client, invite_token=invite["token"], department_id=None)
    body = response.json()
    assert (response.status_code, body["status"], body["request"]) == (201, "registered", None)
    user = body["session"]["user"]
    assert (user["role"], user["department"]["id"], user["email"]) == ("head", 2, EMAIL)
    me = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {body['session']['access_token']}"})
    assert me.status_code == 200
    assert (await login(client)).status_code == 200

    reused = await register(client, email="other@company.kz", invite_token=invite["token"])
    assert (reused.status_code, reused.json()["error"]["code"]) == (410, "invite_invalid")


async def test_email_is_unique_regardless_of_case(client, demo, login_as) -> None:
    admin = await login_as("admin")
    invite = (await client.post("/api/v1/admin/invites", headers=admin, json={"role": "employee"})).json()
    await register(client, invite_token=invite["token"])
    taken = await register(client, email="S.KIM@company.kz")
    assert (taken.status_code, taken.json()["error"]["code"]) == (409, "email_taken")
    bad = await register(client, email="not-an-email")
    assert bad.status_code == 422
    short = await register(client, email="x@company.kz", password="Qz7_k")
    assert short.status_code == 422
    assert "Qz7_k" not in short.text


async def registered_user(client, login_as) -> None:
    admin = await login_as("admin")
    invite = (await client.post("/api/v1/admin/invites", headers=admin, json={"role": "employee"})).json()
    assert (await register(client, invite_token=invite["token"])).status_code == 201


async def test_five_failures_lock_the_email_for_five_minutes(client, demo, login_as, time_machine) -> None:
    await registered_user(client, login_as)
    for _ in range(5):
        assert (await login(client, password="neverno-123")).status_code == 401
    locked = await login(client)
    assert (locked.status_code, locked.json()["error"]["code"]) == (429, "too_many_requests")
    await time_machine.advance(timedelta(minutes=5, seconds=1))
    assert (await login(client)).status_code == 200


async def test_success_resets_the_failure_counter(client, demo, login_as) -> None:
    await registered_user(client, login_as)
    for _ in range(4):
        await login(client, password="neverno-123")
    assert (await login(client)).status_code == 200
    for _ in range(4):
        await login(client, password="neverno-123")
    assert (await login(client)).status_code == 200


async def test_address_limit_stops_guessing_many_emails(client, app, demo) -> None:
    app.state.settings.password_max_failures_per_ip = 6
    for i in range(6):
        assert (await login(client, email=f"user{i}@company.kz")).status_code == 401
    blocked = await login(client, email="fresh@company.kz")
    assert blocked.status_code == 429


async def test_admin_reset_gives_temporary_password_once(client, demo, login_as) -> None:
    """История 77: временный пароль, при входе — задать новый; старые сессии закрываются."""
    await registered_user(client, login_as)
    first = await login(client)
    old_session = bearer(first)
    user_id = first.json()["user"]["id"]
    admin = await login_as("admin")

    assert (await client.post(f"/api/v1/admin/users/{user_id}/reset-password", headers=await login_as("owner"))).status_code == 403
    reset = await client.post(f"/api/v1/admin/users/{user_id}/reset-password", headers=admin)
    temporary = reset.json()["temporary_password"]
    assert reset.status_code == 200 and len(temporary) >= 8
    assert (await client.get("/api/v1/me", headers=old_session)).status_code == 401
    assert (await login(client)).status_code == 401  # старый пароль больше не подходит

    must_change = await login(client, password=temporary)
    assert (must_change.status_code, must_change.json()["error"]["code"]) == (403, "password_change_required")
    changed = await login(client, password=temporary, new_password="novyi-parol-2026")
    assert changed.status_code == 200
    assert (await login(client, password="novyi-parol-2026")).status_code == 200
    assert (await login(client, password=temporary)).status_code == 401

    no_email = await client.post(f"/api/v1/admin/users/{SALES}/reset-password", headers=admin)
    assert no_email.status_code == 409


async def test_telegram_user_sets_email_and_password_in_profile(client, demo, login_as) -> None:
    """Пришедший через Telegram задаёт почту и пароль; дальше смена — с текущим паролем."""
    sales = await login_as("employee_sales")
    me = (await client.get("/api/v1/me", headers=sales)).json()
    assert (me["email"], me["has_password"], me["telegram_linked"]) == (None, False, True)

    missing = await client.put("/api/v1/me/credentials", headers=sales, json={"new_password": PASSWORD})
    assert missing.status_code == 422
    done = await client.put("/api/v1/me/credentials", headers=sales, json={"email": "Kim@Company.kz", "new_password": PASSWORD})
    assert (done.status_code, done.json()["email"], done.json()["has_password"]) == (200, "kim@company.kz", True)
    assert PASSWORD not in done.text
    assert (await login(client, email="kim@company.kz")).status_code == 200

    wrong = await client.put("/api/v1/me/credentials", headers=sales, json={"current_password": "x", "new_password": "novyi-parol-2026"})
    assert (wrong.status_code, wrong.json()["error"]["details"]["fields"][0]["field"]) == (422, "current_password")
    ok = await client.put(
        "/api/v1/me/credentials", headers=sales, json={"current_password": PASSWORD, "new_password": "novyi-parol-2026"}
    )
    assert ok.status_code == 200
    assert (await client.get("/api/v1/me", headers=sales)).status_code == 200  # текущая сессия жива


async def test_email_of_another_user_is_taken(client, demo, login_as) -> None:
    await registered_user(client, login_as)
    sales = await login_as("employee_sales")
    taken = await client.put("/api/v1/me/credentials", headers=sales, json={"email": EMAIL, "new_password": PASSWORD})
    assert (taken.status_code, taken.json()["error"]["code"]) == (409, "email_taken")


async def test_link_and_unlink_telegram(client, demo, login_as, time_machine) -> None:
    """Пользователь с почтой привязывает Telegram и входит через него; отвязать можно при почте и пароле."""
    await registered_user(client, login_as)
    session = bearer(await login(client))
    linked = await client.post("/api/v1/me/telegram", headers=session, json=widget(555_000_777, time_machine))
    assert (linked.status_code, linked.json()["telegram_linked"]) == (200, True)
    via_telegram = await client.post("/api/v1/auth/telegram/widget", json=widget(555_000_777, time_machine))
    assert (via_telegram.status_code, via_telegram.json()["user"]["email"]) == (200, EMAIL)

    sales_telegram = (await client.get("/api/v1/me", headers=await login_as("employee_sales"))).json()["telegram_id"]
    taken = await client.post("/api/v1/me/telegram", headers=session, json=widget(sales_telegram, time_machine))
    assert (taken.status_code, taken.json()["error"]["code"]) == (409, "telegram_taken")

    unlinked = await client.delete("/api/v1/me/telegram", headers=session)
    assert (unlinked.status_code, unlinked.json()["telegram_linked"]) == (200, False)

    only_telegram = await client.delete("/api/v1/me/telegram", headers=await login_as("employee_sales"))
    assert (only_telegram.status_code, only_telegram.json()["error"]["code"]) == (409, "last_login_method")


async def test_disabled_user_cannot_log_in_by_email(client, demo, login_as) -> None:
    await registered_user(client, login_as)
    user_id = (await login(client)).json()["user"]["id"]
    await client.patch(f"/api/v1/admin/users/{user_id}", headers=await login_as("admin"), json={"is_disabled": True})
    response = await login(client)
    assert (response.status_code, response.json()["error"]["code"]) == (403, "user_disabled")


async def test_admin_creates_employee_by_email(client, demo, login_as) -> None:
    admin = await login_as("admin")
    created = await client.post(
        "/api/v1/admin/users", headers=admin, json={"email": "New@Company.kz", "full_name": "Новый Сотрудник", "role": "employee"}
    )
    assert (created.status_code, created.json()["email"], created.json()["telegram_id"]) == (201, "new@company.kz", None)
    neither = await client.post("/api/v1/admin/users", headers=admin, json={"full_name": "Без входа", "role": "employee"})
    assert neither.status_code == 422
    temporary = (await client.post(f"/api/v1/admin/users/{created.json()['id']}/reset-password", headers=admin)).json()
    first = await login(client, email="new@company.kz", password=temporary["temporary_password"], new_password="svoi-parol-2026")
    assert first.status_code == 200


async def test_email_does_not_leak_into_briefs(client, demo, login_as) -> None:
    """Почту видят администратор и сам пользователь, но не краткие карточки и чужие списки."""
    await registered_user(client, login_as)
    users = await client.get("/api/v1/users", headers=await login_as("employee_sales"))
    assert EMAIL not in users.text


async def test_seed_roles_get_email_and_password_from_accounts_file(client, app, tmp_path, clock) -> None:
    """Демо-аккаунты: почта и пароль ролей — из файла вне репозитория, рядом с Telegram ID."""
    import json

    from app.seed import data, load_accounts, reset_demo
    from tests.support import TZ

    path = tmp_path / "accounts.json"
    path.write_text(json.dumps({"owner": {"email": "Owner@Company.kz", "password": "demo-parol-1"}, "admin": 123456789}), encoding="utf-8")
    accounts = load_accounts(path, {u.key for u in data.USERS})
    async with app.state.sessionmaker() as session, session.begin():
        report = await reset_demo(session, clock.now(), TZ, accounts)
    assert "owner" in report.linked
    response = await login(client, email="owner@company.kz", password="demo-parol-1")
    assert (response.status_code, response.json()["user"]["role"]) == (200, "owner")
