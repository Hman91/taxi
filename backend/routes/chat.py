"""REST: paginated chat history (JWT app users) with per-viewer display_text / translated_text."""
from __future__ import annotations

from typing import Any, Tuple

from flask import Blueprint, jsonify, request

from .. import db as db_module
from ..services import chat_service
from .jwt_auth import json_error, require_jwt_with_uid

bp = Blueprint("chat_api", __name__, url_prefix="/api/conversations")


def _guard_enabled(uid: int) -> Tuple[Any, int] | None:
    row = db_module.user_by_id(uid)
    if row is None or not row.get("is_enabled", True):
        return jsonify({"error": "account_disabled"}), 403
    return None


@bp.get("/<int:conversation_id>/messages")
@require_jwt_with_uid("user", "driver", "b2b")
def conversation_messages(conversation_id: int, **kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    bad = _guard_enabled(uid)
    if bad:
        return bad
    before_raw = request.args.get("before_id")
    limit_raw = request.args.get("limit", "50")
    before_id: int | None = None
    if before_raw is not None and str(before_raw).strip() != "":
        try:
            before_id = int(before_raw)
        except (TypeError, ValueError):
            return json_error("invalid_before_id", 400)
    try:
        limit = int(limit_raw)
    except (TypeError, ValueError):
        return json_error("invalid_limit", 400)

    data, err = chat_service.list_messages(
        conversation_id, uid, before_id=before_id, limit=limit
    )
    if err == "not_found":
        return json_error("not_found", 404)
    if err == "forbidden":
        return json_error("forbidden", 403)
    if err == "chat_not_open":
        return json_error("chat_not_open", 400)
    assert data is not None
    return jsonify({"messages": data}), 200
