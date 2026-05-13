"""Ride lifecycle: one active ride per passenger; driver accept / ongoing / complete."""
from __future__ import annotations

import math
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

from .. import db as db_module
from . import chat_service
from . import pricing
from . import realtime_broadcast

# If pickup/destination do not match a FareRoute row, assume this base for the 10% cut.
_FALLBACK_BASE_FARE_DT = 70.0
# One-shot alert payload when balance crosses from positive to depleted (≤0).
_REQUIRED_TOPUP_DT = 100.0
_OWNER_COMMISSION_RATE = 0.10
_B2B_EXTRA_COMMISSION_RATE = 0.05
_SCHEDULE_MIN_LEAD_MINUTES = 30
_SCHEDULE_MAX_HORIZON_DAYS = 30
_SCHEDULE_PICKUP_WINDOW_MINUTES = 30
_SCHEDULE_START_GRACE_MINUTES = 45

_ZONE_COORDS: Dict[str, tuple[float, float]] = {
    "مطار قرطاج": (36.8508, 10.2272),
    "مطار النفيضة": (36.0758, 10.4386),
    "مطار المنستير": (35.7581, 10.7547),
    "وسط سوسة": (35.8256, 10.63699),
    "الحمامات": (36.4000, 10.6167),
    "نابل": (36.4561, 10.7376),
    "القنطاوي": (35.8920, 10.5950),
}


