"""User registration and password login (business logic)."""
from __future__ import annotations

import json
import hashlib
import secrets
import smtplib
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import urlopen
from typing import Any, Dict, Optional, Tuple

from flask import current_app
from sqlalchemy import select
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


def register(
    email: str,
    password: str,
    role: str,
    *,
    display_name: str = "",
    phone: str = "",
    photo_url: str = "",
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    if role not in ("user", "driver"):
        return None, "invalid_role"
    if not email or not password:
        return None, "missing_fields"
    if role == "user" and not phone.strip():
        return None, "phone_required"
    if db_module.user_by_email(email):
        return None, "email_taken"
    pw_hash = generate_password_hash(password)
    uid = db_module.user_create(
        email=email,
        password_hash=pw_hash,
        role=role,
        display_name=display_name.strip() if role == "user" else "",
        phone=phone.strip() if role == "user" else "",
        photo_url=photo_url.strip() if role == "user" else "",
    )
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
        "display_name": row.get("display_name"),
        "phone": row.get("phone"),
        "photo_url": row.get("photo_url"),
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
        "display_name": row.get("display_name"),
        "phone": row.get("phone"),
        "photo_url": row.get("photo_url"),
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


def set_phone(user_id: int, phone: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    raw = (phone or "").strip()
    if not raw:
        return None, "phone_required"
    u = db.session.get(User, user_id)
    if u is None:
        return None, "not_found"
    u.phone = raw
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
        "display_name": row.get("display_name"),
        "phone": row.get("phone"),
        "photo_url": row.get("photo_url"),
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


def _reset_token_hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _send_password_reset_email(email: str, token: str) -> bool:
    host = (current_app.config.get("SMTP_HOST") or "").strip()
    from_email = (current_app.config.get("SMTP_FROM_EMAIL") or "").strip()
    if not host or not from_email:
        return False
    port = int(current_app.config.get("SMTP_PORT") or 587)
    username = (current_app.config.get("SMTP_USERNAME") or "").strip()
    password = str(current_app.config.get("SMTP_PASSWORD") or "")
    use_tls = bool(current_app.config.get("SMTP_USE_TLS", True))

    msg = EmailMessage()
    msg["Subject"] = "Taxi App password reset code"
    msg["From"] = from_email
    msg["To"] = email
    msg.set_content(
        "\n".join(
            [
                "You requested a password reset.",
                f"Your reset code is: {token}",
                "This code expires in 20 minutes.",
                "If you did not request this, ignore this email.",
            ]
        )
    )
    try:
        with smtplib.SMTP(host, port, timeout=10) as server:
            if use_tls:
                server.starttls()
            if username:
                server.login(username, password)
            server.send_message(msg)
        return True
    except Exception:
        current_app.logger.exception("password_reset_email_failed email=%s", email)
        return False


def request_password_reset(email: str) -> Tuple[Dict[str, Any], Optional[str]]:
    """Generate a reset token for user/driver accounts.

    Response is intentionally generic to avoid user enumeration.
    """
    email_n = (email or "").strip().lower()
    generic = {"ok": True}
    if not email_n:
        return generic, None
    u = db.session.scalars(select(User).where(User.email == email_n)).first()
    if u is None or u.role not in ("user", "driver"):
        return generic, None
    token = secrets.token_urlsafe(8)[:8].upper()
    u.password_reset_token_hash = _reset_token_hash(token)
    u.password_reset_expires_at = datetime.now(timezone.utc) + timedelta(minutes=20)
    db.session.commit()
    out: Dict[str, Any] = {"ok": True}
    sent_email = _send_password_reset_email(email_n, token)
    out["email_sent"] = sent_email
    # Always log once for local testing/support.
    current_app.logger.info("password_reset_code email=%s code=%s", email_n, token)
    return out, None


def confirm_password_reset(
    email: str, reset_code: str, new_password: str
) -> Tuple[Dict[str, Any], Optional[str]]:
    email_n = (email or "").strip().lower()
    token = (reset_code or "").strip().upper()
    password = new_password or ""
    if not email_n or not token or not password:
        return {}, "missing_fields"
    if len(password) < 6:
        return {}, "weak_password"
    u = db.session.scalars(select(User).where(User.email == email_n)).first()
    if u is None:
        return {}, "invalid_reset_code"
    if not u.password_reset_token_hash or not u.password_reset_expires_at:
        return {}, "invalid_reset_code"
    if datetime.now(timezone.utc) > u.password_reset_expires_at:
        return {}, "reset_code_expired"
    if _reset_token_hash(token) != u.password_reset_token_hash:
        return {}, "invalid_reset_code"
    u.password_hash = generate_password_hash(password)
    u.password_reset_token_hash = None
    u.password_reset_expires_at = None
    db.session.commit()
    return {"ok": True}, None
