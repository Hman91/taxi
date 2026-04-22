"""PostgreSQL access via SQLAlchemy (replaces legacy SQLite helpers)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import func, select

from .extensions import db
from .models import (
    B2BBooking,
    B2BTenant,
    Driver,
    DriverPinAccount,
    FareRoute,
    Rating,
    Ride,
    RideDispatchCandidate,
    Trip,
    User,
)


def _dt(val: Any) -> Any:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


def _user_dict(u: User) -> Dict[str, Any]:
    return {
        "id": int(u.id),
        "email": u.email,
        "password_hash": u.password_hash,
        "role": u.role,
        "display_name": u.display_name or "",
        "phone": (u.phone or None),
        "photo_url": (u.photo_url or None),
        "preferred_language": u.preferred_language,
        "is_enabled": u.is_enabled,
    }

def list_user_ids_by_role(role: str) -> List[int]:
    rows = db.session.scalars(select(User.id).where(User.role == role.strip().lower())).all()
    return [int(x) for x in rows]


def _driver_dict(d: Driver) -> Dict[str, Any]:
    return {
        "id": int(d.id),
        "user_id": int(d.user_id),
        "display_name": d.display_name or "",
        "vehicle_info": d.vehicle_info or "",
        "is_available": 1 if d.is_available else 0,
        "last_lat": d.last_lat,
        "last_lng": d.last_lng,
        "last_seen_at": _dt(d.last_seen_at),
    }


def _ride_dict(r: Ride) -> Dict[str, Any]:
    driver_name = None
    driver_vehicle = None
    driver_phone = None
    driver_photo_url = None
    driver_car_model = None
    driver_car_color = None
    driver_current_zone = None
    b2b_booking = db.session.scalars(
        select(B2BBooking).where(B2BBooking.ride_id == int(r.id))
    ).first()
    passenger_name = None
    passenger_phone = None
    u = db.session.get(User, int(r.user_id))
    if u is not None:
        display = (u.display_name or "").strip()
        if display:
            passenger_name = display
        else:
            email = (u.email or "").strip()
            if email:
                passenger_name = email.split("@", 1)[0]
        passenger_phone = (u.phone or "").strip() or None
    if b2b_booking is not None:
        passenger_name = b2b_booking.guest_name or passenger_name
        room_blob = (b2b_booking.room_number or "").strip()
        if "Phone:" in room_blob:
            try:
                passenger_phone = room_blob.split("Phone:", 1)[1].split("|", 1)[0].strip()
            except Exception:
                passenger_phone = None
    if r.driver_id is not None:
        d = db.session.get(Driver, int(r.driver_id))
        if d is not None:
            driver_name = d.display_name or None
            driver_vehicle = d.vehicle_info or None
            u = db.session.get(User, int(d.user_id))
            if u is not None:
                email = (u.email or "").strip().lower()
                prefix = "driverpin_"
                suffix = "@taxipro.local"
                if email.startswith(prefix) and email.endswith(suffix):
                    phone = email[len(prefix) : -len(suffix)]
                    pin_row = db.session.scalars(
                        select(DriverPinAccount).where(DriverPinAccount.phone == phone)
                    ).first()
                    if pin_row is not None:
                        driver_phone = pin_row.phone
                        driver_photo_url = pin_row.photo_url
                        driver_car_model = pin_row.car_model
                        driver_car_color = pin_row.car_color
                        driver_current_zone = pin_row.current_zone
    return {
        "id": int(r.id),
        "user_id": int(r.user_id),
        "driver_id": int(r.driver_id) if r.driver_id is not None else None,
        "status": r.status,
        "pickup": r.pickup,
        "destination": r.destination,
        "driver_name": driver_name,
        "driver_vehicle": driver_vehicle,
        "driver_phone": driver_phone,
        "driver_photo_url": driver_photo_url,
        "driver_car_model": driver_car_model,
        "driver_car_color": driver_car_color,
        "driver_current_zone": driver_current_zone,
        "passenger_name": passenger_name,
        "passenger_phone": passenger_phone,
        "is_rated": rating_exists_for_ride(int(r.id)),
        "is_b2b": b2b_booking is not None,
        "b2b_guest_name": b2b_booking.guest_name if b2b_booking is not None else None,
        "b2b_room_number": b2b_booking.room_number if b2b_booking is not None else None,
        "b2b_source_code": b2b_booking.source_code if b2b_booking is not None else None,
        "b2b_fare": float(b2b_booking.fare) if b2b_booking is not None else None,
        "created_at": _dt(r.created_at),
        "updated_at": _dt(r.updated_at),
    }


def _fare_route_dict(r: FareRoute) -> Dict[str, Any]:
    return {
        "id": int(r.id),
        "start": r.start,
        "destination": r.destination,
        "distance_km": float(r.distance_km or 0.0),
        "base_fare": float(r.base_fare),
        "is_enabled": bool(r.is_enabled),
        "sort_order": int(r.sort_order or 0),
    }


def _driver_pin_account_dict(r: DriverPinAccount) -> Dict[str, Any]:
    return {
        "id": int(r.id),
        "phone": r.phone,
        "pin": r.pin,
        "driver_name": r.driver_name,
        "wallet_balance": float(r.wallet_balance or 0.0),
        "owner_commission_rate": float(r.owner_commission_rate or 10.0),
        "b2b_commission_rate": float(r.b2b_commission_rate or 5.0),
        "auto_deduct_enabled": bool(r.auto_deduct_enabled),
        "photo_url": r.photo_url,
        "car_model": r.car_model,
        "car_color": r.car_color,
        "current_zone": r.current_zone,
    }


def _b2b_booking_dict(r: B2BBooking) -> Dict[str, Any]:
    return {
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
        "created_at": _dt(r.created_at),
    }


def init_db() -> None:
    """Reserved for one-off setup; schema is applied with Alembic (`alembic upgrade head`)."""
    return


# --- fare routes (airport / fixed transfers) ---


def list_fare_routes(*, enabled_only: bool = True) -> List[Dict[str, Any]]:
    stmt = select(FareRoute).order_by(FareRoute.sort_order.asc(), FareRoute.id.asc())
    if enabled_only:
        stmt = stmt.where(FareRoute.is_enabled.is_(True))
    rows = db.session.scalars(stmt).all()
    return [_fare_route_dict(x) for x in rows]


def fare_route_by_segments(start: str, destination: str) -> Optional[Dict[str, Any]]:
    row = db.session.scalars(
        select(FareRoute).where(
            FareRoute.start == start.strip(),
            FareRoute.destination == destination.strip(),
            FareRoute.is_enabled.is_(True),
        )
    ).first()
    return _fare_route_dict(row) if row else None


def fare_route_update(
    route_id: int, *, base_fare: Optional[float] = None
) -> Optional[Dict[str, Any]]:
    row = db.session.get(FareRoute, route_id)
    if row is None:
        return None
    if base_fare is not None:
        row.base_fare = float(base_fare)
    db.session.commit()
    return _fare_route_dict(row)


def fare_routes_seed_defaults(rows: List[Dict[str, Any]]) -> int:
    existing = db.session.scalars(select(func.count(FareRoute.id))).one()
    if int(existing or 0) > 0:
        return 0
    created = 0
    for i, row in enumerate(rows, start=1):
        db.session.add(
            FareRoute(
                start=str(row["start"]).strip(),
                destination=str(row["destination"]).strip(),
                distance_km=float(row.get("distance_km", 0.0) or 0.0),
                base_fare=float(row["base_fare"]),
                is_enabled=bool(row.get("is_enabled", True)),
                sort_order=int(row.get("sort_order", i * 10)),
            )
        )
        created += 1
    db.session.commit()
    return created


def driver_pin_by_phone(phone: str) -> Optional[Dict[str, Any]]:
    row = db.session.scalars(
        select(DriverPinAccount).where(DriverPinAccount.phone == phone.strip())
    ).first()
    return _driver_pin_account_dict(row) if row else None


def driver_pin_account_by_user_id(user_id: int) -> Optional[Dict[str, Any]]:
    """Resolve PIN wallet row for drivers logged in as driverpin_{phone}@taxipro.local."""
    u = db.session.get(User, user_id)
    if u is None:
        return None
    email = (u.email or "").strip().lower()
    prefix = "driverpin_"
    suffix = "@taxipro.local"
    if not (email.startswith(prefix) and email.endswith(suffix)):
        return None
    phone = email[len(prefix) : -len(suffix)]
    return driver_pin_by_phone(phone)


def driver_pin_seed_defaults(rows: List[Dict[str, Any]]) -> int:
    existing = db.session.scalars(select(func.count(DriverPinAccount.id))).one()
    if int(existing or 0) > 0:
        return 0
    created = 0
    for row in rows:
        db.session.add(
            DriverPinAccount(
                phone=str(row["phone"]).strip(),
                pin=str(row["pin"]).strip(),
                driver_name=str(row["driver_name"]).strip(),
                wallet_balance=float(row.get("wallet_balance", 0.0) or 0.0),
                owner_commission_rate=float(row.get("owner_commission_rate", 10.0) or 10.0),
                b2b_commission_rate=float(row.get("b2b_commission_rate", 5.0) or 5.0),
                auto_deduct_enabled=bool(row.get("auto_deduct_enabled", True)),
                photo_url=(str(row.get("photo_url") or "").strip() or None),
                car_model=(str(row.get("car_model") or "").strip() or None),
                car_color=(str(row.get("car_color") or "").strip() or None),
                current_zone=(str(row.get("current_zone") or "").strip() or None),
            )
        )
        created += 1
    db.session.commit()
    return created


def list_driver_pin_accounts() -> List[Dict[str, Any]]:
    rows = db.session.scalars(
        select(DriverPinAccount).order_by(DriverPinAccount.id.asc())
    ).all()
    return [_driver_pin_account_dict(r) for r in rows]


def driver_pin_create(
    *,
    phone: str,
    pin: str,
    driver_name: str,
    car_model: str,
    car_color: str,
    photo_url: str,
) -> Optional[Dict[str, Any]]:
    phone = phone.strip()
    if (
        not phone
        or not pin.strip()
        or not driver_name.strip()
        or not car_model.strip()
        or not car_color.strip()
        or not photo_url.strip()
    ):
        return None
    if driver_pin_by_phone(phone) is not None:
        return None
    row = DriverPinAccount(
        phone=phone,
        pin=pin.strip(),
        driver_name=driver_name.strip(),
        car_model=car_model.strip(),
        car_color=car_color.strip(),
        photo_url=photo_url.strip(),
    )
    db.session.add(row)
    db.session.commit()
    db.session.refresh(row)
    return _driver_pin_account_dict(row)


def driver_pin_by_id(account_id: int) -> Optional[Dict[str, Any]]:
    row = db.session.get(DriverPinAccount, account_id)
    return _driver_pin_account_dict(row) if row else None


def driver_pin_update(
    account_id: int,
    *,
    phone: Optional[str] = None,
    pin: Optional[str] = None,
    driver_name: Optional[str] = None,
    wallet_balance: Optional[float] = None,
    owner_commission_rate: Optional[float] = None,
    b2b_commission_rate: Optional[float] = None,
    auto_deduct_enabled: Optional[bool] = None,
    photo_url: Optional[str] = None,
    car_model: Optional[str] = None,
    car_color: Optional[str] = None,
    current_zone: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    row = db.session.get(DriverPinAccount, account_id)
    if row is None:
        return None
    if phone is not None:
        row.phone = phone.strip()
    if pin is not None:
        row.pin = pin.strip()
    if driver_name is not None:
        row.driver_name = driver_name.strip()
    if wallet_balance is not None:
        row.wallet_balance = float(wallet_balance)
    if owner_commission_rate is not None:
        row.owner_commission_rate = float(owner_commission_rate)
    if b2b_commission_rate is not None:
        row.b2b_commission_rate = float(b2b_commission_rate)
    if auto_deduct_enabled is not None:
        row.auto_deduct_enabled = bool(auto_deduct_enabled)
    if photo_url is not None:
        row.photo_url = photo_url.strip() or None
    if car_model is not None:
        row.car_model = car_model.strip() or None
    if car_color is not None:
        row.car_color = car_color.strip() or None
    if current_zone is not None:
        row.current_zone = current_zone.strip() or None
    db.session.commit()
    db.session.refresh(row)
    return _driver_pin_account_dict(row)


def b2b_tenant_by_code(code: str) -> Optional[Dict[str, Any]]:
    row = db.session.scalars(
        select(B2BTenant).where(B2BTenant.code == code.strip())
    ).first()
    if row is None:
        return None
    return {
        "id": int(row.id),
        "code": row.code,
        "label": row.label,
        "is_enabled": bool(row.is_enabled),
    }


def b2b_tenant_seed_defaults(rows: List[Dict[str, Any]]) -> int:
    existing = db.session.scalars(select(func.count(B2BTenant.id))).one()
    if int(existing or 0) > 0:
        return 0
    created = 0
    for row in rows:
        db.session.add(
            B2BTenant(
                code=str(row["code"]).strip(),
                label=str(row.get("label") or "").strip() or None,
                is_enabled=bool(row.get("is_enabled", True)),
            )
        )
        created += 1
    db.session.commit()
    return created


def b2b_booking_insert(
    *,
    tenant_id: Optional[int],
    route: str,
    pickup: str,
    destination: str,
    guest_name: str,
    room_number: str,
    fare: float,
    status: str,
    source_code: str,
    ride_id: Optional[int],
) -> Dict[str, Any]:
    row = B2BBooking(
        tenant_id=tenant_id,
        route=route,
        pickup=pickup,
        destination=destination,
        guest_name=guest_name,
        room_number=room_number or None,
        fare=fare,
        status=status,
        source_code=source_code,
        ride_id=ride_id,
    )
    db.session.add(row)
    db.session.commit()
    db.session.refresh(row)
    return _b2b_booking_dict(row)


def b2b_booking_by_ride_id(ride_id: int) -> Optional[Dict[str, Any]]:
    row = db.session.scalars(
        select(B2BBooking).where(B2BBooking.ride_id == int(ride_id))
    ).first()
    return _b2b_booking_dict(row) if row else None


def b2b_booking_update(booking_id: int, **fields: Any) -> Optional[Dict[str, Any]]:
    row = db.session.get(B2BBooking, int(booking_id))
    if row is None:
        return None
    for k in (
        "status",
        "ride_id",
        "guest_name",
        "room_number",
        "route",
        "pickup",
        "destination",
        "fare",
    ):
        if k in fields and fields[k] is not None:
            setattr(row, k, fields[k])
    db.session.commit()
    db.session.refresh(row)
    return _b2b_booking_dict(row)


# --- users / drivers (JWT app auth) ---


def user_create(
    *,
    email: str,
    password_hash: str,
    role: str,
    display_name: str = "",
    phone: Optional[str] = None,
    photo_url: Optional[str] = None,
) -> int:
    u = User(
        email=email.strip().lower(),
        password_hash=password_hash,
        role=role,
        display_name=(display_name or "").strip(),
        phone=(phone or "").strip() or None,
        photo_url=(photo_url or "").strip() or None,
    )
    db.session.add(u)
    db.session.commit()
    return int(u.id)


def user_by_email(email: str) -> Optional[Dict[str, Any]]:
    u = db.session.scalars(
        select(User).where(User.email == email.strip().lower())
    ).first()
    return _user_dict(u) if u else None


def user_by_id(uid: int) -> Optional[Dict[str, Any]]:
    u = db.session.get(User, uid)
    return _user_dict(u) if u else None


def driver_create(*, user_id: int, display_name: str, vehicle_info: str = "") -> int:
    d = Driver(
        user_id=user_id,
        display_name=display_name,
        vehicle_info=vehicle_info or "",
        is_available=True,
    )
    db.session.add(d)
    db.session.commit()
    return int(d.id)


def driver_by_user_id(user_id: int) -> Optional[Dict[str, Any]]:
    d = db.session.scalars(select(Driver).where(Driver.user_id == user_id)).first()
    return _driver_dict(d) if d else None


def driver_by_id(driver_pk: int) -> Optional[Dict[str, Any]]:
    d = db.session.get(Driver, driver_pk)
    return _driver_dict(d) if d else None


# --- rides ---


def user_has_active_ride(user_id: int) -> bool:
    stmt = (
        select(Ride.id)
        .where(
            Ride.user_id == user_id,
            Ride.status.in_(("pending", "accepted", "ongoing")),
        )
        .limit(1)
    )
    return db.session.scalars(stmt).first() is not None


def ride_insert(
    *,
    user_id: int,
    pickup: str,
    destination: str,
    status: str = "pending",
) -> Dict[str, Any]:
    now = datetime.now(timezone.utc)
    r = Ride(
        user_id=user_id,
        pickup=pickup,
        destination=destination,
        status=status,
        created_at=now,
        updated_at=now,
    )
    db.session.add(r)
    db.session.commit()
    db.session.refresh(r)
    return _ride_dict(r)


def ride_get(ride_id: int) -> Optional[Dict[str, Any]]:
    r = db.session.get(Ride, ride_id)
    return _ride_dict(r) if r else None


def ride_to_dict(row: Any) -> Dict[str, Any]:
    """Normalize a ride ORM row or dict for JSON-style consumers."""
    if isinstance(row, Ride):
        return _ride_dict(row)
    return dict(row)


def ride_update(
    ride_id: int,
    *,
    driver_id: Optional[int] = None,
    status: Optional[str] = None,
    clear_driver: bool = False,
) -> Optional[Dict[str, Any]]:
    r = db.session.get(Ride, ride_id)
    if r is None:
        return None
    new_driver = r.driver_id
    if clear_driver:
        new_driver = None
    elif driver_id is not None:
        new_driver = driver_id
    new_status = status if status is not None else r.status
    r.driver_id = new_driver
    r.status = new_status
    r.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    db.session.refresh(r)
    return _ride_dict(r)


def rides_list_pending() -> List[Dict[str, Any]]:
    rows = db.session.scalars(
        select(Ride).where(Ride.status == "pending").order_by(Ride.id.asc())
    ).all()
    return [_ride_dict(x) for x in rows]


def driver_pin_wallet_balance_for_user(user_id: int) -> float:
    """Wallet from driver_pin account; 0 if missing (PIN drivers only)."""
    acct = driver_pin_account_by_user_id(user_id)
    if acct is None:
        return 0.0
    return float(acct.get("wallet_balance") or 0.0)


def driver_profiles_for_dispatch() -> List[Dict[str, Any]]:
    rows = db.session.scalars(
        select(Driver).where(Driver.is_available.is_(True)).order_by(Driver.id.asc())
    ).all()
    eligible = [
        x
        for x in rows
        if driver_pin_wallet_balance_for_user(int(x.user_id)) > 0.0
    ]
    return [_driver_dict(x) for x in eligible]


def driver_profiles_for_dispatch_online(window_minutes: int = 30) -> List[Dict[str, Any]]:
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=max(1, window_minutes))
    rows = db.session.scalars(
        select(Driver)
        .where(
            Driver.is_available.is_(True),
            Driver.last_seen_at.is_not(None),
            Driver.last_seen_at >= cutoff,
        )
        .order_by(Driver.last_seen_at.desc(), Driver.id.asc())
    ).all()
    eligible = [
        x
        for x in rows
        if driver_pin_wallet_balance_for_user(int(x.user_id)) > 0.0
    ]
    return [_driver_dict(x) for x in eligible]


def driver_mark_online(user_id: int, *, last_lat: float | None = None, last_lng: float | None = None) -> None:
    row = db.session.scalars(select(Driver).where(Driver.user_id == user_id)).first()
    if row is None:
        return
    # Cannot be "available" for dispatch with zero (or negative) wallet balance.
    row.is_available = driver_pin_wallet_balance_for_user(user_id) > 0.0
    if last_lat is not None:
        row.last_lat = float(last_lat)
    if last_lng is not None:
        row.last_lng = float(last_lng)
    row.last_seen_at = datetime.now(timezone.utc)
    db.session.commit()


def driver_touch_online(user_id: int, *, last_lat: float | None = None, last_lng: float | None = None) -> None:
    row = db.session.scalars(select(Driver).where(Driver.user_id == user_id)).first()
    if row is None:
        return
    if last_lat is not None:
        row.last_lat = float(last_lat)
    if last_lng is not None:
        row.last_lng = float(last_lng)
    row.last_seen_at = datetime.now(timezone.utc)
    db.session.commit()


def driver_set_availability_by_user_id(user_id: int, is_available: bool) -> None:
    row = db.session.scalars(select(Driver).where(Driver.user_id == user_id)).first()
    if row is None:
        return
    row.is_available = bool(is_available)
    row.last_seen_at = datetime.now(timezone.utc)
    db.session.commit()


def driver_update_current_zone_by_user_id(user_id: int, current_zone: str) -> None:
    u = db.session.get(User, user_id)
    if u is None:
        return
    email = (u.email or "").strip().lower()
    prefix = "driverpin_"
    suffix = "@taxipro.local"
    if not (email.startswith(prefix) and email.endswith(suffix)):
        return
    phone = email[len(prefix) : -len(suffix)]
    row = db.session.scalars(
        select(DriverPinAccount).where(DriverPinAccount.phone == phone)
    ).first()
    if row is None:
        return
    row.current_zone = (current_zone or "").strip() or None
    db.session.commit()


def driver_current_zone_by_user_id(user_id: int) -> Optional[str]:
    u = db.session.get(User, user_id)
    if u is None:
        return None
    email = (u.email or "").strip().lower()
    prefix = "driverpin_"
    suffix = "@taxipro.local"
    if not (email.startswith(prefix) and email.endswith(suffix)):
        return None
    phone = email[len(prefix) : -len(suffix)]
    row = db.session.scalars(
        select(DriverPinAccount).where(DriverPinAccount.phone == phone)
    ).first()
    if row is None:
        return None
    zone = (row.current_zone or "").strip()
    return zone or None


def ride_dispatch_set_candidates(ride_id: int, driver_user_ids: List[int]) -> None:
    if not driver_user_ids:
        return
    db.session.execute(
        RideDispatchCandidate.__table__.delete().where(
            RideDispatchCandidate.ride_id == ride_id
        )
    )
    for rank, uid in enumerate(driver_user_ids, start=1):
        db.session.add(
            RideDispatchCandidate(
                ride_id=ride_id,
                driver_user_id=int(uid),
                rank=rank,
            )
        )
    db.session.commit()


def ride_dispatch_candidates_for_ride(ride_id: int) -> List[int]:
    rows = db.session.scalars(
        select(RideDispatchCandidate.driver_user_id)
        .where(RideDispatchCandidate.ride_id == ride_id)
        .order_by(RideDispatchCandidate.rank.asc())
    ).all()
    return [int(x) for x in rows]


def ride_dispatch_pending_for_driver_user(driver_user_id: int) -> List[Dict[str, Any]]:
    stmt = (
        select(Ride)
        .join(RideDispatchCandidate, RideDispatchCandidate.ride_id == Ride.id)
        .where(
            Ride.status == "pending",
            RideDispatchCandidate.driver_user_id == driver_user_id,
        )
        .order_by(Ride.id.desc())
    )
    rows = db.session.scalars(stmt).all()
    return [_ride_dict(x) for x in rows]


def rides_for_user(user_id: int) -> List[Dict[str, Any]]:
    rows = db.session.scalars(
        select(Ride).where(Ride.user_id == user_id).order_by(Ride.id.desc())
    ).all()
    return [_ride_dict(x) for x in rows]


def rides_for_driver(driver_pk: int) -> List[Dict[str, Any]]:
    rows = db.session.scalars(
        select(Ride).where(Ride.driver_id == driver_pk).order_by(Ride.id.desc())
    ).all()
    return [_ride_dict(x) for x in rows]


# --- legacy trips / ratings ---


def trip_to_dict(t: Trip) -> Dict[str, Any]:
    return {
        "id": int(t.id),
        "date": t.date,
        "driver": t.driver,
        "route": t.route,
        "fare": t.fare,
        "commission": t.commission,
        "type": t.type,
        "status": t.status,
        "created_at": _dt(t.created_at),
    }


def list_trips() -> List[Dict[str, Any]]:
    rows = db.session.scalars(select(Trip).order_by(Trip.id.desc())).all()
    return [trip_to_dict(t) for t in rows]


def insert_trip(
    *,
    date: str,
    driver: str,
    route: str,
    fare: float,
    commission: float,
    trip_type: str,
    status: str,
) -> Dict[str, Any]:
    t = Trip(
        date=date,
        driver=driver,
        route=route,
        fare=fare,
        commission=commission,
        type=trip_type,
        status=status,
    )
    db.session.add(t)
    db.session.commit()
    db.session.refresh(t)
    return trip_to_dict(t)


def insert_rating(*, ride_id: int, driver_id: int, stars: int) -> None:
    db.session.add(Rating(ride_id=ride_id, driver_id=driver_id, stars=stars))
    db.session.commit()


def rating_stats(driver_id: int | None = None) -> Dict[str, Any]:
    stmt = select(func.count(Rating.id), func.avg(Rating.stars))
    if driver_id is not None:
        stmt = stmt.where(Rating.driver_id == int(driver_id))
    row = db.session.execute(stmt).one()
    n = int(row[0] or 0)
    avg = float(row[1] or 0.0)
    return {"count": n, "average": round(avg, 2) if n else 5.0}


def rating_exists_for_ride(ride_id: int) -> bool:
    stmt = select(Rating.id).where(Rating.ride_id == int(ride_id)).limit(1)
    return db.session.scalars(stmt).first() is not None


def owner_metrics() -> Dict[str, Any]:
    row = db.session.execute(
        select(func.count(Trip.id), func.coalesce(func.sum(Trip.commission), 0.0))
    ).one()
    stats = rating_stats()
    return {
        "total_commission": float(row[1] or 0),
        "trip_count": int(row[0] or 0),
        "rating_average": stats["average"],
        "rating_count": stats["count"],
    }
