"""demo role switcher: linked accounts

Revision ID: 0006
Revises: 0005
Create Date: 2026-11-12 22:10:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("switch_group", sa.String(length=50), nullable=True))
    op.create_index(op.f("ix_users_switch_group"), "users", ["switch_group"], unique=False)
    op.create_table(
        "account_switches",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("from_user_id", sa.Integer(), nullable=False),
        sa.Column("to_user_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["from_user_id"], ["users.id"], name=op.f("fk_account_switches_from_user_id_users"), ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["to_user_id"], ["users.id"], name=op.f("fk_account_switches_to_user_id_users"), ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_account_switches")),
    )


def downgrade() -> None:
    op.drop_table("account_switches")
    op.drop_index(op.f("ix_users_switch_group"), table_name="users")
    op.drop_column("users", "switch_group")
