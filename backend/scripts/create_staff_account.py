"""Create the singleton Owner/Operator account manually.

Usage examples:
  python -m backend.scripts.create_staff_account --role owner --email owner@taxi.com --password "StrongPass123"
  python -m backend.scripts.create_staff_account --role operator --email operator@taxi.com --password "StrongPass123"
"""
from __future__ import annotations

import argparse
import sys

from werkzeug.security import generate_password_hash

from backend import create_app
from backend.extensions import db
from backend.models import User


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--role", required=True, choices=["owner", "operator"])
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    email = args.email.strip().lower()
    if not email:
        print("error: email is required", file=sys.stderr)
        return 2
    if len(args.password) < 6:
        print("error: password must be at least 6 characters", file=sys.stderr)
        return 2

    app = create_app()
    with app.app_context():
        existing_role = db.session.query(User).filter(User.role == args.role).first()
        if existing_role is not None:
            print(f"error: {args.role} account already exists (id={existing_role.id})", file=sys.stderr)
            return 1
        existing_email = db.session.query(User).filter(User.email == email).first()
        if existing_email is not None:
            print(f"error: email already exists ({email})", file=sys.stderr)
            return 1

        u = User(
            email=email,
            password_hash=generate_password_hash(args.password),
            role=args.role,
            display_name=args.role.title(),
            is_enabled=True,
            approval_status="approved",
        )
        db.session.add(u)
        db.session.commit()
        print(f"created {args.role} account id={u.id} email={u.email}")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
