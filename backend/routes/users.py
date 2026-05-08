"""REST: app user profile (JWT)."""
from __future__ import annotations

from typing import Any, Tuple

from flask import Blueprint, jsonify, request

from .. import db as db_module
from ..services import users as users_service
from .jwt_auth import json_error, require_jwt_with_uid

bp = Blueprint("users_api", __name__, url_prefix="/api")


@bp.patch("/me")
@require_jwt_with_uid("user", "driver", "owner", "operator", "b2b")
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


@bp.patch("/me/account")
@require_jwt_with_uid("user", "driver", "owner", "operator", "b2b")
def patch_me_account(**kwargs: Any) -> Tuple[Any, int]:
    uid = kwargs["_uid"]
    row = db_module.user_by_id(uid)
    if row is None or not row.get("is_enabled", True):
        return jsonify({"error": "account_disabled"}), 403
    body = request.get_json(silent=True) or {}
    current_password = body.get("current_password")
    if not isinstance(current_password, str) or not current_password:
        return json_error("current_password_required", 400)
    new_email = body.get("email") if "email" in body else None
    if new_email is not None and not isinstance(new_email, str):
        return json_error("invalid_email", 400)
    new_password = body.get("password") if "password" in body else None
    if new_password is not None and not isinstance(new_password, str):
        return json_error("invalid_password", 400)
    user, err = users_service.update_account_credentials(
        uid,
        current_password=current_password,
        new_email=new_email,
        new_password=new_password,
    )
    if err == "not_found":
        return json_error("not_found", 404)
    if err == "invalid_credentials":
        return json_error("invalid_credentials", 401)
    if err in {"invalid_email", "weak_password", "no_changes"}:
        return json_error(err, 400)
    if err == "email_taken":
        return json_error("email_taken", 409)
    assert user is not None
    return (
        jsonify(
            {
                "user": {
                    "id": user["id"],
                    "email": user["email"],
                    "role": user["role"],
                    "is_enabled": user["is_enabled"],
                }
            }
        ),
        200,
    )
