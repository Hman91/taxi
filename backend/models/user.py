from __future__ import annotations

from sqlalchemy import Boolean, DateTime, String, func, true

from ..extensions import db


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    email = db.Column(db.String(320), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(32), nullable=False)
    display_name = db.Column(db.String(255), nullable=False, server_default="")
    phone = db.Column(db.String(32), nullable=True)
    photo_url = db.Column(db.Text, nullable=True)
    preferred_language = db.Column(String(10), nullable=False, server_default="en")
    is_enabled = db.Column(Boolean, nullable=False, server_default=true())
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())
