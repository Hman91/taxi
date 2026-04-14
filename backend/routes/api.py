"""REST API for Taxi Pro."""
from __future__ import annotations

from datetime import datetime
from functools import wraps
from typing import Any, Callable, Optional, Tuple, TypeVar

from flask import Blueprint, current_app, jsonify, request

from .. import db as db_module
from ..auth_tokens import issue_token, verify_token_safe
from ..services import pricing
from ..services import users as users_service

bp = Blueprint("api", __name__, url_prefix="/api")

F = TypeVar("F", bound=Callable[..., Any])

# Legacy Streamlit driver credentials (phone + PIN) for ops/demo flow.
_DRIVER_PIN_DB = {
    "98123456": {"name": "خليل (سائق 1)", "pin": "1234"},
    "50111222": {"name": "أحمد (سائق 2)", "pin": "0000"},
}


def _bearer_token() -> Optional[str]:
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:].strip()
    return None


def require_roles(*allowed: str) -> Callable[[F], F]:
    def decorator(fn: F) -> F:
        @wraps(fn)
        def wrapped(*args: Any, **kwargs: Any) -> Any:
            token = _bearer_token()
            if not token:
                return jsonify({"error": "missing_token"}), 401
            role = verify_token_safe(token)
            if role is None:
                return jsonify({"error": "invalid_token"}), 401
            if role not in allowed:
                return jsonify({"error": "forbidden"}), 403
            kwargs["_role"] = role
            return fn(*args, **kwargs)

        return wrapped  # type: ignore[return-value]

    return decorator


@bp.get("/health")
def health() -> Tuple[Any, int]:
    return jsonify({"status": "ok", "service": "taxi-pro-api"}), 200


@bp.get("/fares/airport")
def airport_fares() -> Tuple[Any, int]:
    return jsonify({"fares": pricing.FARES_DB}), 200


@bp.post("/fares/quote")
def quote_fare() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    mode = data.get("mode", "airport")
    if mode == "airport":
        route_key = data.get("route_key")
        if not route_key or route_key not in pricing.FARES_DB:
            return jsonify({"error": "invalid_route_key"}), 400
        base = pricing.FARES_DB[route_key]
        final, is_night = pricing.calculate_fare(base)
        return (
            jsonify(
                {
                    "mode": "airport",
                    "route_key": route_key,
                    "base_fare": base,
                    "final_fare": round(final, 3),
                    "is_night": is_night,
                }
            ),
            200,
        )
    if mode == "gps":
        dist = data.get("distance_km")
        if dist is None:
            dist = pricing.random_stub_distance_km()
        else:
            try:
                dist = float(dist)
            except (TypeError, ValueError):
                return jsonify({"error": "invalid_distance"}), 400
        final, is_night = pricing.calculate_gps_fare(dist)
        return (
            jsonify(
                {
                    "mode": "gps",
                    "distance_km": dist,
                    "final_fare": round(final, 3),
                    "is_night": is_night,
                }
            ),
            200,
        )
    return jsonify({"error": "invalid_mode"}), 400


@bp.post("/auth/login")
def login() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    role = (data.get("role") or "").strip().lower()
    secret = data.get("secret") or data.get("password") or ""

    checks = {
        "owner": current_app.config["OWNER_PASSWORD"],
        "driver": current_app.config["DRIVER_CODE"],
        "b2b": current_app.config["B2B_CODE"],
        "operator": current_app.config["OPERATOR_CODE"],
    }
    if role not in checks:
        return jsonify({"error": "invalid_role"}), 400
    if secret != checks[role]:
        return jsonify({"error": "invalid_credentials"}), 401

    token = issue_token(role)
    return jsonify({"access_token": token, "token_type": "Bearer", "role": role}), 200


@bp.post("/auth/login-driver-pin")
def login_driver_pin() -> Tuple[Any, int]:
    """Legacy-compatible driver login using phone + PIN."""
    data = request.get_json(silent=True) or {}
    phone = (data.get("phone") or "").strip()
    pin = (data.get("pin") or "").strip()
    row = _DRIVER_PIN_DB.get(phone)
    if row is None or pin != row["pin"]:
        return jsonify({"error": "invalid_credentials"}), 401
    token = issue_token("driver")
    return (
        jsonify(
            {
                "access_token": token,
                "token_type": "Bearer",
                "role": "driver",
                "driver_name": row["name"],
                "phone": phone,
            }
        ),
        200,
    )


@bp.post("/auth/register")
def register() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    role = (data.get("role") or "user").strip().lower()
    user, err = users_service.register(email, password, role)
    if err:
        code = 409 if err == "email_taken" else 400
        return jsonify({"error": err}), code
    return jsonify({"user": user}), 201


@bp.post("/auth/login-app")
def login_app() -> Tuple[Any, int]:
    """JWT for mobile/web app users (`user` | `driver`) with `uid` in token."""
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    user, err = users_service.authenticate(email, password)
    if err:
        code = 403 if err == "account_disabled" else 401
        return jsonify({"error": err}), code
    token = issue_token(user["role"], user_id=int(user["id"]))
    return (
        jsonify(
            {
                "access_token": token,
                "token_type": "Bearer",
                "role": user["role"],
                "user_id": user["id"],
            }
        ),
        200,
    )


@bp.post("/trips")
@require_roles("driver")
def create_trip(**kwargs: Any) -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    route = (data.get("route") or "").strip()
    if not route:
        return jsonify({"error": "route_required"}), 400
    try:
        price = float(data.get("fare", data.get("price", 0)))
    except (TypeError, ValueError):
        return jsonify({"error": "invalid_fare"}), 400
    trip_type = (data.get("type") or "كاش / بطاقة").strip()
    comm = round(price * 0.10, 3)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    trip = db_module.insert_trip(
        date=now,
        driver="سائق نشط",
        route=route,
        fare=price,
        commission=comm,
        trip_type=trip_type,
        status="Done",
    )
    return jsonify({"trip": trip}), 201


@bp.get("/trips")
@require_roles("owner", "operator")
def list_trips(**kwargs: Any) -> Tuple[Any, int]:
    trips = db_module.list_trips()
    return jsonify({"trips": trips}), 200


@bp.get("/metrics/owner")
@require_roles("owner")
def owner_metrics(**kwargs: Any) -> Tuple[Any, int]:
    m = db_module.owner_metrics()
    return jsonify(m), 200


@bp.post("/ratings")
def add_rating() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    try:
        stars = int(data.get("stars", data.get("rating", 0)))
    except (TypeError, ValueError):
        return jsonify({"error": "invalid_stars"}), 400
    if stars < 1 or stars > 5:
        return jsonify({"error": "stars_out_of_range"}), 400
    db_module.insert_rating(stars)
    stats = db_module.rating_stats()
    return jsonify({"ok": True, "stats": stats}), 201
