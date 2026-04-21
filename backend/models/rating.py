from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, func

from ..extensions import db


class Rating(db.Model):
    __tablename__ = "ratings"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    ride_id = db.Column(
        BigInteger, ForeignKey("rides.id", ondelete="CASCADE"), nullable=False, index=True
    )
    driver_id = db.Column(
        BigInteger, ForeignKey("drivers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    stars = db.Column(Integer, nullable=False)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())
