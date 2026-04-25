"""REST API for Taxi Pro."""
from __future__ import annotations

from datetime import datetime
from functools import wraps
from typing import Any, Callable, Optional, Tuple, TypeVar

from flask import Blueprint, current_app, jsonify, request
from werkzeug.security import generate_password_hash

from .. import db as db_module
from ..auth_tokens import issue_token, verify_token_safe
from ..services import pricing
from ..services import rides as rides_service
from ..services import users as users_service
from .jwt_auth import require_jwt_with_uid

bp = Blueprint("api", __name__, url_prefix="/api")

F = TypeVar("F", bound=Callable[..., Any])

_DRIVER_PIN_DEFAULTS = [
    {"phone": "98123456", "pin": "1234", "driver_name": "خليل (سائق 1)"},
    {"phone": "50111222", "pin": "0000", "driver_name": "أحمد (سائق 2)"},
]

_B2B_TENANT_DEFAULTS = [
    {"code": "Biz2026", "label": "Default B2B Tenant", "is_enabled": True},
]


def _ensure_b2b_operator_user(source_code: str) -> int:
    code = (source_code or "b2b").strip().lower()
    email = f"b2b_operator_{code}@taxipro.local"
    row = db_module.user_by_email(email)
    if row is not None:
        return int(row["id"])
    uid = db_module.user_create(
        email=email,
        password_hash=generate_password_hash(f"b2b::{code}"),
        role="user",
    )
    return int(uid)


def _preferred_language_for_uid(uid: int) -> str:
    row = db_module.user_by_id(uid)
    if not row:
        return "en"
    raw = str(row.get("preferred_language") or "en").strip()
    return raw if raw else "en"


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
    return jsonify({"fares": pricing.get_airport_fares()}), 200


