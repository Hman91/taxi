"""Link ratings to rides and drivers.

Revision ID: 007_ride_rating_links
Revises: 006_ride_dispatch_candidates
Create Date: 2026-04-21
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "007_ride_rating_links"
down_revision = "006_ride_dispatch_candidates"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("ratings", sa.Column("ride_id", sa.BigInteger(), nullable=True))
    op.add_column("ratings", sa.Column("driver_id", sa.BigInteger(), nullable=True))
    op.create_index("ix_ratings_ride_id", "ratings", ["ride_id"], unique=False)
    op.create_index("ix_ratings_driver_id", "ratings", ["driver_id"], unique=False)
    op.create_foreign_key(
        "fk_ratings_ride_id",
        "ratings",
        "rides",
        ["ride_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_ratings_driver_id",
        "ratings",
        "drivers",
        ["driver_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.execute("DELETE FROM ratings WHERE ride_id IS NULL OR driver_id IS NULL")
    op.alter_column("ratings", "ride_id", nullable=False)
    op.alter_column("ratings", "driver_id", nullable=False)


def downgrade() -> None:
    op.drop_constraint("fk_ratings_driver_id", "ratings", type_="foreignkey")
    op.drop_constraint("fk_ratings_ride_id", "ratings", type_="foreignkey")
    op.drop_index("ix_ratings_driver_id", table_name="ratings")
    op.drop_index("ix_ratings_ride_id", table_name="ratings")
    op.drop_column("ratings", "driver_id")
    op.drop_column("ratings", "ride_id")
