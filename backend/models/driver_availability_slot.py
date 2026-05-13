from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, func
from sqlalchemy.orm import relationship

from ..extensions import db


class DriverAvailabilitySlot(db.Model):
    """Future window where a driver is willing to accept scheduled rides."""

    __tablename__ = "driver_availability_slots"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    driver_id = db.Column(
        BigInteger, ForeignKey("drivers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    starts_at = db.Column(DateTime(timezone=True), nullable=False, index=True)
    ends_at = db.Column(DateTime(timezone=True), nullable=False, index=True)
    status = db.Column(String(24), nullable=False, default="open", server_default="open")
    created_at = db.Column(DateTime(timezone=True), server_default=func.now(), nullable=True)

    driver = relationship("Driver", foreign_keys=[driver_id])
