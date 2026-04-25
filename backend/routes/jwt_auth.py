"""Shared JWT (Bearer + uid) guards for app-user API blueprints."""
from __future__ import annotations

from functools import wraps
from typing import Any, Callable, Optional, Tuple, TypeVar

from flask import jsonify, request

from ..auth_tokens import current_jwt_user_id, verify_token_safe

F = TypeVar("F", bound=Callable[..., Any])


def bearer_token() -> Optional[str]:
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:].strip()
    return None


def require_jwt_with_uid(*allowed_roles: str) -> Callable[[F], F]:
    def decorator(fn: F) -> F:
        @wraps(fn)
        def wrapped(*args: Any, **kwargs: Any) -> Any:
            token = bearer_token()
            if not token:
                return jsonify({"error": "missing_token"}), 401
            role = verify_token_safe(token)
            if role is None:
                return jsonify({"error": "invalid_token"}), 401
            if role not in allowed_roles:
                return jsonify({"error": "forbidden"}), 403
            uid = current_jwt_user_id()
            if uid is None:
                return jsonify({"error": "app_user_token_required"}), 403
            kwargs["_uid"] = uid
            kwargs["_role"] = role
            return fn(*args, **kwargs)

        return wrapped  # type: ignore[return-value]

    return decorator


def json_error(code: str, status: int) -> Tuple[Any, int]:
    return jsonify({"error": code}), status
