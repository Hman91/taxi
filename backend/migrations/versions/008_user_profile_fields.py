"""Add passenger profile fields on users.

Revision ID: 008_user_profile_fields
Revises: 007_ride_rating_links
Create Date: 2026-04-22
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "008_user_profile_fields"
down_revision = "007_ride_rating_links"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("display_name", sa.String(length=255), nullable=False, server_default=""),
    )
    op.add_column("users", sa.Column("phone", sa.String(length=32), nullable=True))
    op.add_column("users", sa.Column("photo_url", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "photo_url")
    op.drop_column("users", "phone")
    op.drop_column("users", "display_name")
