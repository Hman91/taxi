"""User registration and password login (business logic)."""
from __future__ import annotations

from typing import Any, Dict, Optional, Tuple

from werkzeug.security import check_password_hash, generate_password_hash

from .. import db as db_module
from ..extensions import db
from ..models import User


def register(email: str, password: str, role: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    if role not in ("user", "driver"):
        return None, "invalid_role"
    if not email or not password:
        return None, "missing_fields"
    if db_module.user_by_email(email):
        return None, "email_taken"
    pw_hash = generate_password_hash(password)
    uid = db_module.user_create(email=email, password_hash=pw_hash, role=role)
    if role == "driver":
        db_module.driver_create(
            user_id=uid,
            display_name=email.split("@", 1)[0],
            vehicle_info="",
        )
    row = db_module.user_by_id(uid)
    assert row is not None
    return {
        "id": row["id"],
        "email": row["email"],
        "role": row["role"],
        "preferred_language": row["preferred_language"],
        "is_enabled": row["is_enabled"],
    }, None


def authenticate(email: str, password: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    row = db_module.user_by_email(email)
    if row is None or not check_password_hash(row["password_hash"], password):
        return None, "invalid_credentials"
    if not row.get("is_enabled", True):
        return None, "account_disabled"
    return {
        "id": row["id"],
        "email": row["email"],
        "role": row["role"],
        "preferred_language": row["preferred_language"],
        "is_enabled": row["is_enabled"],
    }, None


def set_preferred_language(user_id: int, language: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    raw = (language or "").strip()
    if not raw or len(raw) > 10:
        return None, "invalid_language"
    u = db.session.get(User, user_id)
    if u is None:
        return None, "not_found"
    u.preferred_language = raw
    db.session.commit()
    out = db_module.user_by_id(user_id)
    assert out is not None
    return out, None