@bp.post("/fares/quote")
def quote_fare() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    mode = data.get("mode", "airport")
    if mode == "airport":
        route_key = data.get("route_key")
        route = pricing.get_airport_route(route_key or "")
        if not route:
            return jsonify({"error": "invalid_route_key"}), 400
        base = float(route["base_fare"])
        final, is_night = pricing.calculate_fare(base)
        return (
            jsonify(
                {
                    "mode": "airport",
                    "route_key": route_key,
                    "start": route["start"],
                    "destination": route["destination"],
                    "distance_km": route["distance_km"],
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

    db_module.b2b_tenant_seed_defaults(_B2B_TENANT_DEFAULTS)
    checks = {
        "owner": current_app.config["OWNER_PASSWORD"],
        "driver": current_app.config["DRIVER_CODE"],
        "operator": current_app.config["OPERATOR_CODE"],
    }
    if role not in (set(checks.keys()) | {"b2b"}):
        return jsonify({"error": "invalid_role"}), 400
    if role == "b2b":
        tenant = db_module.b2b_tenant_by_code(secret)
        if tenant is None or not tenant.get("is_enabled", False):
            return jsonify({"error": "invalid_credentials"}), 401
        b2b_uid = _ensure_b2b_operator_user(secret)
        app_token = issue_token("user", user_id=b2b_uid)
    else:
        if secret != checks[role]:
            return jsonify({"error": "invalid_credentials"}), 401

    token = issue_token(role)
    out = {"access_token": token, "token_type": "Bearer", "role": role}
    if role == "b2b":
        out["app_access_token"] = app_token
        out["app_role"] = "user"
        out["user_id"] = b2b_uid
    return jsonify(out), 200


@bp.post("/auth/login-driver-pin")
def login_driver_pin() -> Tuple[Any, int]:
    """Driver login using phone + PIN from PostgreSQL table."""
    db_module.driver_pin_seed_defaults(_DRIVER_PIN_DEFAULTS)
    data = request.get_json(silent=True) or {}
    phone = (data.get("phone") or "").strip()
    pin = (data.get("pin") or "").strip()
    row = db_module.driver_pin_by_phone(phone)
    if row is None or pin != row["pin"]:
        return jsonify({"error": "invalid_credentials"}), 401
    # Bridge PIN-only driver accounts to app JWT flow (/api/rides requires uid).
    synthetic_email = f"driverpin_{phone}@taxipro.local"
    app_user = db_module.user_by_email(synthetic_email)
    if app_user is None:
        uid = db_module.user_create(
            email=synthetic_email,
            password_hash=generate_password_hash(f"pin::{phone}"),
            role="driver",
        )
    else:
        uid = int(app_user["id"])
    if db_module.driver_by_user_id(uid) is None:
        db_module.driver_create(
            user_id=uid,
            display_name=row.get("driver_name") or f"Driver {phone}",
            vehicle_info="",
        )
    driver_row = db_module.driver_by_user_id(uid)
    db_module.driver_mark_online(uid)
    token = issue_token("driver", user_id=uid)
    return (
        jsonify(
            {
                "access_token": token,
                "token_type": "Bearer",
                "role": "driver",
                "user_id": uid,
                "driver_id": (driver_row or {}).get("id"),
                "driver_name": row["driver_name"],
                "phone": phone,
                "wallet_balance": row.get("wallet_balance", 0.0),
                "owner_commission_rate": row.get("owner_commission_rate", 10.0),
                "b2b_commission_rate": row.get("b2b_commission_rate", 5.0),
                "auto_deduct_enabled": row.get("auto_deduct_enabled", True),
                "photo_url": row.get("photo_url"),
                "car_model": row.get("car_model"),
                "car_color": row.get("car_color"),
                "current_zone": row.get("current_zone"),
                "preferred_language": _preferred_language_for_uid(uid),
            }
        ),
        200,
    )


@bp.post("/b2b/bookings")
@require_roles("b2b")
def create_b2b_booking(**kwargs: Any) -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    route = (data.get("route") or "").strip()
    guest_name = (data.get("guest_name") or "").strip()
    guest_phone = (data.get("guest_phone") or "").strip()
    hotel_name = (data.get("hotel_name") or "").strip()
    flight_eta = (data.get("flight_eta") or "").strip()
    room_number = (data.get("room_number") or "").strip()
    source_code = (data.get("source_code") or "").strip()
    try:
        fare = float(data.get("fare", 0.0))
    except (TypeError, ValueError):
        return jsonify({"error": "invalid_fare"}), 400
    if not route or not guest_name or fare < 0:
        return jsonify({"error": "missing_fields"}), 400
    parts = route.split("➡️")
    pickup = parts[0].strip() if parts else ""
    destination = parts[1].strip() if len(parts) > 1 else ""
    if not pickup or not destination:
        return jsonify({"error": "invalid_route"}), 400
    db_module.b2b_tenant_seed_defaults(_B2B_TENANT_DEFAULTS)
    tenant = db_module.b2b_tenant_by_code(source_code) if source_code else None
    if source_code and (tenant is None or not tenant.get("is_enabled", False)):
        return jsonify({"error": "invalid_source_code"}), 400
    room_compound = " | ".join(
        [
            f"Room: {room_number or '-'}",
            f"Hotel: {hotel_name or '-'}",
            f"Phone: {guest_phone or '-'}",
            f"Flight: {flight_eta or '-'}",
        ]
    )
    booking = db_module.b2b_booking_insert(
        tenant_id=int(tenant["id"]) if tenant else None,
        route=route,
        pickup=pickup,
        destination=destination,
        guest_name=guest_name,
        room_number=room_compound,
        fare=fare,
        status="pending",
        source_code=source_code or "b2b",
        ride_id=None,
    )
    b2b_user_id = _ensure_b2b_operator_user(source_code or "b2b")
    ride, err = rides_service.request_ride(
        b2b_user_id,
        pickup,
        destination,
        enforce_single_active=False,
    )
    if ride is not None:
        booking = db_module.b2b_booking_update(
            int(booking["id"]),
            ride_id=int(ride["id"]),
            status="requested",
        ) or booking
    return jsonify({"booking": booking, "ride": ride, "ride_error": err}), 201


@bp.post("/auth/register")
def register() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    role = (data.get("role") or "user").strip().lower()
    display_name = (data.get("display_name") or data.get("name") or "").strip()
    phone = (data.get("phone") or "").strip()
    photo_url = (data.get("photo_url") or data.get("image") or "").strip()
    user, err = users_service.register(
        email,
        password,
        role,
        display_name=display_name,
        phone=phone,
        photo_url=photo_url,
    )
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
    if user["role"] == "user" and not str(user.get("phone") or "").strip():
        return jsonify({"error": "phone_required"}), 400
    token = issue_token(user["role"], user_id=int(user["id"]))
    return (
        jsonify(
            {
                "access_token": token,
                "token_type": "Bearer",
                "role": user["role"],
                "user_id": user["id"],
                "display_name": user.get("display_name"),
                "phone": user.get("phone"),
                "photo_url": user.get("photo_url"),
                "preferred_language": str(user.get("preferred_language") or "en").strip()
                or "en",
            }
        ),
        200,
    )


@bp.post("/auth/login-google")
def login_google() -> Tuple[Any, int]:
    """Passenger Google sign-in using Google ID token or access token."""
    data = request.get_json(silent=True) or {}
    id_token = data.get("id_token") or ""
    access_token = data.get("access_token") or ""
    phone = (data.get("phone") or "").strip()
    if id_token:
        user, err = users_service.authenticate_google_id_token(id_token)
        # Flutter Web may return an unusable ID token while access token is valid.
        if err == "invalid_google_token" and access_token:
            user, err = users_service.authenticate_google_access_token(access_token)
    elif access_token:
        user, err = users_service.authenticate_google_access_token(access_token)
    else:
        user, err = None, "missing_google_token"
    if err:
        code = 403 if err == "account_disabled" else 401
        return jsonify({"error": err}), code
    if not str(user.get("phone") or "").strip():
        if not phone:
            return jsonify({"error": "phone_required"}), 400
        patched, perr = users_service.set_phone(int(user["id"]), phone)
        if perr:
            return jsonify({"error": perr}), 400
        user = patched
    token = issue_token(user["role"], user_id=int(user["id"]))
    return (
        jsonify(
            {
                "access_token": token,
                "token_type": "Bearer",
                "role": user["role"],
                "user_id": user["id"],
                "email": user["email"],
                "preferred_language": str(user.get("preferred_language") or "en").strip()
                or "en",
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
    trip_type = (data.get("type") or "Cash").strip()
    phone = (data.get("driver_phone") or "").strip()
    driver_account = db_module.driver_pin_by_phone(phone) if phone else None
    owner_rate = float(driver_account["owner_commission_rate"]) if driver_account else 10.0
    b2b_rate = float(driver_account["b2b_commission_rate"]) if driver_account else 5.0
    auto_deduct = bool(driver_account["auto_deduct_enabled"]) if driver_account else False
    is_b2b = "b2b" in trip_type.lower() or "hotel" in trip_type.lower() or "company" in trip_type.lower()
    applied_rate = b2b_rate if is_b2b else owner_rate
    comm = round(price * (applied_rate / 100.0), 3)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    wallet_after = None
    if driver_account and auto_deduct:
        wallet_after = float(driver_account["wallet_balance"]) - comm
        db_module.driver_pin_update(
            int(driver_account["id"]),
            wallet_balance=wallet_after,
        )
    trip = db_module.insert_trip(
        date=now,
        driver=(driver_account["driver_name"] if driver_account else "سائق نشط"),
        route=route,
        fare=price,
        commission=comm,
        trip_type=trip_type,
        status="Done",
    )
    return jsonify({"trip": trip, "commission_rate": applied_rate, "wallet_after": wallet_after}), 201


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
@require_jwt_with_uid("user")
def add_rating(**kwargs: Any) -> Tuple[Any, int]:
    uid = int(kwargs["_uid"])
    data = request.get_json(silent=True) or {}
    try:
        ride_id = int(data.get("ride_id", 0))
    except (TypeError, ValueError):
        return jsonify({"error": "invalid_ride_id"}), 400
    try:
        stars = int(data.get("stars", data.get("rating", 0)))
    except (TypeError, ValueError):
        return jsonify({"error": "invalid_stars"}), 400
    ride = db_module.ride_get(ride_id)
    if ride is None:
        return jsonify({"error": "ride_not_found"}), 404
    if int(ride.get("user_id") or 0) != uid:
        return jsonify({"error": "forbidden"}), 403
    if ride.get("status") != "completed":
        return jsonify({"error": "ride_not_completed"}), 400
    driver_id = ride.get("driver_id")
    if driver_id is None:
        return jsonify({"error": "ride_driver_missing"}), 400
    if db_module.rating_exists_for_ride(ride_id):
        return jsonify({"error": "rating_exists"}), 409
    if stars < 1 or stars > 5:
        return jsonify({"error": "stars_out_of_range"}), 400
    db_module.insert_rating(ride_id=ride_id, driver_id=int(driver_id), stars=stars)
    stats = db_module.rating_stats()
    driver_stats = db_module.rating_stats(driver_id=int(driver_id))
    return jsonify({"ok": True, "stats": stats, "driver_stats": driver_stats}), 201
