"""SQLAlchemy models (PostgreSQL). Import side effects register metadata on `db`."""
from __future__ import annotations

from .b2b_tenant import B2BTenant
from .b2b_booking import B2BBooking
from .conversation import Conversation
from .driver import Driver
from .driver_pin_account import DriverPinAccount
from .fare_route import FareRoute
from .message import Message
from .rating import Rating
from .ride import Ride
from .ride_dispatch_candidate import RideDispatchCandidate
from .translation import Translation
from .trip import Trip
from .user import User

__all__ = [
    "User",
    "Driver",
    "FareRoute",
    "Ride",
    "RideDispatchCandidate",
    "Trip",
    "Rating",
    "Conversation",
    "Message",
    "Translation",
    "B2BTenant",
    "B2BBooking",
    "DriverPinAccount",
]
