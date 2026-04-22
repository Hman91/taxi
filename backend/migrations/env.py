"""Alembic environment (uses Flask-SQLAlchemy metadata)."""
from __future__ import annotations

import os
from logging.config import fileConfig

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

from alembic import context
from sqlalchemy import create_engine, pool

from backend.config import _normalize_database_url
from backend.extensions import db

import backend.models  # noqa: F401 — ensure models bind to metadata

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = db.metadata


def _is_hosted_builder() -> bool:
    """True on Render/CI when local postgres default must not be used."""
    if os.environ.get("RENDER") or os.environ.get("RENDER_SERVICE_ID") or os.environ.get("CI"):
        return True
    return "/opt/render/" in os.getcwd().replace("\\", "/")


def get_url() -> str:
    raw = (os.environ.get("DATABASE_URL") or "").strip()
    if not raw and _is_hosted_builder():
        raise RuntimeError(
            "DATABASE_URL is not set. In Render → Environment, add your Supabase "
            "Session pooler URI. Build command should be: pip install -r requirements.txt "
            "(no alembic in build) — then run alembic upgrade head in Render Shell after deploy."
        )
    if not raw:
        raw = "postgresql+psycopg2://postgres:postgres@127.0.0.1:5432/taxi"
    return _normalize_database_url(raw)


def run_migrations_offline() -> None:
    url = get_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = create_engine(get_url(), poolclass=pool.NullPool)

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
