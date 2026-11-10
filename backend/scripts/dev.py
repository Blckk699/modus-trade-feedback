"""Локальный запуск без docker и без системного Postgres.

Поднимает Postgres из пакета `pgserver` (данные в `backend/.pgdata`), применяет миграции
и запускает API с автоперезагрузкой. Postgres останавливается вместе со скриптом.

    uv run python scripts/dev.py                    # API на http://127.0.0.1:8000/api/v1/health
    uv run python scripts/dev.py alembic revision --autogenerate -m "appeals"
                                                    # любая команда с DATABASE_URL этой базы

Если в окружении уже задан DATABASE_URL, пользуйтесь им напрямую:
    uv run alembic upgrade head && uv run uvicorn --factory app.main:create_app --reload
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent


def main(argv: list[str]) -> int:
    import pgserver

    server = pgserver.get_server(BACKEND / ".pgdata", cleanup_mode="stop")
    env = {**os.environ, "DATABASE_URL": server.get_uri()}
    print(f"Postgres: {server.get_uri()}", flush=True)

    if argv:
        return subprocess.call(argv, env=env, cwd=BACKEND)

    code = subprocess.call(["alembic", "upgrade", "head"], env=env, cwd=BACKEND)
    if code:
        return code
    try:
        return subprocess.call(
            ["uvicorn", "--factory", "app.main:create_app", "--reload", "--host", "127.0.0.1", "--port", "8000"],
            env=env,
            cwd=BACKEND,
        )
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
