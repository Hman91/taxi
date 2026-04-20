"""Extend driver_pin_accounts with wallet, commission rates, and profile fields.

Revision ID: 005_driver_pin_profile_wallet
Revises: 004_driver_pin_b2b_bookings
Create Date: 2026-04-15
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "005_driver_pin_profile_wallet"
down_revision = "004_driver_pin_b2b_bookings"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "driver_pin_accounts",
        sa.Column("wallet_balance", sa.Float(), nullable=False, server_default=sa.text("0")),
    )
    op.add_column(
        "driver_pin_accounts",
        sa.Column("owner_commission_rate", sa.Float(), nullable=False, server_default=sa.text("10")),
    )
    op.add_column(
        "driver_pin_accounts",
        sa.Column("b2b_commission_rate", sa.Float(), nullable=False, server_default=sa.text("5")),
    )
    op.add_column(
        "driver_pin_accounts",
        sa.Column("auto_deduct_enabled", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )
    op.add_column("driver_pin_accounts", sa.Column("photo_url", sa.Text(), nullable=True))
    op.add_column("driver_pin_accounts", sa.Column("car_model", sa.Text(), nullable=True))
    op.add_column("driver_pin_accounts", sa.Column("car_color", sa.Text(), nullable=True))
    op.add_column("driver_pin_accounts", sa.Column("current_zone", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("driver_pin_accounts", "current_zone")
    op.drop_column("driver_pin_accounts", "car_color")
    op.drop_column("driver_pin_accounts", "car_model")
    op.drop_column("driver_pin_accounts", "photo_url")
    op.drop_column("driver_pin_accounts", "auto_deduct_enabled")
    op.drop_column("driver_pin_accounts", "b2b_commission_rate")
    op.drop_column("driver_pin_accounts", "owner_commission_rate")
    op.drop_column("driver_pin_accounts", "wallet_balance")
