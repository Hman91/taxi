"""App-user ride API (JWT with uid). Legacy code-login tokens are not accepted here."""
from __future__ import annotations

from functools import wraps
from typing import Any, Callable, Optional, Tuple, TypeVar

from flask import Blueprint, jsonify, request

from ..auth_tokens import current_jwt_user_id, verify_token_safe
from ..services import rides as rides_service

bp = Blueprint("rides_api", __name__, url_prefix="/api/rides")

F = TypeVar("F", bound=Callable[..., Any])


def _bearer_token() -> Optional[str]:
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:].strip()
    return None


def require_jwt_with_uid(*allowed_roles: str) -> Callable[[F], F]:
    def decorator(fn: F) -> F:
        @wraps(fn)
        def wrapped(*args: Any, **kwargs: Any) -> Any:
            token = _bearer_token()
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


@bp.get("")
@require_jwt_with_uid("user", "driver")
def list_rides(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    role = kwargs["_role"]
    data = rides_service.list_for_app_user(uid, role)
    return jsonify({"rides": data}), 200


@bp.post("")
@require_jwt_with_uid("user")
def create_ride(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    body = request.get_json(silent=True) or {}
    pickup = (body.get("pickup") or "").strip()
    destination = (body.get("destination") or "").strip()
    ride, err = rides_service.request_ride(uid, pickup, destination)
    if err:
        code = 400 if err != "active_ride_exists" else 409
        return jsonify({"error": err}), code
    return jsonify({"ride": ride}), 201


@bp.post("/<int:ride_id>/accept")
@require_jwt_with_uid("driver")
def accept(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    ride, err = rides_service.accept_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/reject")
@require_jwt_with_uid("driver")
def reject(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    ride, err = rides_service.reject_or_release(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/start")
@require_jwt_with_uid("driver")
def start(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    ride, err = rides_service.start_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/complete")
@require_jwt_with_uid("driver")
def complete(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    ride, err = rides_service.complete_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/cancel")
@require_jwt_with_uid("user")
def cancel(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    ride, err = rides_service.cancel_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200
