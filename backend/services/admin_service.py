"""Operator / owner oversight (no HTTP concerns)."""
from __future__ import annotations

from datetime import date
from datetime import datetime
import json
import os
import re
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import delete, func, select
from sqlalchemy.exc import SQLAlchemyError
from werkzeug.security import generate_password_hash

from ..extensions import db
from .. import db as db_module
from ..models import B2BBooking, B2BTenant, Conversation, Driver, Message, Ride, User
from . import aviation_edge
from . import rides as rides_service


def _ts(val: Any) -> Any:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


def _vehicle_parts(raw: str) -> tuple[str, str]:
    txt = (raw or "").strip()
    if not txt:
        return "", ""
    car_model = ""
    car_color = ""
    if txt.startswith("{"):
        try:
            info = json.loads(txt)
            if isinstance(info, dict):
                car_model = str(info.get("car_model") or "").strip()
                car_color = str(info.get("car_color") or "").strip()
        except Exception:
            pass
    if not car_model:
        m = re.search(r"""['"]car_model['"]\s*:\s*['"]([^'"]+)['"]""", txt)
        if m:
            car_model = str(m.group(1) or "").strip()
    if not car_color:
        m = re.search(r"""['"]car_color['"]\s*:\s*['"]([^'"]+)['"]""", txt)
        if m:
            car_color = str(m.group(1) or "").strip()
    if not car_model or not car_color:
        for part in txt.split(";"):
            seg = part.strip()
            if seg.lower().startswith("model=") and not car_model:
                car_model = seg.split("=", 1)[1].strip()
            if seg.lower().startswith("color=") and not car_color:
                car_color = seg.split("=", 1)[1].strip()
    return car_model, car_color


def _ride_dict(r: Ride) -> Dict[str, Any]:
    """Same shape as app ride JSON; skip per-row fare quotes (admin lists can be large)."""
    return db_module._ride_dict(r, include_fare_quote=False)


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
        .where(User.role.in_(("owner", "operator", "user", "driver", "b2b")))
        .order_by(User.id.desc())
        .offset(offset)
        .limit(limit)
    ).all()
    out: List[Dict[str, Any]] = []
    for u in rows:
        car_model = ""
        car_color = ""
        if u.role == "driver":
            d = db.session.scalars(select(Driver).where(Driver.user_id == int(u.id))).first()
            if d is not None:
                car_model, car_color = _vehicle_parts(d.vehicle_info or "")
        out.append(
            {
                "id": int(u.id),
                "email": u.email,
                "role": u.role,
                "display_name": u.display_name or "",
                "phone": u.phone or "",
                "car_model": car_model,
                "car_color": car_color,
                "preferred_language": u.preferred_language,
                "is_enabled": u.is_enabled,
                "approval_status": u.approval_status,
                "approved_at": _ts(u.approved_at),
                "approved_by_user_id": int(u.approved_by_user_id)
                if u.approved_by_user_id is not None
                else None,
                "created_at": _ts(u.created_at),
            }
        )
    return out


