"""Tunisia fare rules (from legacy Streamlit app)."""
from __future__ import annotations

import random
from datetime import datetime
from typing import Dict, Tuple

FARES_DB: Dict[str, float] = {
    "مطار قرطاج ➡️ الحمامات": 120.0,
    "مطار قرطاج ➡️ سوسة": 155.0,
    "مطار قرطاج ➡️ القنطاوي": 148.0,
    "مطار قرطاج ➡️ نابل": 145.0,
    "مطار النفيضة ➡️ الحمامات": 85.0,
    "مطار النفيضة ➡️ سوسة": 70.0,
    "مطار النفيضة ➡️ القنطاوي": 78.0,
    "مطار النفيضة ➡️ نابل": 128.0,
    "مطار المنستير ➡️ الحمامات": 72.0,
    "مطار المنستير ➡️ سوسة": 55.0,
    "مطار المنستير ➡️ القنطاوي": 40.0,
    "مطار المنستير ➡️ نابل": 118.0,
    "وسط سوسة ➡️ الحمامات": 62.0,
    "وسط سوسة ➡️ سوسة": 35.0,
    "وسط سوسة ➡️ القنطاوي": 38.0,
    "وسط سوسة ➡️ نابل": 80.0,
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
