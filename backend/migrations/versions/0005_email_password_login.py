"""email and password login

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-12 16:30:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("email", sa.String(length=254), nullable=True))
    op.add_column("users", sa.Column("password_hash", sa.String(length=255), nullable=True))
    op.add_column("users", sa.Column("must_change_password", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.alter_column("users", "must_change_password", server_default=None)
    op.create_unique_constraint(op.f("uq_users_email"), "users", ["email"])

    op.alter_column("access_requests", "telegram_id", existing_type=sa.BigInteger(), nullable=True)
    op.add_column("access_requests", sa.Column("email", sa.String(length=254), nullable=True))
    op.add_column("access_requests", sa.Column("password_hash", sa.String(length=255), nullable=True))
    op.create_index("ix_access_requests_email", "access_requests", ["email"], unique=False)
    op.create_index(
        "uq_access_requests_pending_email",
        "access_requests",
        ["email"],
        unique=True,
        postgresql_where=sa.text("status = 'pending'"),
    )

    op.alter_column("access_submissions", "telegram_id", existing_type=sa.BigInteger(), nullable=True)
    op.add_column("access_submissions", sa.Column("email", sa.String(length=254), nullable=True))
    op.create_index("ix_access_submissions_email_created_at", "access_submissions", ["email", "created_at"], unique=False)

    op.create_table(
        "password_attempts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("key", sa.String(length=300), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_password_attempts")),
    )
    op.create_index("ix_password_attempts_key_created_at", "password_attempts", ["key", "created_at"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_password_attempts_key_created_at", table_name="password_attempts")
    op.drop_table("password_attempts")

    op.drop_index("ix_access_submissions_email_created_at", table_name="access_submissions")
    op.drop_column("access_submissions", "email")
    op.execute("DELETE FROM access_submissions WHERE telegram_id IS NULL")
    op.alter_column("access_submissions", "telegram_id", existing_type=sa.BigInteger(), nullable=False)

    op.drop_index("uq_access_requests_pending_email", table_name="access_requests", postgresql_where=sa.text("status = 'pending'"))
    op.drop_index("ix_access_requests_email", table_name="access_requests")
    op.drop_column("access_requests", "password_hash")
    op.drop_column("access_requests", "email")
    op.execute("DELETE FROM access_requests WHERE telegram_id IS NULL")
    op.alter_column("access_requests", "telegram_id", existing_type=sa.BigInteger(), nullable=False)

    op.drop_constraint(op.f("uq_users_email"), "users", type_="unique")
    op.drop_column("users", "must_change_password")
    op.drop_column("users", "password_hash")
    op.drop_column("users", "email")
