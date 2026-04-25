"""Add driver_pin_accounts and b2b_bookings tables.

Revision ID: 004_driver_pin_b2b_bookings
Revises: 003_fare_routes
Create Date: 2026-04-15
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "004_driver_pin_b2b_bookings"
down_revision = "003_fare_routes"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "driver_pin_accounts",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("phone", sa.String(length=32), nullable=False),
        sa.Column("pin", sa.String(length=32), nullable=False),
        sa.Column("driver_name", sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("phone"),
    )
    op.create_index("ix_driver_pin_accounts_phone", "driver_pin_accounts", ["phone"], unique=False)

    op.execute(
        """
        INSERT INTO driver_pin_accounts (phone, pin, driver_name) VALUES
        ('98123456', '1234', 'خليل (سائق 1)'),
        ('50111222', '0000', 'أحمد (سائق 2)')
        """
    )

    op.create_table(
        "b2b_bookings",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("tenant_id", sa.BigInteger(), nullable=True),
        sa.Column("route", sa.Text(), nullable=False),
        sa.Column("pickup", sa.Text(), nullable=False),
        sa.Column("destination", sa.Text(), nullable=False),
        sa.Column("guest_name", sa.Text(), nullable=False),
        sa.Column("room_number", sa.String(length=64), nullable=True),
        sa.Column("fare", sa.Float(), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default=sa.text("'pending'")),
        sa.Column("source_code", sa.String(length=255), nullable=False),
        sa.Column("ride_id", sa.BigInteger(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["ride_id"], ["rides.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["tenant_id"], ["b2b_tenants.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_b2b_bookings_tenant_id", "b2b_bookings", ["tenant_id"], unique=False)
    op.create_index("ix_b2b_bookings_ride_id", "b2b_bookings", ["ride_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_b2b_bookings_ride_id", table_name="b2b_bookings")
    op.drop_index("ix_b2b_bookings_tenant_id", table_name="b2b_bookings")
    op.drop_table("b2b_bookings")

    op.drop_index("ix_driver_pin_accounts_phone", table_name="driver_pin_accounts")
    op.drop_table("driver_pin_accounts")
