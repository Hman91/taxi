import os

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

# Local: use .env (see repo root .env.example). Production: set vars on Render.
# Supabase "Session pooler" URI (postgresql://...@pooler...:5432/postgres) is supported;
# we normalize to SQLAlchemy's postgresql+psycopg2:// driver form.


def _normalize_database_url(url: str) -> str:
    """Map postgres:// and postgresql:// to postgresql+psycopg2:// for SQLAlchemy 2 + psycopg2."""
    u = (url or "").strip()
    if not u:
        return u
    if u.startswith("postgresql+psycopg2://"):
        return u
    if u.startswith("postgres://"):
        return "postgresql+psycopg2://" + u[len("postgres://") :]
    if u.startswith("postgresql://"):
        return "postgresql+psycopg2://" + u[len("postgresql://") :]
    return u


class Config:
    # Render/docs often use SECRET_KEY; this project historically used FLASK_SECRET_KEY.
    SECRET_KEY = os.environ.get("SECRET_KEY") or os.environ.get(
        "FLASK_SECRET_KEY", "dev-change-me-in-production"
    )
    # PostgreSQL (see Alembic). Paste Supabase Session pooler URI as DATABASE_URL as-is;
    # _normalize_database_url() converts to postgresql+psycopg2://...
    SQLALCHEMY_DATABASE_URI = _normalize_database_url(
        os.environ.get(
            "DATABASE_URL",
            "postgresql+psycopg2://postgres:postgres@127.0.0.1:5432/taxi",
        )
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
