from __future__ import annotations

from sqlalchemy import DateTime, Float, String, Text, func

from ..extensions import db


class Trip(db.Model):
    __tablename__ = "trips"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    date = db.Column(db.String(64), nullable=False)
    driver = db.Column(db.String(255), nullable=False)
    route = db.Column(Text, nullable=False)
    fare = db.Column(db.Float, nullable=False)
    commission = db.Column(db.Float, nullable=False)
    type = db.Column(db.String(128), nullable=False)
    status = db.Column(db.String(64), nullable=False)
    created_at = db.Column(DateTime(timezone=True), server_default=func.now())
