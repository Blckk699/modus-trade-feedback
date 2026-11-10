"""Миграции Alembic совпадают с моделями. Упал — сгенерируйте миграцию:
`uv run python scripts/dev.py alembic revision --autogenerate -m "<что изменилось>"`."""

from __future__ import annotations

from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from fastapi import FastAPI

from app.models import Base


async def test_models_match_migrations(app: FastAPI) -> None:
    def diff(connection):
        context = MigrationContext.configure(connection, opts={"compare_type": True})
        return compare_metadata(context, Base.metadata)

    async with app.state.engine.connect() as conn:
        changes = await conn.run_sync(diff)

    assert changes == []
