from __future__ import annotations

from sqlalchemy import Boolean, Float, Integer, Text, UniqueConstraint, true

from ..extensions import db


class FareRoute(db.Model):
    """Airport/intercity fixed fare route used by passenger and B2B flows."""

    __tablename__ = "fare_routes"
    __table_args__ = (
        UniqueConstraint("start", "destination", name="uq_fare_routes_start_destination"),
    )

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    start = db.Column(Text, nullable=False, index=True)
    destination = db.Column(Text, nullable=False, index=True)
    distance_km = db.Column(Float, nullable=False, default=0.0)
    base_fare = db.Column(Float, nullable=False)
    is_enabled = db.Column(Boolean, nullable=False, server_default=true())
    sort_order = db.Column(Integer, nullable=False, default=0)
