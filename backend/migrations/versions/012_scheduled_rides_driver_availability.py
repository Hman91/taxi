"""Add scheduled ride reservations and driver availability slots.

Revision ID: 012_scheduled_rides
Revises: 011_user_approval_and_roles
Create Date: 2026-05-12
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "012_scheduled_rides"
down_revision = "011_user_approval_and_roles"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "rides",
        sa.Column("scheduled_pickup_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "rides",
        sa.Column("reservation_status", sa.String(length=32), nullable=True),
    )
    op.create_index(
        "ix_rides_scheduled_pickup_at",
        "rides",
        ["scheduled_pickup_at"],
        unique=False,
    )
    op.create_index(
        "ix_rides_reservation_status",
        "rides",
        ["reservation_status"],
        unique=False,
    )

    op.create_table(
        "driver_availability_slots",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("driver_id", sa.BigInteger(), nullable=False),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "status",
            sa.String(length=24),
            nullable=False,
            server_default="open",
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["driver_id"], ["drivers.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_driver_availability_slots_driver_id",
        "driver_availability_slots",
        ["driver_id"],
        unique=False,
    )
    op.create_index(
        "ix_driver_availability_slots_starts_at",
        "driver_availability_slots",
        ["starts_at"],
        unique=False,
    )
    op.create_index(
        "ix_driver_availability_slots_ends_at",
        "driver_availability_slots",
        ["ends_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_driver_availability_slots_ends_at", table_name="driver_availability_slots")
    op.drop_index("ix_driver_availability_slots_starts_at", table_name="driver_availability_slots")
    op.drop_index("ix_driver_availability_slots_driver_id", table_name="driver_availability_slots")
    op.drop_table("driver_availability_slots")
    op.drop_index("ix_rides_reservation_status", table_name="rides")
    op.drop_index("ix_rides_scheduled_pickup_at", table_name="rides")
    op.drop_column("rides", "reservation_status")
    op.drop_column("rides", "scheduled_pickup_at")
