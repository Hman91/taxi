"""Tunisia fare rules (from legacy Streamlit app)."""
from __future__ import annotations

import random
import math
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
    # Tourist zones -> airport (new requested options).
    {"start": "الحمامات", "destination": "مطار قرطاج", "distance_km": 82.0, "base_fare": 120.0, "sort_order": 170},
    {"start": "الحمامات", "destination": "مطار النفيضة", "distance_km": 55.0, "base_fare": 85.0, "sort_order": 180},
    {"start": "الحمامات", "destination": "مطار المنستير", "distance_km": 48.0, "base_fare": 72.0, "sort_order": 190},
    {"start": "سوسة", "destination": "مطار قرطاج", "distance_km": 125.0, "base_fare": 155.0, "sort_order": 200},
    {"start": "سوسة", "destination": "مطار النفيضة", "distance_km": 28.0, "base_fare": 70.0, "sort_order": 210},
    {"start": "سوسة", "destination": "مطار المنستير", "distance_km": 25.0, "base_fare": 55.0, "sort_order": 220},
    {"start": "القنطاوي", "destination": "مطار قرطاج", "distance_km": 118.0, "base_fare": 148.0, "sort_order": 230},
    {"start": "القنطاوي", "destination": "مطار النفيضة", "distance_km": 35.0, "base_fare": 78.0, "sort_order": 240},
    {"start": "القنطاوي", "destination": "مطار المنستير", "distance_km": 22.0, "base_fare": 40.0, "sort_order": 250},
    {"start": "نابل", "destination": "مطار قرطاج", "distance_km": 115.0, "base_fare": 145.0, "sort_order": 260},
    {"start": "نابل", "destination": "مطار النفيضة", "distance_km": 98.0, "base_fare": 128.0, "sort_order": 270},
    {"start": "نابل", "destination": "مطار المنستير", "distance_km": 90.0, "base_fare": 118.0, "sort_order": 280},
    # Tourist zone intercity (current location -> tourist zone).
    {"start": "الحمامات", "destination": "سوسة", "distance_km": 72.0, "base_fare": 92.0, "sort_order": 290},
    {"start": "الحمامات", "destination": "القنطاوي", "distance_km": 66.0, "base_fare": 88.0, "sort_order": 300},
    {"start": "الحمامات", "destination": "نابل", "distance_km": 12.0, "base_fare": 30.0, "sort_order": 310},
    {"start": "سوسة", "destination": "الحمامات", "distance_km": 72.0, "base_fare": 92.0, "sort_order": 320},
    {"start": "سوسة", "destination": "القنطاوي", "distance_km": 12.0, "base_fare": 38.0, "sort_order": 330},
    {"start": "سوسة", "destination": "نابل", "distance_km": 76.0, "base_fare": 80.0, "sort_order": 340},
    {"start": "القنطاوي", "destination": "الحمامات", "distance_km": 66.0, "base_fare": 88.0, "sort_order": 350},
    {"start": "القنطاوي", "destination": "سوسة", "distance_km": 12.0, "base_fare": 38.0, "sort_order": 360},
    {"start": "القنطاوي", "destination": "نابل", "distance_km": 78.0, "base_fare": 84.0, "sort_order": 370},
    {"start": "نابل", "destination": "الحمامات", "distance_km": 12.0, "base_fare": 30.0, "sort_order": 380},
    {"start": "نابل", "destination": "سوسة", "distance_km": 76.0, "base_fare": 80.0, "sort_order": 390},
    {"start": "نابل", "destination": "القنطاوي", "distance_km": 78.0, "base_fare": 84.0, "sort_order": 400},
]

_AIRPORTS_AR: Tuple[str, ...] = ("مطار قرطاج", "مطار النفيضة", "مطار المنستير")

# User-requested Tunisia destinations (kept as entered for UI/ops familiarity).
_REQUESTED_TOURIST_ZONES: Tuple[str, ...] = (
    "Sidi Bou Saïd",
    "La Marsa",
    "Gammarth",
    "Carthage",
    "Musée du Bardo",
    "Médina de Tunis",
    "Byrsa Hill",
    "Lac de Tunis",
    "Geant",
    "Azur city",
    "tunisia mall",
    "Nabeul",
    "Hammamet",
    "Yasmine Hammamet",
    "Friguia Park",
    "Hergla park",
    "mall of sousse",
    "Skanes",
    "Marina de Monastir",
    "mahdia",
    "Skifa el Kahla",
    "Borj el Kebir",
)

# Existing local pickup zones that were already used before this extension.
_LEGACY_TOURIST_ZONES_AR: Tuple[str, ...] = (
    "الحمامات",
    "سوسة",
    "القنطاوي",
    "نابل",
    "وسط سوسة",
)

