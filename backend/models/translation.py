from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, Text, UniqueConstraint, func
from sqlalchemy.orm import relationship

from ..extensions import db


class Translation(db.Model):
    """Cached per-recipient translation for a message (dedupe by message + target language)."""

    __tablename__ = "translations"
    __table_args__ = (
        UniqueConstraint(
            "message_id",
            "target_language",
            name="uq_translations_message_target",
        ),
    )

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    message_id = db.Column(
        BigInteger, ForeignKey("messages.id", ondelete="CASCADE"), nullable=False, index=True
    )
    target_language = db.Column(String(10), nullable=False)
    translated_text = db.Column(Text, nullable=False)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())

    message = relationship("Message", backref=db.backref("translation_cache", lazy="dynamic"))
