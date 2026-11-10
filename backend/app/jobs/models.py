"""Таблицы механизма фоновых задач."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import Index, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class JobStatus:
    PENDING = "pending"
    RUNNING = "running"
    DONE = "done"
    FAILED = "failed"


class Job(Base):
    """Разовая задача: выполнить обработчик `kind` с `payload` не раньше `run_at`."""

    __tablename__ = "jobs"
    __table_args__ = (Index("ix_jobs_status_run_at", "status", "run_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    kind: Mapped[str] = mapped_column(String(100))
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    status: Mapped[str] = mapped_column(String(20), default=JobStatus.PENDING)
    run_at: Mapped[datetime]
    attempts: Mapped[int] = mapped_column(default=0)
    max_attempts: Mapped[int] = mapped_column(default=3)
    last_error: Mapped[str | None] = mapped_column(Text)
    # Ключ от повторной постановки: одна и та же задача не встанет в очередь дважды.
    dedup_key: Mapped[str | None] = mapped_column(String(200), unique=True)
    created_at: Mapped[datetime]
    started_at: Mapped[datetime | None]
    finished_at: Mapped[datetime | None]


class PeriodicTask(Base):
    """Состояние периодической задачи: когда её поставить в очередь в следующий раз."""

    __tablename__ = "periodic_tasks"

    name: Mapped[str] = mapped_column(String(100), primary_key=True)
    # Описание расписания; если оно поменялось (например, DIGEST_TIME), next_run_at пересчитывается.
    schedule: Mapped[str] = mapped_column(String(100))
    next_run_at: Mapped[datetime]
    last_run_at: Mapped[datetime | None]
