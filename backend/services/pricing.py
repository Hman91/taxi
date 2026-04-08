"""Tunisia fare rules (from legacy Streamlit app)."""
from __future__ import annotations

import random
from datetime import datetime
from typing import Dict, Tuple

FARES_DB: Dict[str, float] = {
    "مطار قرطاج (TUN) -> نابل / الحمامات": 120.0,
    "مطار قرطاج (TUN) -> سوسة / القنطاوي": 160.0,
    "مطار النفيضة (NBE) -> الحمامات": 80.0,
    "مطار النفيضة (NBE) -> سوسة": 70.0,
    "مطار المنستير (MIR) -> سوسة / القنطاوي": 40.0,
    "مطار المنستير (MIR) -> نابل / الحمامات": 150.0,
}

PRISE_EN_CHARGE = 1.0
PRIX_PAR_KM = 1.2


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
