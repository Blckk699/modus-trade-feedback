"""Проверка подписи данных Telegram: initData из Mini App и колбэк Telegram Login Widget.

Алгоритмы — из документации Telegram:
- Mini App: secret = HMAC_SHA256(key="WebAppData", msg=bot_token); hash = HMAC_SHA256(secret, data_check_string).
- Login Widget: secret = SHA256(bot_token); hash = HMAC_SHA256(secret, data_check_string).
data_check_string — все поля, кроме `hash`, отсортированные по ключу, в виде `key=value` через `\\n`.
"""

from __future__ import annotations

import hashlib
import hmac
import json
from collections.abc import Mapping
from datetime import datetime, timedelta
from typing import Any
from urllib.parse import parse_qsl

from app.errors import InvalidTelegramAuth


def _data_check_string(fields: Mapping[str, str]) -> str:
    return "\n".join(f"{key}={fields[key]}" for key in sorted(fields))


def _check_hash(fields: Mapping[str, str], received: str, secret: bytes) -> None:
    expected = hmac.new(secret, _data_check_string(fields).encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, received.lower()):
        raise InvalidTelegramAuth()


def _check_age(auth_date: Any, now: datetime, max_age: timedelta) -> None:
    try:
        signed_at = datetime.fromtimestamp(int(auth_date), tz=now.tzinfo)
    except (TypeError, ValueError, OverflowError):
        raise InvalidTelegramAuth() from None
    if now - signed_at > max_age or signed_at - now > timedelta(minutes=5):
        raise InvalidTelegramAuth("Данные входа через Telegram устарели. Откройте приложение заново.")


def _require_token(bot_token: str) -> None:
    if not bot_token:
        raise InvalidTelegramAuth("Вход через Telegram не настроен на сервере.")


def verify_mini_app(init_data: str, bot_token: str, now: datetime, max_age: timedelta) -> int:
    """Проверяет `Telegram.WebApp.initData` и возвращает Telegram ID пользователя."""
    return int(verify_mini_app_user(init_data, bot_token, now, max_age)["id"])


def verify_mini_app_user(init_data: str, bot_token: str, now: datetime, max_age: timedelta) -> dict[str, Any]:
    """Проверяет `initData` и возвращает профиль из поля `user` (id, first_name, last_name, username)."""
    _require_token(bot_token)
    fields = dict(parse_qsl(init_data, keep_blank_values=True, strict_parsing=False))
    received = fields.pop("hash", None)
    if not received:
        raise InvalidTelegramAuth()
    secret = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    _check_hash(fields, received, secret)
    _check_age(fields.get("auth_date"), now, max_age)
    try:
        user = json.loads(fields["user"])
        int(user["id"])
    except (KeyError, ValueError, TypeError):
        raise InvalidTelegramAuth() from None
    return user


def verify_login_widget(data: Mapping[str, Any], bot_token: str, now: datetime, max_age: timedelta) -> int:
    """Проверяет поля колбэка Telegram Login Widget и возвращает Telegram ID пользователя."""
    _require_token(bot_token)
    fields = {key: str(value) for key, value in data.items() if value is not None and key != "hash"}
    received = data.get("hash")
    if not received:
        raise InvalidTelegramAuth()
    secret = hashlib.sha256(bot_token.encode()).digest()
    _check_hash(fields, str(received), secret)
    _check_age(fields.get("auth_date"), now, max_age)
    return int(fields["id"])


# --- для тестов и dev-инструментов: подписать данные так же, как Telegram ---------------------------


def sign_mini_app(fields: Mapping[str, str], bot_token: str) -> str:
    """Собирает initData с правильной подписью (только для тестов)."""
    from urllib.parse import urlencode

    secret = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    digest = hmac.new(secret, _data_check_string(fields).encode(), hashlib.sha256).hexdigest()
    return urlencode({**fields, "hash": digest})


def sign_login_widget(fields: Mapping[str, Any], bot_token: str) -> dict[str, Any]:
    """Возвращает поля виджета с правильным `hash` (только для тестов)."""
    secret = hashlib.sha256(bot_token.encode()).digest()
    as_str = {key: str(value) for key, value in fields.items() if value is not None}
    digest = hmac.new(secret, _data_check_string(as_str).encode(), hashlib.sha256).hexdigest()
    return {**fields, "hash": digest}
