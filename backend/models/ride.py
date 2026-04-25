from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, Text, func
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
