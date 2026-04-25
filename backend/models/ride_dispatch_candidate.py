from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, UniqueConstraint, func

from ..extensions import db


class RideDispatchCandidate(db.Model):
    """Drivers selected for a pending ride dispatch wave."""

    __tablename__ = "ride_dispatch_candidates"
    __table_args__ = (
        UniqueConstraint("ride_id", "driver_user_id", name="uq_ride_candidate_driver"),
    )

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    ride_id = db.Column(
        BigInteger, ForeignKey("rides.id", ondelete="CASCADE"), nullable=False, index=True
    )
    driver_user_id = db.Column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    rank = db.Column(Integer, nullable=False, default=0)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now(), nullable=True)
