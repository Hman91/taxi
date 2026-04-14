import os


class Config:
    SECRET_KEY = os.environ.get("FLASK_SECRET_KEY", "dev-change-me-in-production")
    # PostgreSQL (see Alembic migrations). Default matches local docker-style Postgres.
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg2://postgres:postgres@127.0.0.1:5432/taxi",
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {"pool_pre_ping": True}
    OWNER_PASSWORD = os.environ.get("OWNER_PASSWORD", "NabeulGold2026")
    DRIVER_CODE = os.environ.get("DRIVER_CODE", "Driver2026")
    B2B_CODE = os.environ.get("B2B_CODE", "Hotel2026")
    OPERATOR_CODE = os.environ.get("OPERATOR_CODE", "Op2026")
    TOKEN_MAX_AGE_SECONDS = int(os.environ.get("TOKEN_MAX_AGE_SECONDS", "86400"))
    # translation_service: google (deep-translator), none|stub|off to skip vendor calls
    TRANSLATION_PROVIDER = os.environ.get("TRANSLATION_PROVIDER", "google").lower()
    TRANSLATION_TIMEOUT_SECONDS = float(os.environ.get("TRANSLATION_TIMEOUT_SECONDS", "5"))
