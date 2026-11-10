"""Общие обсуждения: публичная формулировка, голоса, публичные комментарии."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import ForeignKey, Index, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class Discussion(Base):
    __tablename__ = "discussions"

    id: Mapped[int] = mapped_column(primary_key=True)
    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"), unique=True)
    public_text: Mapped[str] = mapped_column(Text)
    deadline: Mapped[datetime]
    status: Mapped[str] = mapped_column(String(20))  # DiscussionStatus
    author_name_consent: Mapped[str] = mapped_column(String(20))  # NameConsent
    outcome: Mapped[str | None] = mapped_column(Text)
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime]
    closed_by_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    closed_at: Mapped[datetime | None]


class DiscussionVote(Base):
    """Один голос на пользователя, меняется до срока."""

    __tablename__ = "discussion_votes"

    discussion_id: Mapped[int] = mapped_column(ForeignKey("discussions.id", ondelete="CASCADE"), primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), primary_key=True)
    value: Mapped[str] = mapped_column(String(10))  # VoteValue
    updated_at: Mapped[datetime]


class DiscussionComment(Base):
    __tablename__ = "discussion_comments"
    __table_args__ = (Index("ix_discussion_comments_discussion_id", "discussion_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    discussion_id: Mapped[int] = mapped_column(ForeignKey("discussions.id", ondelete="CASCADE"))
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    text: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime]