# Approximate geo points used to estimate distance_km for newly generated pairs.
_ZONE_COORDS: Dict[str, Tuple[float, float]] = {
    "مطار قرطاج": (36.8510, 10.2270),
    "مطار النفيضة": (36.0756, 10.4380),
    "مطار المنستير": (35.7580, 10.7540),
    "Sidi Bou Saïd": (36.8710, 10.3470),
    "La Marsa": (36.8780, 10.3240),
    "Gammarth": (36.9170, 10.2870),
    "Carthage": (36.8520, 10.3230),
    "Musée du Bardo": (36.8100, 10.1400),
    "Médina de Tunis": (36.8000, 10.1700),
    "Byrsa Hill": (36.8527, 10.3295),
    "Lac de Tunis": (36.8400, 10.2400),
    "Geant": (36.8420, 10.2860),
    "Azur city": (36.7410, 10.2150),
    "tunisia mall": (36.8430, 10.2810),
    "Nabeul": (36.4510, 10.7360),
    "Hammamet": (36.4000, 10.6160),
    "Yasmine Hammamet": (36.3650, 10.5360),
    "Friguia Park": (36.1240, 10.4410),
    "Hergla park": (36.0270, 10.5090),
    "mall of sousse": (35.8290, 10.6350),
    "Skanes": (35.7650, 10.8100),
    "Marina de Monastir": (35.7770, 10.8260),
    "mahdia": (35.5050, 11.0630),
    "Skifa el Kahla": (35.5057, 11.0620),
    "Borj el Kebir": (35.5030, 11.0610),
    "الحمامات": (36.4000, 10.6160),
    "سوسة": (35.8250, 10.6360),
    "القنطاوي": (35.8920, 10.5950),
    "نابل": (36.4510, 10.7360),
    "وسط سوسة": (35.8260, 10.6360),
}


def _haversine_km(a: Tuple[float, float], b: Tuple[float, float]) -> float:
    lat1, lon1 = a
    lat2, lon2 = b
    r = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    x = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    return r * (2 * math.atan2(math.sqrt(x), math.sqrt(1 - x)))


def _estimate_distance_km(start: str, destination: str) -> float:
    a = _ZONE_COORDS.get(start.strip())
    b = _ZONE_COORDS.get(destination.strip())
    if a is None or b is None:
        return 25.0
    # Road factor ~= 1.28 over straight-line.
    km = _haversine_km(a, b) * 1.28
    return round(max(3.0, km), 1)


def _estimate_base_fare(distance_km: float) -> float:
    # Conservative fixed-route pricing heuristic (keeps legacy fares plausible).
    return round(max(28.0, 8.0 + (distance_km * 1.30)), 1)


def _extend_default_routes() -> List[Dict[str, float | str | bool | int]]:
    rows: List[Dict[str, float | str | bool | int]] = list(DEFAULT_FARE_ROUTES)
    seen = {
        (str(r["start"]).strip(), str(r["destination"]).strip())
        for r in rows
    }
    sort_order = max(int(r.get("sort_order", 0) or 0) for r in rows) + 10

    def add(start: str, destination: str) -> None:
        nonlocal sort_order
        key = (start.strip(), destination.strip())
        if key in seen or key[0] == key[1]:
            return
        distance_km = _estimate_distance_km(key[0], key[1])
        rows.append(
            {
                "start": key[0],
                "destination": key[1],
                "distance_km": distance_km,
                "base_fare": _estimate_base_fare(distance_km),
                "sort_order": sort_order,
            }
        )
        seen.add(key)
        sort_order += 10

    # 1) Airport -> new Tunisia list and reverse (Current -> Airport use-case).
    for ap in _AIRPORTS_AR:
        for zone in _REQUESTED_TOURIST_ZONES:
            add(ap, zone)
            add(zone, ap)

    # 2) Current location -> Tunisia list (tourist zones interconnect).
    for start in _REQUESTED_TOURIST_ZONES:
        for destination in _REQUESTED_TOURIST_ZONES:
            add(start, destination)

    # 3) Keep legacy Arabic zones interoperable with new list.
    for start in _LEGACY_TOURIST_ZONES_AR:
        for destination in _REQUESTED_TOURIST_ZONES:
            add(start, destination)
            add(destination, start)

    return rows


ALL_DEFAULT_FARE_ROUTES: List[Dict[str, float | str | bool | int]] = _extend_default_routes()


def _route_key(start: str, destination: str) -> str:
    return f"{start.strip()} ➡️ {destination.strip()}"


def _ensure_seed_if_empty() -> None:
    db_module.fare_routes_seed_defaults(ALL_DEFAULT_FARE_ROUTES)  # no-op when populated
    # Keep old deployments updated when new default routes are added.
    db_module.fare_routes_upsert_defaults(ALL_DEFAULT_FARE_ROUTES)


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
