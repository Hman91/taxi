"""SQLAlchemy models (PostgreSQL). Import side effects register metadata on `db`."""
from __future__ import annotations

from .b2b_tenant import B2BTenant
from .conversation import Conversation
from .driver import Driver
from .message import Message
from .rating import Rating
from .ride import Ride
from .translation import Translation
from .trip import Trip
from .user import User

__all__ = [
    "User",
    "Driver",
    "Ride",
    "Trip",
    "Rating",
    "Conversation",
    "Message",
    "Translation",
    "B2BTenant",
]
