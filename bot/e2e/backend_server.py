"""Локальный бэкенд для e2e-прогона бота: настоящая база и API, фейки Claude, ElevenLabs, Telegram, Битрикс24.

Запускается в окружении бэкенда (его зависимости), база — временный Postgres из pgserver:

    uv run --project backend python bot/e2e/backend_server.py --port 8765

Сид — демо-компания; Telegram ID демо-пользователей: 100000001 + номер в app/seed/data.py
(как в тестах бэкенда), сервисный ключ бота — `e2e-service-key`. Печатает `READY <url>`, когда API готов.
"""

from __future__ import annotations

import argparse
import asyncio
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
BACKEND = HERE.parents[1] / "backend"
sys.path.insert(0, str(BACKEND))
sys.path.insert(0, str(HERE))

from constants import FIRST_TELEGRAM_ID, SERVICE_KEY  # noqa: E402


def telegram_ids() -> dict[str, int]:
    from app.seed import data

    return {u.key: FIRST_TELEGRAM_ID + i for i, u in enumerate(data.USERS)}


async def seed(database_url: str) -> None:
    from app.clock import SystemClock
    from app.config import parse_utc_offset, to_async_url
    from app.db import make_engine, make_sessionmaker
    from app.seed.accounts import Account
    from app.seed.loader import reset_demo

    engine = make_engine(to_async_url(database_url))
    accounts = {key: Account(tid) for key, tid in telegram_ids().items()}
    async with make_sessionmaker(engine)() as session, session.begin():
        await reset_demo(session, SystemClock().now(), parse_utc_offset("+05:00"), accounts)
    await engine.dispose()


def build_app(database_url: str):
    from app.adapters.claude import AppealDraft
    from app.adapters.fakes import FakeBitrix, FakeClaude, FakeSpeech, FakeTelegram
    from app.clock import SystemClock
    from app.config import Settings
    from app.container import Services
    from app.main import create_app

    claude = FakeClaude()
    claude.draft = AppealDraft(
        type="problem",
        category="Межотдельное взаимодействие",
        priority="medium",
        summary="В заявках на камеры не указаны объект и разрешение",
        proposed_solution="Сделать поля обязательными в шаблоне заявки",
    )
    speech = FakeSpeech()
    speech.text = "Счёт сначала забиваю в 1С, потом руками то же самое в Битрикс"
    settings = Settings(
        database_url=database_url,
        bot_service_key=SERVICE_KEY,
        dev_login_enabled=False,
        jobs_worker_enabled=True,
        jobs_poll_seconds=1,
        attachments_dir=tempfile.mkdtemp(prefix="modus-e2e-files-"),
    )
    services = Services(clock=SystemClock(), claude=claude, speech=speech, telegram=FakeTelegram(), bitrix=FakeBitrix())
    return create_app(settings, services)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()

    import pgserver
    import uvicorn

    pgdata = tempfile.mkdtemp(prefix="modus-e2e-pg-")
    server = pgserver.get_server(pgdata, cleanup_mode="delete")
    url = server.get_uri()
    env = {**os.environ, "DATABASE_URL": url}
    code = subprocess.call(["alembic", "upgrade", "head"], env=env, cwd=BACKEND, stdout=subprocess.DEVNULL)
    if code:
        return code
    asyncio.run(seed(url))
    os.environ["DATABASE_URL"] = url
    app = build_app(url)
    print(f"READY http://127.0.0.1:{args.port}", flush=True)
    uvicorn.run(app, host="127.0.0.1", port=args.port, log_level="warning")
    return 0


if __name__ == "__main__":
    sys.exit(main())
