"""Persist locked distance/duration/fare snapshot on rides (Google route at booking).

Revision ID: 014_ride_quote_snapshot
Revises: 013_ride_address_snapshot
Create Date: 2026-05-15
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "014_ride_quote_snapshot"
down_revision = "013_ride_address_snapshot"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("rides", sa.Column("quoted_distance_km", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("quoted_duration_seconds", sa.Integer(), nullable=True))
    op.add_column("rides", sa.Column("quoted_fare_dt", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("quoted_base_fare_dt", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("quoted_night_surcharge_dt", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("quoted_is_night", sa.Boolean(), nullable=True))


def downgrade() -> None:
    op.drop_column("rides", "quoted_is_night")
    op.drop_column("rides", "quoted_night_surcharge_dt")
    op.drop_column("rides", "quoted_base_fare_dt")
    op.drop_column("rides", "quoted_fare_dt")
    op.drop_column("rides", "quoted_duration_seconds")
    op.drop_column("rides", "quoted_distance_km")
