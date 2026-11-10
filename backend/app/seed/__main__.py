"""Команды сида.

    uv run python -m app.seed reset              # стереть данные приложения и загрузить демо заново
    uv run python -m app.seed init               # загрузить демо, только если база пустая (первый запуск)
    uv run python -m app.seed reset --accounts ~/modus-accounts.json

Файл аккаунтов (реальные Telegram ID за ролями) берётся из --accounts, переменной SEED_ACCOUNTS_FILE
или ~/.config/modus-trade/seed-accounts.json. Его нет — сид всё равно загружается и сообщает,
под какими ролями никто не сможет войти. Формат файла — в app/seed/accounts.py.
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

from app.clock import SystemClock
from app.config import get_settings
from app.db import make_engine, make_sessionmaker
from app.seed import data
from app.seed.accounts import AccountsFileError, default_accounts_path, load_accounts
from app.seed.loader import is_empty, reset_demo


async def run(command: str, accounts_path: Path) -> int:
    settings = get_settings()
    try:
        accounts = load_accounts(accounts_path, {u.key for u in data.USERS})
    except AccountsFileError as exc:
        print(f"Ошибка в файле аккаунтов: {exc}", file=sys.stderr)
        return 2

    engine = make_engine(settings.async_database_url)
    try:
        async with make_sessionmaker(engine)() as session, session.begin():
            if command == "init" and not await is_empty(session):
                print("В базе уже есть данные — пропускаю. Для сброса: python -m app.seed reset")
                return 0
            report = await reset_demo(session, SystemClock().now(), settings.tz, accounts, showcase=True)
    finally:
        await engine.dispose()

    print(f"Файл аккаунтов: {accounts_path}" + ("" if accounts_path.exists() else " (нет)"))
    for line in report.lines():
        print(line)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m app.seed", description="Демо-данные Модус Трейд")
    parser.add_argument("command", choices=["reset", "init"])
    parser.add_argument("--accounts", type=Path, help="JSON с Telegram ID демо-пользователей (вне репозитория)")
    args = parser.parse_args(argv)
    path = (args.accounts or default_accounts_path()).expanduser()
    return asyncio.run(run(args.command, path))


if __name__ == "__main__":
    sys.exit(main())
