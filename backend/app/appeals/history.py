"""Запись в историю событий обращения. Каждое изменение обращения проходит через `record`."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.enums import HistoryKind
from app.models import Appeal, HistoryEvent


def record(
    session: AsyncSession,
    appeal: Appeal,
    kind: HistoryKind,
    at: datetime,
    actor_id: int | None,
    *,
    field: str | None = None,
    old_value: object = None,
    new_value: object = None,
    comment: str | None = None,
) -> HistoryEvent:
    """Добавляет событие и двигает `updated_at` обращения. `actor_id=None` — система."""
    event = HistoryEvent(
        appeal_id=appeal.id,
        actor_id=actor_id,
        kind=kind,
        field=field,
        old_value=None if old_value is None else str(old_value),
        new_value=None if new_value is None else str(new_value),
        comment=comment,
        created_at=at,
    )
    session.add(event)
    appeal.updated_at = at
    return event
