"""Access + refresh token pairs (opaque refresh tokens stored hashed)."""
from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Tuple

from flask import current_app

from .. import db as db_module
from ..auth_tokens import issue_access_token
from ..extensions import db
from ..models import RefreshToken, User


def _hash_refresh(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _access_ttl_seconds() -> int:
    return int(
        current_app.config.get("ACCESS_TOKEN_MAX_AGE_SECONDS")
        or current_app.config.get("TOKEN_MAX_AGE_SECONDS")
        or 900
    )


def _refresh_ttl_seconds() -> int:
    return int(current_app.config.get("REFRESH_TOKEN_MAX_AGE_SECONDS") or (30 * 24 * 3600))


def _persist_refresh(*, user_id: int | None, role: str) -> str:
    raw = secrets.token_urlsafe(48)
    now = datetime.now(timezone.utc)
    row = RefreshToken(
        user_id=int(user_id) if user_id is not None else None,
        role=str(role).strip().lower(),
        token_hash=_hash_refresh(raw),
        expires_at=now + timedelta(seconds=_refresh_ttl_seconds()),
    )
    db.session.add(row)
    db.session.commit()
    return raw


def _revoke_row(row: RefreshToken) -> None:
    if row.revoked_at is None:
        row.revoked_at = datetime.now(timezone.utc)
        db.session.commit()


def build_token_bundle(
    *,
    role: str,
    user_id: int | None = None,
    include_role_only_access: bool = False,
    extra: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Create access + refresh; optionally a second role-only access (B2B legacy)."""
    role_norm = str(role).strip().lower()
    uid = int(user_id) if user_id is not None else None
    access = issue_access_token(role_norm, user_id=uid)
    refresh = _persist_refresh(user_id=uid, role=role_norm)
    out: Dict[str, Any] = {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "Bearer",
        "expires_in": _access_ttl_seconds(),
        "role": role_norm,
    }
    if uid is not None:
        out["user_id"] = uid
    if include_role_only_access and uid is not None:
        out["app_access_token"] = issue_access_token(role_norm, user_id=uid)
        out["access_token"] = issue_access_token(role_norm, user_id=None)
    elif include_role_only_access:
        out["app_access_token"] = access
    extra = extra or {}
    out.update(extra)
    return out


def refresh_tokens(raw_refresh: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    token = (raw_refresh or "").strip()
    if not token:
        return None, "missing_refresh_token"
    now = datetime.now(timezone.utc)
    row = db.session.scalars(
        db.select(RefreshToken).where(RefreshToken.token_hash == _hash_refresh(token))
    ).first()
    if row is None:
        return None, "invalid_refresh_token"
    if row.revoked_at is not None:
        return None, "refresh_token_revoked"
    exp = row.expires_at
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    if exp < now:
        _revoke_row(row)
        return None, "refresh_token_expired"
    if row.user_id is not None:
        user = db_module.user_by_id(int(row.user_id))
        if user is None:
            _revoke_row(row)
            return None, "user_not_found"
        if not user.get("is_enabled", True):
            _revoke_row(row)
            return None, "account_disabled"
    _revoke_row(row)
    include_dual = row.role == "b2b" and row.user_id is not None
    return (
        build_token_bundle(
            role=row.role,
            user_id=int(row.user_id) if row.user_id is not None else None,
            include_role_only_access=include_dual,
        ),
        None,
    )


def revoke_refresh_token(raw_refresh: str) -> None:
    token = (raw_refresh or "").strip()
    if not token:
        return
    row = db.session.scalars(
        db.select(RefreshToken).where(RefreshToken.token_hash == _hash_refresh(token))
    ).first()
    if row is not None:
        _revoke_row(row)


def revoke_all_for_user(user_id: int) -> None:
    now = datetime.now(timezone.utc)
    rows = db.session.scalars(
        db.select(RefreshToken).where(
            RefreshToken.user_id == int(user_id),
            RefreshToken.revoked_at.is_(None),
        )
    ).all()
    for row in rows:
        row.revoked_at = now
    if rows:
        db.session.commit()


def authenticate_role_secret(role: str, secret: str) -> Optional[str]:
    role_norm = (role or "").strip().lower()
    secret_norm = (secret or "").strip()
    mapping = {
        "owner": "OWNER_PASSWORD",
        "operator": "OPERATOR_CODE",
        "b2b": "B2B_CODE",
        "driver": "DRIVER_CODE",
    }
    cfg_key = mapping.get(role_norm)
    if not cfg_key:
        return "invalid_role"
    expected = str(current_app.config.get(cfg_key, "")).strip()
    if not expected or secret_norm != expected:
        return "invalid_credentials"
    return None


def login_with_role_secret(role: str, secret: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    err = authenticate_role_secret(role, secret)
    if err:
        return None, err
    role_norm = role.strip().lower()
    if role_norm == "b2b":
        user = db_module.user_by_b2b_source_code(secret)
        if user is None:
            return None, "b2b_user_not_found"
        return (
            build_token_bundle(
                role="b2b",
                user_id=int(user["id"]),
                include_role_only_access=True,
            ),
            None,
        )
    return build_token_bundle(role=role_norm, user_id=None), None


def login_driver_pin(phone: str, pin: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    phone_norm = (phone or "").strip()
    pin_norm = (pin or "").strip()
    if not phone_norm or not pin_norm:
        return None, "missing_fields"
    acct = db_module.driver_pin_by_phone(phone_norm)
    if acct is None or str(acct.get("pin") or "").strip() != pin_norm:
        return None, "invalid_credentials"
    user = db_module.user_by_phone(phone_norm)
    if user is None or str(user.get("role") or "").strip().lower() != "driver":
        driver_user = db_module.ensure_driver_user_for_pin_account(acct)
        if driver_user is None:
            return None, "driver_user_missing"
        user = driver_user
    if not user.get("is_enabled", True):
        return None, "account_disabled"
    uid = int(user["id"])
    driver = db_module.driver_by_user_id(uid)
    bundle = build_token_bundle(role="driver", user_id=uid)
    bundle.update(
        {
            "driver_id": int(driver["id"]) if driver else None,
            "driver_name": acct.get("driver_name") or user.get("display_name") or "",
            "phone": phone_norm,
            "wallet_balance": float(acct.get("wallet_balance") or 0.0),
            "owner_commission_rate": float(acct.get("owner_commission_rate") or 10.0),
            "b2b_commission_rate": float(acct.get("b2b_commission_rate") or 5.0),
            "auto_deduct_enabled": bool(acct.get("auto_deduct_enabled", True)),
            "photo_url": acct.get("photo_url"),
            "car_model": acct.get("car_model"),
            "car_color": acct.get("car_color"),
            "current_zone": acct.get("current_zone"),
            "preferred_language": user.get("preferred_language"),
        }
    )
    return bundle, None
