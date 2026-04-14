"""Push ride status updates to Socket.IO user rooms (thin wrapper over `socketio`)."""
from __future__ import annotations

from typing import Any, Dict

from .. import db as db_module
from ..extensions import socketio


def broadcast_ride_update(ride: Dict[str, Any]) -> None:
    """Notify passenger and assigned driver (if any) with the latest ride JSON."""
    payload = {"ride": ride}
    socketio.emit(
        "ride_status",
        payload,
        room=f"user:{int(ride['user_id'])}",
    )
    did = ride.get("driver_id")
    if did is not None:
        d = db_module.driver_by_id(int(did))
        if d is not None:
            socketio.emit(
                "ride_status",
                payload,
                room=f"user:{int(d['user_id'])}",
            )
