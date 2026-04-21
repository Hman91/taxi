"""User registration and password login (business logic)."""
from __future__ import annotations

import json
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import urlopen
from typing import Any, Dict, Optional, Tuple

from flask import current_app
from werkzeug.security import check_password_hash, generate_password_hash

from .. import db as db_module
from ..extensions import db
from ..models import User

try:
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token as google_id_token
except Exception:  # pragma: no cover - optional dependency for local/dev
    google_requests = None
    google_id_token = None


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


def _upsert_google_user(email: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    row = db_module.user_by_email(email)
    if row is None:
        uid = db_module.user_create(
            email=email,
            password_hash=generate_password_hash(f"google::{email}"),
            role="user",
        )
        row = db_module.user_by_id(uid)
    if row is None:
        return None, "server_error"
    if row.get("role") != "user":
        return None, "invalid_role"
    if not row.get("is_enabled", True):
        return None, "account_disabled"
    return {
        "id": row["id"],
        "email": row["email"],
        "role": row["role"],
        "preferred_language": row["preferred_language"],
        "is_enabled": row["is_enabled"],
    }, None


def authenticate_google_id_token(id_token: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    token = (id_token or "").strip()
    if not token:
        return None, "missing_google_id_token"
    if google_id_token is None or google_requests is None:
        return None, "google_auth_not_configured"
    audience = (current_app.config.get("GOOGLE_OAUTH_CLIENT_ID") or "").strip()
    if not audience:
        return None, "google_auth_not_configured"
    try:
        info = google_id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            audience=audience,
        )
    except Exception:
        # Fallback for web environments where local verification can fail
        # (clock skew / cert fetch / transient issuer checks).
        qs = urlencode({"id_token": token})
        url = f"https://oauth2.googleapis.com/tokeninfo?{qs}"
        try:
            with urlopen(url, timeout=8) as res:  # nosec B310: fixed Google endpoint
                info = json.loads(res.read().decode("utf-8"))
        except (URLError, TimeoutError, ValueError, OSError):
            return None, "invalid_google_token"
        aud = str(info.get("aud") or "").strip()
        azp = str(info.get("azp") or "").strip()
        iss = str(info.get("iss") or "").strip().lower()
        if aud and aud != audience and azp and azp != audience:
            return None, "invalid_google_token"
        if iss and iss not in ("accounts.google.com", "https://accounts.google.com"):
            return None, "invalid_google_token"
    email = str(info.get("email") or "").strip().lower()
    email_verified = bool(info.get("email_verified", False))
    if not email_verified:
        # tokeninfo returns "true"/"false" as strings
        email_verified = str(info.get("email_verified") or "").strip().lower() == "true"
    if not email or not email_verified:
        return None, "google_email_not_verified"
    return _upsert_google_user(email)


def authenticate_google_access_token(access_token: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    token = (access_token or "").strip()
    if not token:
        return None, "missing_google_access_token"
    audience = (current_app.config.get("GOOGLE_OAUTH_CLIENT_ID") or "").strip()
    if not audience:
        return None, "google_auth_not_configured"
    qs = urlencode({"access_token": token})
    url = f"https://www.googleapis.com/oauth2/v3/tokeninfo?{qs}"
    try:
        with urlopen(url, timeout=8) as res:  # nosec B310: fixed Google endpoint
            payload = json.loads(res.read().decode("utf-8"))
    except (URLError, TimeoutError, ValueError, OSError):
        return None, "invalid_google_token"
    aud = str(payload.get("aud") or "").strip()
    azp = str(payload.get("azp") or "").strip()
    email = str(payload.get("email") or "").strip().lower()
    email_verified = str(payload.get("email_verified") or "").strip().lower() == "true"
    if aud and aud != audience and azp and azp != audience:
        return None, "invalid_google_token"
    if not email or not email_verified:
        return None, "google_email_not_verified"
    return _upsert_google_user(email)
