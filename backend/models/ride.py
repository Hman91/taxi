from __future__ import annotations

from sqlalchemy import BigInteger, Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import relationship

from ..extensions import db


class Ride(db.Model):
    __tablename__ = "rides"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    user_id = db.Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    driver_id = db.Column(
        BigInteger, ForeignKey("drivers.id", ondelete="SET NULL"), nullable=True, index=True
    )
    status = db.Column(db.String(32), nullable=False)
    pickup = db.Column(Text, nullable=False)
    destination = db.Column(Text, nullable=False)
    pickup_address = db.Column(Text, nullable=True)
    pickup_display_name = db.Column(Text, nullable=True)
    destination_address = db.Column(Text, nullable=True)
    destination_display_name = db.Column(Text, nullable=True)
    pickup_lat = db.Column(db.Float, nullable=True)
    pickup_lng = db.Column(db.Float, nullable=True)
    destination_lat = db.Column(db.Float, nullable=True)
    destination_lng = db.Column(db.Float, nullable=True)
    quoted_distance_km = db.Column(db.Float, nullable=True)
    quoted_duration_seconds = db.Column(db.Integer, nullable=True)
    quoted_fare_dt = db.Column(db.Float, nullable=True)
    quoted_base_fare_dt = db.Column(db.Float, nullable=True)
    quoted_night_surcharge_dt = db.Column(db.Float, nullable=True)
    quoted_is_night = db.Column(db.Boolean, nullable=True)
    scheduled_pickup_at = db.Column(DateTime(timezone=True), nullable=True, index=True)
    reservation_status = db.Column(String(32), nullable=True, index=True)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())
    updated_at = db.Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", foreign_keys=[user_id])
    driver = relationship("Driver", foreign_keys=[driver_id])
    conversation = relationship(
        "Conversation",
        back_populates="ride",
        uselist=False,
        cascade="all, delete-orphan",
    )
