"""Ride lifecycle: one active ride per passenger; driver accept / ongoing / complete."""
from __future__ import annotations

import math
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
        current_zone = (db_module.driver_current_zone_by_user_id(uid) or "").strip()
        # Hard business rule: offer only to drivers currently in the same pickup zone.
        if current_zone != pickup_norm:
            continue
        lat = d.get("last_lat")
        lng = d.get("last_lng")
        if target is not None and lat is not None and lng is not None:
            score = _distance_km(float(lat), float(lng), target[0], target[1])
        else:
            score = 0.05 + (float(uid) / 1_000_000.0)
        scored.append((score, uid))
    scored.sort(key=lambda x: x[0])
    return [uid for _, uid in scored[:5]]


def request_ride(
    user_id: int,
    pickup: str,
    destination: str,
    *,
    enforce_single_active: bool = True,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    pickup = pickup.strip()
    destination = destination.strip()
    if not pickup or not destination:
        return None, "pickup_destination_required"
    if enforce_single_active and db_module.user_has_active_ride(user_id):
        return None, "active_ride_exists"
    ride = db_module.ride_insert(user_id=user_id, pickup=pickup, destination=destination)
    if ride is not None:
        top5 = _select_top5_driver_user_ids_for_pickup(pickup)
        db_module.ride_dispatch_set_candidates(int(ride["id"]), top5)
        realtime_broadcast.broadcast_ride_update(
            ride,
            event="ride_request_sent",
            message="Your ride request was sent.",
        )
        realtime_broadcast.notify_dispatch_offer(ride, top5)
    return ride, None


def _localized_wallet_message(lang: str, amount: float) -> str:
    code = (lang or "en").strip().lower()
    if code.startswith("ar"):
        return f"المحفظة فارغة. ادفع {int(amount)} د.ت للمالك عبر المشغل لإعادة الشحن."
    if code.startswith("fr"):
        return (
            f"Portefeuille vide. Payez {int(amount)} DT au proprietaire via l'operateur."
        )
    return f"Wallet empty. Pay {int(amount)} DT to the owner via the operator."


def _apply_wallet_on_complete(
    driver_user_id: int,
    ride_before_complete: Dict[str, Any],
) -> None:
    acct = db_module.driver_pin_account_by_user_id(driver_user_id)
    if acct is None:
        return
    pickup = (ride_before_complete.get("pickup") or "").strip()
    dest = (ride_before_complete.get("destination") or "").strip()
    route_key = f"{pickup} ➡️ {dest}"
    gr = pricing.get_airport_route(route_key)
    base_fare = float(gr["base_fare"]) if gr is not None else _FALLBACK_BASE_FARE_DT
    deduct = round(base_fare * _OWNER_COMMISSION_RATE, 3)
    old_bal = float(acct["wallet_balance"] or 0.0)
    new_bal = round(old_bal - deduct, 3)
    db_module.driver_pin_update(int(acct["id"]), wallet_balance=new_bal)
    realtime_broadcast.emit_driver_wallet(
        driver_user_id,
        {
            "event": "wallet_updated",
            "wallet_balance": new_bal,
            "deducted": deduct,
            "base_fare_reference": base_fare,
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


def list_for_app_user(user_id: int, role: str) -> List[Dict[str, Any]]:
    if role == "user":
        return db_module.rides_for_user(user_id)
    if role == "driver":
        d = db_module.driver_by_user_id(user_id)
        pending = db_module.ride_dispatch_pending_for_driver_user(user_id)
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
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    if row["status"] != "pending":
        return None, "invalid_status"
    allowed_driver_users = set(db_module.ride_dispatch_candidates_for_ride(ride_id))
    if allowed_driver_users and driver_user_id not in allowed_driver_users:
        return None, "not_in_dispatch_top5"
    if row["driver_id"] is not None:
        return None, "already_assigned"
    updated = db_module.ride_update(
        ride_id, driver_id=int(d["id"]), status="accepted"
    )
    if updated is not None:
        chat_service.ensure_conversation_for_ride(ride_id)
        realtime_broadcast.broadcast_ride_update(
            updated,
            event="ride_accepted",
            message="A driver accepted your request.",
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
    updated = db_module.ride_update(
        ride_id, clear_driver=True, status="pending"
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
    updated = db_module.ride_update(ride_id, status="ongoing")
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
    updated = db_module.ride_update(ride_id, status="completed")
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
    updated = db_module.ride_update(ride_id, status="cancelled", clear_driver=True)
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
    db_module.driver_mark_online(driver_user_id, last_lat=lat, last_lng=lng)
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
