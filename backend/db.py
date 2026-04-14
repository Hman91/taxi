"""PostgreSQL access via SQLAlchemy (replaces legacy SQLite helpers)."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import func, select

from .extensions import db
from .models import Driver, Rating, Ride, Trip, User


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
        "preferred_language": u.preferred_language,
        "is_enabled": u.is_enabled,
    }


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
    return {
        "id": int(r.id),
        "user_id": int(r.user_id),
        "driver_id": int(r.driver_id) if r.driver_id is not None else None,
        "status": r.status,
        "pickup": r.pickup,
        "destination": r.destination,
        "created_at": _dt(r.created_at),
        "updated_at": _dt(r.updated_at),
    }


def init_db() -> None:
    """Reserved for one-off setup; schema is applied with Alembic (`alembic upgrade head`)."""
    return


# --- users / drivers (JWT app auth) ---


def user_create(*, email: str, password_hash: str, role: str) -> int:
    u = User(
        email=email.strip().lower(),
        password_hash=password_hash,
        role=role,
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


def insert_rating(stars: int) -> None:
    db.session.add(Rating(stars=stars))
    db.session.commit()


def rating_stats() -> Dict[str, Any]:
    row = db.session.execute(
        select(func.count(Rating.id), func.avg(Rating.stars))
    ).one()
    n = int(row[0] or 0)
    avg = float(row[1] or 0.0)
    return {"count": n, "average": round(avg, 2) if n else 5.0}


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
