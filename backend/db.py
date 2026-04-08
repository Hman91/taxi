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
        g.db = conn
    return g.db


def close_db(exc: Optional[BaseException] = None) -> None:
    conn = g.pop("db", None)
    if conn is not None:
        conn.close()


def init_db() -> None:
    db = get_db()
    db.executescript(
        """
        CREATE TABLE IF NOT EXISTS trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            driver TEXT NOT NULL,
            route TEXT NOT NULL,
            fare REAL NOT NULL,
            commission REAL NOT NULL,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS ratings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stars INTEGER NOT NULL CHECK (stars >= 1 AND stars <= 5),
            created_at TEXT DEFAULT (datetime('now'))
        );
        """
    )
    db.commit()


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
