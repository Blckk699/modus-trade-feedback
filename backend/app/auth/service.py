"""Вход и сессии: кто может войти, выдача и проверка токенов, одноразовые коды из бота."""

from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.models import AuthSession, LoginAttempt, LoginCode
from app.config import Settings
from app.errors import InvalidLoginCode, TooManyRequests, Unauthorized, UserDisabled, UserNotRegistered
from app.models import User


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def ensure_can_login(user: User | None) -> User:
    """Войти может только сотрудник, которого завёл администратор, и только с включённым доступом."""
    if user is None:
        raise UserNotRegistered()
    if user.is_disabled:
        raise UserDisabled()
    return user


async def user_by_telegram_id(session: AsyncSession, telegram_id: int) -> User | None:
    return await session.scalar(select(User).where(User.telegram_id == telegram_id))


async def open_session(
    session: AsyncSession, user: User, method: str, now: datetime, settings: Settings
) -> tuple[str, datetime]:
    """Выдаёт новую сессию. Возвращает токен (показывается клиенту один раз) и срок действия."""
    token = secrets.token_urlsafe(32)
    expires_at = now + timedelta(days=settings.session_ttl_days)
    session.add(
        AuthSession(token_hash=_sha256(token), user_id=user.id, method=method, created_at=now, expires_at=expires_at)
    )
    await session.flush()
    return token, expires_at


async def user_by_token(session: AsyncSession, token: str, now: datetime) -> User:
    row = (
        await session.execute(
            select(AuthSession, User)
            .join(User, User.id == AuthSession.user_id)
            .where(AuthSession.token_hash == _sha256(token))
        )
    ).first()
    if row is None:
        raise Unauthorized()
    auth, user = row
    if auth.revoked_at is not None or auth.expires_at <= now:
        raise Unauthorized("Сессия истекла, войдите снова")
    return ensure_can_login(user)


async def revoke_token(session: AsyncSession, token: str, now: datetime) -> None:
    await session.execute(
        update(AuthSession)
        .where(AuthSession.token_hash == _sha256(token), AuthSession.revoked_at.is_(None))
        .values(revoked_at=now)
    )


async def revoke_user_sessions(session: AsyncSession, user_id: int, now: datetime) -> None:
    """Сбросить все сессии пользователя (например, при отключении доступа — B-14)."""
    await session.execute(
        update(AuthSession)
        .where(AuthSession.user_id == user_id, AuthSession.revoked_at.is_(None))
        .values(revoked_at=now)
    )


async def issue_login_code(session: AsyncSession, user: User, now: datetime, settings: Settings) -> tuple[str, datetime]:
    """Новый шестизначный код; прежние неиспользованные коды пользователя гасятся."""
    await session.execute(
        update(LoginCode).where(LoginCode.user_id == user.id, LoginCode.used_at.is_(None)).values(used_at=now)
    )
    while True:
        code = f"{secrets.randbelow(1_000_000):06d}"
        clash = await session.scalar(
            select(LoginCode.id).where(
                LoginCode.code_hash == _sha256(code), LoginCode.used_at.is_(None), LoginCode.expires_at > now
            )
        )
        if clash is None:
            break
    expires_at = now + timedelta(seconds=settings.login_code_ttl_seconds)
    session.add(LoginCode(code_hash=_sha256(code), user_id=user.id, created_at=now, expires_at=expires_at))
    await session.flush()
    return code, expires_at


async def check_code_attempts(session: AsyncSession, ip: str, now: datetime, settings: Settings) -> None:
    """С одного IP не больше N неудачных попыток за окно — дальше 429."""
    since = now - timedelta(seconds=settings.login_code_failure_window_seconds)
    failures = await session.scalar(
        select(func.count()).select_from(LoginAttempt).where(LoginAttempt.ip == ip, LoginAttempt.created_at > since)
    )
    if (failures or 0) >= settings.login_code_max_failures_per_ip:
        raise TooManyRequests()


async def record_code_failure(session: AsyncSession, ip: str, now: datetime, settings: Settings) -> None:
    """Учитывает неудачу. Если неудач по всем IP за время жизни кода слишком много — перебор идёт
    распределённо, и все активные коды сжигаются: пользователи запросят новый в боте."""
    session.add(LoginAttempt(ip=ip, created_at=now))
    await session.flush()
    since = now - timedelta(seconds=settings.login_code_ttl_seconds)
    total = await session.scalar(select(func.count()).select_from(LoginAttempt).where(LoginAttempt.created_at > since))
    if (total or 0) >= settings.login_code_burn_after_failures:
        await session.execute(
            update(LoginCode).where(LoginCode.used_at.is_(None), LoginCode.expires_at > now).values(used_at=now)
        )


async def redeem_login_code(session: AsyncSession, code: str, now: datetime) -> User:
    """Обменивает код на пользователя. Код срабатывает один раз и только до истечения."""
    row = (
        await session.execute(
            select(LoginCode, User)
            .join(User, User.id == LoginCode.user_id)
            .where(LoginCode.code_hash == _sha256(code), LoginCode.used_at.is_(None), LoginCode.expires_at > now)
            .with_for_update(of=LoginCode)
        )
    ).first()
    if row is None:
        raise InvalidLoginCode()
    login_code, user = row
    login_code.used_at = now
    return ensure_can_login(user)
