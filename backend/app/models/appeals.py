"""Обращение и всё, что висит на нём: участники, переписка, история, вложения, повторы, Битрикс24."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import ForeignKey, Index, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class Appeal(Base):
    __tablename__ = "appeals"
    __table_args__ = (
        Index("ix_appeals_status", "status"),
        Index("ix_appeals_assignee_id", "assignee_id"),
        Index("ix_appeals_author_id", "author_id"),
        Index("ix_appeals_category_id", "category_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    number: Mapped[str] = mapped_column(String(20), unique=True)  # A-001
    type: Mapped[str] = mapped_column(String(20))  # AppealType
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))
    priority: Mapped[str] = mapped_column(String(20))  # Priority
    status: Mapped[str] = mapped_column(String(20))  # AppealStatus
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    # null — обращение в очереди нераспределённых у администратора.
    assignee_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    text: Mapped[str] = mapped_column(Text)
    summary: Mapped[str | None] = mapped_column(String(500))
    proposed_solution: Mapped[str | None] = mapped_column(Text)
    source: Mapped[str] = mapped_column(String(20))  # AppealSource
    forwarded_from: Mapped[str | None] = mapped_column(String(300))
    # Единственный срок — первого ответа. null у отзывов и нераспределённых.
    first_response_due_at: Mapped[datetime | None]
    first_response_at: Mapped[datetime | None]
    # Шаг эскалации: 0 — нет, 1 — напомнили ответственному, 2 — руководителю, 3 — «Зависло».
    escalation_level: Mapped[int] = mapped_column(default=0)
    decision: Mapped[str | None] = mapped_column(Text)
    rejection_reason: Mapped[str | None] = mapped_column(Text)
    result: Mapped[str | None] = mapped_column(Text)
    public_summary: Mapped[str | None] = mapped_column(Text)
    public_result: Mapped[str | None] = mapped_column(Text)
    implemented_at: Mapped[datetime | None]
    closed_reason: Mapped[str | None] = mapped_column(String(30))  # ClosedReason
    merged_into_id: Mapped[int | None] = mapped_column(ForeignKey("appeals.id"))
    created_at: Mapped[datetime]
    updated_at: Mapped[datetime]


class AppealParticipant(Base):
    """Автор склеенного повтора — участник основного обращения: получает его статусы."""

    __tablename__ = "appeal_participants"

    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"), primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), primary_key=True)
    via_appeal_id: Mapped[int | None] = mapped_column(ForeignKey("appeals.id"))
    added_at: Mapped[datetime]


class Message(Base):
    """Приватная переписка автора с ответственным."""

    __tablename__ = "messages"
    __table_args__ = (Index("ix_messages_appeal_id", "appeal_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"))
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    text: Mapped[str] = mapped_column(Text)
    is_clarification_question: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime]


class HistoryEvent(Base):
    """Событие истории обращения: кто, что изменил, старое и новое значение, когда."""

    __tablename__ = "history_events"
    __table_args__ = (Index("ix_history_events_appeal_id", "appeal_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"))
    actor_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))  # null — система
    kind: Mapped[str] = mapped_column(String(40))  # HistoryKind
    field: Mapped[str | None] = mapped_column(String(50))
    old_value: Mapped[str | None] = mapped_column(Text)
    new_value: Mapped[str | None] = mapped_column(Text)
    comment: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime]


class Attachment(Base):
    __tablename__ = "attachments"
    __table_args__ = (Index("ix_attachments_appeal_id", "appeal_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"))
    filename: Mapped[str] = mapped_column(String(300))
    content_type: Mapped[str] = mapped_column(String(150))
    size_bytes: Mapped[int]
    # Где лежит файл в хранилище (путь относительно каталога вложений).
    storage_key: Mapped[str] = mapped_column(String(300))
    uploaded_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime]


class DuplicateSuggestion(Base):
    """Подсказка «похоже на …» с объяснением сходства. «Это другое» ставит `dismissed_at`."""

    __tablename__ = "duplicate_suggestions"
    __table_args__ = (UniqueConstraint("appeal_id", "similar_appeal_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"))
    similar_appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"))
    explanation: Mapped[str] = mapped_column(Text)
    dismissed_at: Mapped[datetime | None]
    dismissed_by_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime]


class BitrixTask(Base):
    """Ссылка на задачу Битрикс24, созданную из обращения. Одна на обращение."""

    __tablename__ = "bitrix_tasks"

    appeal_id: Mapped[int] = mapped_column(ForeignKey("appeals.id", ondelete="CASCADE"), primary_key=True)
    task_id: Mapped[str] = mapped_column(String(50))
    url: Mapped[str] = mapped_column(String(500))
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime]
