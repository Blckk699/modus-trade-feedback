"""T-11 против бэкенда B-20: заявка по почте видна администратору в боте; после привязки Telegram на сайте
бот узнаёт пользователя по почте и шлёт ему уведомления.

Пока на бэкенде нет реализации B-20 (маршруты входа по почте отвечают 404/405), тесты пропускаются.
"""

import hashlib
import hmac
import time

import httpx
import pytest

from app import texts
from e2e.conftest import ADMIN_TELEGRAM_ID
from e2e.constants import BOT_TOKEN
from e2e.test_local_backend import as_user, drain, shown

ADMIN = as_user(ADMIN_TELEGRAM_ID)
PASSWORD = "Modus-e2e-2026"


def signed_login(telegram_id: int, first_name: str) -> dict:
    """Поля колбэка Telegram Login, подписанные так же, как подписывает Telegram (secret = SHA256(токен бота))."""
    fields = {"id": telegram_id, "first_name": first_name, "auth_date": int(time.time())}
    check = "\n".join(f"{k}={fields[k]}" for k in sorted(fields))
    secret = hashlib.sha256(BOT_TOKEN.encode()).digest()
    return {**fields, "hash": hmac.new(secret, check.encode(), hashlib.sha256).hexdigest()}


@pytest.fixture
async def site(api_url):
    """Сайт: запросы без сервисного ключа — вход по почте и сессия, как у веба."""
    async with httpx.AsyncClient(base_url=api_url, timeout=15) as client:
        yield client


async def register(site, email: str, name: str) -> httpx.Response:
    response = await site.post("/api/v1/auth/register", json={"full_name": name, "email": email, "password": PASSWORD})
    if response.status_code in (404, 405):
        pytest.skip("на бэкенде ещё нет B-20 (вход по почте)")
    return response


async def test_email_request_shows_email_to_admin_and_linked_telegram_is_recognised(bot, backend, site):
    email, telegram_id = "olga.smirnova@modus-e2e.kz", 555_200_001
    await drain(bot)

    registered = await register(site, email, "Ольга Смирнова")
    assert registered.status_code in (200, 201), registered.text
    assert registered.json()["status"] == "pending"

    # Админ узнаёт о заявке в боте — с почтой, раз Telegram у заявителя нет.
    to_admin = [m for m in await drain(bot) if m.chat_id == ADMIN_TELEGRAM_ID]
    assert any(email in shown(m) for m in to_admin), [shown(m) for m in to_admin]

    page = (await backend.get("/api/v1/admin/access-requests", params={"status": "pending"}, headers=ADMIN)).json()
    [request] = [r for r in page["items"] if r.get("email") == email]
    approved = await backend.post(f"/api/v1/admin/access-requests/{request['id']}/approve", json={}, headers=ADMIN)
    assert approved.status_code == 200, approved.text

    # До привязки бот этот Telegram не знает: заявка и подсказка о привязке.
    await bot.send_text("/start", user_id=telegram_id, first_name="Ольга")
    assert texts.LINK_HINT in shown(bot.telegram.messages()[-1])

    login = await site.post("/api/v1/auth/login", json={"email": email, "password": PASSWORD})
    assert login.status_code == 200, login.text
    token = login.json()["access_token"]
    linked = await site.post(
        "/api/v1/me/telegram", json=signed_login(telegram_id, "Ольга"), headers={"Authorization": f"Bearer {token}"}
    )
    assert linked.status_code == 200, linked.text
    assert linked.json()["telegram_linked"] is True

    await bot.send_text("/start", user_id=telegram_id, first_name="Ольга")
    assert shown(bot.telegram.messages()[-1]).startswith("Здравствуйте, Ольга!")
