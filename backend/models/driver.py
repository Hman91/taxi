from __future__ import annotations

from sqlalchemy import BigInteger, Boolean, DateTime, Float, ForeignKey, String, Text, func
from sqlalchemy.orm import relationship

from ..extensions import db


class Driver(db.Model):
    __tablename__ = "drivers"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    user_id = db.Column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    display_name = db.Column(db.String(255), nullable=False, default="")
    vehicle_info = db.Column(Text, nullable=True)
    is_available = db.Column(Boolean, nullable=False, default=True)
    last_lat = db.Column(Float, nullable=True)
    last_lng = db.Column(Float, nullable=True)
    last_seen_at = db.Column(DateTime(timezone=True), nullable=True)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", backref=db.backref("driver_profile", uselist=False))
