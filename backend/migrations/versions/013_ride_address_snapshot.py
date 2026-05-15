"""Store passenger-selected pickup/destination address snapshots on rides.

Revision ID: 013_ride_address_snapshot
Revises: 012_scheduled_rides
Create Date: 2026-05-14
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "013_ride_address_snapshot"
down_revision = "012_scheduled_rides"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("rides", sa.Column("pickup_address", sa.Text(), nullable=True))
    op.add_column("rides", sa.Column("pickup_display_name", sa.Text(), nullable=True))
    op.add_column("rides", sa.Column("destination_address", sa.Text(), nullable=True))
    op.add_column("rides", sa.Column("destination_display_name", sa.Text(), nullable=True))
    op.add_column("rides", sa.Column("pickup_lat", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("pickup_lng", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("destination_lat", sa.Float(), nullable=True))
    op.add_column("rides", sa.Column("destination_lng", sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column("rides", "destination_lng")
    op.drop_column("rides", "destination_lat")
    op.drop_column("rides", "pickup_lng")
    op.drop_column("rides", "pickup_lat")
    op.drop_column("rides", "destination_display_name")
    op.drop_column("rides", "destination_address")
    op.drop_column("rides", "pickup_display_name")
    op.drop_column("rides", "pickup_address")
