"""Add ride_dispatch_candidates table for nearest-5 dispatch.

Revision ID: 006_ride_dispatch_candidates
Revises: 005_driver_pin_profile_wallet
Create Date: 2026-04-15
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "006_ride_dispatch_candidates"
down_revision = "005_driver_pin_profile_wallet"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "ride_dispatch_candidates",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("ride_id", sa.BigInteger(), nullable=False),
        sa.Column("driver_user_id", sa.BigInteger(), nullable=False),
        sa.Column("rank", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["ride_id"], ["rides.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["driver_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("ride_id", "driver_user_id", name="uq_ride_candidate_driver"),
    )
    op.create_index(
        "ix_ride_dispatch_candidates_ride_id",
        "ride_dispatch_candidates",
        ["ride_id"],
        unique=False,
    )
    op.create_index(
        "ix_ride_dispatch_candidates_driver_user_id",
        "ride_dispatch_candidates",
        ["driver_user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_ride_dispatch_candidates_driver_user_id", table_name="ride_dispatch_candidates")
    op.drop_index("ix_ride_dispatch_candidates_ride_id", table_name="ride_dispatch_candidates")
    op.drop_table("ride_dispatch_candidates")
