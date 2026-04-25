"""
One-off copy of legacy SQLite data into PostgreSQL.

Order: users → drivers → rides → trips → ratings (preserves integer IDs and FKs).

Requires:
  - `DATABASE_URL` pointing at PostgreSQL with Alembic schema already applied
  - SQLite file (default: `TAXI_SQLITE_PATH` or `backend/data/taxi.db`)

Usage (from repository root):
  python -m backend.scripts.migrate_sqlite_to_pg --dry-run
  python -m backend.scripts.migrate_sqlite_to_pg --replace
"""
from __future__ import annotations

import argparse
import os
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Optional

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection, Engine

_TABLES = ("users", "drivers", "rides", "trips", "ratings")


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _default_sqlite_path() -> Path:
    return Path(
        os.environ.get(
            "TAXI_SQLITE_PATH",
            str(_repo_root() / "backend" / "data" / "taxi.db"),
        )
    )


def _pg_url() -> str:
    return os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg2://postgres:postgres@127.0.0.1:5432/taxi",
    )


def _parse_sqlite_datetime(raw: Any) -> Optional[datetime]:
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    s = str(raw).strip()
    if not s:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M:%S.%f"):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def _sqlite_table_exists(conn: sqlite3.Connection, name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (name,),
    ).fetchone()
    return row is not None


def _sqlite_counts(conn: sqlite3.Connection) -> dict[str, int]:
    out: dict[str, int] = {}
    for table in _TABLES:
        if not _sqlite_table_exists(conn, table):
            out[table] = 0
            continue
        row = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()
        out[table] = int(row[0]) if row else 0
    return out


def _pg_counts(engine: Engine) -> dict[str, int]:
    out: dict[str, int] = {}
    with engine.connect() as conn:
        for table in _TABLES:
            n = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
            out[table] = int(n or 0)
    return out


def _truncate_pg(conn: Connection) -> None:
    conn.execute(
        text(
            "TRUNCATE TABLE ratings, trips, rides, drivers, users "
            "RESTART IDENTITY CASCADE"
        )
    )


def _sync_sequences(conn: Connection) -> None:
    for table in _TABLES:
        seq = conn.execute(
            text("SELECT pg_get_serial_sequence(:q, 'id')"),
            {"q": f"public.{table}"},
        ).scalar()
        if not seq:
            continue
        max_id = conn.execute(text(f"SELECT COALESCE(MAX(id), 0) FROM {table}")).scalar()
        m = int(max_id or 0)
        seq_lit = str(seq).replace("'", "''")
        if m == 0:
            conn.execute(text(f"SELECT setval('{seq_lit}', 1, false)"))
        else:
            conn.execute(text(f"SELECT setval('{seq_lit}', {m}, true)"))


def _fetchall(conn: sqlite3.Connection, sql: str) -> list[sqlite3.Row]:
    return list(conn.execute(sql).fetchall())


