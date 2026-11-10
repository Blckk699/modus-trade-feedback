"""Общие зависимости маршрутов: база, настройки, часы, адаптеры, учётные данные запроса.

Использование в маршруте:

    @router.post("/appeals/draft")
    async def draft(body: DraftIn, session: SessionDep, claude: ClaudeDep, clock: ClockDep): ...
"""

from __future__ import annotations

import hmac
from collections.abc import AsyncIterator
from dataclasses import dataclass
from typing import Annotated, Literal

from fastapi import Depends, Header, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters.bitrix import Bitrix24Gateway
from app.adapters.claude import ClaudeClient
from app.adapters.speech import SpeechToText
from app.adapters.telegram import TelegramGateway
from app.auth.service import ensure_can_login, user_by_telegram_id, user_by_token
from app.clock import Clock
from app.config import Settings
from app.container import Services
from app.db import session_scope
from app.errors import Forbidden, Unauthorized
from app.models import User


def get_settings(request: Request) -> Settings:
    return request.app.state.settings


def get_services(request: Request) -> Services:
    return request.app.state.services


async def get_session(request: Request) -> AsyncIterator[AsyncSession]:
    async for session in session_scope(request.app.state.sessionmaker):
        yield session


def get_clock(services: Annotated[Services, Depends(get_services)]) -> Clock:
    return services.clock


def get_claude(services: Annotated[Services, Depends(get_services)]) -> ClaudeClient:
    return services.claude


def get_speech(services: Annotated[Services, Depends(get_services)]) -> SpeechToText:
    return services.speech


def get_telegram(services: Annotated[Services, Depends(get_services)]) -> TelegramGateway:
    return services.telegram


def get_bitrix(services: Annotated[Services, Depends(get_services)]) -> Bitrix24Gateway:
    return services.bitrix


SettingsDep = Annotated[Settings, Depends(get_settings)]
ServicesDep = Annotated[Services, Depends(get_services)]
SessionDep = Annotated[AsyncSession, Depends(get_session)]
ClockDep = Annotated[Clock, Depends(get_clock)]
ClaudeDep = Annotated[ClaudeClient, Depends(get_claude)]
SpeechDep = Annotated[SpeechToText, Depends(get_speech)]
TelegramDep = Annotated[TelegramGateway, Depends(get_telegram)]
BitrixDep = Annotated[Bitrix24Gateway, Depends(get_bitrix)]


@dataclass(frozen=True)
class Credentials:
    """Кто стучится в API, до проверки по базе.

    - `bearer`: пользователь клиента, `Authorization: Bearer <token>`;
    - `service`: бот с верным `X-Service-Key`, действует от имени `telegram_id` из `X-Telegram-Id`.
    """

    kind: Literal["bearer", "service"]
    token: str | None = None
    telegram_id: int | None = None


def get_credentials(
    settings: SettingsDep,
    authorization: Annotated[str | None, Header()] = None,
    x_service_key: Annotated[str | None, Header()] = None,
    x_telegram_id: Annotated[str | None, Header()] = None,
) -> Credentials:
    if x_service_key is not None:
        expected = settings.bot_service_key
        if not expected or not hmac.compare_digest(x_service_key.encode(), expected.encode()):
            raise Unauthorized("Неверный сервисный ключ")
        if not x_telegram_id or not x_telegram_id.strip().lstrip("-").isdigit():
            raise Unauthorized("Для сервисного запроса нужен заголовок X-Telegram-Id")
        return Credentials(kind="service", telegram_id=int(x_telegram_id))
    if authorization:
        scheme, _, token = authorization.partition(" ")
        if scheme.lower() == "bearer" and token.strip():
            return Credentials(kind="bearer", token=token.strip())
    raise Unauthorized()


CredentialsDep = Annotated[Credentials, Depends(get_credentials)]


async def get_current_user(credentials: CredentialsDep, session: SessionDep, clock: ClockDep) -> User:
    """Пользователь запроса: по токену сессии или, для бота, по `X-Telegram-Id`.

    Бот получает ровно права этого пользователя. Незаведённый — 403 `user_not_registered`,
    отключённый — 403 `user_disabled`, нет или истекла сессия — 401.
    """
    if credentials.kind == "service":
        return ensure_can_login(await user_by_telegram_id(session, credentials.telegram_id))
    return await user_by_token(session, credentials.token, clock.now())


def require_service(credentials: CredentialsDep) -> Credentials:
    """Маршрут только для бота (`X-Service-Key` + `X-Telegram-Id`)."""
    if credentials.kind != "service":
        raise Forbidden("Это действие доступно только боту")
    return credentials


def require_bot_key(settings: SettingsDep, x_service_key: Annotated[str | None, Header()] = None) -> None:
    """Служебные маршруты бота `/bot/*`: только `X-Service-Key`, без пользователя."""
    expected = settings.bot_service_key
    if not x_service_key or not expected or not hmac.compare_digest(x_service_key.encode(), expected.encode()):
        raise Unauthorized("Неверный сервисный ключ")


CurrentUserDep = Annotated[User, Depends(get_current_user)]
BotKeyDep = Annotated[None, Depends(require_bot_key)]
ServiceCredentialsDep = Annotated[Credentials, Depends(require_service)]
