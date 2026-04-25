from __future__ import annotations

from sqlalchemy import Boolean, Float, String, Text, true

from ..extensions import db


class DriverPinAccount(db.Model):
    """Legacy/demo driver login account for phone+PIN auth."""

    __tablename__ = "driver_pin_accounts"

    id = db.Column(db.BigInteger, primary_key=True, autoincrement=True)
    phone = db.Column(String(32), unique=True, nullable=False, index=True)
    pin = db.Column(String(32), nullable=False)
    driver_name = db.Column(Text, nullable=False)
    wallet_balance = db.Column(Float, nullable=False, default=0.0)
    owner_commission_rate = db.Column(Float, nullable=False, default=10.0)
    b2b_commission_rate = db.Column(Float, nullable=False, default=5.0)
    auto_deduct_enabled = db.Column(Boolean, nullable=False, server_default=true())
    photo_url = db.Column(Text, nullable=True)
    car_model = db.Column(Text, nullable=True)
    car_color = db.Column(Text, nullable=True)
    current_zone = db.Column(Text, nullable=True)