def set_user_enabled(
    user_id: int,
    enabled: bool,
    *,
    acted_by_user_id: Optional[int] = None,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    u = db.session.get(User, user_id)
    if u is None:
        return None, "not_found"
    if u.role not in ("owner", "operator", "user", "driver", "b2b"):
        return None, "invalid_user_role"
    u.is_enabled = bool(enabled)
    if u.role in ("driver", "b2b"):
        if enabled:
            u.approval_status = "approved"
            u.approved_at = datetime.utcnow()
            u.approved_by_user_id = acted_by_user_id
        else:
            u.approval_status = "rejected"
            u.approved_by_user_id = acted_by_user_id
    db.session.commit()
    db.session.refresh(u)
    return {
        "id": int(u.id),
        "email": u.email,
        "role": u.role,
        "is_enabled": u.is_enabled,
        "approval_status": u.approval_status,
        "approved_at": _ts(u.approved_at),
        "approved_by_user_id": int(u.approved_by_user_id)
        if u.approved_by_user_id is not None
        else None,
        "preferred_language": u.preferred_language,
    }, None


def list_pending_approvals(*, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
    limit = min(max(1, limit), 500)
    offset = max(0, offset)
    rows = db.session.scalars(
        select(User)
        .where(
            User.role.in_(("driver", "b2b")),
            User.approval_status == "pending",
        )
        .order_by(User.id.asc())
        .offset(offset)
        .limit(limit)
    ).all()
    out: List[Dict[str, Any]] = []
    for u in rows:
        car_model = ""
        car_color = ""
        if u.role == "driver":
            d = db.session.scalars(select(Driver).where(Driver.user_id == int(u.id))).first()
            if d is not None:
                car_model, car_color = _vehicle_parts(d.vehicle_info or "")
        out.append(
            {
                "id": int(u.id),
                "email": u.email,
                "role": u.role,
                "display_name": u.display_name or "",
                "phone": u.phone or "",
                "photo_url": u.photo_url or "",
                "car_model": car_model,
                "car_color": car_color,
                "approval_status": u.approval_status,
                "is_enabled": u.is_enabled,
                "created_at": _ts(u.created_at),
            }
        )
    return out


def create_app_user(
    *,
    email: str,
    password: str,
    role: str,
    display_name: str = "",
    phone: str = "",
    car_model: str = "",
    car_color: str = "",
    acted_by_user_id: Optional[int] = None,
    auto_approve: bool = True,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    role_norm = (role or "").strip().lower()
    if role_norm not in ("driver", "b2b"):
        return None, "invalid_role"
    email_norm = (email or "").strip().lower()
    if not email_norm or "@" not in email_norm:
        return None, "invalid_email"
    if len(password or "") < 6:
        return None, "weak_password"
    if db_module.user_by_email(email_norm) is not None:
        return None, "email_taken"
    if not (display_name or "").strip():
        return None, "name_required"
    if not (phone or "").strip():
        return None, "phone_required"
    if role_norm == "driver" and (not car_model.strip() or not car_color.strip()):
        return None, "driver_vehicle_required"

    user_id = db_module.user_create(
        email=email_norm,
        password_hash=generate_password_hash(password),
        role=role_norm,
        display_name=display_name.strip(),
        phone=phone.strip(),
        is_enabled=bool(auto_approve),
        approval_status="approved" if auto_approve else "pending",
    )
    if role_norm == "driver":
        db_module.driver_create(
            user_id=user_id,
            display_name=display_name.strip(),
            vehicle_info=json.dumps(
                {
                    "car_model": car_model.strip(),
                    "car_color": car_color.strip(),
                }
            ),
        )
    u = db.session.get(User, int(user_id))
    if u is None:
        return None, "not_found"
    if auto_approve:
        u.approved_at = datetime.utcnow()
        u.approved_by_user_id = acted_by_user_id
        db.session.commit()
    return {
        "id": int(u.id),
        "email": u.email,
        "role": u.role,
        "display_name": u.display_name or "",
        "phone": u.phone or "",
        "is_enabled": bool(u.is_enabled),
        "approval_status": u.approval_status,
    }, None


def patch_app_user(
    user_id: int,
    *,
    email: Optional[str] = None,
    display_name: Optional[str] = None,
    phone: Optional[str] = None,
    car_model: Optional[str] = None,
    car_color: Optional[str] = None,
    password: Optional[str] = None,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    u = db.session.get(User, int(user_id))
    if u is None:
        return None, "not_found"
    if u.role not in ("driver", "b2b"):
        return None, "invalid_user_role"

    if email is not None:
        email_norm = email.strip().lower()
        if not email_norm or "@" not in email_norm:
            return None, "invalid_email"
        clash = db.session.scalars(
            select(User).where(User.email == email_norm, User.id != int(user_id))
        ).first()
        if clash is not None:
            return None, "email_taken"
        u.email = email_norm
    if display_name is not None:
        u.display_name = display_name.strip()
    if phone is not None:
        p = phone.strip()
        if not p:
            return None, "phone_required"
        u.phone = p
    if password is not None:
        pw = password.strip()
        if len(pw) < 6:
            return None, "weak_password"
        u.password_hash = generate_password_hash(pw)

    if u.role == "driver":
        d = db.session.scalars(select(Driver).where(Driver.user_id == int(u.id))).first()
        if d is not None:
            if display_name is not None:
                d.display_name = (display_name or "").strip()
            info: Dict[str, Any] = {}
            raw = (d.vehicle_info or "").strip()
            if raw:
                try:
                    parsed = json.loads(raw)
                    if isinstance(parsed, dict):
                        info = dict(parsed)
                except Exception:
                    info = {}
            if car_model is not None:
                info["car_model"] = car_model.strip()
            if car_color is not None:
                info["car_color"] = car_color.strip()
            d.vehicle_info = json.dumps(info)

    db.session.commit()
    db.session.refresh(u)
    return {
        "id": int(u.id),
        "email": u.email,
        "role": u.role,
        "display_name": u.display_name or "",
        "phone": u.phone or "",
        "is_enabled": bool(u.is_enabled),
        "approval_status": u.approval_status,
    }, None


def delete_app_user(user_id: int) -> Optional[str]:
    u = db.session.get(User, int(user_id))
    if u is None:
        return "not_found"
    if u.role not in ("driver", "b2b", "user"):
        return "invalid_user_role"
    try:
        uid = int(u.id)
        # Defensive cleanup for databases that may miss ON DELETE CASCADE.
        db.session.execute(delete(Message).where(Message.sender_user_id == uid))
        db.session.execute(delete(B2BBooking).where(B2BBooking.user_id == uid))
        rides = db.session.scalars(select(Ride.id).where(Ride.user_id == uid)).all()
        if rides:
            ride_ids = [int(rid) for rid in rides]
            db.session.execute(delete(Conversation).where(Conversation.ride_id.in_(ride_ids)))
            db.session.execute(delete(Ride).where(Ride.id.in_(ride_ids)))
        if u.role == "driver":
            d = db.session.scalars(select(Driver).where(Driver.user_id == uid)).first()
            if d is not None:
                db.session.delete(d)
        db.session.delete(u)
        db.session.commit()
        return None
    except SQLAlchemyError:
        db.session.rollback()
        return "cannot_delete_user"


def list_b2b_tenants() -> List[Dict[str, Any]]:
    rows = db.session.scalars(select(B2BTenant).order_by(B2BTenant.id.asc())).all()
    out: List[Dict[str, Any]] = []
    for t in rows:
        total_fare = db.session.execute(
            select(func.coalesce(func.sum(B2BBooking.fare), 0.0)).where(
                B2BBooking.tenant_id == int(t.id)
            )
        ).scalar_one()
        out.append(
            {
                "id": int(t.id),
                "code": t.code,
                "label": t.label,
                "contact_name": t.contact_name,
                "pin": t.pin,
                "phone": t.phone,
                "hotel": t.hotel,
                "is_enabled": t.is_enabled,
                "wallet_balance": round(float(total_fare or 0.0) * 0.05, 3),
            }
        )
    return out


def create_b2b_tenant(
    *,
    code: str,
    label: str,
    contact_name: str,
    pin: str,
    phone: str,
    hotel: str,
    is_enabled: bool = True,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    c = (code or "").strip()
    if not c:
        return None, "code_required"
    exists = db.session.scalars(select(B2BTenant).where(B2BTenant.code == c)).first()
    if exists is not None:
        return None, "code_exists"
    t = B2BTenant(
        code=c,
        label=(label or "").strip() or None,
        contact_name=(contact_name or "").strip() or None,
        pin=(pin or "").strip() or None,
        phone=(phone or "").strip() or None,
        hotel=(hotel or "").strip() or None,
        is_enabled=bool(is_enabled),
    )
    db.session.add(t)
    db.session.commit()
    db.session.refresh(t)
    return {
        "id": int(t.id),
        "code": t.code,
        "label": t.label,
        "contact_name": t.contact_name,
        "pin": t.pin,
        "phone": t.phone,
        "hotel": t.hotel,
        "is_enabled": t.is_enabled,
    }, None


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
        "contact_name": t.contact_name,
        "pin": t.pin,
        "phone": t.phone,
        "hotel": t.hotel,
        "is_enabled": t.is_enabled,
    }, None


def patch_b2b_tenant(
    tenant_id: int,
    *,
    code: Optional[str] = None,
    label: Optional[str] = None,
    contact_name: Optional[str] = None,
    pin: Optional[str] = None,
    phone: Optional[str] = None,
    hotel: Optional[str] = None,
    is_enabled: Optional[bool] = None,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    t = db.session.get(B2BTenant, tenant_id)
    if t is None:
        return None, "not_found"
    if code is not None:
        c = code.strip()
        if not c:
            return None, "code_required"
        clash = db.session.scalars(
            select(B2BTenant).where(B2BTenant.code == c, B2BTenant.id != tenant_id)
        ).first()
        if clash is not None:
            return None, "code_exists"
        t.code = c
    if label is not None:
        t.label = label.strip() or None
    if contact_name is not None:
        t.contact_name = contact_name.strip() or None
    if pin is not None:
        t.pin = pin.strip() or None
    if phone is not None:
        t.phone = phone.strip() or None
    if hotel is not None:
        t.hotel = hotel.strip() or None
    if is_enabled is not None:
        t.is_enabled = bool(is_enabled)
    db.session.commit()
    db.session.refresh(t)
    return {
        "id": int(t.id),
        "code": t.code,
        "label": t.label,
        "contact_name": t.contact_name,
        "pin": t.pin,
        "phone": t.phone,
        "hotel": t.hotel,
        "is_enabled": t.is_enabled,
    }, None


def list_b2b_bookings(*, limit: int = 200) -> List[Dict[str, Any]]:
    limit = min(max(1, limit), 500)
    rows = db.session.scalars(
        select(B2BBooking).order_by(B2BBooking.id.desc()).limit(limit)
    ).all()
    return [
        {
            "id": int(r.id),
            "tenant_id": int(r.tenant_id) if r.tenant_id is not None else None,
            "route": r.route,
            "pickup": r.pickup,
            "destination": r.destination,
            "guest_name": r.guest_name,
            "room_number": r.room_number,
            "fare": float(r.fare),
            "status": r.status,
            "source_code": r.source_code,
            "ride_id": int(r.ride_id) if r.ride_id is not None else None,
            "created_at": _ts(r.created_at),
        }
        for r in rows
    ]


def list_driver_wallet_breakdown() -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []

    def _is_system_driver(*, email: str = "", name: str = "") -> bool:
        e = (email or "").strip().lower()
        n = (name or "").strip().lower()
        if e.endswith("@taxipro.local") or e.endswith("@example.com"):
            return True
        if e.startswith("smoke_") or e.startswith("dispatch_"):
            return True
        if n.startswith("smoke_") or n.startswith("driver "):
            return True
        return False

    rows = db.session.execute(
        select(Driver, User).join(User, Driver.user_id == User.id).order_by(Driver.id.asc())
    ).all()
    for d, u in rows:
        if _is_system_driver(
            email=(u.email or ""),
            name=(d.display_name or u.display_name or ""),
        ):
            continue
        uid = int(u.id)
        acc = db_module.driver_pin_ensure_for_app_driver(uid)
        if acc is None:
            continue
        car_model = str(acc.get("car_model") or "").strip()
        car_color = str(acc.get("car_color") or "").strip()
        if (not car_model or not car_color):
            raw = (d.vehicle_info or "").strip()
            if raw:
                if raw.startswith("{"):
                    try:
                        info = json.loads(raw)
                        if not car_model:
                            car_model = str(info.get("car_model") or "").strip()
                        if not car_color:
                            car_color = str(info.get("car_color") or "").strip()
                    except Exception:
                        pass
                else:
                    for part in raw.split(";"):
                        seg = part.strip()
                        if seg.lower().startswith("model=") and not car_model:
                            car_model = seg.split("=", 1)[1].strip()
                        if seg.lower().startswith("color=") and not car_color:
                            car_color = seg.split("=", 1)[1].strip()
        summary = rides_service.driver_gains_summary(uid)
        out.append(
            {
                "id": int(acc.get("id") or 0),
                "driver_name": (d.display_name or u.display_name or acc.get("driver_name") or "-").strip(),
                "phone": (u.phone or acc.get("phone") or "").strip(),
                "wallet_balance": float(acc.get("wallet_balance") or 0.0),
                "owner_commission_rate": float(acc.get("owner_commission_rate") or 10.0),
                "b2b_commission_rate": float(acc.get("b2b_commission_rate") or 5.0),
                "car_model": car_model,
                "car_color": car_color,
                **summary,
                "source": "driver_account",
            }
        )
    return out


def list_driver_ratings() -> List[Dict[str, Any]]:
    def _is_system_driver(*, email: str = "", name: str = "") -> bool:
        e = (email or "").strip().lower()
        n = (name or "").strip().lower()
        if e.endswith("@taxipro.local") or e.endswith("@example.com"):
            return True
        if e.startswith("smoke_") or e.startswith("dispatch_"):
            return True
        if n.startswith("smoke_") or n.startswith("driver "):
            return True
        return False

    rows = db.session.execute(
        select(Driver, User).join(User, Driver.user_id == User.id).order_by(Driver.id.asc())
    ).all()
    out: List[Dict[str, Any]] = []
    for d, u in rows:
        if _is_system_driver(email=(u.email or ""), name=(d.display_name or u.display_name or "")):
            continue
        stats = db_module.rating_stats(driver_id=int(d.id))
        out.append(
            {
                "driver_name": (d.display_name or u.display_name or "").strip(),
                "phone": (u.phone or "").strip(),
                "driver_id": int(d.id),
                "rating_average": stats["average"],
                "rating_count": stats["count"],
            }
        )
    return out


def list_tunisia_flight_arrivals_demo() -> List[Dict[str, Any]]:
    """Curated demo schedule for operator 'Today's arrivals' (not a live flight radar)."""
    today = date.today().isoformat()
    return [
        {
            "flight_number": "TB101",
            "airline": "Nouvelair (BJ)",
            "status": "scheduled",
            "aircraft": "A320",
            "departure_airport": "Paris Orly",
            "departure_iata": "ORY",
            "departure_city": "Paris",
            "departure_country": "France",
            "takeoff_time": "05:40",
            "expected_arrival": f"{today} 08:15",
            "arrival_terminal": "T1",
            "arrival_gate": "B12",
            "arrival_airport_ar": "مطار النفيضة",
            "arrival_airport_en": "Enfidha Airport (NBE)",
        },
        {
            "flight_number": "TU214",
            "airline": "Tunisair (TU)",
            "status": "scheduled",
            "aircraft": "A320",
            "departure_airport": "Brussels",
            "departure_iata": "BRU",
            "departure_city": "Brussels",
            "departure_country": "Belgium",
            "takeoff_time": "06:10",
            "expected_arrival": f"{today} 09:40",
            "arrival_terminal": "",
            "arrival_gate": "",
            "arrival_airport_ar": "مطار قرطاج",
            "arrival_airport_en": "Tunis–Carthage Airport (TUN)",
        },
        {
            "flight_number": "AF987",
            "airline": "Air France (AF)",
            "status": "scheduled",
            "aircraft": "A320",
            "departure_airport": "Paris CDG",
            "departure_iata": "CDG",
            "departure_city": "Paris",
            "departure_country": "France",
            "takeoff_time": "07:25",
            "expected_arrival": f"{today} 10:50",
            "arrival_terminal": "2E",
            "arrival_gate": "",
            "arrival_airport_ar": "مطار المنستير",
            "arrival_airport_en": "Monastir Airport (MIR)",
        },
    ]


def _dedupe_sort_flight_rows(flights: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen: set[tuple[str, str]] = set()
    out: List[Dict[str, Any]] = []
    for row in sorted(flights, key=lambda x: str(x.get("expected_arrival") or "")):
        key = (str(row.get("flight_number") or ""), str(row.get("expected_arrival") or ""))
        if key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out


def resolve_tunisia_flight_arrivals() -> Tuple[List[Dict[str, Any]], str]:
    """Return (flight rows, diagnostic source id) for `/tunisia-flight-arrivals`.

    ``flight_data_source`` explains which path produced the list (for UI hints).
    """
    api_key = (os.environ.get("AVIATION_EDGE_API_KEY") or "").strip()
    if not api_key:
        return list_tunisia_flight_arrivals_demo(), "demo_no_api_key"

    schedules = aviation_edge.tunisia_arrivals_via_timetables(api_key)
    if schedules:
        return _dedupe_sort_flight_rows(schedules), "aviation_edge_timetable"

    tracking = aviation_edge.tunisia_arrivals_via_live_tracker(api_key)
    if tracking:
        return _dedupe_sort_flight_rows(tracking), "aviation_edge_flights"

    return list_tunisia_flight_arrivals_demo(), "demo_aviation_edge_empty"


def list_tunisia_flight_arrivals_live() -> List[Dict[str, Any]]:
    """Backwards-compatible helper: flight rows only (no source tag)."""
    rows, _src = resolve_tunisia_flight_arrivals()
    return rows
