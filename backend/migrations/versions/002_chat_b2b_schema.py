"""Chat tables (conversations, messages, translations), user/driver flags, b2b_tenants.

Revision ID: 002_chat_b2b
Revises: 001_initial
Create Date: 2026-04-13

"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "002_chat_b2b"
down_revision = "001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "preferred_language",
            sa.String(length=10),
            server_default=sa.text("'en'"),
            nullable=False,
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "is_enabled",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
    )

    op.add_column("drivers", sa.Column("last_lat", sa.Float(), nullable=True))
    op.add_column("drivers", sa.Column("last_lng", sa.Float(), nullable=True))
    op.add_column(
        "drivers",
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        "conversations",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("ride_id", sa.BigInteger(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["ride_id"], ["rides.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("ride_id"),
    )

    op.create_table(
        "messages",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("conversation_id", sa.BigInteger(), nullable=False),
        sa.Column("sender_user_id", sa.BigInteger(), nullable=False),
        sa.Column("original_text", sa.Text(), nullable=False),
        sa.Column("original_language", sa.String(length=10), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["conversation_id"], ["conversations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["sender_user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_messages_sender_user_id",
        "messages",
        ["sender_user_id"],
        unique=False,
    )
    op.execute(
        "CREATE INDEX idx_messages_conversation_history "
        "ON messages (conversation_id, id DESC)"
    )

    op.create_table(
        "translations",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("message_id", sa.BigInteger(), nullable=False),
        sa.Column("target_language", sa.String(length=10), nullable=False),
        sa.Column("translated_text", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["message_id"], ["messages.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "message_id",
            "target_language",
            name="uq_translations_message_target",
        ),
    )
    op.create_index(
        "ix_translations_message_id",
        "translations",
        ["message_id"],
        unique=False,
    )

    op.create_table(
        "b2b_tenants",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("code", sa.String(length=255), nullable=False),
        sa.Column("label", sa.Text(), nullable=True),
        sa.Column(
            "is_enabled",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )


def downgrade() -> None:
    op.drop_table("b2b_tenants")

    op.drop_index("ix_translations_message_id", table_name="translations")
    op.drop_table("translations")

    op.execute("DROP INDEX IF EXISTS idx_messages_conversation_history")
    op.drop_index("ix_messages_sender_user_id", table_name="messages")
    op.drop_table("messages")

    op.drop_table("conversations")

    op.drop_column("drivers", "last_seen_at")
    op.drop_column("drivers", "last_lng")
    op.drop_column("drivers", "last_lat")

    op.drop_column("users", "is_enabled")
    op.drop_column("users", "preferred_language")
