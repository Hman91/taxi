"""
HTTP smoke checks against a running Taxi Pro API (no extra dependencies).

Covers: health, app auth + register, rides lifecycle, chat REST (conversation +
messages), PATCH /me, admin rides + owner metrics, disable user + login-app 403.

Usage (server must be up, DB migrated):

    python -m backend.scripts.smoke_api
    python -m backend.scripts.smoke_api --base-url http://127.0.0.1:5000

Optional env (defaults match dev Config): OPERATOR_CODE, OWNER_PASSWORD
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, Optional, Tuple
from uuid import uuid4


def _request(
    method: str,
    url: str,
    *,
    json_body: Optional[Dict[str, Any]] = None,
    bearer: Optional[str] = None,
    timeout: float = 60.0,
) -> Tuple[int, Any]:
    headers = {"Accept": "application/json"}
    data: Optional[bytes] = None
    if json_body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(json_body).encode("utf-8")
    if bearer:
        headers["Authorization"] = f"Bearer {bearer}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode()
            if not raw:
                return resp.status, {}
            return resp.status, json.loads(raw)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            parsed: Any = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"_raw": raw}
        return e.code, parsed


def _fail(step: str, status: int, body: Any) -> None:
    print(f"FAIL: {step} (HTTP {status}): {body}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    p = argparse.ArgumentParser(description="Taxi Pro API smoke tests")
    p.add_argument(
        "--base-url",
        default=os.environ.get("SMOKE_API_BASE", "http://127.0.0.1:5000"),
        help="API root (no trailing slash)",
    )
    args = p.parse_args()
    base = args.base_url.rstrip("/")
    op_secret = os.environ.get("OPERATOR_CODE", "Operator2026")
    owner_secret = os.environ.get("OWNER_PASSWORD", "NabeulGold2026")
    suffix = uuid4().hex[:10]
    pass_email = f"smoke_p_{suffix}@example.com"
    drv_email = f"smoke_d_{suffix}@example.com"
    password = "SmokeTestPwd!9"

    # Health
    st, body = _request("GET", f"{base}/api/health")
    if st != 200:
        _fail("GET /api/health", st, body)

    # Register passenger + driver (creates driver row for accept)
    st, body = _request(
        "POST",
        f"{base}/api/auth/register",
        json_body={"email": pass_email, "password": password, "role": "user"},
    )
    if st != 201:
        _fail("POST /api/auth/register (user)", st, body)
    st, body = _request(
        "POST",
        f"{base}/api/auth/register",
        json_body={"email": drv_email, "password": password, "role": "driver"},
    )
    if st != 201:
        _fail("POST /api/auth/register (driver)", st, body)

    st, body = _request(
        "POST",
        f"{base}/api/auth/login-app",
        json_body={"email": pass_email, "password": password},
    )
    if st != 200:
        _fail("POST /api/auth/login-app (passenger)", st, body)
    pass_token = body["access_token"]
    pass_uid = int(body["user_id"])

    st, body = _request(
        "POST",
        f"{base}/api/auth/login-app",
        json_body={"email": drv_email, "password": password},
    )
    if st != 200:
        _fail("POST /api/auth/login-app (driver)", st, body)
    drv_token = body["access_token"]

    # Rides
    st, body = _request(
        "POST",
        f"{base}/api/rides",
        bearer=pass_token,
        json_body={"pickup": "A", "destination": "B"},
    )
    if st != 201:
        _fail("POST /api/rides", st, body)
    ride_id = int(body["ride"]["id"])

    st, body = _request("POST", f"{base}/api/rides/{ride_id}/accept", bearer=drv_token)
    if st != 200:
        _fail("POST /api/rides/.../accept", st, body)

    # Chat REST
    st, body = _request("GET", f"{base}/api/rides/{ride_id}/conversation", bearer=pass_token)
    if st != 200:
        _fail("GET /api/rides/.../conversation", st, body)
    conv_id = int(body["conversation_id"])

    st, body = _request("GET", f"{base}/api/conversations/{conv_id}/messages", bearer=pass_token)
    if st != 200:
        _fail("GET /api/conversations/.../messages", st, body)
    if "messages" not in body:
        _fail("messages payload", st, body)

    # Profile
    st, body = _request(
        "PATCH",
        f"{base}/api/me",
        bearer=pass_token,
        json_body={"preferred_language": "en"},
    )
    if st != 200:
        _fail("PATCH /api/me", st, body)

    # Admin: operator → rides
    st, body = _request(
        "POST",
        f"{base}/api/auth/login",
        json_body={"role": "operator", "secret": op_secret},
    )
    if st != 200:
        _fail("POST /api/auth/login (operator)", st, body)
    op_token = body["access_token"]

    st, body = _request("GET", f"{base}/api/admin/rides?limit=5", bearer=op_token)
    if st != 200:
        _fail("GET /api/admin/rides", st, body)
    if "rides" not in body:
        _fail("admin rides payload", st, body)

    # Owner-only metrics
    st, body = _request(
        "POST",
        f"{base}/api/auth/login",
        json_body={"role": "owner", "secret": owner_secret},
    )
    if st != 200:
        _fail("POST /api/auth/login (owner)", st, body)
    own_token = body["access_token"]

    st, body = _request("GET", f"{base}/api/admin/metrics", bearer=own_token)
    if st != 200:
        _fail("GET /api/admin/metrics (owner)", st, body)

    # Operator should not see owner metrics
    st, _ = _request("GET", f"{base}/api/admin/metrics", bearer=op_token)
    if st != 403:
        _fail("GET /api/admin/metrics (operator must be 403)", st, _)

    # Disable passenger → login-app 403
    st, body = _request(
        "PATCH",
        f"{base}/api/admin/users/{pass_uid}",
        bearer=op_token,
        json_body={"is_enabled": False},
    )
    if st != 200:
        _fail("PATCH /api/admin/users (disable)", st, body)

    st, body = _request(
        "POST",
        f"{base}/api/auth/login-app",
        json_body={"email": pass_email, "password": password},
    )
    if st != 403 or body.get("error") != "account_disabled":
        _fail("login-app when disabled (expect 403 account_disabled)", st, body)

    # Re-enable (cleanup)
    st, body = _request(
        "PATCH",
        f"{base}/api/admin/users/{pass_uid}",
        bearer=op_token,
        json_body={"is_enabled": True},
    )
    if st != 200:
        _fail("PATCH /api/admin/users (re-enable)", st, body)

    print("smoke_api: OK (auth, rides, chat REST, profile, admin, disabled flow)")


if __name__ == "__main__":
    main()
