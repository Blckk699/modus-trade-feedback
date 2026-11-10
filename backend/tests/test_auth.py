"""Вход через Telegram и роли (B-03, истории 23, 64, 65): три способа входа, dev-вход, бот, отказы."""

from __future__ import annotations

import json

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import update

from app.auth.telegram import sign_login_widget, sign_mini_app
from app.models import User
from tests.support import TimeMachine, bot_headers, telegram_id_of

BOT_TOKEN = "123456:TEST-BOT-TOKEN"
EMPLOYEE = "employee_procurement"


@pytest.fixture(autouse=True)
def bot_token(app: FastAPI) -> None:
    app.state.settings.telegram_bot_token = BOT_TOKEN


def init_data(telegram_id: int, auth_date: int, token: str = BOT_TOKEN) -> str:
    user = json.dumps({"id": telegram_id, "first_name": "Айгерим"}, ensure_ascii=False)
    return sign_mini_app({"auth_date": str(auth_date), "query_id": "AAH1", "user": user}, token)


def widget(telegram_id: int, auth_date: int, token: str = BOT_TOKEN) -> dict:
    return sign_login_widget({"id": telegram_id, "first_name": "Айгерим", "username": "aigerim", "auth_date": auth_date}, token)


def now_ts(time_machine: TimeMachine) -> int:
    return int(time_machine.now.timestamp())


async def me(client: httpx.AsyncClient, token: str) -> httpx.Response:
    return await client.get("/api/v1/me", headers={"Authorization": f"Bearer {token}"})


async def disable(app: FastAPI, seed_key: str) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        await session.execute(update(User).where(User.seed_key == seed_key).values(is_disabled=True))


# --- Mini App -------------------------------------------------------------------------------


