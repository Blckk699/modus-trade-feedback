"""Очередь уведомлений: бот доставляет их в Telegram, клиенты показывают счётчик непрочитанного."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = (
        Index("ix_notifications_user_id_read_at", "user_id", "read_at"),
        Index("ix_notifications_delivery", "delivered_at", "next_attempt_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    kind: Mapped[str] = mapped_column(String(40))  # NotificationKind
    text: Mapped[str] = mapped_column(Text)
    appeal_id: Mapped[int | None] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"))
    path: Mapped[str | None] = mapped_column(String(200))
    buttons: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)
    read_at: Mapped[datetime | None]
    # Доставка ботом: подтверждённая не повторяется, неудачная — после next_attempt_at.
    delivered_at: Mapped[datetime | None]
    next_attempt_at: Mapped[datetime]
    attempts: Mapped[int] = mapped_column(default=0)
    failed_permanently: Mapped[bool] = mapped_column(default=False)
    last_error: Mapped[str | None] = mapped_column(Text)
    telegram_message_id: Mapped[int | None]
    created_at: Mapped[datetime]
