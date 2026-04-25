"""REST: app user profile (JWT)."""
from __future__ import annotations

from typing import Any, Tuple

from flask import Blueprint, jsonify, request

from .. import db as db_module
from ..services import users as users_service
from .jwt_auth import json_error, require_jwt_with_uid

bp = Blueprint("users_api", __name__, url_prefix="/api")


@bp.patch("/me")
@require_jwt_with_uid("user", "driver")
def patch_me(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    row = db_module.user_by_id(uid)
    if row is None or not row.get("is_enabled", True):
        return jsonify({"error": "account_disabled"}), 403
    body = request.get_json(silent=True) or {}
    if "preferred_language" not in body:
        return json_error("preferred_language_required", 400)
    lang = body.get("preferred_language")
    if not isinstance(lang, str):
        return json_error("invalid_language", 400)
    user, err = users_service.set_preferred_language(uid, lang)
    if err == "invalid_language":
        return json_error("invalid_language", 400)
    if err == "not_found":
        return json_error("not_found", 404)
    assert user is not None
    return (
        jsonify(
            {
                "user": {
                    "id": user["id"],
                    "email": user["email"],
                    "role": user["role"],
                    "preferred_language": user["preferred_language"],
                    "is_enabled": user["is_enabled"],
                }
            }
        ),
        200,
    )