async def test_mini_app_login_by_signed_init_data(client, demo, time_machine) -> None:
    """История 23: сотрудник входит из Mini App без пароля."""
    response = await client.post(
        "/api/v1/auth/telegram/mini-app",
        json={"init_data": init_data(telegram_id_of(EMPLOYEE), now_ts(time_machine))},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["user"]["full_name"] == "Айгерим Нурланова"

    whoami = (await me(client, body["access_token"])).json()
    assert (whoami["role"], whoami["department"]["name"]) == ("employee", "Закупки")
    assert [c["name"] for c in whoami["deputy_for"]] == ["Межотдельное взаимодействие"]


async def test_mini_app_rejects_forged_or_stale_data(client, demo, time_machine) -> None:
    tid = telegram_id_of(EMPLOYEE)
    forged = init_data(tid, now_ts(time_machine), token="999:OTHER-BOT")
    stale = init_data(tid, now_ts(time_machine) - 2 * 86400)
    for data in (forged, stale, "user=%7B%22id%22%3A1%7D"):
        response = await client.post("/api/v1/auth/telegram/mini-app", json={"init_data": data})
        assert response.status_code == 401
        assert response.json()["error"]["code"] == "invalid_telegram_auth"


# --- Telegram Login -------------------------------------------------------------------------


async def test_widget_login(client, demo, time_machine) -> None:
    response = await client.post("/api/v1/auth/telegram/widget", json=widget(telegram_id_of("owner"), now_ts(time_machine)))
    assert response.status_code == 200
    assert response.json()["user"]["permissions"]["analytics_scope"] == "company"

    tampered = {**widget(telegram_id_of("owner"), now_ts(time_machine)), "id": telegram_id_of("admin")}
    response = await client.post("/api/v1/auth/telegram/widget", json=tampered)
    assert response.json()["error"]["code"] == "invalid_telegram_auth"


# --- отказы ---------------------------------------------------------------------------------


async def test_stranger_and_disabled_user_cannot_log_in(app, client, demo, time_machine) -> None:
    """Войти может только сотрудник, которого завёл администратор, и с включённым доступом."""
    stranger = await client.post("/api/v1/auth/telegram/mini-app", json={"init_data": init_data(777, now_ts(time_machine))})
    assert (stranger.status_code, stranger.json()["error"]["code"]) == (403, "user_not_registered")

    session = await client.post("/api/v1/auth/telegram/widget", json=widget(telegram_id_of(EMPLOYEE), now_ts(time_machine)))
    token = session.json()["access_token"]
    await disable(app, EMPLOYEE)

    again = await client.post("/api/v1/auth/telegram/widget", json=widget(telegram_id_of(EMPLOYEE), now_ts(time_machine)))
    assert (again.status_code, again.json()["error"]["code"]) == (403, "user_disabled")
    assert (await me(client, token)).json()["error"]["code"] == "user_disabled", "старая сессия тоже не пускает"
    bot = await client.get("/api/v1/me", headers=bot_headers(telegram_id_of(EMPLOYEE)))
    assert bot.json()["error"]["code"] == "user_disabled"


# --- код из бота для мобильного приложения ----------------------------------------------------


async def issue_code(client: httpx.AsyncClient, seed_key: str) -> str:
    response = await client.post("/api/v1/auth/login-codes", headers=bot_headers(telegram_id_of(seed_key)))
    assert response.status_code == 201, response.text
    assert response.json()["ttl_seconds"] == 300
    return response.json()["code"]


async def test_code_from_bot_is_exchanged_once(client, demo) -> None:
    code = await issue_code(client, EMPLOYEE)
    first = await client.post("/api/v1/auth/code", json={"code": code})
    assert first.status_code == 200
    assert first.json()["user"]["full_name"] == "Айгерим Нурланова"

    second = await client.post("/api/v1/auth/code", json={"code": code})
    assert (second.status_code, second.json()["error"]["code"]) == (401, "invalid_login_code")


async def test_code_expires_and_new_code_cancels_old(client, demo, time_machine) -> None:
    expired = await issue_code(client, EMPLOYEE)
    await time_machine.advance(seconds=301)
    assert (await client.post("/api/v1/auth/code", json={"code": expired})).status_code == 401

    old = await issue_code(client, EMPLOYEE)
    new = await issue_code(client, EMPLOYEE)
    assert (await client.post("/api/v1/auth/code", json={"code": old})).status_code == 401
    assert (await client.post("/api/v1/auth/code", json={"code": new})).status_code == 200


async def test_only_bot_issues_codes(client, login_as) -> None:
    as_user = await client.post("/api/v1/auth/login-codes", headers=await login_as(EMPLOYEE))
    assert as_user.status_code == 403
    wrong_key = await client.post("/api/v1/auth/login-codes", headers=bot_headers(telegram_id_of(EMPLOYEE), "wrong"))
    assert wrong_key.status_code == 401
    stranger = await client.post("/api/v1/auth/login-codes", headers=bot_headers(777))
    assert stranger.json()["error"]["code"] == "user_not_registered"


# --- бот от имени пользователя ----------------------------------------------------------------


async def test_bot_acts_as_user_with_that_users_rights(client, demo) -> None:
    whoami = await client.get("/api/v1/me", headers=bot_headers(telegram_id_of("head_procurement")))
    assert whoami.status_code == 200
    assert whoami.json()["full_name"] == "Марат Сейткали"
    assert whoami.json()["permissions"]["analytics_scope"] == "department"

    no_user = await client.get("/api/v1/me", headers={"X-Service-Key": "test-service-key"})
    assert no_user.status_code == 401


# --- dev-вход --------------------------------------------------------------------------------


async def test_dev_login_is_off_unless_enabled(app, client, demo) -> None:
    for response in (
        await client.get("/api/v1/auth/dev/users"),
        await client.post("/api/v1/auth/dev/login", json={"user_id": 1}),
    ):
        assert (response.status_code, response.json()["error"]["code"]) == (403, "dev_login_disabled")

    app.state.settings.dev_login_enabled = True
    users = (await client.get("/api/v1/auth/dev/users")).json()
    assert {u["role"] for u in users} == {"employee", "head", "admin", "owner"}
    session = await client.post("/api/v1/auth/dev/login", json={"user_id": users[0]["id"]})
    assert session.status_code == 200
    assert (await me(client, session.json()["access_token"])).status_code == 200


# --- сессия -----------------------------------------------------------------------------------


async def test_logout_and_expiry_end_the_session(client, login_as, time_machine) -> None:
    headers = await login_as("owner")
    assert (await client.get("/api/v1/me", headers=headers)).status_code == 200
    assert (await client.post("/api/v1/auth/logout", headers=headers)).status_code == 204
    assert (await client.get("/api/v1/me", headers=headers)).status_code == 401

    fresh = await login_as("owner")
    await time_machine.advance(days=31)
    response = await client.get("/api/v1/me", headers=fresh)
    assert (response.status_code, response.json()["error"]["code"]) == (401, "unauthorized")


async def test_no_token_is_unauthorized(client, demo) -> None:
    assert (await client.get("/api/v1/me")).status_code == 401
    assert (await client.get("/api/v1/me", headers={"Authorization": "Bearer nonsense"})).status_code == 401


# --- «кто я»: роль, подразделение, назначения ---------------------------------------------------


@pytest.mark.parametrize(
    ("who", "expected"),
    [
        ("owner", {"analytics_scope": "company", "can_view_all_appeals": True, "can_upload_meetings": True, "can_manage_settings": False}),
        ("admin", {"analytics_scope": "none", "can_view_all_appeals": True, "can_upload_meetings": False, "can_manage_settings": True}),
        ("head_sales", {"analytics_scope": "department", "can_view_department": True, "can_process_appeals": True}),
        ("employee_sales", {"analytics_scope": "none", "can_process_appeals": True, "can_view_all_appeals": False}),
        ("employee_pm", {"analytics_scope": "none", "can_process_appeals": False, "can_upload_meetings": False}),
    ],
)
async def test_me_reports_role_and_permissions(client, login_as, who, expected) -> None:
    body = (await client.get("/api/v1/me", headers=await login_as(who))).json()
    for key, value in expected.items():
        assert body["permissions"][key] == value, key


async def test_me_lists_assignments(client, login_as) -> None:
    body = (await client.get("/api/v1/me", headers=await login_as("employee_it"))).json()
    assert [c["name"] for c in body["responsible_for"]] == ["Интеграции и IT", "Коммуникации"]
    assert body["assigned_open_count"] == 2  # A-007 и A-012
    assert body["telegram_id"] == telegram_id_of("employee_it"), "свой Telegram ID пользователь видит"


# --- защита кода из бота от перебора ---------------------------------------------------------------


def client_from(app: FastAPI, ip: str) -> httpx.AsyncClient:
    """Клиент с другим адресом подключения (как если бы запрос пришёл не через Caddy)."""
    return httpx.AsyncClient(transport=httpx.ASGITransport(app=app, client=(ip, 40000)), base_url="http://testserver")


async def guess(client: httpx.AsyncClient, code: str, forwarded_for: str | None = None) -> httpx.Response:
    headers = {"X-Forwarded-For": forwarded_for} if forwarded_for else {}
    return await client.post("/api/v1/auth/code", json={"code": code}, headers=headers)


async def test_too_many_wrong_codes_from_one_ip_get_429(client, demo) -> None:
    """За доверенным прокси (127.0.0.1) адрес клиента берётся из X-Forwarded-For."""
    code = await issue_code(client, EMPLOYEE)
    wrong = "000000" if code != "000000" else "111111"
    for _ in range(5):
        assert (await guess(client, wrong, "203.0.113.5")).status_code == 401
    blocked = await guess(client, code, "203.0.113.5")
    assert (blocked.status_code, blocked.json()["error"]["code"]) == (429, "too_many_requests")
    assert (await guess(client, code, "203.0.113.6")).status_code == 200, "другой адрес не заблокирован"


async def test_forwarded_for_from_untrusted_peer_is_ignored(app, client, demo) -> None:
    code = await issue_code(client, EMPLOYEE)
    wrong = "000000" if code != "000000" else "111111"
    async with client_from(app, "198.51.100.7") as outsider:
        for i in range(5):
            assert (await guess(outsider, wrong, f"10.0.0.{i}")).status_code == 401
        assert (await guess(outsider, code, "10.0.0.99")).status_code == 429, "подмена X-Forwarded-For не помогает"


async def test_distributed_guessing_burns_active_codes(app, client, demo) -> None:
    app.state.settings.login_code_burn_after_failures = 3
    code = await issue_code(client, EMPLOYEE)
    wrong = "000000" if code != "000000" else "111111"
    for i in range(3):
        await guess(client, wrong, f"203.0.113.{i}")
    burned = await guess(client, code, "203.0.113.50")
    assert (burned.status_code, burned.json()["error"]["code"]) == (401, "invalid_login_code")
    fresh = await issue_code(client, EMPLOYEE)
    assert (await guess(client, fresh, "203.0.113.51")).status_code == 200, "новый код из бота работает"


# --- подпись и срок виджета -------------------------------------------------------------------------


async def test_widget_rejects_wrong_hash_and_old_data(client, demo, time_machine) -> None:
    tid = telegram_id_of("owner")
    wrong_hash = {**widget(tid, now_ts(time_machine)), "hash": "0" * 64}
    stale = widget(tid, now_ts(time_machine) - 11 * 60)
    fresh_enough = widget(tid, now_ts(time_machine) - 9 * 60)
    for body in (wrong_hash, stale, widget(tid, now_ts(time_machine), token="999:OTHER")):
        response = await client.post("/api/v1/auth/telegram/widget", json=body)
        assert (response.status_code, response.json()["error"]["code"]) == (401, "invalid_telegram_auth")
    assert (await client.post("/api/v1/auth/telegram/widget", json=fresh_enough)).status_code == 200
