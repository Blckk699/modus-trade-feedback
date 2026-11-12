"""Вход через Битрикс24 (B-23): OAuth локального приложения портала.

Ход: `GET /auth/bitrix/start` → страница входа портала → `GET /auth/bitrix/callback` → страница веба
`/auth/bitrix/done?code=…` → `POST /auth/bitrix/exchange` → обычная сессия.

- `state` одноразовый, живёт 10 минут и лежит в cookie браузера; в базе только его хеш.
- Токен сессии в адресной строке не появляется: веб получает одноразовый код на 60 секунд и меняет
  его на сессию. Код привязан к тому же cookie, поэтому чужой код в своём браузере не сработает.
- Токены портала не хранятся: они нужны только чтобы узнать, кто вошёл.
- Администратора и собственника по почте не сопоставляем (решение владельца проекта): им
  `bitrix_user_id` задаётся только явно, иначе владелец почтового ящика на портале получил бы их права.
"""

from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta
from urllib.parse import urlencode

from fastapi import APIRouter, Request, Response
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, Field
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.access.router import _notify_managers
from app.adapters.bitrix_oauth import BitrixProfile
from app.api.deps import ClockDep, ServicesDep, SessionDep, SettingsDep
from app.auth import service
from app.auth.models import LoginTicket
from app.auth.passwords import EMAIL_RE
from app.auth.router import SessionOut, _session_for
from app.config import Settings
from app.domain.enums import Role
from app.errors import ExternalServiceError, InvalidBitrixAuth, NotFound, UserDisabled
from app.models import AccessRequest, User

router = APIRouter(tags=["auth"])

STATE_COOKIE = "bitrix_state"
COOKIE_PATH = "/api/v1/auth/bitrix"
STATE_TTL = timedelta(minutes=10)
EXCHANGE_TTL = timedelta(seconds=60)
# По почте сопоставляем только эти роли.
EMAIL_MATCH_ROLES = (Role.EMPLOYEE, Role.HEAD)


class AuthMethodsOut(BaseModel):
    bitrix24: bool


class BitrixExchangeIn(BaseModel):
    code: str = Field(min_length=1, max_length=200)


class _Refused(Exception):
    """Вход не состоялся: код ошибки уходит странице веба в `?error=`."""

    def __init__(self, code: str) -> None:
        self.code = code
        super().__init__(code)


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def _portal_email(value: str | None) -> str | None:
    """Почта с портала в том виде, в каком хранится у нас; непохожее на почту значение не учитываем."""
    email = (value or "").strip().lower()
    return email if len(email) <= 254 and EMAIL_RE.match(email) else None


def _secure(settings: Settings) -> bool:
    return settings.public_web_url.lower().startswith("https://")


def _drop_cookie(response: Response, settings: Settings) -> None:
    response.delete_cookie(STATE_COOKIE, path=COOKIE_PATH, secure=_secure(settings), httponly=True, samesite="lax")


def _done(settings: Settings, **params: str) -> RedirectResponse:
    response = RedirectResponse(f"{settings.public_web_url.rstrip('/')}/auth/bitrix/done?{urlencode(params)}", 302)
    # Одноразовый код не должен утечь со страницы веба в заголовке Referer и осесть в кешах.
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Cache-Control"] = "no-store"
    return response


@router.get("/auth/methods", response_model=AuthMethodsOut, summary="Какие способы входа включены")
async def auth_methods(settings: SettingsDep) -> AuthMethodsOut:
    return AuthMethodsOut(bitrix24=settings.bitrix24_login_configured)


@router.get(
    "/auth/bitrix/start",
    status_code=302,
    response_class=RedirectResponse,
    summary="Начать вход через Битрикс24",
)
async def bitrix_start(session: SessionDep, clock: ClockDep, settings: SettingsDep) -> RedirectResponse:
    if not settings.bitrix24_login_configured:
        raise NotFound("Вход через Битрикс24 не настроен")
    now = clock.now()
    # Заодно убираем просроченные билеты: таблица не растёт.
    await session.execute(delete(LoginTicket).where(LoginTicket.expires_at < now))
    state = secrets.token_urlsafe(32)
    session.add(LoginTicket(kind="state", token_hash=_sha256(state), created_at=now, expires_at=now + STATE_TTL))
    await session.flush()

    query = urlencode({"client_id": settings.bitrix24_client_id.strip(), "state": state})
    response = RedirectResponse(f"https://{settings.bitrix24_portal_host}/oauth/authorize/?{query}", 302)
    response.set_cookie(
        STATE_COOKIE,
        state,
        max_age=int(STATE_TTL.total_seconds()),
        path=COOKIE_PATH,
        secure=_secure(settings),
        httponly=True,
        samesite="lax",
    )
    response.headers["Cache-Control"] = "no-store"
    return response


async def _consume_state(session: AsyncSession, state: str | None, cookie: str | None, now: datetime) -> None:
    """`state` из адреса совпадает с cookie этого браузера, выдан нами, не истёк и ещё не использован."""
    if not state or not cookie or not hmac.compare_digest(state.encode(), cookie.encode()):
        raise _Refused(InvalidBitrixAuth.code)
    ticket = await session.scalar(
        select(LoginTicket)
        .where(
            LoginTicket.kind == "state",
            LoginTicket.token_hash == _sha256(state),
            LoginTicket.used_at.is_(None),
            LoginTicket.expires_at > now,
        )
        .with_for_update()
    )
    if ticket is None:
        raise _Refused(InvalidBitrixAuth.code)
    ticket.used_at = now


