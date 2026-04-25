"""Socket.IO event registration (real-time chat + ride updates)."""
from __future__ import annotations

from flask_socketio import SocketIO

from . import chat as chat_socket


def register_socket_handlers(sio: SocketIO) -> None:
    chat_socket.register_handlers(sio)
