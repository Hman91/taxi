"""SQLite access for Taxi Pro."""
from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any, Dict, List, Optional

from flask import current_app, g


def get_db() -> sqlite3.Connection:
    if "db" not in g:
        path = current_app.config["DATABASE_PATH"]
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        g.db = conn
    return g.db


def close_db(exc: Optional[BaseException] = None) -> None:
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


def init_db() -> None:
    db = get_db()
    schema_path = Path(__file__).resolve().with_name("schema.sql")
    if schema_path.is_file():
        db.executescript(schema_path.read_text(encoding="utf-8"))
    else:
        raise FileNotFoundError(f"Missing schema file: {schema_path}")
    db.commit()


# --- users / drivers (JWT app auth) ---


def user_create(*, email: str, password_hash: str, role: str) -> int:
    db = get_db()
    cur = db.execute(
        "INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)",
        (email.strip().lower(), password_hash, role),
    )
    db.commit()
    return int(cur.lastrowid)


def user_by_email(email: str) -> Optional[sqlite3.Row]:
    db = get_db()
    return db.execute(
        "SELECT id, email, password_hash, role FROM users WHERE email = ?",
        (email.strip().lower(),),
    ).fetchone()


def user_by_id(uid: int) -> Optional[sqlite3.Row]:
    db = get_db()
    return db.execute(
        "SELECT id, email, password_hash, role FROM users WHERE id = ?", (uid,)
    ).fetchone()


def driver_create(*, user_id: int, display_name: str, vehicle_info: str = "") -> int:
    db = get_db()
    cur = db.execute(
        """
        INSERT INTO drivers (user_id, display_name, vehicle_info)
        VALUES (?, ?, ?)
        """,
        (user_id, display_name, vehicle_info),
    )
    db.commit()
    return int(cur.lastrowid)


def driver_by_user_id(user_id: int) -> Optional[sqlite3.Row]:
    db = get_db()
    return db.execute(
        "SELECT id, user_id, display_name, vehicle_info, is_available FROM drivers WHERE user_id = ?",
        (user_id,),
    ).fetchone()


def driver_by_id(driver_pk: int) -> Optional[sqlite3.Row]:
    db = get_db()
    return db.execute(
        "SELECT id, user_id, display_name, vehicle_info, is_available FROM drivers WHERE id = ?",
        (driver_pk,),
    ).fetchone()


# --- rides ---


def user_has_active_ride(user_id: int) -> bool:
    db = get_db()
    row = db.execute(
        """
        SELECT 1 FROM rides
        WHERE user_id = ? AND status IN ('pending', 'accepted', 'ongoing')
        LIMIT 1
        """,
        (user_id,),
    ).fetchone()
    return row is not None


def ride_insert(
    *,
    user_id: int,
    pickup: str,
    destination: str,
    status: str = "pending",
) -> Dict[str, Any]:
    db = get_db()
    cur = db.execute(
        """
        INSERT INTO rides (user_id, pickup, destination, status)
        VALUES (?, ?, ?, ?)
        """,
        (user_id, pickup, destination, status),
    )
    db.commit()
    rid = int(cur.lastrowid)
    row = db.execute("SELECT * FROM rides WHERE id = ?", (rid,)).fetchone()
    assert row is not None
    return ride_to_dict(row)


def ride_get(ride_id: int) -> Optional[sqlite3.Row]:
    db = get_db()
    return db.execute("SELECT * FROM rides WHERE id = ?", (ride_id,)).fetchone()


def ride_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    return {
        "id": row["id"],
        "user_id": row["user_id"],
        "driver_id": row["driver_id"],
        "status": row["status"],
        "pickup": row["pickup"],
        "destination": row["destination"],
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
    }


def ride_update(
    ride_id: int,
    *,
    driver_id: Optional[int] = None,
    status: Optional[str] = None,
    clear_driver: bool = False,
) -> Optional[Dict[str, Any]]:
    db = get_db()
    row = ride_get(ride_id)
    if row is None:
        return None
    new_driver = row["driver_id"]
    if clear_driver:
        new_driver = None
    elif driver_id is not None:
        new_driver = driver_id
    new_status = status if status is not None else row["status"]
    db.execute(
        """
        UPDATE rides SET driver_id = ?, status = ?, updated_at = datetime('now')
        WHERE id = ?
        """,
        (new_driver, new_status, ride_id),
    )
    db.commit()
    out = ride_get(ride_id)
    return ride_to_dict(out) if out else None


def rides_list_pending() -> List[Dict[str, Any]]:
    db = get_db()
    cur = db.execute(
        "SELECT * FROM rides WHERE status = 'pending' ORDER BY id ASC"
    )
    return [ride_to_dict(r) for r in cur.fetchall()]


def rides_for_user(user_id: int) -> List[Dict[str, Any]]:
    db = get_db()
    cur = db.execute(
        "SELECT * FROM rides WHERE user_id = ? ORDER BY id DESC", (user_id,)
    )
    return [ride_to_dict(r) for r in cur.fetchall()]


def rides_for_driver(driver_pk: int) -> List[Dict[str, Any]]:
    db = get_db()
    cur = db.execute(
        "SELECT * FROM rides WHERE driver_id = ? ORDER BY id DESC", (driver_pk,)
    )
    return [ride_to_dict(r) for r in cur.fetchall()]


# --- legacy trips / ratings ---


def trip_to_dict(row: sqlite3.Row) -> Dict[str, Any]:
    return {
        "id": row["id"],
        "date": row["date"],
        "driver": row["driver"],
        "route": row["route"],
        "fare": row["fare"],
        "commission": row["commission"],
        "type": row["type"],
        "status": row["status"],
        "created_at": row["created_at"],
    }


def list_trips() -> List[Dict[str, Any]]:
    db = get_db()
    cur = db.execute(
        "SELECT id, date, driver, route, fare, commission, type, status, created_at "
        "FROM trips ORDER BY id DESC"
    )
    return [trip_to_dict(row) for row in cur.fetchall()]


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
    db = get_db()
    cur = db.execute(
        """
        INSERT INTO trips (date, driver, route, fare, commission, type, status)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (date, driver, route, fare, commission, trip_type, status),
    )
    db.commit()
    tid = cur.lastrowid
    row = db.execute(
        "SELECT id, date, driver, route, fare, commission, type, status, created_at "
        "FROM trips WHERE id = ?",
        (tid,),
    ).fetchone()
    assert row is not None
    return trip_to_dict(row)


def insert_rating(stars: int) -> None:
    db = get_db()
    db.execute("INSERT INTO ratings (stars) VALUES (?)", (stars,))
    db.commit()


def rating_stats() -> Dict[str, Any]:
    db = get_db()
    row = db.execute(
        "SELECT COUNT(*) AS n, AVG(stars) AS avg_stars FROM ratings"
    ).fetchone()
    n = int(row["n"] or 0)
    avg = float(row["avg_stars"] or 0.0)
    return {"count": n, "average": round(avg, 2) if n else 5.0}


def owner_metrics() -> Dict[str, Any]:
    db = get_db()
    row = db.execute(
        "SELECT COUNT(*) AS trip_count, COALESCE(SUM(commission), 0) AS total_commission "
        "FROM trips"
    ).fetchone()
    stats = rating_stats()
    return {
        "total_commission": float(row["total_commission"] or 0),
        "trip_count": int(row["trip_count"] or 0),
        "rating_average": stats["average"],
        "rating_count": stats["count"],
    }
