"""Aviation Edge (https://aviation-edge.com) — airport timetables & live flight data.

Used by operator/owner/driver dashboards for Tunisia arrivals. The API key is read
from the environment (``AVIATION_EDGE_API_KEY``) by the caller — never hard-code keys.
"""
from __future__ import annotations

import json
from datetime import date, datetime
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

_AE_BASE = "https://aviation-edge.com/v2/public"

_TUNISIA_IATA = frozenset({"TUN", "NBE", "MIR"})

_DEP_IATA_FALLBACK: Dict[str, Tuple[str, str]] = {
    "IST": ("Istanbul", "Turkey"),
    "BRU": ("Brussels", "Belgium"),
    "LGW": ("London", "United Kingdom"),
    "ORY": ("Paris", "France"),
    "CDG": ("Paris", "France"),
    "DOH": ("Doha", "Qatar"),
}


def _today_tunisia() -> date:
    try:
        return datetime.now(ZoneInfo("Africa/Tunis")).date()
    except Exception:
        return date.today()


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
        return s.split("T", 1)[1][:5]
    if " " in s:
        return s.split(" ", 1)[1][:5]
    return s[:5]


def _pretty_datetime(raw: str, *, fallback_epoch: Any = None) -> str:
    s = (raw or "").strip()
    dt: Optional[datetime] = None
    if s:
        sx = s.replace("Z", "+00:00")
        try:
            dt = datetime.fromisoformat(sx)
        except Exception:
            dt = None
    if dt is None and isinstance(fallback_epoch, (int, float)):
        try:
            dt = datetime.fromtimestamp(float(fallback_epoch))
        except Exception:
            dt = None
    if dt is None:
        return s
    return dt.strftime("%d %b %Y").strip() + f" – {dt.strftime('%H:%M')}"


def _tunisia_airport_labels(arrival_code: str) -> Tuple[str, str]:
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
    return arr_ar, arr_en


def _ae_sub(obj: Any) -> Dict[str, Any]:
    return obj if isinstance(obj, dict) else {}


def _ae_iata(block: Dict[str, Any]) -> str:
    return str(block.get("iataCode") or block.get("iata_code") or "").strip().upper()


def _ae_pick_time(block: Dict[str, Any]) -> str:
    for k in (
        "estimatedTime",
        "estimated_time",
        "actualTime",
        "actual_time",
        "scheduledTime",
        "scheduled_time",
    ):
        v = block.get(k)
        if v not in (None, ""):
            return str(v).strip()
    return ""


def _arrival_calendar_day_tunisia(arrival_raw: str) -> Optional[str]:
    s = (arrival_raw or "").strip().replace("Z", "+00:00")
    if not s:
        return None
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=ZoneInfo("UTC"))
    return dt.astimezone(ZoneInfo("Africa/Tunis")).date().isoformat()


def _ae_terminal_gate(block: Dict[str, Any]) -> Tuple[str, str]:
    t = str(block.get("terminal") or block.get("Terminal") or "").strip()
    g = str(block.get("gate") or block.get("Gate") or "").strip()
    return t, g


def _ae_parse_list(payload: Any) -> List[Dict[str, Any]]:
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if isinstance(payload, dict):
        if payload.get("error"):
            return []
        for k in ("data", "response", "flights", "result"):
            v = payload.get(k)
            if isinstance(v, list):
                return [x for x in v if isinstance(x, dict)]
    return []


