"""Add profile fields to b2b_tenants.

Revision ID: 009_b2b_tenant_profile_fields
Revises: 008_user_profile_fields
Create Date: 2026-04-27
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "009_b2b_tenant_profile_fields"
down_revision = "008_user_profile_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("b2b_tenants", sa.Column("contact_name", sa.String(length=255), nullable=True))
    op.add_column("b2b_tenants", sa.Column("pin", sa.String(length=64), nullable=True))
    op.add_column("b2b_tenants", sa.Column("phone", sa.String(length=32), nullable=True))
    op.add_column("b2b_tenants", sa.Column("hotel", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("b2b_tenants", "hotel")
    op.drop_column("b2b_tenants", "phone")
    op.drop_column("b2b_tenants", "pin")
    op.drop_column("b2b_tenants", "contact_name")
