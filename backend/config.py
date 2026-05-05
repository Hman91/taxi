import os
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent
_BACKEND_DIR = Path(__file__).resolve().parent

try:
    from dotenv import load_dotenv

    # Load env files regardless of Flask cwd:
    # 1) `taxi/.env` at repo root (documented in `.env.example`)
    # 2) `backend/.env` alongside this file (many local setups keep it here)
    # Later loads do not overwrite vars already set (python-dotenv default).
    load_dotenv(_REPO_ROOT / ".env")
    load_dotenv(_BACKEND_DIR / ".env")
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
    PASSWORD_RESET_DEV_MODE = os.environ.get("PASSWORD_RESET_DEV_MODE", "0")
    SMTP_HOST = os.environ.get("SMTP_HOST", "").strip()
    SMTP_PORT = int(os.environ.get("SMTP_PORT", "587"))
    SMTP_USERNAME = os.environ.get("SMTP_USERNAME", "").strip()
    SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD", "")
    SMTP_FROM_EMAIL = os.environ.get("SMTP_FROM_EMAIL", "").strip()
    SMTP_USE_TLS = str(os.environ.get("SMTP_USE_TLS", "1")).strip().lower() in (
        "1",
        "true",
        "yes",
    )