def _distance_km(a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    return math.sqrt((a_lat - b_lat) ** 2 + (a_lng - b_lng) ** 2) * 111.0


def _wallet_depleted_or_missing_for_driver(user_id: int) -> bool:
    acct = db_module.driver_pin_account_by_user_id(user_id)
    if acct is None:
        return True
    return float(acct.get("wallet_balance") or 0.0) <= 0.0


def _select_top5_driver_user_ids_for_pickup(pickup_zone: str) -> List[int]:
    candidates = db_module.driver_profiles_for_dispatch_online(window_minutes=30)
    if not candidates:
        candidates = db_module.driver_profiles_for_dispatch()
    if not candidates:
        return []
    pickup_norm = pickup_zone.strip()
    target = _ZONE_COORDS.get(pickup_norm)
    scored: List[tuple[float, int]] = []
    for d in candidates:
        uid = int(d["user_id"])
        if not bool(int(d.get("is_available", 0))):
            continue
        if _wallet_depleted_or_missing_for_driver(uid):
            # Depleted wallet drivers must not receive new dispatch offers.
            db_module.driver_set_availability_by_user_id(uid, False)
            continue
        current_zone = (db_module.driver_current_zone_by_user_id(uid) or "").strip()
        lat = d.get("last_lat")
        lng = d.get("last_lng")
        if current_zone == pickup_norm:
            # Strongly prefer drivers already in the pickup zone.
            score = 0.0
        elif target is not None and lat is not None and lng is not None:
            # Next best: nearest by recent GPS point.
            score = 1.0 + _distance_km(float(lat), float(lng), target[0], target[1])
        elif target is not None and current_zone in _ZONE_COORDS:
            # Fallback: zone-to-zone proximity when GPS point is missing.
            cz = _ZONE_COORDS[current_zone]
            score = 2.0 + _distance_km(cz[0], cz[1], target[0], target[1])
        else:
            # Last fallback: deterministic stable ordering.
            score = 3.0 + (float(uid) / 1_000_000.0)
        scored.append((score, uid))
    scored.sort(key=lambda x: x[0])
    return [uid for _, uid in scored[:5]]


def _parse_scheduled_pickup_at(raw: Any) -> tuple[datetime | None, str | None]:
    if raw in (None, ""):
        return None, None
    if isinstance(raw, datetime):
        dt = raw
    elif isinstance(raw, str):
        value = raw.strip()
        if value.endswith("Z"):
            value = value[:-1] + "+00:00"
        try:
            dt = datetime.fromisoformat(value)
        except ValueError:
            return None, "invalid_scheduled_pickup_at"
    else:
        return None, "invalid_scheduled_pickup_at"
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    dt = dt.astimezone(timezone.utc)
    now = datetime.now(timezone.utc)
    if dt < now + timedelta(minutes=_SCHEDULE_MIN_LEAD_MINUTES):
        return None, "scheduled_pickup_too_soon"
    if dt > now + timedelta(days=_SCHEDULE_MAX_HORIZON_DAYS):
        return None, "scheduled_pickup_too_far"
    return dt, None


def _select_scheduled_driver_user_ids(pickup_zone: str, pickup_at: datetime) -> List[int]:
    eligible = set(
        db_module.driver_user_ids_available_for_scheduled_pickup(
            pickup_at,
            window_minutes=_SCHEDULE_PICKUP_WINDOW_MINUTES,
        )
    )
    if not eligible:
        return _select_top5_driver_user_ids_for_pickup(pickup_zone)
    ordered_now = _select_top5_driver_user_ids_for_pickup(pickup_zone)
    ordered = [uid for uid in ordered_now if uid in eligible]
    for uid in sorted(eligible):
        if uid not in ordered:
            ordered.append(uid)
    return ordered[:5]


def request_ride(
    user_id: int,
    pickup: str,
    destination: str,
    *,
    enforce_single_active: bool = True,
    scheduled_pickup_at: Any = None,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    pickup = pickup.strip()
    destination = destination.strip()
    if not pickup or not destination:
        return None, "pickup_destination_required"
    scheduled_dt, schedule_err = _parse_scheduled_pickup_at(scheduled_pickup_at)
    if schedule_err:
        return None, schedule_err
    if enforce_single_active and db_module.user_has_active_ride(user_id):
        return None, "active_ride_exists"
    is_scheduled = scheduled_dt is not None
    ride = db_module.ride_insert(
        user_id=user_id,
        pickup=pickup,
        destination=destination,
        scheduled_pickup_at=scheduled_dt,
        reservation_status="searching" if is_scheduled else None,
    )
    if ride is not None:
        top5 = (
            _select_scheduled_driver_user_ids(pickup, scheduled_dt)
            if scheduled_dt is not None
            else _select_top5_driver_user_ids_for_pickup(pickup)
        )
        db_module.ride_dispatch_set_candidates(int(ride["id"]), top5)
        realtime_broadcast.broadcast_ride_update(
            ride,
            event="scheduled_ride_searching" if is_scheduled else "ride_request_sent",
            message=(
                "Searching for an available driver for your scheduled ride."
                if is_scheduled
                else "Your ride request was sent."
            ),
        )
        realtime_broadcast.notify_dispatch_offer(ride, top5)
    return ride, None


def _localized_wallet_message(lang: str, amount: float) -> str:
    """Short text pushed on the driver_wallet socket when the wallet hits zero."""
    code = (lang or "en").strip().lower()
    amt = int(amount)
    if code.startswith("ar"):
        return (
            f"محفظتك 0 د.ت. ادفع {amt} د.ت للمالك عبر المشغّل لإعادة الشحن والعودة للعمل."
        )
    if code.startswith("fr"):
        return (
            f"Portefeuille à 0 DT. Payez {amt} DT au propriétaire via l’opérateur "
            "pour recharger et repasser en ligne."
        )
    if code.startswith("de"):
        return (
            f"Guthaben 0 DT. Zahlen Sie {amt} DT an den Eigentümer (über den Operator), "
            "um aufzuladen und wieder online zu gehen."
        )
    if code.startswith("es"):
        return (
            f"Monedero en 0 DT. Pague {amt} DT al propietario (vía el operador) "
            "para recargar y volver en línea."
        )
    if code.startswith("it"):
        return (
            f"Portafoglio a 0 DT. Paga {amt} DT al proprietario (tramite l’operatore) "
            "per ricaricare e tornare online."
        )
    if code.startswith("ru"):
        return (
            f"Баланс 0 DT. Внесите {amt} DT владельцу (через оператора), "
            "чтобы пополнить и снова выйти на линию."
        )
    if code.startswith("zh"):
        return f"钱包余额为 0 DT。请通过运营商向店主支付 {amt} DT 充值后才能恢复在线。"
    return (
        f"Your wallet is at 0 DT. Pay {amt} DT to the owner (via the operator) "
        "to top up and go back online."
    )


def _apply_wallet_on_complete(
    driver_user_id: int,
    ride_before_complete: Dict[str, Any],
) -> None:
    acct = db_module.driver_pin_account_by_user_id(driver_user_id)
    if acct is None:
        return
    fare_ref, effective_rate, deduct, is_b2b = _deduction_components_for_ride(
        ride_before_complete
    )
    old_bal = float(acct["wallet_balance"] or 0.0)
    new_bal = round(old_bal - deduct, 3)
    db_module.driver_pin_update(int(acct["id"]), wallet_balance=new_bal)
    if new_bal <= 0.0:
        db_module.driver_set_availability_by_user_id(driver_user_id, False)
    realtime_broadcast.emit_driver_wallet(
        driver_user_id,
        {
            "event": "wallet_updated",
            "wallet_balance": new_bal,
            "deducted": deduct,
            "base_fare_reference": fare_ref,
            "commission_rate_applied": effective_rate,
            "is_b2b_ride": is_b2b,
            "ride_id": int(ride_before_complete["id"]),
        },
    )
    if new_bal <= 0 < old_bal:
        driver = db_module.user_by_id(driver_user_id) or {}
        driver_lang = str(driver.get("preferred_language") or "en")
        driver_msg = _localized_wallet_message(driver_lang, _REQUIRED_TOPUP_DT)
        realtime_broadcast.emit_driver_wallet(
            driver_user_id,
            {
                "event": "wallet_depleted",
                "wallet_balance": new_bal,
                "required_topup_dt": _REQUIRED_TOPUP_DT,
                "ride_id": int(ride_before_complete["id"]),
                "message": driver_msg,
                "message_i18n_key": "driver_wallet_depleted",
            },
        )
        owner_msg = _localized_wallet_message("en", _REQUIRED_TOPUP_DT)
        realtime_broadcast.emit_owner_alert(
            {
                "event": "driver_wallet_depleted",
                "driver_user_id": driver_user_id,
                "driver_name": (acct.get("driver_name") or "").strip(),
                "wallet_balance": new_bal,
                "required_topup_dt": _REQUIRED_TOPUP_DT,
                "ride_id": int(ride_before_complete["id"]),
                "message": owner_msg,
            }
        )


def _deduction_components_for_ride(
    ride_row: Dict[str, Any],
) -> tuple[float, float, float, bool]:
    pickup = (ride_row.get("pickup") or "").strip()
    dest = (ride_row.get("destination") or "").strip()
    route_key = f"{pickup} ➡️ {dest}"
    gr = pricing.get_airport_route(route_key)
    base_fare = float(gr["base_fare"]) if gr is not None else _FALLBACK_BASE_FARE_DT
    b2b_booking = db_module.b2b_booking_by_ride_id(int(ride_row["id"]))
    is_b2b = b2b_booking is not None
    effective_rate = _OWNER_COMMISSION_RATE + (_B2B_EXTRA_COMMISSION_RATE if is_b2b else 0.0)
    fare_ref = float(b2b_booking["fare"]) if is_b2b else base_fare
    deduct = round(fare_ref * effective_rate, 3)
    return fare_ref, effective_rate, deduct, is_b2b


def driver_gains_summary(driver_user_id: int) -> Dict[str, Any]:
    d = db_module.driver_by_user_id(driver_user_id)
    acct = db_module.driver_pin_account_by_user_id(driver_user_id)
    if d is None:
        return {
            "driver_user_id": driver_user_id,
            "is_available": False,
            "wallet_balance": float((acct or {}).get("wallet_balance") or 0.0),
            "completed_rides_count": 0,
            "gross_normal": 0.0,
            "gross_b2b": 0.0,
            "deducted_normal": 0.0,
            "deducted_b2b": 0.0,
            "total_gross": 0.0,
            "total_deducted": 0.0,
            "net_gains": 0.0,
        }
    rides = db_module.rides_for_driver(int(d["id"]))
    completed = [r for r in rides if r.get("status") == "completed"]
    gross_normal = 0.0
    gross_b2b = 0.0
    deducted_normal = 0.0
    deducted_b2b = 0.0
    for r in completed:
        fare_ref, _rate, deduct, is_b2b = _deduction_components_for_ride(r)
        if is_b2b:
            gross_b2b += fare_ref
            deducted_b2b += deduct
        else:
            gross_normal += fare_ref
            deducted_normal += deduct
    total_gross = round(gross_normal + gross_b2b, 3)
    total_deducted = round(deducted_normal + deducted_b2b, 3)
    net_gains = round(total_gross - total_deducted, 3)
    return {
        "driver_user_id": driver_user_id,
        "driver_id": int(d["id"]),
        "is_available": bool(int(d.get("is_available", 0))),
        "wallet_balance": float((acct or {}).get("wallet_balance") or 0.0),
        "completed_rides_count": len(completed),
        "gross_normal": round(gross_normal, 3),
        "gross_b2b": round(gross_b2b, 3),
        "deducted_normal": round(deducted_normal, 3),
        "deducted_b2b": round(deducted_b2b, 3),
        "total_gross": total_gross,
        "total_deducted": total_deducted,
        "net_gains": net_gains,
    }


def set_driver_availability(driver_user_id: int, is_available: bool) -> None:
    depleted = _wallet_depleted_or_missing_for_driver(driver_user_id)
    # A depleted wallet forces driver offline until wallet is topped up.
    db_module.driver_set_availability_by_user_id(
        driver_user_id, False if depleted else is_available
    )


def list_driver_availability(driver_user_id: int) -> List[Dict[str, Any]]:
    return db_module.driver_availability_slots_for_user(driver_user_id)


def create_driver_availability_slot(
    driver_user_id: int,
    starts_at: Any,
    ends_at: Any,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    start, start_err = _parse_scheduled_pickup_at(starts_at)
    if start_err:
        return None, "invalid_starts_at" if start_err == "invalid_scheduled_pickup_at" else start_err
    end, end_err = _parse_scheduled_pickup_at(ends_at)
    if end_err:
        return None, "invalid_ends_at" if end_err == "invalid_scheduled_pickup_at" else end_err
    assert start is not None and end is not None
    if end <= start:
        return None, "invalid_availability_window"
    if end - start > timedelta(hours=12):
        return None, "availability_window_too_long"
    slot = db_module.driver_availability_slot_insert(
        driver_user_id=driver_user_id,
        starts_at=start,
        ends_at=end,
    )
    if slot is None:
        return None, "not_a_driver"
    return slot, None


def delete_driver_availability_slot(driver_user_id: int, slot_id: int) -> bool:
    return db_module.driver_availability_slot_delete(driver_user_id, slot_id)


def list_for_app_user(user_id: int, role: str) -> List[Dict[str, Any]]:
    if role == "user":
        return db_module.rides_for_user(user_id)
    if role == "b2b":
        return db_module.rides_for_b2b_user(user_id)
    if role == "driver":
        d = db_module.driver_by_user_id(user_id)
        depleted = _wallet_depleted_or_missing_for_driver(user_id)
        is_available = bool(int((d or {}).get("is_available", 0)))
        # Keep DB state consistent: depleted wallet means forced offline.
        if depleted and is_available:
            db_module.driver_set_availability_by_user_id(user_id, False)
            is_available = False
        pending: List[Dict[str, Any]] = []
        # Depleted drivers must not see offers. Offline drivers can still see
        # scheduled offers that match their future availability calendar.
        if not depleted:
            pending = db_module.ride_dispatch_pending_for_driver_user(user_id)
            if not is_available:
                pending = [r for r in pending if r.get("scheduled_pickup_at")]
        if d is None:
            return pending
        mine = db_module.rides_for_driver(int(d["id"]))
        mine_ids = {r["id"] for r in mine}
        return mine + [r for r in pending if r["id"] not in mine_ids]
    return []


def accept_ride(ride_id: int, driver_user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    d = db_module.driver_by_user_id(driver_user_id)
    if d is None:
        return None, "not_a_driver"
    if _wallet_depleted_or_missing_for_driver(driver_user_id):
        db_module.driver_set_availability_by_user_id(driver_user_id, False)
        return None, "wallet_depleted"
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    scheduled_raw = row.get("scheduled_pickup_at")
    if not scheduled_raw and not bool(int(d.get("is_available", 0))):
        return None, "driver_unavailable"
    if row["status"] != "pending":
        return None, "invalid_status"
    allowed_driver_users = set(db_module.ride_dispatch_candidates_for_ride(ride_id))
    if allowed_driver_users and driver_user_id not in allowed_driver_users:
        return None, "not_in_dispatch_top5"
    if row["driver_id"] is not None:
        return None, "already_assigned"
    scheduled_dt, schedule_err = _parse_scheduled_pickup_at(scheduled_raw)
    if scheduled_raw and schedule_err == "scheduled_pickup_too_soon":
        scheduled_dt = datetime.fromisoformat(str(scheduled_raw).replace("Z", "+00:00"))
        if scheduled_dt.tzinfo is None:
            scheduled_dt = scheduled_dt.replace(tzinfo=timezone.utc)
        scheduled_dt = scheduled_dt.astimezone(timezone.utc)
    if scheduled_dt is not None and db_module.driver_has_scheduled_overlap(
        int(d["id"]),
        scheduled_dt,
        window_minutes=60,
        exclude_ride_id=ride_id,
    ):
        return None, "driver_schedule_conflict"
    updated = db_module.ride_update(
        ride_id,
        driver_id=int(d["id"]),
        status="accepted",
        reservation_status="reserved" if scheduled_dt is not None else None,
    )
    if updated is not None:
        chat_service.ensure_conversation_for_ride(ride_id)
        realtime_broadcast.broadcast_ride_update(
            updated,
            event="scheduled_ride_reserved" if scheduled_dt is not None else "ride_accepted",
            message=(
                "Your scheduled ride is reserved."
                if scheduled_dt is not None
                else "A driver accepted your request."
            ),
        )
        other_candidates = [uid for uid in allowed_driver_users if uid != driver_user_id]
        if other_candidates:
            realtime_broadcast.notify_dispatch_taken(
                updated,
                accepted_driver_user_id=driver_user_id,
                other_driver_user_ids=other_candidates,
            )
    return updated, None


def reject_or_release(ride_id: int, driver_user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """Driver releases an accepted ride back to the pending pool."""
    d = db_module.driver_by_user_id(driver_user_id)
    if d is None:
        return None, "not_a_driver"
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    if row["driver_id"] != int(d["id"]):
        return None, "forbidden"
    if row["status"] not in ("accepted", "ongoing"):
        return None, "invalid_status"
    next_reservation_status = "searching" if row.get("scheduled_pickup_at") else None
    updated = db_module.ride_update(
        ride_id, clear_driver=True, status="pending", reservation_status=next_reservation_status
    )
    if updated is not None:
        realtime_broadcast.broadcast_ride_update(updated, event="ride_released")
    return updated, None


def start_ride(ride_id: int, driver_user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    d = db_module.driver_by_user_id(driver_user_id)
    if d is None:
        return None, "not_a_driver"
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    if row["driver_id"] != int(d["id"]) or row["status"] != "accepted":
        return None, "invalid_status"
    scheduled_raw = row.get("scheduled_pickup_at")
    if scheduled_raw:
        scheduled_dt = datetime.fromisoformat(str(scheduled_raw).replace("Z", "+00:00"))
        if scheduled_dt.tzinfo is None:
            scheduled_dt = scheduled_dt.replace(tzinfo=timezone.utc)
        scheduled_dt = scheduled_dt.astimezone(timezone.utc)
        if datetime.now(timezone.utc) < scheduled_dt - timedelta(minutes=_SCHEDULE_START_GRACE_MINUTES):
            return None, "scheduled_pickup_not_ready"
    updated = db_module.ride_update(ride_id, status="ongoing", reservation_status="in_progress")
    if updated is not None:
        realtime_broadcast.broadcast_ride_update(updated, event="ride_started")
    return updated, None


def complete_ride(ride_id: int, driver_user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    d = db_module.driver_by_user_id(driver_user_id)
    if d is None:
        return None, "not_a_driver"
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    if row["driver_id"] != int(d["id"]) or row["status"] != "ongoing":
        return None, "invalid_status"
    updated = db_module.ride_update(ride_id, status="completed", reservation_status="completed")
    if updated is not None:
        _apply_wallet_on_complete(driver_user_id, row)
        realtime_broadcast.broadcast_ride_update(updated, event="ride_completed")
    return updated, None


def cancel_ride(ride_id: int, user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    if int(row["user_id"]) != user_id:
        return None, "forbidden"
    if row["status"] in ("completed", "cancelled"):
        return None, "invalid_status"
    candidate_driver_users = db_module.ride_dispatch_candidates_for_ride(ride_id)
    updated = db_module.ride_update(
        ride_id,
        status="cancelled",
        clear_driver=True,
        reservation_status="cancelled" if row.get("scheduled_pickup_at") else None,
    )
    if updated is not None:
        realtime_broadcast.broadcast_ride_update(updated, event="ride_cancelled")
        if candidate_driver_users:
            realtime_broadcast.notify_dispatch_cancelled(
                updated,
                driver_user_ids=candidate_driver_users,
            )
    return updated, None


def update_driver_live_location(
    *,
    driver_user_id: int,
    current_zone: str,
    lat: float | None = None,
    lng: float | None = None,
) -> None:
    db_module.driver_touch_online(driver_user_id, last_lat=lat, last_lng=lng)
    if current_zone.strip():
        db_module.driver_update_current_zone_by_user_id(driver_user_id, current_zone.strip())
    # Notify passengers when the assigned driver reaches/approaches pickup zone.
    rides = list_for_app_user(driver_user_id, "driver")
    for ride in rides:
        if ride.get("status") != "accepted":
            continue
        if (ride.get("pickup") or "").strip() != current_zone.strip():
            continue
        realtime_broadcast.notify_passenger_driver_near_pickup(
            ride,
            current_zone=current_zone.strip(),
        )
