"""Socket.IO: JWT connect, join_conversation, send_message → receive_message (rules.md)."""
from __future__ import annotations

from typing import Any, Dict

from flask import request
from flask_socketio import SocketIO, join_room, leave_room

from ..auth_tokens import decode_app_token
from .. import db as db_module
from ..services import chat_service
from ..services.realtime_broadcast import emit_chat_message_to_participants

# sid -> user_id for the active Engine.IO session
_sid_user: Dict[str, int] = {}


def register_handlers(sio: SocketIO) -> None:
    @sio.on("connect")
    def handle_connect(auth: Any) -> bool:
        token = _extract_token(auth)
        if not token:
            return False
        uid, role = decode_app_token(token)
        # Chat membership is enforced later by conversation/ride participant checks.
        # Accept any signed token that carries a uid so role-list drift can't break chat.
        if uid is None or not str(role or "").strip():
            return False
        row = db_module.user_by_id(uid)
        if row is None or not row.get("is_enabled", True):
            return False
        join_room(f"user:{uid}")
        _sid_user[request.sid] = uid
        return True

    @sio.on("disconnect")
    def handle_disconnect() -> None:
        _sid_user.pop(request.sid, None)

    @sio.on("join_conversation")
    def handle_join_conversation(data: Any) -> None:
        uid = _sid_user.get(request.sid)
        if uid is None:
            sio.emit("error", {"code": "unauthorized"}, to=request.sid)
            return
        if not isinstance(data, dict):
            sio.emit("error", {"code": "invalid_payload"}, to=request.sid)
            return
        try:
            cid = int(data.get("conversation_id", 0))
        except (TypeError, ValueError):
            sio.emit("error", {"code": "invalid_conversation_id"}, to=request.sid)
            return
        conv = chat_service.conversation_participant_check(cid, uid)
        if conv is None:
            sio.emit("error", {"code": "forbidden"}, to=request.sid)
            return
        join_room(f"conversation:{cid}")
        sio.emit("joined_conversation", {"conversation_id": cid}, to=request.sid)

    @sio.on("leave_conversation")
    def handle_leave_conversation(data: Any) -> None:
        if not isinstance(data, dict):
            return
        try:
            cid = int(data.get("conversation_id", 0))
        except (TypeError, ValueError):
            return
        leave_room(f"conversation:{cid}")

    @sio.on("send_message")
    def handle_send_message(data: Any) -> None:
        uid = _sid_user.get(request.sid)
        if uid is None:
            sio.emit("error", {"code": "unauthorized"}, to=request.sid)
            return
        if not isinstance(data, dict):
            sio.emit("error", {"code": "invalid_payload"}, to=request.sid)
            return
        try:
            cid = int(data.get("conversation_id", 0))
        except (TypeError, ValueError):
            sio.emit("error", {"code": "invalid_conversation_id"}, to=request.sid)
            return
        text = data.get("text", "")
        msg, err = chat_service.save_chat_message(uid, cid, str(text))
        if err:
            sio.emit("error", {"code": err}, to=request.sid)
            return
        assert msg is not None
        emit_chat_message_to_participants(cid, msg)


def _extract_token(auth: Any) -> str | None:
    if isinstance(auth, dict):
        t = auth.get("token") or auth.get("access_token")
        if isinstance(t, str) and t.strip():
            return t.strip()
    q = getattr(request, "args", None)
    if q:
        t = q.get("token")
        if isinstance(t, str) and t.strip():
            return t.strip()
    return None
