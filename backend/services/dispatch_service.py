"""Nearest-driver dispatch: GPS-ranked offers to online, available drivers."""
from __future__ import annotations

import logging
import math
import threading
from typing import Any, Dict, List, Optional, Set, Tuple

from .. import db as db_module
from . import realtime_broadcast

log = logging.getLogger(__name__)

DISPATCH_WAVE_SIZE = 5
_DISPATCH_WAVE_SIZE = DISPATCH_WAVE_SIZE
_DISPATCH_WAVE_TIMEOUT_SEC = 90.0
_DISPATCH_MAX_WAVES = 3
_ONLINE_WINDOW_MINUTES = 30
_EARTH_RADIUS_KM = 6371.0

# Catalog zone centers when ride pickup has no GPS snapshot yet.
_ZONE_COORDS: Dict[str, Tuple[float, float]] = {
    "مطار قرطاج": (36.8508, 10.2272),
    "مطار النفيضة": (36.0758, 10.4386),
    "مطار المنستير": (35.7581, 10.7547),
    "وسط سوسة": (35.8256, 10.63699),
    "الحمامات": (36.4000, 10.6167),
    "نابل": (36.4561, 10.7376),
    "القنطاوي": (35.8920, 10.5950),
}


def haversine_km(a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    p1, p2 = math.radians(a_lat), math.radians(b_lat)
    dlat = math.radians(b_lat - a_lat)
    dlng = math.radians(b_lng - a_lng)
    x = (
        math.sin(dlat / 2) ** 2
        + math.cos(p1) * math.cos(p2) * math.sin(dlng / 2) ** 2
    )
    return 2 * _EARTH_RADIUS_KM * math.asin(math.sqrt(min(1.0, x)))


def resolve_pickup_coords(
    pickup_zone: str,
    pickup_lat: float | None,
    pickup_lng: float | None,
) -> Optional[Tuple[float, float]]:
    if pickup_lat is not None and pickup_lng is not None:
        return float(pickup_lat), float(pickup_lng)
    zone = pickup_zone.strip()
    if zone in _ZONE_COORDS:
        return _ZONE_COORDS[zone]
    return None


def _wallet_depleted_or_missing_for_driver(user_id: int) -> bool:
    acct = db_module.driver_pin_account_by_user_id(user_id)
    if acct is None:
        return True
    return float(acct.get("wallet_balance") or 0.0) <= 0.0


def _driver_distance_km_to_pickup(
    d: Dict[str, Any],
    pickup: Tuple[float, float],
    pickup_zone: str,
) -> Optional[float]:
    lat = d.get("last_lat")
    lng = d.get("last_lng")
    if lat is not None and lng is not None:
        return haversine_km(float(lat), float(lng), pickup[0], pickup[1])
    current_zone = (db_module.driver_current_zone_by_user_id(int(d["user_id"])) or "").strip()
    if current_zone in _ZONE_COORDS:
        cz = _ZONE_COORDS[current_zone]
        return haversine_km(cz[0], cz[1], pickup[0], pickup[1]) + 0.25
    if current_zone == pickup_zone.strip():
        return 0.05
    return None


def select_nearest_driver_user_ids(
    pickup_zone: str,
    *,
    pickup_lat: float | None = None,
    pickup_lng: float | None = None,
    count: int = _DISPATCH_WAVE_SIZE,
    exclude_user_ids: Optional[Set[int]] = None,
    eligible_only: Optional[Set[int]] = None,
) -> List[int]:
    """Rank online, available, non-busy drivers by distance to pickup GPS (or zone center)."""
    pickup = resolve_pickup_coords(pickup_zone, pickup_lat, pickup_lng)
    if pickup is None:
        return []

    exclude = exclude_user_ids or set()
    busy = db_module.driver_user_ids_with_active_ride()
    disabled = db_module.driver_user_ids_disabled()

    online = db_module.driver_profiles_for_dispatch_online(
        window_minutes=_ONLINE_WINDOW_MINUTES
    )
    all_available = db_module.driver_profiles_for_dispatch()
    seen_uids: Set[int] = set()
    candidates: List[Dict[str, Any]] = []
    for d in online + all_available:
        uid = int(d["user_id"])
        if uid in seen_uids:
            continue
        seen_uids.add(uid)
        candidates.append(d)

    scored: List[Tuple[float, int]] = []
    for d in candidates:
        uid = int(d["user_id"])
        if uid in exclude or uid in busy or uid in disabled:
            continue
        if eligible_only is not None and uid not in eligible_only:
            continue
        if not bool(int(d.get("is_available", 0))):
            continue
        if _wallet_depleted_or_missing_for_driver(uid):
            db_module.driver_set_availability_by_user_id(uid, False)
            continue
        dist = _driver_distance_km_to_pickup(d, pickup, pickup_zone)
        if dist is None:
            # Unknown position: still eligible, ranked after drivers with GPS/zone.
            dist = 50_000.0 + float(uid) / 1_000_000.0
        scored.append((dist, uid))

    scored.sort(key=lambda x: x[0])
    return [uid for _, uid in scored[: max(1, count)]]


def select_nearest_for_ride(
    ride: Dict[str, Any],
    *,
    count: int = _DISPATCH_WAVE_SIZE,
    exclude_user_ids: Optional[Set[int]] = None,
    eligible_only: Optional[Set[int]] = None,
) -> List[int]:
    pickup_zone = (ride.get("pickup") or "").strip()
    return select_nearest_driver_user_ids(
        pickup_zone,
        pickup_lat=ride.get("pickup_lat"),
        pickup_lng=ride.get("pickup_lng"),
        count=count,
        exclude_user_ids=exclude_user_ids,
        eligible_only=eligible_only,
    )


def dispatch_offer_to_drivers(
    ride: Dict[str, Any],
    driver_user_ids: List[int],
    *,
    replace_candidates: bool,
) -> List[int]:
    """Persist candidates and push socket offers. Returns user ids actually notified."""
    ride_id = int(ride["id"])
    if replace_candidates:
        db_module.ride_dispatch_set_candidates(ride_id, driver_user_ids)
        notified = list(driver_user_ids)
    else:
        notified = db_module.ride_dispatch_append_candidates(ride_id, driver_user_ids)
    if notified:
        realtime_broadcast.notify_dispatch_offer(ride, notified)
    return notified


def initial_dispatch(ride: Dict[str, Any], *, eligible_only: Optional[Set[int]] = None) -> List[int]:
    """First wave: nearest [count] drivers."""
    top = select_nearest_for_ride(
        ride, count=_DISPATCH_WAVE_SIZE, eligible_only=eligible_only
    )
    if top:
        dispatch_offer_to_drivers(ride, top, replace_candidates=True)
    else:
        db_module.ride_dispatch_set_candidates(int(ride["id"]), [])
    return top


def expand_dispatch_wave(ride_id: int, wave: int) -> List[int]:
    """Add the next nearest drivers if the ride is still pending and unassigned."""
    row = db_module.ride_get(ride_id)
    if row is None:
        return []
    if row.get("status") != "pending" or row.get("driver_id") is not None:
        return []
    if wave > _DISPATCH_MAX_WAVES:
        return []

    existing = set(db_module.ride_dispatch_candidates_for_ride(ride_id))
    more = select_nearest_for_ride(
        row,
        count=_DISPATCH_WAVE_SIZE,
        exclude_user_ids=existing,
    )
    if not more:
        return []
    notified = dispatch_offer_to_drivers(row, more, replace_candidates=False)
    log.info(
        "dispatch wave %s for ride %s: added %s driver(s)",
        wave,
        ride_id,
        len(notified),
    )
    return notified


def schedule_dispatch_expansion(app: Any, ride_id: int) -> None:
    """Background timers: waves 2–3 if nobody accepts."""

    def _run_wave(wave: int) -> None:
        try:
            with app.app_context():
                expand_dispatch_wave(ride_id, wave)
        except Exception:
            log.exception("dispatch expansion wave %s failed for ride %s", wave, ride_id)

    for wave in range(2, _DISPATCH_MAX_WAVES + 1):
        delay = _DISPATCH_WAVE_TIMEOUT_SEC * (wave - 1)
        threading.Timer(delay, _run_wave, args=(wave,)).start()


def redispatch_released_ride(ride: Dict[str, Any]) -> List[int]:
    """Re-offer after a driver releases an accepted ride back to pending."""
    return initial_dispatch(ride)
