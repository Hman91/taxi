import os
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


class Config:
    SECRET_KEY = os.environ.get("FLASK_SECRET_KEY", "dev-change-me-in-production")
    DATABASE_PATH = os.environ.get(
        "TAXI_DATABASE_PATH",
        str(_repo_root() / "backend" / "data" / "taxi.db"),
    )
    OWNER_PASSWORD = os.environ.get("OWNER_PASSWORD", "NabeulGold2026")
    DRIVER_CODE = os.environ.get("DRIVER_CODE", "Driver2026")
    B2B_CODE = os.environ.get("B2B_CODE", "Biz2026")
    OPERATOR_CODE = os.environ.get("OPERATOR_CODE", "Operator2026")
    TOKEN_MAX_AGE_SECONDS = int(os.environ.get("TOKEN_MAX_AGE_SECONDS", "86400"))
