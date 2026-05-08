"""Operator + owner admin API (rides, drivers, chat read, toggles, owner-only metrics)."""
from __future__ import annotations

from typing import Any, Tuple

from flask import Blueprint, jsonify, request

from .. import db as db_module
from ..services import admin_service
from .api import require_roles

bp = Blueprint("admin_api", __name__, url_prefix="/api/admin")


def _json_error(code: str, status: int) -> Tuple[Any, int]:
    return jsonify({"error": code}), status


@bp.get("/tunisia-flight-arrivals")
@require_roles("owner", "operator", "driver")
def admin_tunisia_flight_arrivals(**kwargs: Any) -> Tuple[Any, int]:
    flights, source = admin_service.resolve_tunisia_flight_arrivals()
    return jsonify({"flights": flights, "flight_data_source": source}), 200


@bp.get("/fare-routes")
@require_roles("owner", "operator")
def admin_fare_routes_list(**kwargs: Any) -> Tuple[Any, int]:
    rows = db_module.list_fare_routes(enabled_only=False)
    return jsonify({"routes": rows}), 200


@bp.patch("/fare-routes/<int:route_id>")
@require_roles("owner", "operator")
def admin_fare_routes_patch(route_id: int, **kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    if "base_fare" not in body:
        return _json_error("base_fare_required", 400)
    try:
        base_fare = float(body["base_fare"])
    except (TypeError, ValueError):
        return _json_error("invalid_base_fare", 400)
    row = db_module.fare_route_update(route_id, base_fare=base_fare)
    if row is None:
        return _json_error("not_found", 404)
    return jsonify({"route": row}), 200


@bp.get("/rides")
@require_roles("owner", "operator")
def admin_rides(**kwargs: Any) -> Tuple[Any, int]:
    limit_raw = request.args.get("limit", "200")
    try:
        limit = int(limit_raw)
    except (TypeError, ValueError):
        return _json_error("invalid_limit", 400)
    data = admin_service.list_rides(limit=limit)
    return jsonify({"rides": data}), 200


@bp.get("/drivers/locations")
@require_roles("owner", "operator")
def admin_driver_locations(**kwargs: Any) -> Tuple[Any, int]:
    data = admin_service.list_driver_locations()
    return jsonify({"drivers": data}), 200


@bp.get("/conversations/<int:conversation_id>/messages")
@require_roles("owner", "operator")
def admin_conversation_messages(conversation_id: int, **kwargs: Any) -> Tuple[Any, int]:
    lang = request.args.get("lang") or request.args.get("target_lang")
    before_raw = request.args.get("before_id")
    limit_raw = request.args.get("limit", "50")
    before_id: int | None = None
    if before_raw is not None and str(before_raw).strip() != "":
        try:
            before_id = int(before_raw)
        except (TypeError, ValueError):
            return _json_error("invalid_before_id", 400)
    try:
        limit = int(limit_raw)
    except (TypeError, ValueError):
        return _json_error("invalid_limit", 400)

    data, err = admin_service.list_conversation_messages_admin(
        conversation_id,
        target_lang=lang,
        before_id=before_id,
        limit=limit,
    )
    if err == "not_found":
        return _json_error("not_found", 404)
    assert data is not None
    return jsonify({"messages": data}), 200


@bp.get("/metrics")
@require_roles("owner")
def admin_owner_metrics(**kwargs: Any) -> Tuple[Any, int]:
    m = db_module.owner_metrics()
    return jsonify(m), 200

@bp.get("/ratings/drivers")
@require_roles("owner", "operator")
def admin_driver_ratings(**kwargs: Any) -> Tuple[Any, int]:
    rows = admin_service.list_driver_ratings()
    return jsonify({"driver_ratings": rows}), 200


@bp.get("/users")
@require_roles("owner", "operator")
def admin_list_users(**kwargs: Any) -> Tuple[Any, int]:
    limit_raw = request.args.get("limit", "100")
    offset_raw = request.args.get("offset", "0")
    try:
        limit = int(limit_raw)
        offset = int(offset_raw)
    except (TypeError, ValueError):
        return _json_error("invalid_pagination", 400)
    data = admin_service.list_app_users(limit=limit, offset=offset)
    return jsonify({"users": data}), 200


@bp.get("/users/pending")
@require_roles("owner", "operator")
def admin_list_pending_users(**kwargs: Any) -> Tuple[Any, int]:
    limit_raw = request.args.get("limit", "100")
    offset_raw = request.args.get("offset", "0")
    try:
        limit = int(limit_raw)
        offset = int(offset_raw)
    except (TypeError, ValueError):
        return _json_error("invalid_pagination", 400)
    data = admin_service.list_pending_approvals(limit=limit, offset=offset)
    return jsonify({"users": data}), 200


@bp.patch("/users/<int:user_id>")
@require_roles("owner", "operator")
def admin_patch_user(user_id: int, **kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    if "is_enabled" not in body:
        return _json_error("is_enabled_required", 400)
    if not isinstance(body.get("is_enabled"), bool):
        return _json_error("invalid_is_enabled", 400)
    actor_user_id = kwargs.get("user_id")
    user, err = admin_service.set_user_enabled(
        user_id,
        bool(body["is_enabled"]),
        acted_by_user_id=int(actor_user_id) if actor_user_id is not None else None,
    )
    if err == "not_found":
        return _json_error("not_found", 404)
    if err == "invalid_user_role":
        return _json_error("invalid_user_role", 400)
    assert user is not None
    return jsonify({"user": user}), 200


@bp.post("/users")
@require_roles("owner", "operator")
def admin_create_app_user(**kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    actor_user_id = kwargs.get("user_id")
    user, err = admin_service.create_app_user(
        email=str(body.get("email") or "").strip(),
        password=str(body.get("password") or ""),
        role=str(body.get("role") or "").strip().lower(),
        display_name=str(body.get("display_name") or "").strip(),
        phone=str(body.get("phone") or "").strip(),
        car_model=str(body.get("car_model") or "").strip(),
        car_color=str(body.get("car_color") or "").strip(),
        acted_by_user_id=int(actor_user_id) if actor_user_id is not None else None,
        auto_approve=bool(body.get("auto_approve", True)),
    )
    if err in {
        "invalid_role",
        "invalid_email",
        "weak_password",
        "name_required",
        "phone_required",
        "driver_vehicle_required",
    }:
        return _json_error(err, 400)
    if err == "email_taken":
        return _json_error("email_taken", 409)
    assert user is not None
    return jsonify({"user": user}), 201


@bp.patch("/users/<int:user_id>/profile")
@require_roles("owner", "operator")
def admin_patch_app_user_profile(user_id: int, **kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    user, err = admin_service.patch_app_user(
        user_id,
        email=(str(body.get("email")).strip() if "email" in body else None),
        display_name=(
            str(body.get("display_name")).strip() if "display_name" in body else None
        ),
        phone=(str(body.get("phone")).strip() if "phone" in body else None),
        car_model=(str(body.get("car_model")).strip() if "car_model" in body else None),
        car_color=(str(body.get("car_color")).strip() if "car_color" in body else None),
        password=(str(body.get("password")) if "password" in body else None),
    )
    if err == "not_found":
        return _json_error("not_found", 404)
    if err in {"invalid_user_role", "invalid_email", "phone_required", "weak_password"}:
        return _json_error(err, 400)
    if err == "email_taken":
        return _json_error("email_taken", 409)
    assert user is not None
    return jsonify({"user": user}), 200


@bp.delete("/users/<int:user_id>")
@require_roles("owner", "operator")
def admin_delete_app_user(user_id: int, **kwargs: Any) -> Tuple[Any, int]:
    err = admin_service.delete_app_user(user_id)
    if err == "not_found":
        return _json_error("not_found", 404)
    if err == "invalid_user_role":
        return _json_error("invalid_user_role", 400)
    if err == "cannot_delete_user":
        return _json_error("cannot_delete_user", 409)
    return jsonify({"deleted": True, "user_id": user_id}), 200


@bp.get("/b2b-tenants")
@require_roles("owner", "operator")
def admin_list_b2b(**kwargs: Any) -> Tuple[Any, int]:
    data = admin_service.list_b2b_tenants()
    return jsonify({"b2b_tenants": data}), 200


@bp.patch("/b2b-tenants/<int:tenant_id>")
@require_roles("owner", "operator")
def admin_patch_b2b(tenant_id: int, **kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    row, err = admin_service.patch_b2b_tenant(
        tenant_id,
        code=(body.get("code") if "code" in body else None),
        label=(body.get("label") if "label" in body else None),
        contact_name=(body.get("contact_name") if "contact_name" in body else None),
        pin=(body.get("pin") if "pin" in body else None),
        phone=(body.get("phone") if "phone" in body else None),
        hotel=(body.get("hotel") if "hotel" in body else None),
        is_enabled=(bool(body["is_enabled"]) if "is_enabled" in body else None),
    )
    if err == "not_found":
        return _json_error("not_found", 404)
    if err == "code_required":
        return _json_error("code_required", 400)
    if err == "code_exists":
        return _json_error("code_exists", 409)
    assert row is not None
    return jsonify({"b2b_tenant": row}), 200


@bp.post("/b2b-tenants")
@require_roles("owner", "operator")
def admin_create_b2b(**kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    code = str(body.get("code") or "").strip()
    if not code:
        return _json_error("code_required", 400)
    row, err = admin_service.create_b2b_tenant(
        code=code,
        label=str(body.get("label") or "").strip(),
        contact_name=str(body.get("contact_name") or "").strip(),
        pin=str(body.get("pin") or "").strip(),
        phone=str(body.get("phone") or "").strip(),
        hotel=str(body.get("hotel") or "").strip(),
        is_enabled=bool(body.get("is_enabled", True)),
    )
    if err == "code_required":
        return _json_error("code_required", 400)
    if err == "code_exists":
        return _json_error("code_exists", 409)
    assert row is not None
    return jsonify({"b2b_tenant": row}), 201


@bp.get("/b2b-bookings")
@require_roles("owner", "operator")
def admin_list_b2b_bookings(**kwargs: Any) -> Tuple[Any, int]:
    limit_raw = request.args.get("limit", "200")
    try:
        limit = int(limit_raw)
    except (TypeError, ValueError):
        return _json_error("invalid_limit", 400)
    data = admin_service.list_b2b_bookings(limit=limit)
    return jsonify({"b2b_bookings": data}), 200


@bp.get("/driver-pin-accounts")
@require_roles("owner", "operator")
def admin_list_driver_pin_accounts(**kwargs: Any) -> Tuple[Any, int]:
    rows = db_module.list_driver_pin_accounts()
    return jsonify({"driver_pin_accounts": rows}), 200


@bp.get("/driver-wallet-breakdown")
@require_roles("owner", "operator")
def admin_driver_wallet_breakdown(**kwargs: Any) -> Tuple[Any, int]:
    rows = admin_service.list_driver_wallet_breakdown()
    return jsonify({"driver_wallets": rows}), 200


@bp.post("/driver-pin-accounts")
@require_roles("owner", "operator")
def admin_create_driver_pin_account(**kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    phone = str(body.get("phone") or "").strip()
    pin = str(body.get("pin") or "").strip()
    driver_name = str(body.get("driver_name") or "").strip()
    car_model = str(body.get("car_model") or "").strip()
    car_color = str(body.get("car_color") or "").strip()
    photo_url = str(body.get("photo_url") or "").strip()
    if not phone or not pin or not driver_name or not car_model or not car_color:
        return _json_error("missing_fields", 400)
    row = db_module.driver_pin_create(
        phone=phone,
        pin=pin,
        driver_name=driver_name,
        car_model=car_model,
        car_color=car_color,
        photo_url=photo_url,
    )
    if row is None:
        return _json_error("phone_exists_or_invalid", 400)
    return jsonify({"driver_pin_account": row}), 201


@bp.patch("/driver-pin-accounts/<int:account_id>")
@require_roles("owner", "operator")
def admin_patch_driver_pin_account(account_id: int, **kwargs: Any) -> Tuple[Any, int]:
    body = request.get_json(silent=True) or {}
    payload: dict[str, Any] = {}
    for key in (
        "phone",
        "pin",
        "driver_name",
        "wallet_balance",
        "owner_commission_rate",
        "b2b_commission_rate",
        "auto_deduct_enabled",
        "photo_url",
        "car_model",
        "car_color",
        "current_zone",
    ):
        if key in body:
            payload[key] = body.get(key)
    if not payload:
        return _json_error("no_fields", 400)
    row = db_module.driver_pin_update(account_id, **payload)
    if row is None:
        return _json_error("not_found", 404)
    return jsonify({"driver_pin_account": row}), 200
