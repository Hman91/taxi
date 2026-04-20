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
    B2B_CODE = os.environ.get("B2B_CODE", "Biz2026")
    OPERATOR_CODE = os.environ.get("OPERATOR_CODE", "Operator2026")
    TOKEN_MAX_AGE_SECONDS = int(os.environ.get("TOKEN_MAX_AGE_SECONDS", "86400"))
    # translation_service: google (deep-translator), none|stub|off to skip vendor calls
    TRANSLATION_PROVIDER = os.environ.get("TRANSLATION_PROVIDER", "google").lower()
    TRANSLATION_TIMEOUT_SECONDS = float(os.environ.get("TRANSLATION_TIMEOUT_SECONDS", "5"))
    # Web application OAuth client (verify ID tokens from Flutter Web + Android serverClientId).
    GOOGLE_OAUTH_CLIENT_ID = os.environ.get(
        "GOOGLE_OAUTH_CLIENT_ID",
        "962065998165-o2v10060s3l65ve7n8leee7hn28ddh6d.apps.googleusercontent.com",
    )
