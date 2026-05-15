from __future__ import annotations

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, func

from ..extensions import db


class RefreshToken(db.Model):
    __tablename__ = "refresh_tokens"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    user_id = db.Column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True
    )
    role = db.Column(String(32), nullable=False, index=True)
    token_hash = db.Column(String(64), nullable=False, unique=True, index=True)
    expires_at = db.Column(DateTime(timezone=True), nullable=False)
    revoked_at = db.Column(DateTime(timezone=True), nullable=True)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())
