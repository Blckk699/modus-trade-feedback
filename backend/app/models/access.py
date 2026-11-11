"""Заявки на доступ и приглашения (B-18, истории 71–74)."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import BigInteger, ForeignKey, Index, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class AccessRequest(Base):
    """Заявка незнакомого Telegram-аккаунта. На аккаунт не больше одной заявки `pending`."""

    __tablename__ = "access_requests"
    __table_args__ = (
        Index("ix_access_requests_telegram_id", "telegram_id"),
        Index(
            "uq_access_requests_pending_telegram_id",
            "telegram_id",
            unique=True,
            postgresql_where=text("status = 'pending'"),
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    telegram_id: Mapped[int] = mapped_column(BigInteger)
    telegram_username: Mapped[str | None] = mapped_column(String(64))
    full_name: Mapped[str] = mapped_column(String(200))
    department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id", ondelete="SET NULL"))
    comment: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20))  # pending | approved | rejected
    assigned_role: Mapped[str | None] = mapped_column(String(20))
    assigned_department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id", ondelete="SET NULL"))
    decided_by_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    decided_at: Mapped[datetime | None]
    reject_reason: Mapped[str | None] = mapped_column(Text)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))
    created_at: Mapped[datetime]
    updated_at: Mapped[datetime]


class AccessSubmission(Base):
    """Журнал подач заявки — для лимита частоты с одного Telegram-аккаунта."""

    __tablename__ = "access_submissions"
    __table_args__ = (Index("ix_access_submissions_telegram_id_created_at", "telegram_id", "created_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    telegram_id: Mapped[int] = mapped_column(BigInteger)
    created_at: Mapped[datetime]


class Invite(Base):
    """Ссылка-приглашение. В базе только SHA-256 токена: сам токен показывается один раз при создании."""

    __tablename__ = "invites"

    id: Mapped[int] = mapped_column(primary_key=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    role: Mapped[str] = mapped_column(String(20))
    department_id: Mapped[int | None] = mapped_column(ForeignKey("departments.id", ondelete="SET NULL"))
    full_name: Mapped[str | None] = mapped_column(String(200))
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime]
    expires_at: Mapped[datetime]
    max_uses: Mapped[int]
    used_count: Mapped[int] = mapped_column(default=0)
    revoked_at: Mapped[datetime | None]


class InviteAttempt(Base):
    """Неудачная попытка с токеном приглашения: ключ — IP клиента или `tg:<id>` для бота. Для лимита перебора."""

    __tablename__ = "invite_attempts"
    __table_args__ = (Index("ix_invite_attempts_key_created_at", "key", "created_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime]
