from __future__ import annotations

from sqlalchemy import DateTime, Integer, func

from ..extensions import db


class Rating(db.Model):
    __tablename__ = "ratings"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    stars = db.Column(Integer, nullable=False)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())
