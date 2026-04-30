"""Operator / owner oversight (no HTTP concerns)."""
from __future__ import annotations

from datetime import date
from datetime import datetime
import json
import os
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import urlencode
from urllib.request import urlopen

from sqlalchemy import func, select

from ..extensions import db
from .. import db as db_module
from ..models import B2BBooking, B2BTenant, Conversation, Driver, Message, Ride, User
from . import rides as rides_service


def _ts(val: Any) -> Any:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


def _ride_dict(r: Ride) -> Dict[str, Any]:
    passenger_name = None
    passenger = db.session.get(User, int(r.user_id))
    if passenger is not None:
        email = (passenger.email or "").strip()
        if email:
            passenger_name = email.split("@", 1)[0]
    driver_name = ""
    if r.driver_id is not None:
        d = db.session.get(Driver, int(r.driver_id))
        if d is not None:
            driver_name = (d.display_name or "").strip()
    b2b_guest_name = None
    b2b = db.session.scalars(
        select(B2BBooking).where(B2BBooking.ride_id == int(r.id))
    ).first()
    if b2b is not None:
        b2b_guest_name = (b2b.guest_name or "").strip() or None
        if b2b_guest_name:
            passenger_name = b2b_guest_name
    if not passenger_name:
        passenger_name = f"user_{int(r.user_id)}"
    if not driver_name and r.driver_id is not None:
        driver_name = f"driver_{int(r.driver_id)}"
    return {
        "id": int(r.id),
        "user_id": int(r.user_id),
        "driver_id": int(r.driver_id) if r.driver_id is not None else None,
        "driver_name": driver_name,
        "passenger_name": passenger_name,
        "b2b_guest_name": b2b_guest_name,
        "is_b2b": b2b is not None,
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
    for acc in db_module.list_driver_pin_accounts():
        phone = (acc.get("phone") or "").strip()
        if not phone:
            continue
        app_user = db_module.user_by_email(f"driverpin_{phone}@taxipro.local")
        if app_user is None:
            summary = {
                "completed_rides_count": 0,
                "gross_normal": 0.0,
                "gross_b2b": 0.0,
                "deducted_normal": 0.0,
                "deducted_b2b": 0.0,
                "total_gross": 0.0,
                "total_deducted": 0.0,
                "net_gains": 0.0,
                "is_available": False,
            }
        else:
            summary = rides_service.driver_gains_summary(int(app_user["id"]))
        out.append(
            {
                "id": int(acc.get("id") or 0),
                "driver_name": acc.get("driver_name"),
                "phone": phone,
                "wallet_balance": float(acc.get("wallet_balance") or 0.0),
                "owner_commission_rate": float(acc.get("owner_commission_rate") or 10.0),
                "b2b_commission_rate": float(acc.get("b2b_commission_rate") or 5.0),
                **summary,
            }
        )
    return out


def list_tunisia_flight_arrivals_demo() -> List[Dict[str, Any]]:
    """Curated demo schedule for operator 'Today's arrivals' (not a live flight radar)."""
    today = date.today().isoformat()
    return [
        {
            "flight_number": "TB101",
            "departure_airport": "Paris Orly",
            "takeoff_time": "05:40",
            "expected_arrival": f"{today} 08:15",
            "arrival_airport_ar": "مطار النفيضة",
            "arrival_airport_en": "Enfidha Airport (NBE)",
        },
        {
            "flight_number": "TU214",
            "departure_airport": "Brussels",
            "takeoff_time": "06:10",
            "expected_arrival": f"{today} 09:40",
            "arrival_airport_ar": "مطار قرطاج",
            "arrival_airport_en": "Tunis–Carthage Airport (TUN)",
        },
        {
            "flight_number": "AF987",
            "departure_airport": "Paris CDG",
            "takeoff_time": "07:25",
            "expected_arrival": f"{today} 10:50",
            "arrival_airport_ar": "مطار المنستير",
            "arrival_airport_en": "Monastir Airport (MIR)",
        },
    ]


def _hhmm_from_isoish(raw: str) -> str:
    s = (raw or "").strip()
    if not s:
        return ""
    s = s.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(s)
        return dt.strftime("%H:%M")
    except Exception:
        pass
    if "T" in s:
        tail = s.split("T", 1)[1]
        return tail[:5]
    if " " in s:
        tail = s.split(" ", 1)[1]
        return tail[:5]
    return s[:5]


def list_tunisia_flight_arrivals_live() -> List[Dict[str, Any]]:
    """Live arrivals from AirLabs for Tunisian airports.

    Returns an empty list if API key is missing or vendor is unavailable.
    """
    api_key = (os.environ.get("AIRLABS_API_KEY") or "").strip()
    if not api_key:
        return []

    # Main Tunisian arrival airports used by this app's operations.
    tunisian_iata = {"TUN", "NBE", "MIR"}
    today = date.today().isoformat()
    flights: List[Dict[str, Any]] = []

    for arr_iata in tunisian_iata:
        try:
            query = urlencode(
                {
                    "api_key": api_key,
                    "arr_iata": arr_iata,
                    "limit": "20",
                }
            )
            url = f"https://airlabs.co/api/v9/flights?{query}"
            with urlopen(url, timeout=8) as resp:
                payload = json.loads(resp.read().decode("utf-8"))
        except Exception:
            continue

        rows = payload.get("response") if isinstance(payload, dict) else None
        if not isinstance(rows, list):
            continue

        for r in rows:
            if not isinstance(r, dict):
                continue
            arrival_code = str(r.get("arr_iata") or arr_iata or "").upper()
            if arrival_code not in tunisian_iata:
                continue

            flight_number = (
                str(r.get("flight_iata") or "").strip()
                or str(r.get("flight_number") or "").strip()
                or str(r.get("flight_icao") or "").strip()
                or str(r.get("hex") or "").strip()
            )
            if not flight_number:
                continue

            dep_airport = (
                str(r.get("dep_name") or "").strip()
                or str(r.get("dep_city") or "").strip()
                or str(r.get("dep_iata") or "").strip()
                or "Unknown"
            )
            takeoff_raw = str(r.get("dep_time") or "").strip()
            arrival_raw = str(r.get("arr_time") or "").strip()

            arr_en = {
                "TUN": "Tunis–Carthage Airport (TUN)",
                "NBE": "Enfidha Airport (NBE)",
                "MIR": "Monastir Airport (MIR)",
            }.get(arrival_code, f"{arrival_code} Airport")
            arr_ar = {
                "TUN": "مطار قرطاج",
                "NBE": "مطار النفيضة",
                "MIR": "مطار المنستير",
            }.get(arrival_code, "مطار")

            expected = arrival_raw or f"{today} {_hhmm_from_isoish(takeoff_raw)}"
            flights.append(
                {
                    "flight_number": flight_number,
                    "departure_airport": dep_airport,
                    "takeoff_time": _hhmm_from_isoish(takeoff_raw),
                    "expected_arrival": expected,
                    "arrival_airport_ar": arr_ar,
                    "arrival_airport_en": arr_en,
                }
            )

    # De-duplicate by flight number + expected arrival and sort by ETA text.
    seen: set[tuple[str, str]] = set()
    out: List[Dict[str, Any]] = []
    for row in sorted(flights, key=lambda x: str(x.get("expected_arrival") or "")):
        key = (str(row.get("flight_number") or ""), str(row.get("expected_arrival") or ""))
        if key in seen:
            continue
        seen.add(key)
        out.append(row)
    return out
