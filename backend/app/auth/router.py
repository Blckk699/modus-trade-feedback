"""Маршруты входа: Mini App, Telegram Login, код из бота, dev-вход, выход, «кто я»."""

from __future__ import annotations

from datetime import timedelta
from typing import Annotated, Literal

from fastapi import APIRouter, Body, Request, Response
from pydantic import BaseModel, Field
from sqlalchemy import select

from app.api.deps import (
    ClockDep,
    CredentialsDep,
    CurrentUserDep,
    ServiceCredentialsDep,
    SessionDep,
    SettingsDep,
)
from app.api.schemas import UserBrief
from app.auth import service
from app.auth.me import MeOut, build_me, user_brief
from app.auth.telegram import verify_login_widget, verify_mini_app
from app.clock import LocalDatetime
from app.errors import DevLoginDisabled, Forbidden, InvalidLoginCode, NotFound
from app.models import User

router = APIRouter(tags=["auth"])


class SessionOut(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_at: LocalDatetime
    user: MeOut


class MiniAppLoginIn(BaseModel):
    init_data: str = Field(min_length=1)


class WidgetLoginIn(BaseModel):
    id: int
    first_name: str
    last_name: str | None = None
    username: str | None = None
    photo_url: str | None = None
    auth_date: int
    hash: str


class CodeLoginIn(BaseModel):
    code: str = Field(pattern=r"^[0-9]{6}$")


class LoginCodeOut(BaseModel):
    code: str
    expires_at: LocalDatetime
    ttl_seconds: int


class DevLoginIn(BaseModel):
    user_id: int


async def _session_for(
    session: SessionDep, user: User, method: str, clock: ClockDep, settings: SettingsDep
) -> SessionOut:
    token, expires_at = await service.open_session(session, user, method, clock.now(), settings)
    return SessionOut(access_token=token, expires_at=expires_at, user=await build_me(session, user))


@router.post("/auth/telegram/mini-app", response_model=SessionOut, summary="Вход из Mini App по initData")
async def login_mini_app(body: MiniAppLoginIn, session: SessionDep, clock: ClockDep, settings: SettingsDep) -> SessionOut:
    max_age = timedelta(seconds=settings.telegram_auth_max_age_seconds)
    telegram_id = verify_mini_app(body.init_data, settings.telegram_bot_token, clock.now(), max_age)
    user = service.ensure_can_login(await service.user_by_telegram_id(session, telegram_id))
    return await _session_for(session, user, "mini_app", clock, settings)


@router.post("/auth/telegram/widget", response_model=SessionOut, summary="Вход через Telegram Login в вебе")
async def login_widget(body: WidgetLoginIn, session: SessionDep, clock: ClockDep, settings: SettingsDep) -> SessionOut:
    max_age = timedelta(seconds=settings.telegram_widget_max_age_seconds)
    telegram_id = verify_login_widget(body.model_dump(), settings.telegram_bot_token, clock.now(), max_age)
    user = service.ensure_can_login(await service.user_by_telegram_id(session, telegram_id))
    return await _session_for(session, user, "widget", clock, settings)


@router.post("/auth/code", response_model=SessionOut, summary="Вход по одноразовому коду из бота")
async def login_code(
    body: CodeLoginIn, request: Request, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> SessionOut:
    # Адрес клиента: X-Forwarded-For учитывается только от доверенного прокси (см. create_app).
    ip = request.client.host if request.client else "unknown"
    now = clock.now()
    await service.check_code_attempts(session, ip, now, settings)
    try:
        user = await service.redeem_login_code(session, body.code, now)
    except InvalidLoginCode:
        # Транзакция запроса откатится вместе с ошибкой — неудачу пишем отдельной.
        async with request.app.state.sessionmaker() as failures, failures.begin():
            await service.record_code_failure(failures, ip, now, settings)
        raise
    return await _session_for(session, user, "code", clock, settings)


@router.post("/auth/login-codes", response_model=LoginCodeOut, status_code=201, summary="Выдать код входа (бот)")
async def issue_code(
    _: ServiceCredentialsDep, user: CurrentUserDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> LoginCodeOut:
    code, expires_at = await service.issue_login_code(session, user, clock.now(), settings)
    return LoginCodeOut(code=code, expires_at=expires_at, ttl_seconds=settings.login_code_ttl_seconds)


@router.get("/auth/dev/users", response_model=list[UserBrief], summary="Пользователи для dev-входа")
async def dev_users(session: SessionDep, settings: SettingsDep) -> list[UserBrief]:
    if not settings.dev_login_enabled:
        raise DevLoginDisabled()
    users = (await session.execute(select(User).where(User.is_disabled.is_(False)).order_by(User.id))).scalars()
    return [await user_brief(session, u) for u in users]


@router.post("/auth/dev/login", response_model=SessionOut, summary="Dev-вход под выбранным пользователем")
async def dev_login(
    body: Annotated[DevLoginIn, Body()], session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> SessionOut:
    if not settings.dev_login_enabled:
        raise DevLoginDisabled()
    user = await session.get(User, body.user_id)
    if user is None:
        raise NotFound("Пользователь не найден")
    service.ensure_can_login(user)
    return await _session_for(session, user, "dev", clock, settings)


@router.post("/auth/logout", status_code=204, summary="Выход")
async def logout(credentials: CredentialsDep, _: CurrentUserDep, session: SessionDep, clock: ClockDep) -> Response:
    if credentials.kind != "bearer":
        raise Forbidden("Выход доступен только для сессии клиента")
    await service.revoke_token(session, credentials.token, clock.now())
    return Response(status_code=204)


@router.get("/me", response_model=MeOut, summary="Кто я")
async def me(user: CurrentUserDep, session: SessionDep) -> MeOut:
    return await build_me(session, user)
