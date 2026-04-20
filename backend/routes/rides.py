"""App-user ride API (JWT with uid). Legacy code-login tokens are not accepted here."""
from __future__ import annotations

from typing import Any, Tuple

from flask import Blueprint, jsonify, request

from .. import db as db_module
from ..services import chat_service
from ..services import rides as rides_service
from .jwt_auth import json_error, require_jwt_with_uid

bp = Blueprint("rides_api", __name__, url_prefix="/api/rides")


def _guard_enabled(uid: int) -> Tuple[Any, int] | None:
    row = db_module.user_by_id(uid)
    if row is None or not row.get("is_enabled", True):
        return jsonify({"error": "account_disabled"}), 403
    return None


@bp.get("")
@require_jwt_with_uid("user", "driver")
def list_rides(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    role = kwargs["_role"]
    data = rides_service.list_for_app_user(uid, role)
    return jsonify({"rides": data}), 200


@bp.post("")
@require_jwt_with_uid("user")
def create_ride(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    body = request.get_json(silent=True) or {}
    pickup = (body.get("pickup") or "").strip()
    destination = (body.get("destination") or "").strip()
    ride, err = rides_service.request_ride(uid, pickup, destination)
    if err:
        code = 400 if err != "active_ride_exists" else 409
        return jsonify({"error": err}), code
    return jsonify({"ride": ride}), 201


@bp.post("/guest")
def create_guest_ride() -> Tuple[Any, int]:
    return jsonify({"error": "guest_passenger_disabled_use_google_login"}), 403


@bp.post("/guest/<int:ride_id>/cancel")
def cancel_guest_ride(ride_id: int) -> Tuple[Any, int]:
    return jsonify({"error": "guest_passenger_disabled_use_google_login"}), 403


@bp.get("/<int:ride_id>/conversation")
@require_jwt_with_uid("user", "driver")
def ride_conversation(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    data, err = chat_service.get_conversation_for_ride(ride_id, uid)
    if err == "not_found":
        return json_error("not_found", 404)
    if err == "forbidden":
        return json_error("forbidden", 403)
    if err == "chat_not_open":
        return json_error("chat_not_open", 400)
    assert data is not None
    return jsonify(data), 200


@bp.post("/<int:ride_id>/accept")
@require_jwt_with_uid("driver")
def accept(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    ride, err = rides_service.accept_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/reject")
@require_jwt_with_uid("driver")
def reject(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    ride, err = rides_service.reject_or_release(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/start")
@require_jwt_with_uid("driver")
def start(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    ride, err = rides_service.start_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/complete")
@require_jwt_with_uid("driver")
def complete(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    ride, err = rides_service.complete_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/<int:ride_id>/cancel")
@require_jwt_with_uid("user")
def cancel(ride_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    ride, err = rides_service.cancel_ride(ride_id, uid)
    if err:
        st = 404 if err == "not_found" else 400
        return jsonify({"error": err}), st
    return jsonify({"ride": ride}), 200


@bp.post("/driver/location")
@require_jwt_with_uid("driver")
def driver_location(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    body = request.get_json(silent=True) or {}
    current_zone = (body.get("current_zone") or "").strip()
    lat_raw = body.get("lat")
    lng_raw = body.get("lng")
    lat = None
    lng = None
    try:
        if lat_raw is not None:
            lat = float(lat_raw)
        if lng_raw is not None:
            lng = float(lng_raw)
    except (TypeError, ValueError):
        return jsonify({"error": "invalid_coordinates"}), 400
    rides_service.update_driver_live_location(
        driver_user_id=uid,
        current_zone=current_zone,
        lat=lat,
        lng=lng,
    )
    return jsonify({"ok": True}), 200
