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
from app.auth.passwords import hash_password, normalize_email, verify_password
from app.auth.telegram import verify_login_widget, verify_mini_app
from app.clock import LocalDatetime
from app.errors import (
    AccessRequestPending,
    AccessRequestRejected,
    DevLoginDisabled,
    EmailTaken,
    Forbidden,
    InvalidCredentials,
    InvalidLoginCode,
    LastLoginMethod,
    NotFound,
    PasswordChangeRequired,
    TelegramTaken,
    UserDisabled,
    ValidationFailed,
)
from app.models import AccessRequest, AccountSwitch, User

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


Password = Annotated[str, Field(min_length=8, max_length=128)]


class EmailLoginIn(BaseModel):
    email: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=128)
    new_password: Password | None = None


class CredentialsUpdateIn(BaseModel):
    email: str | None = Field(default=None, max_length=254)
    new_password: Password | None = None
    current_password: str | None = Field(default=None, max_length=128)


def _field(field: str, message: str) -> ValidationFailed:
    # Только имя поля и пояснение: значение пароля в ответ и в журналы не попадает.
    return ValidationFailed(message, details={"fields": [{"field": field, "message": message}]})


async def _session_for(
    session: SessionDep, user: User, method: str, clock: ClockDep, settings: SettingsDep, *, ttl: timedelta | None = None
) -> SessionOut:
    token, expires_at = await service.open_session(session, user, method, clock.now(), settings, ttl=ttl)
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


@router.post("/auth/login", response_model=SessionOut, summary="Вход по почте и паролю")
async def login_email(
    body: EmailLoginIn, request: Request, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> SessionOut:
    now = clock.now()
    email = normalize_email(body.email)
    keys = service.password_attempt_keys(email, request.client.host if request.client else "unknown", settings)
    await service.check_password_attempts(session, keys, now)

    user = await service.user_by_email(session, email)
    if user is not None and verify_password(body.password, user.password_hash):
        await service.clear_password_failures(session, email)
        if user.is_disabled:
            raise UserDisabled()
        if user.must_change_password:
            if body.new_password is None:
                raise PasswordChangeRequired()
            user.password_hash = hash_password(body.new_password)
            user.must_change_password = False
            await service.revoke_user_sessions(session, user.id, now)
        return await _session_for(session, user, "password", clock, settings)

    if user is None:
        # Про заявку говорим, только если пароль верный: по одной почте не узнать, подавалась ли она.
        latest = await session.scalar(
            select(AccessRequest)
            .where(AccessRequest.email == email)
            .order_by(AccessRequest.created_at.desc(), AccessRequest.id.desc())
            .limit(1)
        )
        if latest is not None and verify_password(body.password, latest.password_hash):
            if latest.status == "pending":
                raise AccessRequestPending()
            if latest.status == "rejected":
                raise AccessRequestRejected(details={"reason": latest.reject_reason})

    # Транзакция запроса откатится вместе с ошибкой — неудачу пишем отдельной.
    async with request.app.state.sessionmaker() as failures, failures.begin():
        service.record_password_failure(failures, keys, now)
    raise InvalidCredentials()


@router.put("/me/credentials", response_model=MeOut, summary="Задать или сменить почту и пароль")
async def update_credentials(
    body: CredentialsUpdateIn, credentials: CredentialsDep, user: CurrentUserDep, session: SessionDep, clock: ClockDep
) -> MeOut:
    now = clock.now()
    if user.password_hash is not None:
        if not body.current_password or not verify_password(body.current_password, user.password_hash):
            raise _field("current_password", "Неверный текущий пароль")
    else:
        if body.new_password is None:
            raise _field("new_password", "Задайте пароль не короче 8 символов")
        if body.email is None and user.email is None:
            raise _field("email", "Укажите почту")
    if body.email is not None:
        email = normalize_email(body.email)
        owner = await service.user_by_email(session, email)
        if owner is not None and owner.id != user.id:
            raise EmailTaken("Эта почта уже у другого сотрудника.")
        user.email = email
    if body.new_password is not None:
        user.password_hash = hash_password(body.new_password)
        user.must_change_password = False
        keep = credentials.token if credentials.kind == "bearer" else None
        await service.revoke_other_sessions(session, user.id, keep, now)
    await session.flush()
    return await build_me(session, user)


@router.post("/me/telegram", response_model=MeOut, summary="Привязать Telegram")
async def link_telegram(
    body: WidgetLoginIn, user: CurrentUserDep, session: SessionDep, clock: ClockDep, settings: SettingsDep
) -> MeOut:
    max_age = timedelta(seconds=settings.telegram_widget_max_age_seconds)
    telegram_id = verify_login_widget(body.model_dump(), settings.telegram_bot_token, clock.now(), max_age)
    owner = await service.user_by_telegram_id(session, telegram_id)
    if owner is not None and owner.id != user.id:
        raise TelegramTaken()
    user.telegram_id = telegram_id
    await session.flush()
    return await build_me(session, user)


@router.delete("/me/telegram", response_model=MeOut, summary="Отвязать Telegram")
async def unlink_telegram(user: CurrentUserDep, session: SessionDep) -> MeOut:
    if user.email is None or user.password_hash is None:
        raise LastLoginMethod()
    user.telegram_id = None
    await session.flush()
    return await build_me(session, user)


class SwitchIn(BaseModel):
    user_id: int


@router.post("/auth/switch", response_model=SessionOut, summary="Переключиться на связанный аккаунт")
async def switch_account(
    body: SwitchIn,
    credentials: CredentialsDep,
    user: CurrentUserDep,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
) -> SessionOut:
    """Демо-переключатель ролей: новая сессия выбранного пользователя с его же правами, как при обычном входе.
    Группа связанных аккаунтов задаётся только настройкой вне репозитория."""
    if credentials.kind != "bearer":
        raise Forbidden("Переключение доступно только для сессии клиента")
    target = await session.get(User, body.user_id)
    if (
        user.switch_group is None
        or target is None
        or target.id == user.id
        or target.switch_group != user.switch_group
    ):
        raise Forbidden("Переключиться на этого пользователя нельзя.")
    service.ensure_can_login(target)
    session.add(AccountSwitch(from_user_id=user.id, to_user_id=target.id, created_at=clock.now()))
    # В журнале только кто, на кого и когда: без адресов и токенов.
    ttl = timedelta(hours=settings.switch_session_ttl_hours)
    return await _session_for(session, target, "switch", clock, settings, ttl=ttl)
