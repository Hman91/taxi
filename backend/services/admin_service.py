"""Operator / owner oversight (no HTTP concerns)."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import select

from ..extensions import db
from ..models import B2BTenant, Conversation, Driver, Message, Ride, User


def _ts(val: Any) -> Any:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


def _ride_dict(r: Ride) -> Dict[str, Any]:
    return {
        "id": int(r.id),
        "user_id": int(r.user_id),
        "driver_id": int(r.driver_id) if r.driver_id is not None else None,
        "status": r.status,
        "pickup": r.pickup,
        "destination": r.destination,
        "created_at": _ts(r.created_at),
        "updated_at": _ts(r.updated_at),
    }


def list_rides(*, limit: int = 200) -> List[Dict[str, Any]]:
    limit = min(max(1, limit), 500)
    rows = db.session.scalars(select(Ride).order_by(Ride.id.desc()).limit(limit)).all()
    return [_ride_dict(r) for r in rows]


def list_driver_locations() -> List[Dict[str, Any]]:
    stmt = (
        select(Driver, User.email)
        .join(User, Driver.user_id == User.id)
        .order_by(Driver.id.asc())
    )
    rows = db.session.execute(stmt).all()
    out: List[Dict[str, Any]] = []
    for d, email in rows:
        out.append(
            {
                "driver_id": int(d.id),
                "user_id": int(d.user_id),
                "email": email,
                "display_name": d.display_name or "",
                "is_available": bool(d.is_available),
                "last_lat": d.last_lat,
                "last_lng": d.last_lng,
                "last_seen_at": _ts(d.last_seen_at),
            }
        )
    return out


def list_conversation_messages_admin(
    conversation_id: int,
    *,
    target_lang: Optional[str] = None,
    before_id: Optional[int] = None,
    limit: int = 50,
) -> Tuple[Optional[List[Dict[str, Any]]], Optional[str]]:
    conv = db.session.get(Conversation, conversation_id)
    if conv is None:
        return None, "not_found"
    limit = min(max(1, limit), 100)
    stmt = select(Message).where(Message.conversation_id == conversation_id)
    if before_id is not None:
        stmt = stmt.where(Message.id < before_id)
    stmt = stmt.order_by(Message.id.desc()).limit(limit)
    rows = list(db.session.scalars(stmt).all())
    rows.reverse()
    from . import translation_service

    out: List[Dict[str, Any]] = []
    for m in rows:
        base = {
            "id": int(m.id),
            "message_id": int(m.id),
            "conversation_id": int(m.conversation_id),
            "sender_user_id": int(m.sender_user_id),
            "original_text": m.original_text,
            "original_language": m.original_language,
            "created_at": _ts(m.created_at),
        }
        out.append(
            translation_service.enrich_message_for_target_lang(base, target_lang)
        )
    return out, None


def list_app_users(*, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
    limit = min(max(1, limit), 500)
    offset = max(0, offset)
    rows = db.session.scalars(
        select(User)
        .where(User.role.in_(("user", "driver")))
        .order_by(User.id.desc())
        .offset(offset)
        .limit(limit)
    ).all()
    return [
        {
            "id": int(u.id),
            "email": u.email,
            "role": u.role,
            "preferred_language": u.preferred_language,
            "is_enabled": u.is_enabled,
            "created_at": _ts(u.created_at),
        }
        for u in rows
    ]


def set_user_enabled(user_id: int, enabled: bool) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    u = db.session.get(User, user_id)
    if u is None:
        return None, "not_found"
    if u.role not in ("user", "driver"):
        return None, "invalid_user_role"
    u.is_enabled = bool(enabled)
    db.session.commit()
    db.session.refresh(u)
    return {
        "id": int(u.id),
        "email": u.email,
        "role": u.role,
        "is_enabled": u.is_enabled,
        "preferred_language": u.preferred_language,
    }, None


def list_b2b_tenants() -> List[Dict[str, Any]]:
    rows = db.session.scalars(select(B2BTenant).order_by(B2BTenant.id.asc())).all()
    return [
        {
            "id": int(t.id),
            "code": t.code,
            "label": t.label,
            "is_enabled": t.is_enabled,
        }
        for t in rows
    ]


def set_b2b_tenant_enabled(tenant_id: int, enabled: bool) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    t = db.session.get(B2BTenant, tenant_id)
    if t is None:
        return None, "not_found"
    t.is_enabled = bool(enabled)
    db.session.commit()
    db.session.refresh(t)
    return {
        "id": int(t.id),
        "code": t.code,
        "label": t.label,
        "is_enabled": t.is_enabled,
    }, None
