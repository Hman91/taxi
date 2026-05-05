"""Add password reset token fields on users.

Revision ID: 010_user_password_reset_fields
Revises: 009_b2b_tenant_profile_fields
Create Date: 2026-05-05
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "010_user_password_reset_fields"
down_revision = "009_b2b_tenant_profile_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("password_reset_token_hash", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("password_reset_expires_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "password_reset_expires_at")
    op.drop_column("users", "password_reset_token_hash")
