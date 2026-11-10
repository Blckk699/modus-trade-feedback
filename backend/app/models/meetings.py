"""Режим «совещание»: запись, расшифровка, черновики обращений с цитатами."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import ForeignKey, Index, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class Meeting(Base):
    __tablename__ = "meetings"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(300))
    status: Mapped[str] = mapped_column(String(20))  # MeetingStatus
    error: Mapped[str | None] = mapped_column(Text)
    filename: Mapped[str] = mapped_column(String(300))
    content_type: Mapped[str] = mapped_column(String(150))
    storage_key: Mapped[str] = mapped_column(String(300))
    transcript: Mapped[str | None] = mapped_column(Text)
    uploaded_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime]


class MeetingDraft(Base):
    """Черновик обращения из расшифровки. Обращение создаётся только после подтверждения."""

    __tablename__ = "meeting_drafts"
    __table_args__ = (Index("ix_meeting_drafts_meeting_id", "meeting_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    meeting_id: Mapped[int] = mapped_column(ForeignKey("meetings.id", ondelete="CASCADE"))
    status: Mapped[str] = mapped_column(String(20))  # MeetingDraftStatus
    type: Mapped[str] = mapped_column(String(20))
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))
    priority: Mapped[str] = mapped_column(String(20))
    summary: Mapped[str] = mapped_column(String(500))
    text: Mapped[str] = mapped_column(Text)
    proposed_solution: Mapped[str | None] = mapped_column(Text)
    quote: Mapped[str] = mapped_column(Text)
    author_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    appeal_id: Mapped[int | None] = mapped_column(ForeignKey("appeals.id"))
    created_at: Mapped[datetime]
