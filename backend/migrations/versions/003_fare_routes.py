"""Add fare_routes table and seed fixed airport routes.

Revision ID: 003_fare_routes
Revises: 002_chat_b2b
Create Date: 2026-04-15
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "003_fare_routes"
down_revision = "002_chat_b2b"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "fare_routes",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("start", sa.Text(), nullable=False),
        sa.Column("destination", sa.Text(), nullable=False),
        sa.Column("distance_km", sa.Float(), nullable=False, server_default=sa.text("0")),
        sa.Column("base_fare", sa.Float(), nullable=False),
        sa.Column("is_enabled", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("start", "destination", name="uq_fare_routes_start_destination"),
    )
    op.create_index("ix_fare_routes_start", "fare_routes", ["start"], unique=False)
    op.create_index("ix_fare_routes_destination", "fare_routes", ["destination"], unique=False)

    op.execute(
        """
        INSERT INTO fare_routes (start, destination, distance_km, base_fare, is_enabled, sort_order) VALUES
        ('مطار قرطاج', 'الحمامات', 82.0, 120.0, true, 10),
        ('مطار قرطاج', 'سوسة', 125.0, 155.0, true, 20),
        ('مطار قرطاج', 'القنطاوي', 118.0, 148.0, true, 30),
        ('مطار قرطاج', 'نابل', 115.0, 145.0, true, 40),
        ('مطار النفيضة', 'الحمامات', 55.0, 85.0, true, 50),
        ('مطار النفيضة', 'سوسة', 28.0, 70.0, true, 60),
        ('مطار النفيضة', 'القنطاوي', 35.0, 78.0, true, 70),
        ('مطار النفيضة', 'نابل', 98.0, 128.0, true, 80),
        ('مطار المنستير', 'الحمامات', 48.0, 72.0, true, 90),
        ('مطار المنستير', 'سوسة', 25.0, 55.0, true, 100),
        ('مطار المنستير', 'القنطاوي', 22.0, 40.0, true, 110),
        ('مطار المنستير', 'نابل', 90.0, 118.0, true, 120),
        ('وسط سوسة', 'الحمامات', 38.0, 62.0, true, 130),
        ('وسط سوسة', 'سوسة', 8.0, 35.0, true, 140),
        ('وسط سوسة', 'القنطاوي', 12.0, 38.0, true, 150),
        ('وسط سوسة', 'نابل', 76.0, 80.0, true, 160)
        """
    )


def downgrade() -> None:
    op.drop_index("ix_fare_routes_destination", table_name="fare_routes")
    op.drop_index("ix_fare_routes_start", table_name="fare_routes")
    op.drop_table("fare_routes")
