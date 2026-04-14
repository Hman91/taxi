"""Ride lifecycle: one active ride per passenger; driver accept / ongoing / complete."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from .. import db as db_module
from . import chat_service
from . import realtime_broadcast


def request_ride(user_id: int, pickup: str, destination: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    pickup = pickup.strip()
    destination = destination.strip()
    if not pickup or not destination:
        return None, "pickup_destination_required"
    if db_module.user_has_active_ride(user_id):
        return None, "active_ride_exists"
    ride = db_module.ride_insert(user_id=user_id, pickup=pickup, destination=destination)
    if ride is not None:
        realtime_broadcast.broadcast_ride_update(ride)
    return ride, None


def list_for_app_user(user_id: int, role: str) -> List[Dict[str, Any]]:
    if role == "user":
        return db_module.rides_for_user(user_id)
    if role == "driver":
        d = db_module.driver_by_user_id(user_id)
        pending = db_module.rides_list_pending()
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
    if row["driver_id"] is not None:
        return None, "already_assigned"
    updated = db_module.ride_update(
        ride_id, driver_id=int(d["id"]), status="accepted"
    )
    if updated is not None:
        chat_service.ensure_conversation_for_ride(ride_id)
        realtime_broadcast.broadcast_ride_update(updated)
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
        realtime_broadcast.broadcast_ride_update(updated)
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
        realtime_broadcast.broadcast_ride_update(updated)
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
        realtime_broadcast.broadcast_ride_update(updated)
    return updated, None


def cancel_ride(ride_id: int, user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    row = db_module.ride_get(ride_id)
    if row is None:
        return None, "not_found"
    if int(row["user_id"]) != user_id:
        return None, "forbidden"
    if row["status"] in ("completed", "cancelled"):
        return None, "invalid_status"
    updated = db_module.ride_update(ride_id, status="cancelled", clear_driver=True)
    if updated is not None:
        realtime_broadcast.broadcast_ride_update(updated)
    return updated, None