def _ae_get_json(url: str, *, timeout: float) -> Any:
    req = Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 TaxiPro/1.0 (AviationEdge)",
            "Accept": "application/json",
        },
    )
    with urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _normalize_timetable_row(
    item: Dict[str, Any], *, arr_iata: str, today_tun: str
) -> Optional[Dict[str, Any]]:
    dep = _ae_sub(item.get("departure"))
    arr = _ae_sub(item.get("arrival"))
    arrival_code = _ae_iata(arr) or str(arr_iata or "").strip().upper()
    if arrival_code not in _TUNISIA_IATA:
        return None

    arrival_raw = _ae_pick_time(arr)
    tun_day = _arrival_calendar_day_tunisia(arrival_raw)
    if tun_day is not None and tun_day != today_tun:
        return None

    fl = _ae_sub(item.get("flight"))
    flight_number = str(
        fl.get("iataNumber") or fl.get("iata_number") or ""
    ).strip()
    if not flight_number:
        ai = str(
            (_ae_sub(item.get("airline"))).get("iataCode")
            or (_ae_sub(item.get("airline"))).get("iata_code")
            or ""
        ).strip().upper()
        num = str(fl.get("number") or "").strip()
        if ai and num:
            flight_number = f"{ai}{num}"
        elif num:
            flight_number = num
    if not flight_number:
        return None

    al = _ae_sub(item.get("airline"))
    airline_iata = str(al.get("iataCode") or al.get("iata_code") or "").strip().upper()
    airline_icao = str(al.get("icaoCode") or al.get("icao_code") or "").strip().upper()
    airline_name = str(al.get("name") or "").strip()
    airline_out = (
        f"{airline_name} ({airline_iata})"
        if airline_name and airline_iata
        else (
            f"{airline_iata} / {airline_icao}"
            if airline_iata and airline_icao
            else airline_iata or airline_icao or airline_name or "—"
        )
    )

    dep_iata = _ae_iata(dep)
    dep_airport = (
        str(dep.get("airport") or dep.get("name") or "").strip()
        or dep_iata
        or "Unknown"
    )
    dep_city = str(dep.get("city") or "").strip()
    dep_country = str(dep.get("country") or "").strip()
    if dep_iata and (not dep_city or not dep_country):
        fb = _DEP_IATA_FALLBACK.get(dep_iata)
        if fb is not None:
            dep_city = dep_city or fb[0]
            dep_country = dep_country or fb[1]

    takeoff_raw = _ae_pick_time(dep)
    status_raw = str(item.get("status") or "").strip().lower()
    ac = _ae_sub(item.get("aircraft"))
    aircraft = str(ac.get("modelText") or ac.get("model_text") or ac.get("modelCode") or ac.get("model_code") or "").strip()
    term, gate = _ae_terminal_gate(arr)

    arr_ar, arr_en = _tunisia_airport_labels(arrival_code)
    return {
        "flight_number": flight_number,
        "airline": airline_out,
        "status": status_raw or "scheduled",
        "aircraft": aircraft,
        "departure_airport": dep_airport,
        "departure_iata": dep_iata,
        "departure_city": dep_city,
        "departure_country": dep_country,
        "takeoff_time": _hhmm_from_isoish(takeoff_raw),
        "expected_arrival": _pretty_datetime(arrival_raw),
        "arrival_terminal": term,
        "arrival_gate": gate,
        "arrival_airport_ar": arr_ar,
        "arrival_airport_en": arr_en,
    }


