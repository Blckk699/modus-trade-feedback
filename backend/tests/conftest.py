"""Тестовая обвязка.

Шов один — HTTP API. Тест получает:
- `client` — httpx.AsyncClient к приложению (без сети, через ASGI);
- `clock` — замороженные часы, `time_machine.advance(...)` двигает их и выполняет созревшие задачи;
- `fake_claude`, `fake_speech`, `fake_telegram`, `fake_bitrix`, `fake_bitrix_oauth` — фейки адаптеров, уже подставленные в приложение;
- чистую базу: перед каждым тестом все таблицы очищаются;
- `demo` — загрузить демо-компанию из сида (у всех демо-пользователей тестовые Telegram ID);
- `login_as("owner")` — заголовки входа под демо-пользователем одной строкой: ключ из
  `app/seed/data.py` или роль (`"head"` — первый руководитель).

База: если задан TEST_DATABASE_URL (например, Postgres из docker compose) — она, иначе
временный Postgres из пакета `pgserver` на всю сессию тестов. Схема создаётся миграциями Alembic.
"""

from __future__ import annotations

import os
import tempfile
from collections.abc import AsyncIterator, Iterator
from datetime import datetime
from pathlib import Path

import httpx
import pytest
from alembic import command
from alembic.config import Config
from fastapi import FastAPI
from sqlalchemy import select, text

from app.adapters.fakes import FakeBitrix, FakeBitrixOAuth, FakeClaude, FakeSpeech, FakeTelegram
from app.auth.service import open_session
from app.clock import FrozenClock
from app.config import Settings
from app.container import Services
from app.jobs.runner import JobRunner
from app.main import create_app
from app.models import Base, User
from app.seed import Account, SeedReport, data, reset_demo
from tests.support import TZ, TimeMachine, telegram_id_of

BACKEND = Path(__file__).resolve().parent.parent

# Понедельник, 9 ноября 2026, 10:00 по UTC+5 — рабочий день, удобная точка отсчёта.
DEFAULT_NOW = datetime(2026, 11, 9, 10, 0, tzinfo=TZ)


@pytest.fixture(scope="session")
def database_url() -> Iterator[str]:
    url = os.environ.get("TEST_DATABASE_URL")
    if url:
        yield url
        return
    import pgserver

    with tempfile.TemporaryDirectory(prefix="modus-pg-") as tmp:
        server = pgserver.get_server(tmp, cleanup_mode="stop")
        try:
            yield server.get_uri()
        finally:
            server.cleanup()


@pytest.fixture(scope="session")
def migrated_database_url(database_url: str) -> str:
    cfg = Config(str(BACKEND / "alembic.ini"))
    cfg.attributes["database_url"] = database_url
    cfg.attributes["configure_logger"] = False
    command.downgrade(cfg, "base")
    command.upgrade(cfg, "head")
    return database_url


@pytest.fixture
def settings(migrated_database_url: str) -> Settings:
    return Settings(
        _env_file=None,
        database_url=migrated_database_url,
        jobs_worker_enabled=False,
        dev_login_enabled=False,
        bot_service_key="test-service-key",
        anthropic_api_key="",
        elevenlabs_api_key="",
        telegram_bot_token="",
        bitrix24_webhook_url="",
        bitrix24_client_id="",
        bitrix24_client_secret="",
        bitrix24_portal="",
    )


@pytest.fixture
def clock() -> FrozenClock:
    return FrozenClock(DEFAULT_NOW)


@pytest.fixture
def fake_claude() -> FakeClaude:
    return FakeClaude()


@pytest.fixture
def fake_speech() -> FakeSpeech:
    return FakeSpeech()


@pytest.fixture
def fake_telegram() -> FakeTelegram:
    return FakeTelegram()


@pytest.fixture
def fake_bitrix() -> FakeBitrix:
    return FakeBitrix()


@pytest.fixture
def fake_bitrix_oauth() -> FakeBitrixOAuth:
    return FakeBitrixOAuth()


@pytest.fixture
async def app(
    settings: Settings,
    clock: FrozenClock,
    fake_claude: FakeClaude,
    fake_speech: FakeSpeech,
    fake_telegram: FakeTelegram,
    fake_bitrix: FakeBitrix,
    fake_bitrix_oauth: FakeBitrixOAuth,
) -> AsyncIterator[FastAPI]:
    services = Services(
        clock=clock,
        claude=fake_claude,
        speech=fake_speech,
        telegram=fake_telegram,
        bitrix=fake_bitrix,
        bitrix_oauth=fake_bitrix_oauth,
    )
    application = create_app(settings, services)
    await _truncate_all(application)
    yield application
    await application.state.engine.dispose()


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as c:
        yield c


@pytest.fixture
def jobs(app: FastAPI) -> JobRunner:
    """Исполнитель фоновых задач приложения. Его реестр — копия общего, в тесте можно добавлять обработчики."""
    return app.state.jobs


@pytest.fixture
def time_machine(clock: FrozenClock, jobs: JobRunner) -> TimeMachine:
    return TimeMachine(clock, jobs)


@pytest.fixture
async def demo(app: FastAPI, clock: FrozenClock) -> SeedReport:
    """Демо-компания из сида. Telegram ID у всех — `tests.support.telegram_id_of(key)`."""
    accounts = {u.key: Account(telegram_id_of(u.key)) for u in data.USERS}
    async with app.state.sessionmaker() as session, session.begin():
        return await reset_demo(session, clock.now(), TZ, accounts)


@pytest.fixture
def login_as(app: FastAPI, demo: SeedReport, clock: FrozenClock):
    """`headers = await login_as("owner")` — сессия демо-пользователя по ключу сида или по роли."""

    async def login(who: str) -> dict[str, str]:
        async with app.state.sessionmaker() as session, session.begin():
            query = select(User).order_by(User.id)
            query = query.where(User.role == who) if who in {"employee", "head", "admin", "owner"} else query.where(
                User.seed_key == who
            )
            user = (await session.execute(query.limit(1))).scalar_one()
            token, _ = await open_session(session, user, "test", clock.now(), app.state.settings)
        return {"Authorization": f"Bearer {token}"}

    return login


async def _truncate_all(application: FastAPI) -> None:
    tables = ", ".join(f'"{t.name}"' for t in Base.metadata.sorted_tables)
    if not tables:
        return
    async with application.state.engine.begin() as conn:
        await conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))
