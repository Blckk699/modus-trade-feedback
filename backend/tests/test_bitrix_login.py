"""Вход через Битрикс24 (B-23): начало входа, возврат с портала, обмен кода на сессию."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from urllib.parse import parse_qs, urlsplit

import httpx
import pytest
from fastapi import FastAPI
from sqlalchemy import func, select

from app.adapters.bitrix_oauth import Bitrix24OAuthClient, BitrixProfile
from app.errors import ExternalServiceError, InvalidBitrixAuth
from app.models import AccessRequest, Notification, User

PORTAL = "b24-test.bitrix24.ru"
CLIENT_ID = "local.test-app"
CLIENT_SECRET = "test-client-secret"
TOKEN_URL = "https://oauth.bitrix24.tech/oauth/token/"
DONE = "http://localhost:5173/auth/bitrix/done"
COOKIE = "bitrix_state"
OWNER, ADMIN, HEAD, EMPLOYEE, SALES = 1, 2, 3, 4, 8
PORTAL_ID = 501  # ID сотрудника в ответе фейка портала
PORTAL_EMAIL = "portal.user@company.kz"


@pytest.fixture(autouse=True)
def bitrix_configured(app: FastAPI) -> None:
    settings = app.state.settings
    settings.bitrix24_client_id = CLIENT_ID
    settings.bitrix24_client_secret = CLIENT_SECRET
    settings.bitrix24_portal = PORTAL


@pytest.fixture
async def other_browser(app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    """Второй браузер: у него нет cookie первого."""
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://testserver") as c:
        yield c


async def start(client: httpx.AsyncClient) -> str:
    """Начинает вход и возвращает `state`, с которым портал вернёт пользователя."""
    response = await client.get("/api/v1/auth/bitrix/start")
    assert response.status_code == 302
    return parse_qs(urlsplit(response.headers["location"]).query)["state"][0]


async def callback(client: httpx.AsyncClient, state: str | None, **params: str) -> httpx.Response:
    query = {"code": "portal-code", "domain": PORTAL, "member_id": "abc123", **params}
    if state is not None:
        query["state"] = state
    return await client.get("/api/v1/auth/bitrix/callback", params=query)


def outcome(response: httpx.Response) -> dict[str, str]:
    """Что получит страница веба: `{"code": …}` или `{"error": …}`."""
    assert response.status_code == 302
    location = response.headers["location"]
    assert location.startswith(DONE + "?")
    assert response.headers["referrer-policy"] == "no-referrer"
    return {key: values[0] for key, values in parse_qs(urlsplit(location).query).items()}


async def portal_login(client: httpx.AsyncClient, **params: str) -> dict[str, str]:
    return outcome(await callback(client, await start(client), **params))


async def exchange(client: httpx.AsyncClient, code: str) -> httpx.Response:
    return await client.post("/api/v1/auth/bitrix/exchange", json={"code": code})


def restore_cookie(client: httpx.AsyncClient, value: str) -> None:
    """Вернуть браузеру cookie входа — как если бы запрос повторили с прежним cookie."""
    client.cookies.set(COOKIE, value, domain="testserver.local", path="/api/v1/auth/bitrix")
    sent = client.build_request("GET", "/api/v1/auth/bitrix/callback").headers.get("cookie", "")
    assert f"{COOKIE}={value}" in sent


async def set_user(app: FastAPI, user_id: int, **fields) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        user = await session.get(User, user_id)
        for key, value in fields.items():
            setattr(user, key, value)


async def get_user(app: FastAPI, user_id: int) -> User:
    async with app.state.sessionmaker() as session:
        return await session.get(User, user_id)


async def access_requests(app: FastAPI) -> list[AccessRequest]:
    async with app.state.sessionmaker() as session:
        return list((await session.execute(select(AccessRequest).order_by(AccessRequest.id))).scalars())


async def created_notifications(app: FastAPI) -> list[Notification]:
    async with app.state.sessionmaker() as session:
        rows = await session.execute(select(Notification).where(Notification.kind == "access_request_created"))
        return list(rows.scalars())


# --- флаг доступности и начало входа ----------------------------------------------------------------


async def test_methods_show_bitrix_when_configured(client) -> None:
    response = await client.get("/api/v1/auth/methods")
    assert (response.status_code, response.json()) == (200, {"bitrix24": True})


@pytest.mark.parametrize("missing", ["bitrix24_client_id", "bitrix24_client_secret", "bitrix24_portal"])
async def test_without_any_of_three_settings_bitrix_is_off(client, app, missing: str) -> None:
    setattr(app.state.settings, missing, "")
    assert (await client.get("/api/v1/auth/methods")).json() == {"bitrix24": False}
    response = await client.get("/api/v1/auth/bitrix/start")
    assert (response.status_code, response.json()["error"]["code"]) == (404, "not_found")
    assert "set-cookie" not in response.headers
    # Возврат без настройки тоже не входит и к порталу не ходит.
    assert outcome(await callback(client, "any")) == {"error": "invalid_bitrix_auth"}


async def test_start_redirects_to_portal_with_one_time_state_in_cookie(client) -> None:
    response = await client.get("/api/v1/auth/bitrix/start")
    assert response.status_code == 302
    location = urlsplit(response.headers["location"])
    assert (location.scheme, location.netloc, location.path) == ("https", PORTAL, "/oauth/authorize/")
    query = parse_qs(location.query)
    assert query["client_id"] == [CLIENT_ID]
    state = query["state"][0]
    assert len(state) >= 32
    assert CLIENT_SECRET not in response.headers["location"]

    cookie = response.headers["set-cookie"]
    assert cookie.startswith(f"{COOKIE}={state};")
    attributes = {part.strip().lower() for part in cookie.split(";")[1:]}
    assert {"httponly", "samesite=lax", "path=/api/v1/auth/bitrix", "max-age=600"} <= attributes
    assert "secure" not in attributes  # веб в тестах на http

    second = await client.get("/api/v1/auth/bitrix/start")
    assert parse_qs(urlsplit(second.headers["location"]).query)["state"][0] != state


async def test_cookie_is_secure_when_web_is_https_and_portal_setting_may_be_an_address(client, app) -> None:
    app.state.settings.public_web_url = "https://feedback.example.kz"
    app.state.settings.bitrix24_portal = f"https://{PORTAL.upper()}/"
    response = await client.get("/api/v1/auth/bitrix/start")
    assert urlsplit(response.headers["location"]).netloc == PORTAL
    assert "secure" in {part.strip().lower() for part in response.headers["set-cookie"].split(";")}


# --- вход сопоставленного сотрудника ----------------------------------------------------------------


async def test_user_known_by_bitrix_id_gets_session(client, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    back = await callback(client, await start(client))
    result = outcome(back)
    assert set(result) == {"code"}
    assert [c.args for c in fake_bitrix_oauth.calls] == [{"code": "portal-code"}]

    session = await exchange(client, result["code"])
    assert session.status_code == 200
    body = session.json()
    assert (body["token_type"], body["user"]["id"], body["user"]["bitrix_user_id"]) == ("bearer", EMPLOYEE, PORTAL_ID)
    # В адресной строке был только одноразовый код: токена сессии там нет.
    assert body["access_token"] not in back.headers["location"]
    assert body["access_token"] != result["code"]

    me = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {body['access_token']}"})
    assert (me.status_code, me.json()["id"]) == (200, EMPLOYEE)
    assert COOKIE not in client.cookies  # cookie входа больше не нужен


@pytest.mark.parametrize("user_id", [EMPLOYEE, HEAD])
async def test_employee_and_head_are_matched_by_email_and_id_is_remembered(
    client, app, demo, fake_bitrix_oauth, user_id: int
) -> None:
    await set_user(app, user_id, email="s.kim@company.kz")
    fake_bitrix_oauth.profile = BitrixProfile(id=77, email=" S.Kim@Company.KZ ", first_name="Сергей")

    result = await portal_login(client)
    session = await exchange(client, result["code"])
    assert (session.status_code, session.json()["user"]["id"]) == (200, user_id)
    assert (await get_user(app, user_id)).bitrix_user_id == 77
    assert await access_requests(app) == []

    # Дальше узнаём по ID портала, даже если почта на портале сменилась.
    fake_bitrix_oauth.profile = BitrixProfile(id=77, email="other@company.kz")
    again = await portal_login(client)
    assert (await exchange(client, again["code"])).json()["user"]["id"] == user_id


@pytest.mark.parametrize("user_id", [ADMIN, OWNER])
async def test_admin_and_owner_are_never_matched_by_email(client, app, demo, fake_bitrix_oauth, user_id: int) -> None:
    await set_user(app, user_id, email="boss@company.kz")
    fake_bitrix_oauth.profile = BitrixProfile(id=77, email="boss@company.kz", first_name="Чужой")

    assert await portal_login(client) == {"error": "invalid_bitrix_auth"}
    assert (await get_user(app, user_id)).bitrix_user_id is None
    assert await access_requests(app) == []
    assert await created_notifications(app) == []

    # С явно заданным ID портала администратор и собственник входят.
    await set_user(app, user_id, bitrix_user_id=77)
    result = await portal_login(client)
    assert (await exchange(client, result["code"])).json()["user"]["id"] == user_id


async def test_email_of_employee_linked_to_another_portal_user_is_not_matched(
    client, app, demo, login_as, fake_bitrix_oauth
) -> None:
    await set_user(app, EMPLOYEE, email="s.kim@company.kz", bitrix_user_id=10)
    fake_bitrix_oauth.profile = BitrixProfile(id=77, email="s.kim@company.kz", first_name="Двойник")

    assert await portal_login(client) == {"error": "access_request_pending"}
    assert (await get_user(app, EMPLOYEE)).bitrix_user_id == 10
    [request] = await access_requests(app)

    # Одобрение создаёт сотрудника без занятой почты; входит он по ID портала.
    admin = await login_as("admin")
    approved = await client.post(f"/api/v1/admin/access-requests/{request.id}/approve", headers=admin, json={})
    assert approved.status_code == 200
    created = await get_user(app, approved.json()["user_id"])
    assert (created.email, created.bitrix_user_id) == (None, 77)


async def test_disabled_user_is_refused(client, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID, is_disabled=True)
    assert await portal_login(client) == {"error": "user_disabled"}

    await set_user(app, SALES, email="sales@company.kz", is_disabled=True)
    fake_bitrix_oauth.profile = BitrixProfile(id=78, email="sales@company.kz")
    assert await portal_login(client) == {"error": "user_disabled"}
    assert await access_requests(app) == []


async def test_user_disabled_between_callback_and_exchange_gets_no_session(client, app, demo) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    result = await portal_login(client)
    await set_user(app, EMPLOYEE, is_disabled=True)
    refused = await exchange(client, result["code"])
    assert (refused.status_code, refused.json()["error"]["code"]) == (403, "user_disabled")


# --- незнакомый сотрудник: заявка на доступ ---------------------------------------------------------


async def test_stranger_gets_one_access_request_and_logs_in_after_approval(client, app, demo, login_as) -> None:
    assert await portal_login(client) == {"error": "access_request_pending"}
    [request] = await access_requests(app)
    assert (request.status, request.bitrix_user_id, request.email) == ("pending", PORTAL_ID, PORTAL_EMAIL)
    assert (request.full_name, request.comment) == ("Пётр Портальный", "Логист")
    assert (request.password_hash, request.telegram_id) == (None, None)

    sent = await created_notifications(app)
    async with app.state.sessionmaker() as session:
        managers = set((await session.execute(select(User.id).where(User.role.in_(["admin", "owner"])))).scalars())
    assert {n.user_id for n in sent} == managers
    assert all("Пётр Портальный" in n.text and n.path == "/settings/access-requests" for n in sent)

    # Повторный вход заявку не дублирует и менеджеров заново не дёргает.
    assert await portal_login(client) == {"error": "access_request_pending"}
    assert len(await access_requests(app)) == 1
    assert len(await created_notifications(app)) == len(managers)

    admin = await login_as("admin")
    page = (await client.get("/api/v1/admin/access-requests?status=pending", headers=admin)).json()
    assert [(i["id"], i["full_name"], i["email"]) for i in page["items"]] == [
        (request.id, "Пётр Портальный", PORTAL_EMAIL)
    ]
    approved = await client.post(
        f"/api/v1/admin/access-requests/{request.id}/approve", headers=admin, json={"role": "employee"}
    )
    assert approved.status_code == 200
    user = await get_user(app, approved.json()["user_id"])
    assert (user.bitrix_user_id, user.email, user.password_hash) == (PORTAL_ID, PORTAL_EMAIL, None)

    result = await portal_login(client)
    session = await exchange(client, result["code"])
    assert (session.status_code, session.json()["user"]["id"]) == (200, user.id)
    assert len(await access_requests(app)) == 1


async def test_stranger_without_email_and_name_still_gets_request(client, app, demo, fake_bitrix_oauth) -> None:
    fake_bitrix_oauth.profile = BitrixProfile(id=900, email="не почта")
    assert await portal_login(client) == {"error": "access_request_pending"}
    [request] = await access_requests(app)
    assert (request.bitrix_user_id, request.email, request.comment) == (900, None, None)
    assert request.full_name == "Сотрудник Битрикс24 №900"


async def test_rejected_stranger_is_told_so(client, app, demo, login_as) -> None:
    await portal_login(client)
    [request] = await access_requests(app)
    rejected = await client.post(
        f"/api/v1/admin/access-requests/{request.id}/reject", headers=await login_as("owner"), json={"reason": "Не наш"}
    )
    assert rejected.status_code == 200

    assert await portal_login(client) == {"error": "access_request_rejected"}
    assert len(await access_requests(app)) == 1


async def test_pending_email_registration_is_not_duplicated(client, app, demo) -> None:
    registered = await client.post(
        "/api/v1/auth/register", json={"full_name": "Пётр", "email": PORTAL_EMAIL, "password": "korova-2026"}
    )
    assert registered.status_code == 201

    assert await portal_login(client) == {"error": "access_request_pending"}
    [request] = await access_requests(app)
    assert request.bitrix_user_id is None  # чужую заявку с паролем к порталу не привязываем


# --- проверки возврата ------------------------------------------------------------------------------


async def test_wrong_or_missing_state_is_refused(client, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    state = await start(client)
    assert outcome(await callback(client, state + "x")) == {"error": "invalid_bitrix_auth"}
    await start(client)
    assert outcome(await callback(client, None)) == {"error": "invalid_bitrix_auth"}
    assert fake_bitrix_oauth.calls == []


async def test_state_works_once(client, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    state = await start(client)
    assert "code" in outcome(await callback(client, state))
    # Тот же `state` с тем же cookie второй раз не проходит.
    restore_cookie(client, state)
    assert outcome(await callback(client, state)) == {"error": "invalid_bitrix_auth"}
    assert len(fake_bitrix_oauth.calls) == 1


async def test_state_expires_in_ten_minutes(client, app, demo, time_machine, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    state = await start(client)
    await time_machine.advance(minutes=9, seconds=59)
    assert "code" in outcome(await callback(client, state))

    state = await start(client)
    await time_machine.advance(minutes=10)
    restore_cookie(client, state)
    assert outcome(await callback(client, state)) == {"error": "invalid_bitrix_auth"}
    assert len(fake_bitrix_oauth.calls) == 1


async def test_state_is_bound_to_the_browser(client, other_browser, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    state = await start(client)
    # Ссылку возврата открыли в другом браузере (без cookie или со своим).
    assert outcome(await callback(other_browser, state)) == {"error": "invalid_bitrix_auth"}
    await start(other_browser)
    assert outcome(await callback(other_browser, state)) == {"error": "invalid_bitrix_auth"}
    assert fake_bitrix_oauth.calls == []
    # Свой браузер при этом входит.
    assert "code" in outcome(await callback(client, state))


@pytest.mark.parametrize("domain", ["evil.bitrix24.ru", f"{PORTAL}.evil.ru", ""])
async def test_foreign_portal_domain_is_refused(client, app, demo, fake_bitrix_oauth, domain: str) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    assert await portal_login(client, domain=domain) == {"error": "invalid_bitrix_auth"}
    assert fake_bitrix_oauth.calls == []


async def test_portal_domain_is_compared_without_case(client, app, demo) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    assert "code" in await portal_login(client, domain=PORTAL.upper())


async def test_missing_or_rejected_portal_code_is_refused(client, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    assert await portal_login(client, code="") == {"error": "invalid_bitrix_auth"}
    assert fake_bitrix_oauth.calls == []
    fake_bitrix_oauth.reject = True
    assert await portal_login(client) == {"error": "invalid_bitrix_auth"}


async def test_portal_failure_is_reported_as_unavailable(client, app, demo, fake_bitrix_oauth) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    fake_bitrix_oauth.fail = True
    assert await portal_login(client) == {"error": "bitrix_unavailable"}
    assert COOKIE not in client.cookies
    async with app.state.sessionmaker() as session:
        assert await session.scalar(select(func.count()).select_from(AccessRequest)) == 0

    fake_bitrix_oauth.fail = False
    assert "code" in await portal_login(client)


# --- обмен кода на сессию ---------------------------------------------------------------------------


async def test_exchange_code_works_once(client, app, demo) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    result = await portal_login(client)
    state_cookie = client.cookies[COOKIE]
    assert (await exchange(client, result["code"])).status_code == 200

    restore_cookie(client, state_cookie)
    again = await exchange(client, result["code"])
    assert (again.status_code, again.json()["error"]["code"]) == (401, "invalid_bitrix_auth")
    assert again.json()["error"]["message"] == "Не удалось подтвердить вход через Битрикс24. Попробуйте ещё раз."


async def test_exchange_code_expires_in_a_minute(client, app, demo, time_machine) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    result = await portal_login(client)
    await time_machine.advance(seconds=60)
    late = await exchange(client, result["code"])
    assert (late.status_code, late.json()["error"]["code"]) == (401, "invalid_bitrix_auth")

    result = await portal_login(client)
    await time_machine.advance(seconds=59)
    assert (await exchange(client, result["code"])).status_code == 200


async def test_exchange_needs_the_cookie_of_the_browser_that_started(client, other_browser, app, demo) -> None:
    """Защита от подстановки чужого входа: код из чужой ссылки в своём браузере не срабатывает."""
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)
    result = await portal_login(client)

    without_cookie = await exchange(other_browser, result["code"])
    assert (without_cookie.status_code, without_cookie.json()["error"]["code"]) == (401, "invalid_bitrix_auth")
    await start(other_browser)  # у чужого браузера свой cookie
    assert (await exchange(other_browser, result["code"])).status_code == 401

    # Неудачные чужие попытки код не сжигают: свой браузер входит.
    assert (await exchange(client, result["code"])).status_code == 200


async def test_unknown_or_malformed_exchange_code(client, app, demo) -> None:
    await start(client)
    unknown = await exchange(client, "no-such-code")
    assert (unknown.status_code, unknown.json()["error"]["code"]) == (401, "invalid_bitrix_auth")
    assert (await client.post("/api/v1/auth/bitrix/exchange", json={"code": ""})).status_code == 422
    assert (await client.post("/api/v1/auth/bitrix/exchange", json={})).status_code == 422


async def test_state_cannot_be_exchanged_for_session(client, app, demo) -> None:
    state = await start(client)
    assert (await exchange(client, state)).status_code == 401


# --- кто видит ID портала ---------------------------------------------------------------------------


async def test_bitrix_id_is_shown_to_admin_and_owner_of_the_account_only(client, app, demo, login_as) -> None:
    await set_user(app, EMPLOYEE, bitrix_user_id=PORTAL_ID)

    def shown(users: list[dict]) -> int | None:
        return next(u for u in users if u["id"] == EMPLOYEE)["bitrix_user_id"]

    admin = (await client.get("/api/v1/users", headers=await login_as("admin"))).json()
    himself = (await client.get("/api/v1/users", headers=await login_as("employee_procurement"))).json()
    colleague = (await client.get("/api/v1/users", headers=await login_as("employee_sales"))).json()
    assert (shown(admin), shown(himself), shown(colleague)) == (PORTAL_ID, PORTAL_ID, None)

    me = (await client.get("/api/v1/me", headers=await login_as("employee_procurement"))).json()
    assert me["bitrix_user_id"] == PORTAL_ID
    patched = await client.patch(f"/api/v1/admin/users/{EMPLOYEE}", headers=await login_as("admin"), json={})
    assert patched.json()["bitrix_user_id"] == PORTAL_ID
    # В кратких карточках (автор, исполнитель) его нет.
    appeals = await client.get("/api/v1/appeals", headers=await login_as("owner"))
    assert appeals.status_code == 200
    assert "bitrix_user_id" not in appeals.text


# --- адаптер портала --------------------------------------------------------------------------------


def oauth_client(handler) -> Bitrix24OAuthClient:
    return Bitrix24OAuthClient(
        client_id=CLIENT_ID,
        client_secret=CLIENT_SECRET,
        portal=PORTAL,
        token_url=TOKEN_URL,
        transport=httpx.MockTransport(handler),
    )


def portal(token: dict | None = None, user: dict | None = None, *, token_status: int = 200, user_status: int = 200):
    """Подмена портала: сервер токенов и `user.current`. Запросы складываются в `seen`."""
    seen: list[httpx.Request] = []
    token_body = {"access_token": "portal-access-token", "client_endpoint": f"https://{PORTAL}/rest/"} | (token or {})
    user_body = user or {
        "result": {"ID": "501", "EMAIL": "P.User@Company.kz", "NAME": "Пётр", "LAST_NAME": "Портальный", "WORK_POSITION": ""}
    }

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if request.url.host == "oauth.bitrix24.tech":
            return httpx.Response(token_status, json=token_body)
        return httpx.Response(user_status, json=user_body)

    return handler, seen


async def test_adapter_exchanges_code_and_reads_current_user() -> None:
    handler, seen = portal()
    profile = await oauth_client(handler).current_user("portal-code")
    assert profile == BitrixProfile(id=501, email="P.User@Company.kz", first_name="Пётр", last_name="Портальный")
    assert profile.full_name == "Пётр Портальный"

    token_request, user_request = seen
    assert token_request.method == "GET"
    assert str(token_request.url).startswith(TOKEN_URL)
    assert dict(token_request.url.params) == {
        "grant_type": "authorization_code",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code": "portal-code",
    }
    assert str(user_request.url) == f"https://{PORTAL}/rest/user.current?auth=portal-access-token"


@pytest.mark.parametrize(
    "endpoint", ["https://evil.bitrix24.ru/rest/", f"http://{PORTAL}/rest/", f"https://{PORTAL}.evil.ru/rest/", None]
)
async def test_adapter_never_sends_token_to_another_portal(endpoint: str | None) -> None:
    handler, seen = portal(token={"client_endpoint": endpoint})
    with pytest.raises(InvalidBitrixAuth):
        await oauth_client(handler).current_user("portal-code")
    assert len(seen) == 1  # до `user.current` дело не дошло


async def test_adapter_tells_rejected_code_from_unavailable_portal(caplog) -> None:
    caplog.set_level(logging.DEBUG)
    rejected, _ = portal(token={"error": "invalid_grant", "error_description": "code expired"}, token_status=400)
    with pytest.raises(InvalidBitrixAuth):
        await oauth_client(rejected).current_user("portal-code")

    expired_token, _ = portal(user={"error": "expired_token"}, user_status=401)
    with pytest.raises(InvalidBitrixAuth):
        await oauth_client(expired_token).current_user("portal-code")

    no_id, _ = portal(user={"result": {"EMAIL": "x@company.kz"}})
    with pytest.raises(InvalidBitrixAuth):
        await oauth_client(no_id).current_user("portal-code")

    for broken in (portal(token_status=502)[0], portal(user_status=500)[0]):
        with pytest.raises(ExternalServiceError) as failed:
            await oauth_client(broken).current_user("portal-code")
        assert failed.value.code == "bitrix_unavailable"

    def offline(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError(f"cannot reach {request.url}")

    with pytest.raises(ExternalServiceError) as failed:
        await oauth_client(offline).current_user("portal-code")
    assert failed.value.code == "bitrix_unavailable"

    # Ни секрет приложения, ни код, ни токен портала в журнал не попадают.
    assert caplog.text
    for secret in (CLIENT_SECRET, "portal-code", "portal-access-token"):
        assert secret not in caplog.text


async def test_refusal_reason_is_logged_without_personal_data(client, demo, other_browser, caplog) -> None:
    """Один код `invalid_bitrix_auth` скрывает разные причины; в журнале видно, какая именно."""
    state = await start(client)
    with caplog.at_level("INFO", logger="app.auth.bitrix"):
        assert outcome(await callback(other_browser, state)) == {"error": "invalid_bitrix_auth"}
        assert outcome(await callback(client, state + "x")) == {"error": "invalid_bitrix_auth"}
    assert "invalid_bitrix_auth (state_cookie_missing)" in caplog.text
    assert "invalid_bitrix_auth (state_mismatch)" in caplog.text
    assert state not in caplog.text and PORTAL_EMAIL not in caplog.text
