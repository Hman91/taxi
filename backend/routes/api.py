"""REST API for Taxi Pro."""
from __future__ import annotations

from datetime import datetime
from functools import wraps
import re
from typing import Any, Callable, Optional, Tuple, TypeVar

from flask import Blueprint, jsonify, request
from werkzeug.security import generate_password_hash
from .. import db as db_module
from ..auth_tokens import issue_token, verify_token_safe
from ..services import pricing
from ..services import rides as rides_service
from ..services import users as users_service
from .jwt_auth import require_jwt_with_uid

bp = Blueprint("api", __name__, url_prefix="/api")

F = TypeVar("F", bound=Callable[..., Any])

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
    return jsonify({"error": "deprecated_use_login_app"}), 410


@bp.post("/auth/login-driver-pin")
def login_driver_pin() -> Tuple[Any, int]:
    return jsonify({"error": "deprecated_use_login_app"}), 410


@bp.post("/b2b/bookings")
@require_jwt_with_uid("b2b")
def create_b2b_booking(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    data = request.get_json(silent=True) or {}
    route = (data.get("route") or "").strip()
    guest_name = (data.get("guest_name") or "").strip()
    guest_phone = (data.get("guest_phone") or "").strip()
    hotel_name = (data.get("hotel_name") or "").strip()
    flight_eta = (data.get("flight_eta") or "").strip()
    room_number = (data.get("room_number") or "").strip()
    source_code_input = (data.get("source_code") or "").strip()
    user = db_module.user_by_id(int(uid)) or {}
    email = str(user.get("email") or "").strip().lower()
    source_code_by_uid = email.split("@")[0].strip() if "@" in email else ""
    source_code = source_code_by_uid or source_code_input or "b2b"
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
    tenant = db_module.b2b_tenant_by_code(source_code) if source_code else None
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
    ride, err = rides_service.request_ride(
        int(uid),
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


@bp.get("/b2b/me")
@require_jwt_with_uid("b2b")
def b2b_me(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    user = db_module.user_by_id(int(uid))
    if user is None:
        return jsonify({"error": "not_found"}), 404
    email = str(user.get("email") or "").strip().lower()
    source_code = email.split("@")[0].strip() if "@" in email else ""
    tenant = db_module.b2b_tenant_by_code(source_code) if source_code else None
    return (
        jsonify(
            {
                "user": {
                    "id": user.get("id"),
                    "email": user.get("email"),
                    "display_name": user.get("display_name"),
                    "phone": user.get("phone"),
                    "source_code": source_code,
                },
                "tenant": tenant,
            }
        ),
        200,
    )


@bp.patch("/b2b/me")
@require_jwt_with_uid("b2b")
def b2b_me_patch(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    user = db_module.user_by_id(int(uid))
    if user is None:
        return jsonify({"error": "not_found"}), 404
    body = request.get_json(silent=True) or {}

    email = str(user.get("email") or "").strip().lower()
    source_code = email.split("@")[0].strip() if "@" in email else ""

    display_name = body.get("display_name")
    phone = body.get("phone")
    label = body.get("label")
    contact_name = body.get("contact_name")
    pin = body.get("pin")
    tenant_phone = body.get("tenant_phone")
    hotel = body.get("hotel")
    new_email = body.get("email")
    new_password = body.get("password")

    # Optional user profile patch (name/phone) without password change.
    if display_name is not None or phone is not None:
        u = db_module.db.session.get(db_module.User, int(uid))
        if u is None:
            return jsonify({"error": "not_found"}), 404
        if display_name is not None:
            u.display_name = str(display_name).strip() or None
        if phone is not None:
            u.phone = str(phone).strip() or None
        db_module.db.session.commit()

    # Optional account credentials patch (B2B self-service, no current password required).
    if new_email is not None or new_password is not None:
        u = db_module.db.session.get(db_module.User, int(uid))
        if u is None:
            return jsonify({"error": "not_found"}), 404
        if new_email is not None:
            email_norm = str(new_email).strip().lower()
            if not email_norm:
                return jsonify({"error": "invalid_email"}), 400
            existing = db_module.user_by_email(email_norm)
            if existing is not None and int(existing["id"]) != int(uid):
                return jsonify({"error": "email_taken"}), 409
            u.email = email_norm
        if new_password is not None:
            pw = str(new_password)
            if pw.strip() and len(pw) < 6:
                return jsonify({"error": "weak_password"}), 400
            if pw.strip():
                u.password_hash = generate_password_hash(pw.strip())
        db_module.db.session.commit()
        user = db_module.user_by_id(int(uid)) or user
        email = str(user.get("email") or "").strip().lower()
        source_code = email.split("@")[0].strip() if "@" in email else source_code

    tenant = db_module.b2b_tenant_update_by_code(
        source_code,
        label=str(label).strip() if label is not None else None,
        contact_name=str(contact_name).strip() if contact_name is not None else None,
        pin=str(pin).strip() if pin is not None else None,
        phone=str(tenant_phone).strip() if tenant_phone is not None else None,
        hotel=str(hotel).strip() if hotel is not None else None,
    ) or db_module.b2b_tenant_by_code(source_code)

    user = db_module.user_by_id(int(uid)) or user
    return (
        jsonify(
            {
                "user": {
                    "id": user.get("id"),
                    "email": user.get("email"),
                    "display_name": user.get("display_name"),
                    "phone": user.get("phone"),
                    "source_code": source_code,
                },
                "tenant": tenant,
            }
        ),
        200,
    )


@bp.get("/driver/me")
@require_jwt_with_uid("driver")
def driver_me(**kwargs: Any) -> Tuple[Any, int]:
    uid = int(kwargs["_uid"])
    user = db_module.user_by_id(uid)
    if user is None:
        return jsonify({"error": "not_found"}), 404
    pin = db_module.driver_pin_ensure_for_app_driver(uid)
    driver = db_module.driver_by_user_id(uid)
    return (
        jsonify(
            {
                "user": {
                    "id": user.get("id"),
                    "email": user.get("email"),
                    "display_name": user.get("display_name"),
                    "phone": user.get("phone"),
                },
                "driver": driver,
                "pin_account": pin,
            }
        ),
        200,
    )


@bp.patch("/driver/me")
@require_jwt_with_uid("driver")
def driver_me_patch(**kwargs: Any) -> Tuple[Any, int]:
    uid = int(kwargs["_uid"])
    user = db_module.user_by_id(uid)
    if user is None:
        return jsonify({"error": "not_found"}), 404
    body = request.get_json(silent=True) or {}

    display_name = body.get("display_name")
    phone = body.get("phone")
    email = body.get("email")
    password = body.get("password")
    car_model = body.get("car_model")
    car_color = body.get("car_color")
    photo_url = body.get("photo_url")

    u = db_module.db.session.get(db_module.User, uid)
    if u is None:
        return jsonify({"error": "not_found"}), 404
    if display_name is not None:
        name_norm = str(display_name).strip()
        if not name_norm:
            return jsonify({"error": "name_required"}), 400
        u.display_name = name_norm
    if phone is not None:
        phone_norm = str(phone).strip()
        if not phone_norm:
            return jsonify({"error": "phone_required"}), 400
        u.phone = phone_norm
    if email is not None:
        email_norm = str(email).strip().lower()
        if not email_norm:
            return jsonify({"error": "invalid_email"}), 400
        existing = db_module.user_by_email(email_norm)
        if existing is not None and int(existing["id"]) != uid:
            return jsonify({"error": "email_taken"}), 409
        u.email = email_norm
    if password is not None:
        pw = str(password).strip()
        if pw and len(pw) < 6:
            return jsonify({"error": "weak_password"}), 400
        if pw:
            u.password_hash = generate_password_hash(pw)
    db_module.db.session.commit()

    acct = db_module.driver_pin_ensure_for_app_driver(uid)
    if acct is not None:
        updates: dict[str, Any] = {}
        new_phone = str((u.phone or "")).strip()
        if new_phone and new_phone != str(acct.get("phone") or "").strip():
            updates["phone"] = new_phone
        if display_name is not None:
            updates["driver_name"] = str(display_name).strip()
        if car_model is not None:
            updates["car_model"] = str(car_model).strip()
        if car_color is not None:
            updates["car_color"] = str(car_color).strip()
        if photo_url is not None:
            updates["photo_url"] = str(photo_url).strip()
        if updates:
            acct = db_module.driver_pin_update(int(acct["id"]), **updates)

    d = db_module.db.session.scalars(
        db_module.select(db_module.Driver).where(db_module.Driver.user_id == uid)
    ).first()
    if d is not None:
        if display_name is not None:
            d.display_name = str(display_name).strip() or d.display_name
        if car_model is not None or car_color is not None:
            current = str(d.vehicle_info or "")
            current_model = ""
            current_color = ""
            m1 = re.search(r'["\']car_model["\']\s*:\s*["\']([^"\']+)["\']', current)
            m2 = re.search(r'model\s*=\s*([^;,\n]+)', current, flags=re.IGNORECASE)
            c1 = re.search(r'["\']car_color["\']\s*:\s*["\']([^"\']+)["\']', current)
            c2 = re.search(r'color\s*=\s*([^;,\n]+)', current, flags=re.IGNORECASE)
            if m1:
                current_model = str(m1.group(1)).strip()
            elif m2:
                current_model = str(m2.group(1)).strip()
            if c1:
                current_color = str(c1.group(1)).strip()
            elif c2:
                current_color = str(c2.group(1)).strip()

            new_model = str(car_model).strip() if car_model is not None else current_model
            new_color = str(car_color).strip() if car_color is not None else current_color
            d.vehicle_info = (
                ""
                if not new_model and not new_color
                else f"model={new_model};color={new_color}"
            )
        db_module.db.session.commit()

    return jsonify({"ok": True, "user": db_module.user_by_id(uid), "pin_account": acct}), 200


def _user_public_dict(row: dict[str, Any]) -> dict[str, Any]:
    """Safe subset for client apps (no secrets)."""
    return {
        "id": row.get("id"),
        "email": row.get("email"),
        "role": row.get("role"),
        "display_name": row.get("display_name") or "",
        "phone": row.get("phone"),
        "photo_url": row.get("photo_url"),
        "preferred_language": str(row.get("preferred_language") or "en").strip() or "en",
        "is_enabled": bool(row.get("is_enabled", True)),
        "approval_status": row.get("approval_status") or "approved",
    }


@bp.get("/passenger/me")
@require_jwt_with_uid("user")
def passenger_me(**kwargs: Any) -> Tuple[Any, int]:
    uid = int(kwargs["_uid"])
    user = db_module.user_by_id(uid)
    if user is None:
        return jsonify({"error": "not_found"}), 404
    return jsonify({"user": _user_public_dict(user)}), 200


@bp.patch("/passenger/me")
@require_jwt_with_uid("user")
def passenger_me_patch(**kwargs: Any) -> Tuple[Any, int]:
    uid = int(kwargs["_uid"])
    user = db_module.user_by_id(uid)
    if user is None:
        return jsonify({"error": "not_found"}), 404
    body = request.get_json(silent=True) or {}

    display_name = body.get("display_name")
    phone = body.get("phone")
    email = body.get("email")
    password = body.get("password")
    photo_url = body.get("photo_url")

    u = db_module.db.session.get(db_module.User, uid)
    if u is None:
        return jsonify({"error": "not_found"}), 404
    if display_name is not None:
        name_norm = str(display_name).strip()
        if not name_norm:
            return jsonify({"error": "name_required"}), 400
        u.display_name = name_norm
    if phone is not None:
        phone_norm = str(phone).strip()
        if not phone_norm:
            return jsonify({"error": "phone_required"}), 400
        u.phone = phone_norm
    if email is not None:
        email_norm = str(email).strip().lower()
        if not email_norm:
            return jsonify({"error": "invalid_email"}), 400
        existing = db_module.user_by_email(email_norm)
        if existing is not None and int(existing["id"]) != uid:
            return jsonify({"error": "email_taken"}), 409
        u.email = email_norm
    if photo_url is not None:
        raw = str(photo_url).strip()
        u.photo_url = raw or None
    if password is not None:
        pw = str(password).strip()
        if pw:
            if len(pw) < 6:
                return jsonify({"error": "weak_password"}), 400
            u.password_hash = generate_password_hash(pw)

    db_module.db.session.commit()
    refreshed = db_module.user_by_id(uid)
    assert refreshed is not None
    return jsonify({"ok": True, "user": _user_public_dict(refreshed)}), 200


@bp.post("/auth/register")
def register() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    role = (data.get("role") or "").strip().lower()
    display_name = (data.get("display_name") or data.get("name") or "").strip()
    phone = (data.get("phone") or "").strip()
    photo_url = (data.get("photo_url") or data.get("image") or "").strip()
    car_model = (data.get("car_model") or "").strip()
    car_color = (data.get("car_color") or "").strip()
    user, err = users_service.register(
        email,
        password,
        role,
        display_name=display_name,
        phone=phone,
        photo_url=photo_url,
        car_model=car_model,
        car_color=car_color,
    )
    if err:
        code = 409 if err == "email_taken" else 400
        return jsonify({"error": err}), code
    return jsonify({"user": user}), 201


@bp.post("/auth/login-app")
def login_app() -> Tuple[Any, int]:
    """JWT for app users (`owner|operator|driver|b2b|user`) with `uid` in token."""
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""
    user, err = users_service.authenticate(email, password)
    if err:
        code = 403 if err in {"account_disabled", "account_pending"} else 401
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
                "email": user.get("email"),
                "display_name": user.get("display_name"),
                "phone": user.get("phone"),
                "photo_url": user.get("photo_url"),
                "preferred_language": str(user.get("preferred_language") or "en").strip()
                or "en",
            }
        ),
        200,
    )


@bp.post("/auth/forgot-password-request")
def forgot_password_request() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    out, err = users_service.request_password_reset(email)
    if err:
        return jsonify({"error": err}), 400
    return jsonify(out), 200


@bp.post("/auth/forgot-password-confirm")
def forgot_password_confirm() -> Tuple[Any, int]:
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip()
    reset_code = (data.get("reset_code") or "").strip()
    new_password = data.get("new_password") or ""
    out, err = users_service.confirm_password_reset(
        email=email,
        reset_code=reset_code,
        new_password=new_password,
    )
    if err:
        code = 410 if err == "reset_code_expired" else 400
        return jsonify({"error": err}), code
    return jsonify(out), 200


@bp.post("/auth/login-google")
def login_google() -> Tuple[Any, int]:
    """Google sign-in for self-registerable app roles."""
    data = request.get_json(silent=True) or {}
    id_token = data.get("id_token") or ""
    access_token = data.get("access_token") or ""
    role = (data.get("role") or "").strip().lower()
    phone = (data.get("phone") or "").strip()
    if id_token:
        user, err = users_service.authenticate_google_id_token(id_token, role)
        # Flutter Web may return an unusable ID token while access token is valid.
        if err == "invalid_google_token" and access_token:
            user, err = users_service.authenticate_google_access_token(access_token, role)
    elif access_token:
        user, err = users_service.authenticate_google_access_token(access_token, role)
    else:
        user, err = None, "missing_google_token"
    if err:
        code = 403 if err in {"account_disabled", "account_pending"} else 401
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
                "display_name": user.get("display_name"),
                "phone": user.get("phone"),
                "photo_url": user.get("photo_url"),
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
@require_jwt_with_uid("user", "b2b")
def add_rating(**kwargs: Any) -> Tuple[Any, int]:
    uid = int(kwargs["_uid"])
    role = str(kwargs.get("_role") or "").strip().lower()
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
    is_owner_passenger = int(ride.get("user_id") or 0) == uid
    is_owner_b2b = False
    if role == "b2b":
        u = db_module.user_by_id(uid) or {}
        email = str(u.get("email") or "").strip().lower()
        my_code = email.split("@", 1)[0].strip() if "@" in email else ""
        ride_code = str(ride.get("b2b_source_code") or "").strip().lower()
        is_owner_b2b = bool(my_code and ride_code and my_code == ride_code)
    if not (is_owner_passenger or is_owner_b2b):
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