async def _pending_or_new_request(session: AsyncSession, profile: BitrixProfile, email: str | None, now: datetime) -> str:
    """Незнакомый сотрудник портала: заявка на доступ, не больше одной на рассмотрении."""
    latest = await session.scalar(
        select(AccessRequest)
        .where(AccessRequest.bitrix_user_id == profile.id)
        .order_by(AccessRequest.created_at.desc(), AccessRequest.id.desc())
        .limit(1)
    )
    if latest is not None and latest.status in ("pending", "rejected"):
        return f"access_request_{latest.status}"
    if email is not None:
        same_email = await session.scalar(
            select(AccessRequest.id).where(AccessRequest.email == email, AccessRequest.status == "pending").limit(1)
        )
        if same_email is not None:
            return "access_request_pending"

    request = AccessRequest(
        bitrix_user_id=profile.id,
        email=email,
        full_name=(profile.full_name or email or f"Сотрудник Битрикс24 №{profile.id}")[:200],
        comment=profile.position,
        status="pending",
        created_at=now,
        updated_at=now,
    )
    try:
        # Два возврата одного сотрудника одновременно: вторую заявку не пустит уникальный индекс.
        async with session.begin_nested():
            session.add(request)
            await session.flush()
    except IntegrityError:
        return "access_request_pending"
    await _notify_managers(session, request, now)
    return "access_request_pending"


async def _match_user(session: AsyncSession, profile: BitrixProfile, now: datetime) -> User:
    """Сотрудник системы для сотрудника портала: по `bitrix_user_id`, затем по почте."""
    user = await session.scalar(select(User).where(User.bitrix_user_id == profile.id))
    if user is None:
        email = _portal_email(profile.email)
        by_email = await service.user_by_email(session, email) if email else None
        if by_email is not None and by_email.role not in EMAIL_MATCH_ROLES:
            raise _Refused(InvalidBitrixAuth.code)
        if by_email is not None and by_email.bitrix_user_id is None:
            by_email.bitrix_user_id = profile.id
            user = by_email
        else:
            raise _Refused(await _pending_or_new_request(session, profile, email, now))
    if user.is_disabled:
        raise _Refused(UserDisabled.code)
    return user


@router.get(
    "/auth/bitrix/callback",
    status_code=302,
    response_class=RedirectResponse,
    summary="Возврат с портала Битрикс24",
)
async def bitrix_callback(
    request: Request,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
    services: ServicesDep,
    code: str | None = None,
    state: str | None = None,
    domain: str | None = None,
    member_id: str | None = None,
) -> RedirectResponse:
    now = clock.now()
    cookie = request.cookies.get(STATE_COOKIE)
    try:
        if not settings.bitrix24_login_configured:
            raise _Refused(InvalidBitrixAuth.code)
        await _consume_state(session, state, cookie, now)
        if (domain or "").strip().lower() != settings.bitrix24_portal_host or not code:
            raise _Refused(InvalidBitrixAuth.code)
        try:
            profile = await services.bitrix_oauth.current_user(code)
        except (InvalidBitrixAuth, ExternalServiceError) as exc:
            code_ = exc.code if isinstance(exc, InvalidBitrixAuth) else "bitrix_unavailable"
            raise _Refused(code_) from None
        user = await _match_user(session, profile, now)
        exchange = secrets.token_urlsafe(32)
        session.add(
            LoginTicket(
                kind="exchange",
                token_hash=_sha256(exchange),
                user_id=user.id,
                cookie_hash=_sha256(cookie),
                created_at=now,
                expires_at=now + EXCHANGE_TTL,
            )
        )
        await session.flush()
    except _Refused as refused:
        # Ответ — переход, а не ошибка: использованный `state` и созданная заявка сохраняются.
        response = _done(settings, error=refused.code)
        _drop_cookie(response, settings)
        return response
    return _done(settings, code=exchange)


@router.post("/auth/bitrix/exchange", response_model=SessionOut, summary="Обменять код входа через Битрикс24 на сессию")
async def bitrix_exchange(
    body: BitrixExchangeIn,
    request: Request,
    response: Response,
    session: SessionDep,
    clock: ClockDep,
    settings: SettingsDep,
) -> SessionOut:
    now = clock.now()
    cookie = request.cookies.get(STATE_COOKIE)
    row = (
        await session.execute(
            select(LoginTicket, User)
            .join(User, User.id == LoginTicket.user_id)
            .where(
                LoginTicket.kind == "exchange",
                LoginTicket.token_hash == _sha256(body.code),
                LoginTicket.used_at.is_(None),
                LoginTicket.expires_at > now,
            )
            .with_for_update(of=LoginTicket)
        )
    ).first()
    # Код меняет на сессию только браузер, который начинал вход: иначе чужой код вошёл бы под чужим именем.
    if row is None or not cookie or not hmac.compare_digest(_sha256(cookie), row[0].cookie_hash or ""):
        raise InvalidBitrixAuth()
    ticket, user = row
    service.ensure_can_login(user)
    ticket.used_at = now
    response.headers["Cache-Control"] = "no-store"
    _drop_cookie(response, settings)
    return await _session_for(session, user, "bitrix", clock, settings)

