"""Файл аккаунтов вне репозитория: какой реальный Telegram ID закреплён за каким демо-пользователем.

Формат — JSON, ключи — `key` из `app/seed/data.py`:

    {
      "owner": 123456789,
      "admin": {"telegram_id": 234567890},
      "head_procurement": {"telegram_id": 345678901, "full_name": "Имя для показа"}
    }

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
    telegram_id: int
    full_name: str | None = None


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
        if isinstance(value, dict):
            telegram_id, full_name = value.get("telegram_id"), value.get("full_name")
        else:
            telegram_id, full_name = value, None
        if not isinstance(telegram_id, int) or isinstance(telegram_id, bool) or telegram_id <= 0:
            raise AccountsFileError(f"{path}: у «{key}» Telegram ID должен быть положительным целым числом")
        if full_name is not None and (not isinstance(full_name, str) or not full_name.strip()):
            raise AccountsFileError(f"{path}: у «{key}» full_name должен быть непустой строкой")
        if telegram_id in seen:
            raise AccountsFileError(f"{path}: один Telegram ID у «{seen[telegram_id]}» и «{key}»")
        seen[telegram_id] = key
        accounts[key] = Account(telegram_id, full_name.strip() if full_name else None)
    return accounts
