"""Общие соглашения API: префикс /api/v1, health, единый формат ошибок, учётные данные запроса."""

from __future__ import annotations

import httpx
from fastapi import APIRouter, FastAPI

from app.api.deps import CredentialsDep
from app.errors import InvalidTransition, NotFound


async def test_health(client: httpx.AsyncClient) -> None:
    response = await client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_unknown_route_answers_in_error_format(client: httpx.AsyncClient) -> None:
    response = await client.get("/api/v1/no-such-thing")

    assert response.status_code == 404
    assert response.json() == {"error": {"code": "not_found", "message": "Не найдено", "details": None}}


def _mount_examples(app: FastAPI) -> None:
    router = APIRouter(prefix="/api/v1/_examples")

    @router.get("/appeal/{number}")
    async def get_appeal(number: int) -> dict:
        raise NotFound(f"Обращение {number} не найдено")

    @router.post("/transition")
    async def transition() -> dict:
        raise InvalidTransition(details={"from": "new", "to": "implemented"})

    @router.get("/boom")
    async def boom() -> dict:
        raise RuntimeError("секретная внутренность")

    @router.get("/whoami")
    async def whoami(credentials: CredentialsDep) -> dict:
        return {"kind": credentials.kind, "telegram_id": credentials.telegram_id}

    app.include_router(router)


async def test_domain_errors_have_code_message_and_details(app: FastAPI, client: httpx.AsyncClient) -> None:
    _mount_examples(app)

    missing = await client.get("/api/v1/_examples/appeal/7")
    assert missing.status_code == 404
    assert missing.json()["error"] == {"code": "not_found", "message": "Обращение 7 не найдено", "details": None}

    forbidden_move = await client.post("/api/v1/_examples/transition")
    assert forbidden_move.status_code == 409
    assert forbidden_move.json()["error"]["code"] == "invalid_transition"
    assert forbidden_move.json()["error"]["details"] == {"from": "new", "to": "implemented"}


async def test_validation_errors_use_validation_error_code(app: FastAPI, client: httpx.AsyncClient) -> None:
    _mount_examples(app)

    response = await client.get("/api/v1/_examples/appeal/not-a-number")

    assert response.status_code == 422
    error = response.json()["error"]
    assert error["code"] == "validation_error"
    assert error["details"]["errors"][0]["loc"] == ["path", "number"]


async def test_unexpected_errors_do_not_leak_internals(app: FastAPI) -> None:
    _mount_examples(app)
    transport = httpx.ASGITransport(app=app, raise_app_exceptions=False)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as raw_client:
        response = await raw_client.get("/api/v1/_examples/boom")

    assert response.status_code == 500
    assert response.json() == {"error": {"code": "internal_error", "message": "Внутренняя ошибка сервера", "details": None}}


async def test_requests_carry_user_token_or_bot_service_key(app: FastAPI, client: httpx.AsyncClient) -> None:
    _mount_examples(app)
    url = "/api/v1/_examples/whoami"

    anonymous = await client.get(url)
    assert anonymous.status_code == 401
    assert anonymous.json()["error"]["code"] == "unauthorized"

    user = await client.get(url, headers={"Authorization": "Bearer some-session-token"})
    assert user.json() == {"kind": "bearer", "telegram_id": None}

    bot = await client.get(url, headers={"X-Service-Key": "test-service-key", "X-Telegram-Id": "500100"})
    assert bot.json() == {"kind": "service", "telegram_id": 500100}

    wrong_key = await client.get(url, headers={"X-Service-Key": "guess", "X-Telegram-Id": "500100"})
    assert wrong_key.status_code == 401

    bot_without_user = await client.get(url, headers={"X-Service-Key": "test-service-key"})
    assert bot_without_user.status_code == 401
