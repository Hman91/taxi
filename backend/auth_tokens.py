"""Signed bearer tokens for API roles and app users (dev-friendly; harden for production)."""
from __future__ import annotations

from typing import Any, Dict, Optional

from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer

from flask import current_app, g, has_request_context


def _serializer() -> URLSafeTimedSerializer:
    return URLSafeTimedSerializer(
        secret_key=current_app.config["SECRET_KEY"],
        salt="taxi-pro-v1",
    )


def issue_token(role: str, user_id: int | None = None) -> str:
    payload: Dict[str, Any] = {"role": role}
    if user_id is not None:
        payload["uid"] = int(user_id)
    return _serializer().dumps(payload)


def verify_token(token: str) -> str:
    max_age = current_app.config["TOKEN_MAX_AGE_SECONDS"]
    data = _serializer().loads(token, max_age=max_age)
    return str(data["role"])


def verify_token_safe(token: str) -> Optional[str]:
    if has_request_context():
        g.jwt_user_id = None  # type: ignore[attr-defined]
    try:
        max_age = current_app.config["TOKEN_MAX_AGE_SECONDS"]
        data = _serializer().loads(token, max_age=max_age)
    except (BadSignature, SignatureExpired, KeyError, TypeError):
        return None
    role = str(data["role"])
    if has_request_context() and data.get("uid") is not None:
        try:
            g.jwt_user_id = int(data["uid"])  # type: ignore[attr-defined]
        except (TypeError, ValueError):
            g.jwt_user_id = None  # type: ignore[attr-defined]
    return role


def current_jwt_user_id() -> Optional[int]:
    if not has_request_context():
        return None
    uid = getattr(g, "jwt_user_id", None)
    return int(uid) if uid is not None else None


def decode_app_token(token: str) -> tuple[Optional[int], Optional[str]]:
    """Parse a Bearer-style app token into (user_id, role), or (None, None) if invalid or missing uid."""
    try:
        max_age = current_app.config["TOKEN_MAX_AGE_SECONDS"]
        data = _serializer().loads(token, max_age=max_age)
        role = str(data.get("role", ""))
        uid_raw = data.get("uid")
        if uid_raw is None:
            return None, None
        return int(uid_raw), role
    except (BadSignature, SignatureExpired, KeyError, TypeError, ValueError):
        return None, None
