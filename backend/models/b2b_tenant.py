from __future__ import annotations

from sqlalchemy import Boolean, String, Text, true

from ..extensions import db


class B2BTenant(db.Model):
    """B2B partner tenant; enable/disable independent of app users."""

    __tablename__ = "b2b_tenants"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    code = db.Column(db.String(255), unique=True, nullable=False, index=True)
    label = db.Column(Text, nullable=True)
    is_enabled = db.Column(Boolean, nullable=False, server_default=true())
