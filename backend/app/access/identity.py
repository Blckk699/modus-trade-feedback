"""Кто обращается без сессии: незнакомый Telegram-аккаунт из бота, Mini App или веба.

Способ ровно один:
- бот — `X-Service-Key` + `X-Telegram-Id` (профиль бот передаёт в теле);
- Mini App — `init_data` в теле;
- веб — `telegram_login` в теле (колбэк Telegram Login как есть).
"""

from __future__ import annotations

import hmac
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Annotated, Literal

from fastapi import Depends, Header
from pydantic import BaseModel, Field

from app.api.deps import SettingsDep
from app.auth.telegram import verify_login_widget, verify_mini_app_user
from app.config import Settings
from app.errors import Unauthorized, ValidationFailed


class TelegramLoginIn(BaseModel):
    id: int
    first_name: str
    last_name: str | None = None
    username: str | None = None
    photo_url: str | None = None
    auth_date: int
    hash: str


class TelegramIdentityIn(BaseModel):
    init_data: str | None = Field(default=None, min_length=1)
    telegram_login: TelegramLoginIn | None = None


@dataclass(frozen=True)
class TelegramProfile:
    telegram_id: int
    channel: Literal["bot", "mini_app", "widget"]
    username: str | None = None
    name: str | None = None


def bot_telegram_id(
    settings: SettingsDep,
    x_service_key: Annotated[str | None, Header()] = None,
    x_telegram_id: Annotated[str | None, Header()] = None,
) -> int | None:
    """Telegram ID из заголовков бота, если запрос от бота. Неверный ключ — 401."""
    if x_service_key is None:
        return None
    expected = settings.bot_service_key
    if not expected or not hmac.compare_digest(x_service_key.encode(), expected.encode()):
        raise Unauthorized("Неверный сервисный ключ")
    if not x_telegram_id or not x_telegram_id.strip().lstrip("-").isdigit():
        raise Unauthorized("Для сервисного запроса нужен заголовок X-Telegram-Id")
    return int(x_telegram_id)


BotTelegramIdDep = Annotated[int | None, Depends(bot_telegram_id)]


def _name(first: str | None, last: str | None) -> str | None:
    name = " ".join(part.strip() for part in (first, last) if part and part.strip())
    return name or None


def identify(
    body: TelegramIdentityIn,
    bot_id: int | None,
    settings: Settings,
    now: datetime,
    *,
    bot_username: str | None = None,
) -> TelegramProfile:
    given = [name for name in ("init_data", "telegram_login") if getattr(body, name) is not None]
    if bot_id is not None:
        if given:
            raise ValidationFailed(
                "Бот опознаёт пользователя заголовками, без данных Telegram в теле",
                details={"fields": [{"field": given[0], "message": "Не передавайте вместе с X-Service-Key"}]},
            )
        return TelegramProfile(telegram_id=bot_id, channel="bot", username=bot_username)
    if not given:
        raise Unauthorized("Нужны данные входа через Telegram")
    if len(given) > 1:
        raise ValidationFailed(
            "Передайте что-то одно: init_data или telegram_login",
            details={"fields": [{"field": "telegram_login", "message": "Только одно из init_data и telegram_login"}]},
        )
    if body.init_data is not None:
        max_age = timedelta(seconds=settings.telegram_auth_max_age_seconds)
        user = verify_mini_app_user(body.init_data, settings.telegram_bot_token, now, max_age)
        return TelegramProfile(
            telegram_id=int(user["id"]),
            channel="mini_app",
            username=user.get("username") or None,
            name=_name(user.get("first_name"), user.get("last_name")),
        )
    login = body.telegram_login
    max_age = timedelta(seconds=settings.telegram_widget_max_age_seconds)
    telegram_id = verify_login_widget(login.model_dump(), settings.telegram_bot_token, now, max_age)
    return TelegramProfile(
        telegram_id=telegram_id,
        channel="widget",
        username=login.username or None,
        name=_name(login.first_name, login.last_name),
    )
