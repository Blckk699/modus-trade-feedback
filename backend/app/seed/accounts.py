"""Файл аккаунтов вне репозитория: какой реальный Telegram ID закреплён за каким демо-пользователем.

Формат — JSON, ключи — `key` из `app/seed/data.py`:

    {
      "owner": 123456789,
      "admin": {"telegram_id": 234567890},
      "head_procurement": {"telegram_id": 345678901, "full_name": "Имя для показа"},
      "employee_procurement": {"email": "a.nurlanova@company.kz", "password": "пароль-для-демо"}
    }

У роли нужен хотя бы один способ входа: `telegram_id` или пара `email` и `password`.

Telegram ID команды — секрет: файл не кладётся в репозиторий, сид их не печатает.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path

ENV_VAR = "SEED_ACCOUNTS_FILE"
DEFAULT_PATH = Path("~/.config/modus-trade/seed-accounts.json")


@dataclass(frozen=True)
class Account:
    telegram_id: int | None
    full_name: str | None = None
    email: str | None = None
    password: str | None = None


class AccountsFileError(ValueError):
    pass


def default_accounts_path() -> Path:
    return Path(os.environ.get(ENV_VAR) or DEFAULT_PATH).expanduser()


def load_accounts(path: Path | None, known_keys: set[str]) -> dict[str, Account]:
    """Читает файл. Нет файла — пустой словарь (сид работает, просто никто не войдёт под этими ролями)."""
    if path is None or not path.exists():
        return {}
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise AccountsFileError(f"{path}: не JSON ({exc.msg}, строка {exc.lineno})") from None
    if not isinstance(raw, dict):
        raise AccountsFileError(f"{path}: ожидается объект {{ключ пользователя: Telegram ID}}")

    unknown = sorted(set(raw) - known_keys)
    if unknown:
        raise AccountsFileError(
            f"{path}: неизвестные ключи {', '.join(unknown)}. Допустимые: {', '.join(sorted(known_keys))}"
        )

    accounts: dict[str, Account] = {}
    seen: dict[int, str] = {}
    for key, value in raw.items():
        email = password = None
        if isinstance(value, dict):
            telegram_id, full_name = value.get("telegram_id"), value.get("full_name")
            email, password = value.get("email"), value.get("password")
        else:
            telegram_id, full_name = value, None
        if telegram_id is not None and (not isinstance(telegram_id, int) or isinstance(telegram_id, bool) or telegram_id <= 0):
            raise AccountsFileError(f"{path}: у «{key}» Telegram ID должен быть положительным целым числом")
        if (email is None) != (password is None):
            raise AccountsFileError(f"{path}: у «{key}» почта и пароль задаются вместе")
        if email is not None and (not isinstance(email, str) or "@" not in email):
            raise AccountsFileError(f"{path}: у «{key}» почта должна быть строкой вида name@company.kz")
        if password is not None and (not isinstance(password, str) or len(password) < 8):
            raise AccountsFileError(f"{path}: у «{key}» пароль — строка не короче 8 символов")
        if telegram_id is None and email is None:
            raise AccountsFileError(f"{path}: у «{key}» нужен telegram_id или почта с паролем")
        if full_name is not None and (not isinstance(full_name, str) or not full_name.strip()):
            raise AccountsFileError(f"{path}: у «{key}» full_name должен быть непустой строкой")
        if telegram_id is not None:
            if telegram_id in seen:
                raise AccountsFileError(f"{path}: один Telegram ID у «{seen[telegram_id]}» и «{key}»")
            seen[telegram_id] = key
        accounts[key] = Account(
            telegram_id,
            full_name.strip() if full_name else None,
            email.strip().lower() if email else None,
            password,
        )
    return accounts