def _normalize_live_flights_row(
    item: Dict[str, Any], *, arr_iata: str, tunisian_iata: frozenset[str]
) -> Optional[Dict[str, Any]]:
    dep = _ae_sub(item.get("departure"))
    arr = _ae_sub(item.get("arrival"))
    arrival_code = _ae_iata(arr) or str(arr_iata or "").strip().upper()
    if arrival_code not in tunisian_iata:
        return None

    arrival_raw = _ae_pick_time(arr)
    today_tun = _today_tunisia().isoformat()
    tun_day = _arrival_calendar_day_tunisia(arrival_raw)
    if tun_day is not None and tun_day != today_tun:
        return None

    fl = _ae_sub(item.get("flight"))
    flight_number = str(
        fl.get("iataNumber")
        or fl.get("iata_number")
        or fl.get("icaoNumber")
        or fl.get("icao_number")
        or fl.get("number")
        or ""
    ).strip()
    if not flight_number:
        return None

    dep_iata = _ae_iata(dep)
    dep_airport = (
        str(dep.get("airport") or dep.get("name") or "").strip()
        or str(dep.get("city") or "").strip()
        or dep_iata
        or "Unknown"
    )
    dep_city = str(dep.get("city") or "").strip()
    dep_country = str(dep.get("country") or "").strip()
    if dep_iata and (not dep_city or not dep_country):
        fb = _DEP_IATA_FALLBACK.get(dep_iata)
        if fb is not None:
            dep_city = dep_city or fb[0]
            dep_country = dep_country or fb[1]

    takeoff_raw = _ae_pick_time(dep)
    al = _ae_sub(item.get("airline"))
    airline_iata = str(al.get("iataCode") or al.get("iata_code") or "").strip().upper()
    airline_icao = str(al.get("icaoCode") or al.get("icao_code") or "").strip().upper()
    airline_name = str(al.get("name") or "").strip()
    airline_out = (
        f"{airline_name} ({airline_iata})"
        if airline_name and airline_iata
        else (
            f"{airline_iata} / {airline_icao}"
            if airline_iata and airline_icao
            else airline_iata or airline_icao or airline_name or "—"
        )
    )
    ac = _ae_sub(item.get("aircraft"))
    aircraft = str(
        ac.get("icaoCode")
        or ac.get("icao_code")
        or ac.get("modelText")
        or ac.get("model_text")
        or ac.get("modelCode")
        or ac.get("model_code")
        or ""
    ).strip()
    status_raw = str(item.get("status") or "").strip().lower()
    arr_ar, arr_en = _tunisia_airport_labels(arrival_code)
    term, gate = _ae_terminal_gate(arr)

    return {
        "flight_number": flight_number,
        "airline": airline_out,
        "status": status_raw or "unknown",
        "aircraft": aircraft,
        "departure_airport": dep_airport,
        "departure_iata": dep_iata,
        "departure_city": dep_city,
        "departure_country": dep_country,
        "takeoff_time": _hhmm_from_isoish(takeoff_raw),
        "expected_arrival": _pretty_datetime(arrival_raw),
        "arrival_terminal": term,
        "arrival_gate": gate,
        "arrival_airport_ar": arr_ar,
        "arrival_airport_en": arr_en,
    }


def fetch_timetable_arrivals(api_key: str, iata: str) -> List[Dict[str, Any]]:
    """Real-time timetable: arrivals at ``iata`` (TUN / NBE / MIR)."""
    today_tun = _today_tunisia().isoformat()
    query = urlencode(
        {
            "key": api_key,
            "iataCode": iata.upper(),
            "type": "arrival",
        }
    )
    url = f"{_AE_BASE}/timetable?{query}"
    try:
        payload = _ae_get_json(url, timeout=14.0)
    except Exception:
        return []
    rows: List[Dict[str, Any]] = []
    for item in _ae_parse_list(payload):
        row = _normalize_timetable_row(item, arr_iata=iata, today_tun=today_tun)
        if row is not None:
            rows.append(row)
    return rows


def fetch_live_tracker_arrivals(api_key: str, iata: str) -> List[Dict[str, Any]]:
    """Flight tracker snapshot filtered by arrival airport."""
    query = urlencode({"key": api_key, "arrIata": iata.upper()})
    url = f"{_AE_BASE}/flights?{query}"
    try:
        payload = _ae_get_json(url, timeout=10.0)
    except Exception:
        return []
    rows: List[Dict[str, Any]] = []
    for item in _ae_parse_list(payload):
        row = _normalize_live_flights_row(
            item, arr_iata=iata, tunisian_iata=_TUNISIA_IATA
        )
        if row is not None:
            rows.append(row)
    return rows


def tunisia_arrivals_via_timetables(api_key: str) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for iata in sorted(_TUNISIA_IATA):
        out.extend(fetch_timetable_arrivals(api_key, iata))
    return out


def tunisia_arrivals_via_live_tracker(api_key: str) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for iata in sorted(_TUNISIA_IATA):
        out.extend(fetch_live_tracker_arrivals(api_key, iata))
    return out
