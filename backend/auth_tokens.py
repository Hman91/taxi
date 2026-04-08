"""Signed bearer tokens for API roles (dev-friendly; use proper auth in production)."""
from __future__ import annotations

from typing import Optional

from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer

from flask import current_app


def _serializer() -> URLSafeTimedSerializer:
    return URLSafeTimedSerializer(
        secret_key=current_app.config["SECRET_KEY"],
        salt="taxi-pro-v1",
    )


def issue_token(role: str) -> str:
    return _serializer().dumps({"role": role})


def verify_token(token: str) -> str:
    max_age = current_app.config["TOKEN_MAX_AGE_SECONDS"]
    data = _serializer().loads(token, max_age=max_age)
    return str(data["role"])


def verify_token_safe(token: str) -> Optional[str]:
    try:
        return verify_token(token)
    except (BadSignature, SignatureExpired, KeyError, TypeError):
        return None
