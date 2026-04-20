from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, Float, ForeignKey, String, Text, func

from ..extensions import db


class B2BBooking(db.Model):
    """B2B guest booking requests persisted for operations/audit."""

    __tablename__ = "b2b_bookings"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    tenant_id = db.Column(BigInteger, ForeignKey("b2b_tenants.id", ondelete="SET NULL"), nullable=True, index=True)
    route = db.Column(Text, nullable=False)
    pickup = db.Column(Text, nullable=False)
    destination = db.Column(Text, nullable=False)
    guest_name = db.Column(Text, nullable=False)
    room_number = db.Column(String(64), nullable=True)
    fare = db.Column(Float, nullable=False)
    status = db.Column(String(32), nullable=False, default="pending")
    source_code = db.Column(String(255), nullable=False)
    ride_id = db.Column(BigInteger, ForeignKey("rides.id", ondelete="SET NULL"), nullable=True, index=True)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now(), nullable=True)
