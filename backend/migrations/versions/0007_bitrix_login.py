"""bitrix24 oauth login

Revision ID: 0007
Revises: 0006
Create Date: 2026-11-12 23:40:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("bitrix_user_id", sa.BigInteger(), nullable=True))
    op.create_unique_constraint(op.f("uq_users_bitrix_user_id"), "users", ["bitrix_user_id"])

    op.add_column("access_requests", sa.Column("bitrix_user_id", sa.BigInteger(), nullable=True))
    op.create_index("ix_access_requests_bitrix_user_id", "access_requests", ["bitrix_user_id"], unique=False)
    op.create_index(
        "uq_access_requests_pending_bitrix_user_id",
        "access_requests",
        ["bitrix_user_id"],
        unique=True,
        postgresql_where=sa.text("status = 'pending'"),
    )

    op.create_table(
        "login_tickets",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("kind", sa.String(length=20), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("cookie_hash", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name=op.f("fk_login_tickets_user_id_users"), ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_login_tickets")),
        sa.UniqueConstraint("token_hash", name=op.f("uq_login_tickets_token_hash")),
    )


def downgrade() -> None:
    op.drop_table("login_tickets")

    op.drop_index(
        "uq_access_requests_pending_bitrix_user_id",
        table_name="access_requests",
        postgresql_where=sa.text("status = 'pending'"),
    )
    op.drop_index("ix_access_requests_bitrix_user_id", table_name="access_requests")
    # Заявки, поданные только через портал, без этого столбца никому не принадлежат.
    op.execute("DELETE FROM access_requests WHERE telegram_id IS NULL AND email IS NULL")
    op.drop_column("access_requests", "bitrix_user_id")

    op.drop_constraint(op.f("uq_users_bitrix_user_id"), "users", type_="unique")
    op.drop_column("users", "bitrix_user_id")
