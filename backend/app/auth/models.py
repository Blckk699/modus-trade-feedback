"""Сессии клиентов и одноразовые коды входа из бота."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class AuthSession(Base):
    """Сессия клиента. В базе только SHA-256 токена — сам токен знает лишь клиент."""

    __tablename__ = "auth_sessions"
    __table_args__ = (Index("ix_auth_sessions_user_id", "user_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    method: Mapped[str] = mapped_column(String(20))  # mini_app | widget | code | dev | password | bitrix | invite_*
    created_at: Mapped[datetime]
    expires_at: Mapped[datetime]
    revoked_at: Mapped[datetime | None]


class LoginAttempt(Base):
    """Неудачная попытка входа по коду: по ним ограничивается перебор."""

    __tablename__ = "login_attempts"
    __table_args__ = (Index("ix_login_attempts_ip_created_at", "ip", "created_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    ip: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime]


class LoginCode(Base):
    """Одноразовый код для входа в мобильное приложение. Хранится хешем, обменивается один раз."""

    __tablename__ = "login_codes"
    __table_args__ = (Index("ix_login_codes_code_hash", "code_hash"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    code_hash: Mapped[str] = mapped_column(String(64))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    created_at: Mapped[datetime]
    expires_at: Mapped[datetime]
    used_at: Mapped[datetime | None]


class PasswordAttempt(Base):
    """Неудачный вход по паролю. Ключ — `email:<почта>` или `ip:<адрес>`: лимиты по почте и по адресу."""

    __tablename__ = "password_attempts"
    __table_args__ = (Index("ix_password_attempts_key_created_at", "key", "created_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(300))
    created_at: Mapped[datetime]


class AccountSwitch(Base):
    """Журнал демо-переключателя ролей: кто, на кого и когда переключился."""

    __tablename__ = "account_switches"

    id: Mapped[int] = mapped_column(primary_key=True)
    from_user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    to_user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    created_at: Mapped[datetime]


class LoginTicket(Base):
    """Одноразовый билет входа через Битрикс24. В базе только SHA-256 значения.

    `state` — защита начала входа (10 минут, значение лежит в cookie браузера);
    `exchange` — код обмена на сессию (60 секунд, привязан к пользователю и к тому же cookie).
    """

    __tablename__ = "login_tickets"

    id: Mapped[int] = mapped_column(primary_key=True)
    kind: Mapped[str] = mapped_column(String(20))  # state | exchange
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    cookie_hash: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime]
    expires_at: Mapped[datetime]
    used_at: Mapped[datetime | None]
