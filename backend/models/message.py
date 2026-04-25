from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import relationship

from ..extensions import db


class Message(db.Model):
    """Chat line: store original text only (translations live in `translations`)."""

    __tablename__ = "messages"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    conversation_id = db.Column(
        BigInteger, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False
    )
    sender_user_id = db.Column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    original_text = db.Column(Text, nullable=False)
    original_language = db.Column(String(10), nullable=False)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())

    conversation = relationship("Conversation", back_populates="messages")
    sender = relationship("User", backref=db.backref("sent_messages", lazy="dynamic"))
