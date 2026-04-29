"""Chat: conversation per ride, participant checks, paginated message history."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import select

from ..extensions import db
from .. import db as db_module
from ..models import Conversation, Message, Ride
from . import translation_service

_MESSAGE_MAX_LEN = 8000


def _user_display_name(user_id: int) -> str:
    u = db_module.user_by_id(user_id) or {}
    email = str(u.get("email") or "").strip()
    if email:
        return email.split("@", 1)[0]
    return f"User {user_id}"


def _sender_name_for_ride(ride: Dict[str, Any], sender_user_id: int) -> str:
    if int(ride.get("user_id") or 0) == sender_user_id:
        return _user_display_name(sender_user_id)
    did = ride.get("driver_id")
    if did is None:
        return _user_display_name(sender_user_id)
    d = db_module.driver_by_id(int(did))
    if d is None:
        return _user_display_name(sender_user_id)
    if int(d.get("user_id") or 0) == sender_user_id:
        name = str(d.get("display_name") or "").strip()
        if name:
            return name
    return _user_display_name(sender_user_id)


def _participant_ok(ride: Dict[str, Any], user_id: int) -> bool:
    if int(ride["user_id"]) == user_id:
        return True
    if ride["driver_id"] is None:
        return False
    driver_id = int(ride["driver_id"])

    # Primary check: lookup by driver PK attached to the ride.
    d = db_module.driver_by_id(driver_id)
    if d is not None and int(d.get("user_id") or 0) == user_id:
        return True

    # Fallback 1: verify that the current user's driver profile matches ride.driver_id.
    # This guards against edge cases where relationship resolution by PK is stale.
    my_driver = db_module.driver_by_user_id(user_id)
    if my_driver is not None and int(my_driver.get("id") or 0) == driver_id:
        return True

    # Fallback 2: match PIN account phone against resolved ride driver phone.
    # Useful when PIN-linked data is available but driver relationship lookup is inconsistent.
    ride_driver_phone = str(ride.get("driver_phone") or "").strip()
    if ride_driver_phone:
        my_pin = db_module.driver_pin_account_by_user_id(user_id)
        if my_pin is not None and str(my_pin.get("phone") or "").strip() == ride_driver_phone:
            return True

    return False


def ensure_conversation_for_ride(ride_id: int) -> Optional[int]:
    """Create a conversation row when the ride is accepted+; idempotent. Returns conversation id or None."""
    r = db.session.get(Ride, ride_id)
    if r is None:
        return None
    if r.status not in ("accepted", "ongoing", "completed"):
        return None
    existing = db.session.scalars(
        select(Conversation).where(Conversation.ride_id == ride_id)
    ).first()
    if existing:
        return int(existing.id)
    c = Conversation(ride_id=ride_id)
    db.session.add(c)
    db.session.commit()
    return int(c.id)


def conversation_participant_check(
    conversation_id: int, user_id: int
) -> Optional[Conversation]:
    """Return the conversation if this user may join the Socket.IO room (read path)."""
    conv = db.session.get(Conversation, conversation_id)
    if conv is None:
        return None
    ride = db_module.ride_get(int(conv.ride_id))
    if ride is None:
        return None
    if not _participant_ok(ride, user_id):
        return None
    if ride["status"] not in ("accepted", "ongoing", "completed", "cancelled"):
        return None
    return conv


def participant_user_ids_for_conversation(conversation_id: int) -> List[int]:
    """Passenger and driver user ids for this ride-linked conversation (deduped)."""
    conv = db.session.get(Conversation, conversation_id)
    if conv is None:
        return []
    ride = db_module.ride_get(int(conv.ride_id))
    if ride is None:
        return []
    out: List[int] = [int(ride["user_id"])]
    did = ride.get("driver_id")
    if did is not None:
        d = db_module.driver_by_id(int(did))
        if d is not None:
            du = int(d["user_id"])
            if du not in out:
                out.append(du)
    return out


def get_conversation_for_ride(ride_id: int, user_id: int) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    ride = db_module.ride_get(ride_id)
    if ride is None:
        return None, "not_found"
    if not _participant_ok(ride, user_id):
        return None, "forbidden"
    existing = db.session.scalars(
        select(Conversation).where(Conversation.ride_id == ride_id)
    ).first()
    if existing:
        if ride["status"] in ("accepted", "ongoing", "completed", "cancelled"):
            return {"conversation_id": int(existing.id), "ride_id": ride_id}, None
        return None, "chat_not_open"
    if ride["status"] not in ("accepted", "ongoing", "completed"):
        return None, "chat_not_open"
    cid = ensure_conversation_for_ride(ride_id)
    if cid is None:
        return None, "chat_not_open"
    return {"conversation_id": cid, "ride_id": ride_id}, None


def list_messages(
    conversation_id: int,
    user_id: int,
    *,
    before_id: Optional[int] = None,
    limit: int = 50,
) -> Tuple[Optional[List[Dict[str, Any]]], Optional[str]]:
    conv = db.session.get(Conversation, conversation_id)
    if conv is None:
        return None, "not_found"
    ride = db_module.ride_get(int(conv.ride_id))
    if ride is None:
        return None, "not_found"
    if not _participant_ok(ride, user_id):
        return None, "forbidden"
    if ride["status"] not in ("accepted", "ongoing", "completed", "cancelled"):
        return None, "chat_not_open"

    limit = min(max(1, limit), 100)
    stmt = select(Message).where(Message.conversation_id == conversation_id)
    if before_id is not None:
        stmt = stmt.where(Message.id < before_id)
    stmt = stmt.order_by(Message.id.desc()).limit(limit)
    rows = list(db.session.scalars(stmt).all())
    rows.reverse()

    out: List[Dict[str, Any]] = []
    for m in rows:
        base = {
            "id": int(m.id),
            "message_id": int(m.id),
            "conversation_id": int(m.conversation_id),
            "sender_user_id": int(m.sender_user_id),
            "sender_id": int(m.sender_user_id),
            "sender_name": _sender_name_for_ride(ride, int(m.sender_user_id)),
            "original_text": m.original_text,
            "original_language": m.original_language,
            "created_at": m.created_at.isoformat() if m.created_at else None,
        }
        out.append(translation_service.enrich_message_for_viewer(base, user_id))
    return out, None


def _message_to_dict(m: Message) -> Dict[str, Any]:
    sid = int(m.sender_user_id)
    conv = db.session.get(Conversation, int(m.conversation_id))
    ride_id = int(conv.ride_id) if conv is not None and conv.ride_id is not None else None
    ride = db_module.ride_get(ride_id) if ride_id is not None else None
    return {
        "message_id": int(m.id),
        "conversation_id": int(m.conversation_id),
        "ride_id": ride_id,
        "sender_id": sid,
        "sender_user_id": sid,
        "sender_name": _sender_name_for_ride(ride, sid) if ride is not None else _user_display_name(sid),
        "original_text": m.original_text,
        "original_language": m.original_language,
        "created_at": m.created_at.isoformat() if m.created_at else None,
    }


def save_chat_message(
    user_id: int, conversation_id: int, text: str
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """Persist a chat line when ride is active (accepted or ongoing)."""
    raw = (text or "").strip()
    if not raw:
        return None, "empty_message"
    if len(raw) > _MESSAGE_MAX_LEN:
        return None, "message_too_long"

    urow = db_module.user_by_id(user_id)
    if urow is None or not urow.get("is_enabled", True):
        return None, "forbidden"

    conv = db.session.get(Conversation, conversation_id)
    if conv is None:
        return None, "not_found"
    ride = db_module.ride_get(int(conv.ride_id))
    if ride is None:
        return None, "not_found"
    if not _participant_ok(ride, user_id):
        return None, "forbidden"
    if ride["status"] not in ("accepted", "ongoing"):
        return None, "chat_not_open"

    lang = (urow.get("preferred_language") or "en").strip() or "en"
    if len(lang) > 10:
        lang = lang[:10]

    m = Message(
        conversation_id=conversation_id,
        sender_user_id=user_id,
        original_text=raw,
        original_language=lang,
    )
    db.session.add(m)
    db.session.commit()
    db.session.refresh(m)
    return _message_to_dict(m), None
