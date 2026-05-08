"""Add user approval workflow fields.

Revision ID: 011_user_approval_and_roles
Revises: 010_user_password_reset_fields
Create Date: 2026-05-07
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "011_user_approval_and_roles"
down_revision = "010_user_password_reset_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "approval_status",
            sa.String(length=16),
            nullable=False,
            server_default="approved",
        ),
    )
    op.add_column(
        "users",
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("approved_by_user_id", sa.BigInteger(), nullable=True),
    )

    op.execute(
        """
        UPDATE users
        SET approval_status = CASE
            WHEN role IN ('driver', 'b2b') AND is_enabled = false THEN 'pending'
            ELSE 'approved'
        END
        """
    )


def downgrade() -> None:
    op.drop_column("users", "approved_by_user_id")
    op.drop_column("users", "approved_at")
    op.drop_column("users", "approval_status")