def migrate(
    *,
    sqlite_path: Path,
    pg_engine: Engine,
    dry_run: bool,
    replace: bool,
) -> int:
    if not sqlite_path.is_file():
        if dry_run:
            try:
                dst = _pg_counts(pg_engine)
                print("PostgreSQL row counts:", dst)
            except Exception as e:
                print(f"Could not connect to PostgreSQL: {e}", file=sys.stderr)
                return 1
        print(f"No SQLite file at {sqlite_path}; nothing to migrate.", file=sys.stderr)
        return 0

    sl = sqlite3.connect(str(sqlite_path))
    sl.row_factory = sqlite3.Row
    try:
        src = _sqlite_counts(sl)
        print("SQLite row counts:", src)

        dst_before = _pg_counts(pg_engine)
        print("PostgreSQL row counts (before):", dst_before)

        if dry_run:
            print("Dry run: no changes written.")
            return 0

        total_dst = sum(dst_before.values())
        if total_dst > 0 and not replace:
            print(
                "PostgreSQL already has data. Re-run with --replace to TRUNCATE "
                "these tables and import again, or use an empty database.",
                file=sys.stderr,
            )
            return 1

        with pg_engine.begin() as pg:
            if replace and total_dst > 0:
                _truncate_pg(pg)

            if _sqlite_table_exists(sl, "users"):
                for r in _fetchall(
                    sl, "SELECT id, email, password_hash, role, created_at FROM users ORDER BY id"
                ):
                    pg.execute(
                        text(
                            "INSERT INTO users (id, email, password_hash, role, created_at) "
                            "VALUES (:id, :email, :password_hash, :role, :created_at)"
                        ),
                        {
                            "id": int(r["id"]),
                            "email": r["email"],
                            "password_hash": r["password_hash"],
                            "role": r["role"],
                            "created_at": _parse_sqlite_datetime(r["created_at"]),
                        },
                    )

            if _sqlite_table_exists(sl, "drivers"):
                for r in _fetchall(
                    sl,
                    "SELECT id, user_id, display_name, vehicle_info, is_available, created_at "
                    "FROM drivers ORDER BY id",
                ):
                    avail = bool(int(r["is_available"])) if r["is_available"] is not None else True
                    pg.execute(
                        text(
                            "INSERT INTO drivers (id, user_id, display_name, vehicle_info, is_available, created_at) "
                            "VALUES (:id, :user_id, :display_name, :vehicle_info, :is_available, :created_at)"
                        ),
                        {
                            "id": int(r["id"]),
                            "user_id": int(r["user_id"]),
                            "display_name": r["display_name"] or "",
                            "vehicle_info": r["vehicle_info"],
                            "is_available": avail,
                            "created_at": _parse_sqlite_datetime(r["created_at"]),
                        },
                    )

            if _sqlite_table_exists(sl, "rides"):
                for r in _fetchall(
                    sl,
                    "SELECT id, user_id, driver_id, status, pickup, destination, created_at, updated_at "
                    "FROM rides ORDER BY id",
                ):
                    pg.execute(
                        text(
                            "INSERT INTO rides (id, user_id, driver_id, status, pickup, destination, created_at, updated_at) "
                            "VALUES (:id, :user_id, :driver_id, :status, :pickup, :destination, :created_at, :updated_at)"
                        ),
                        {
                            "id": int(r["id"]),
                            "user_id": int(r["user_id"]),
                            "driver_id": int(r["driver_id"]) if r["driver_id"] is not None else None,
                            "status": r["status"],
                            "pickup": r["pickup"],
                            "destination": r["destination"],
                            "created_at": _parse_sqlite_datetime(r["created_at"]),
                            "updated_at": _parse_sqlite_datetime(r["updated_at"]),
                        },
                    )

            if _sqlite_table_exists(sl, "trips"):
                for r in _fetchall(
                    sl,
                    "SELECT id, date, driver, route, fare, commission, type, status, created_at FROM trips ORDER BY id",
                ):
                    pg.execute(
                        text(
                            "INSERT INTO trips (id, date, driver, route, fare, commission, type, status, created_at) "
                            "VALUES (:id, :date, :driver, :route, :fare, :commission, :type, :status, :created_at)"
                        ),
                        {
                            "id": int(r["id"]),
                            "date": r["date"],
                            "driver": r["driver"],
                            "route": r["route"],
                            "fare": float(r["fare"]),
                            "commission": float(r["commission"]),
                            "type": r["type"],
                            "status": r["status"],
                            "created_at": _parse_sqlite_datetime(r["created_at"]),
                        },
                    )

            if _sqlite_table_exists(sl, "ratings"):
                for r in _fetchall(sl, "SELECT id, stars, created_at FROM ratings ORDER BY id"):
                    pg.execute(
                        text(
                            "INSERT INTO ratings (id, stars, created_at) VALUES (:id, :stars, :created_at)"
                        ),
                        {
                            "id": int(r["id"]),
                            "stars": int(r["stars"]),
                            "created_at": _parse_sqlite_datetime(r["created_at"]),
                        },
                    )

            _sync_sequences(pg)

        dst_after = _pg_counts(pg_engine)
        print("PostgreSQL row counts (after):", dst_after)
        if src != dst_after:
            print("Warning: row counts differ between SQLite and PostgreSQL.", file=sys.stderr)
            return 1
        print("Migration finished; counts match.")
        return 0
    finally:
        sl.close()


def main(argv: Optional[Iterable[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Copy Taxi Pro data from SQLite to PostgreSQL.")
    p.add_argument(
        "--sqlite-path",
        type=Path,
        default=None,
        help="Path to taxi.db (default: TAXI_SQLITE_PATH or backend/data/taxi.db)",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print row counts; do not write to PostgreSQL.",
    )
    p.add_argument(
        "--replace",
        action="store_true",
        help="If PostgreSQL tables already have rows, TRUNCATE them before import.",
    )
    args = p.parse_args(list(argv) if argv is not None else None)

    sqlite_path = args.sqlite_path or _default_sqlite_path()
    engine = create_engine(_pg_url(), pool_pre_ping=True)
    return migrate(
        sqlite_path=sqlite_path,
        pg_engine=engine,
        dry_run=args.dry_run,
        replace=args.replace,
    )


if __name__ == "__main__":
    raise SystemExit(main())
