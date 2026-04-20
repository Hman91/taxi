"""Push ride status updates to Socket.IO user rooms (thin wrapper over `socketio`)."""
from __future__ import annotations

from typing import Any, Dict, Iterable, Optional

from .. import db as db_module
from ..extensions import socketio


def _emit_to_user(user_id: int, payload: Dict[str, Any]) -> None:
    socketio.emit("ride_status", payload, room=f"user:{int(user_id)}")


def emit_driver_wallet(user_id: int, payload: Dict[str, Any]) -> None:
    socketio.emit("driver_wallet", payload, room=f"user:{int(user_id)}")


def broadcast_ride_update(
    ride: Dict[str, Any],
    *,
    event: str = "ride_status_changed",
    message: Optional[str] = None,
) -> None:
    """Notify passenger and assigned driver (if any) with latest ride JSON."""
    payload = {"ride": ride, "event": event}
    if message:
        payload["message"] = message
    _emit_to_user(int(ride["user_id"]), payload)
    did = ride.get("driver_id")
    if did is not None:
        d = db_module.driver_by_id(int(did))
        if d is not None:
            _emit_to_user(int(d["user_id"]), payload)


def notify_dispatch_offer(ride: Dict[str, Any], driver_user_ids: Iterable[int]) -> None:
    payload = {
        "event": "ride_request_sent",
        "ride": ride,
        "message": "Passenger sent a new ride request.",
    }
    for uid in driver_user_ids:
        _emit_to_user(int(uid), payload)


def notify_dispatch_taken(
    ride: Dict[str, Any],
    *,
    accepted_driver_user_id: int,
    other_driver_user_ids: Iterable[int],
) -> None:
    payload = {
        "event": "ride_taken_by_other_driver",
        "ride": ride,
        "message": "This request was accepted by another driver.",
        "accepted_driver_user_id": int(accepted_driver_user_id),
        # Alias kept for client compatibility with older handlers.
        "driver_id": int(accepted_driver_user_id),
    }
    for uid in other_driver_user_ids:
        if int(uid) == int(accepted_driver_user_id):
            continue
        _emit_to_user(int(uid), payload)


def notify_dispatch_cancelled(
    ride: Dict[str, Any],
    *,
    driver_user_ids: Iterable[int],
) -> None:
    payload = {
        "event": "ride_cancelled_by_passenger",
        "ride": ride,
        "message": "Passenger cancelled the request.",
    }
    for uid in driver_user_ids:
        _emit_to_user(int(uid), payload)


def notify_passenger_driver_near_pickup(ride: Dict[str, Any], *, current_zone: str) -> None:
    payload = {
        "event": "driver_near_pickup",
        "ride": ride,
        "current_zone": current_zone,
        "message": "Driver is near your pickup point.",
    }
    _emit_to_user(int(ride["user_id"]), payload)
