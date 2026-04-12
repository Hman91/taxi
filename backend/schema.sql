-- Taxi Pro — canonical schema (SQLite, foreign keys).
-- Aligns with .cursor/rules.md: users, drivers, rides + legacy trips/ratings.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'driver')),
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS drivers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT '',
    vehicle_info TEXT,
    is_available INTEGER NOT NULL DEFAULT 1 CHECK (is_available IN (0, 1)),
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS rides (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (
        status IN ('pending', 'accepted', 'ongoing', 'completed', 'cancelled')
    ),
    pickup TEXT NOT NULL,
    destination TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_rides_user_status ON rides(user_id, status);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides(driver_id);

-- Legacy tables (owner/operator metrics, Streamlit-era trips)
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
