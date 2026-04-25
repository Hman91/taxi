"""Tunisia fare rules (from legacy Streamlit app)."""
from __future__ import annotations

import random
from datetime import datetime
from typing import Dict, List, Optional, Tuple

from .. import db as db_module

PRISE_EN_CHARGE = 1.0
PRIX_PAR_KM = 1.2

DEFAULT_FARE_ROUTES: List[Dict[str, float | str | bool | int]] = [
    {"start": "مطار قرطاج", "destination": "الحمامات", "distance_km": 82.0, "base_fare": 120.0, "sort_order": 10},
    {"start": "مطار قرطاج", "destination": "سوسة", "distance_km": 125.0, "base_fare": 155.0, "sort_order": 20},
    {"start": "مطار قرطاج", "destination": "القنطاوي", "distance_km": 118.0, "base_fare": 148.0, "sort_order": 30},
    {"start": "مطار قرطاج", "destination": "نابل", "distance_km": 115.0, "base_fare": 145.0, "sort_order": 40},
    {"start": "مطار النفيضة", "destination": "الحمامات", "distance_km": 55.0, "base_fare": 85.0, "sort_order": 50},
    {"start": "مطار النفيضة", "destination": "سوسة", "distance_km": 28.0, "base_fare": 70.0, "sort_order": 60},
    {"start": "مطار النفيضة", "destination": "القنطاوي", "distance_km": 35.0, "base_fare": 78.0, "sort_order": 70},
    {"start": "مطار النفيضة", "destination": "نابل", "distance_km": 98.0, "base_fare": 128.0, "sort_order": 80},
    {"start": "مطار المنستير", "destination": "الحمامات", "distance_km": 48.0, "base_fare": 72.0, "sort_order": 90},
    {"start": "مطار المنستير", "destination": "سوسة", "distance_km": 25.0, "base_fare": 55.0, "sort_order": 100},
    {"start": "مطار المنستير", "destination": "القنطاوي", "distance_km": 22.0, "base_fare": 40.0, "sort_order": 110},
    {"start": "مطار المنستير", "destination": "نابل", "distance_km": 90.0, "base_fare": 118.0, "sort_order": 120},
    {"start": "وسط سوسة", "destination": "الحمامات", "distance_km": 38.0, "base_fare": 62.0, "sort_order": 130},
    {"start": "وسط سوسة", "destination": "سوسة", "distance_km": 8.0, "base_fare": 35.0, "sort_order": 140},
    {"start": "وسط سوسة", "destination": "القنطاوي", "distance_km": 12.0, "base_fare": 38.0, "sort_order": 150},
    {"start": "وسط سوسة", "destination": "نابل", "distance_km": 76.0, "base_fare": 80.0, "sort_order": 160},
]


def _route_key(start: str, destination: str) -> str:
    return f"{start.strip()} ➡️ {destination.strip()}"


def _ensure_seed_if_empty() -> None:
    db_module.fare_routes_seed_defaults(DEFAULT_FARE_ROUTES)  # no-op when populated


def get_airport_fares() -> Dict[str, float]:
    _ensure_seed_if_empty()
    rows = db_module.list_fare_routes(enabled_only=True)
    return {_route_key(r["start"], r["destination"]): float(r["base_fare"]) for r in rows}


def get_airport_route(route_key: str) -> Optional[Dict[str, float | str]]:
    _ensure_seed_if_empty()
    parts = route_key.split("➡️")
    if len(parts) != 2:
        return None
    start = parts[0].strip()
    destination = parts[1].strip()
    row = db_module.fare_route_by_segments(start, destination)
    if row is None:
        return None
    return {
        "start": row["start"],
        "destination": row["destination"],
        "distance_km": float(row["distance_km"]),
        "base_fare": float(row["base_fare"]),
    }


def calculate_fare(base_fare: float) -> Tuple[float, bool]:
    current_hour = datetime.now().hour
    is_night = current_hour >= 21 or current_hour < 5
    final_price = base_fare * 1.5 if is_night else base_fare
    return final_price, is_night


def calculate_gps_fare(distance_km: float) -> Tuple[float, bool]:
    base_fare = PRISE_EN_CHARGE + (distance_km * PRIX_PAR_KM)
    return calculate_fare(base_fare)


def random_stub_distance_km() -> float:
    """Placeholder until real routing; matches old np.random.uniform(2, 20)."""
    return round(random.uniform(2.0, 20.0), 1)
