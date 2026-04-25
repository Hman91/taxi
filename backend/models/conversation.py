from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship

from ..extensions import db


class Conversation(db.Model):
    """One chat thread per ride (passenger ↔ driver)."""

    __tablename__ = "conversations"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    ride_id = db.Column(
        BigInteger, ForeignKey("rides.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())

    ride = relationship("Ride", back_populates="conversation")
    messages = relationship(
        "Message",
        back_populates="conversation",
        order_by="Message.id",
        cascade="all, delete-orphan",
    )
