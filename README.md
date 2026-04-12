# taxi

> **Taxi Pro Tunisia** — Flask REST API + SQLite + Flutter (see `.cursor/context.md` for product scope).

## Repository layout (aligned with `main` + stack)

| Path | Role |
|------|------|
| `app.py` | Same entry idea as `main`: run Streamlit prototype (`python app.py` → `legacy/streamlit_app.py`). |
| `backend/` | Flask app factory, blueprints, services, `schema.sql`, SQLite file under `backend/data/`. |
| `flutter/taxi_pro/` | Flutter client; API calls go through `lib/services/taxi_app_service.dart`. |
| `legacy/` | Streamlit UI (heavy prototype). |

## Backend (API)

```bash
cd /path/to/taxi
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python -m backend
```

Defaults: `http://127.0.0.1:5000`. Database: `backend/data/taxi.db` (created from `backend/schema.sql`).

### Environment variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `FLASK_SECRET_KEY` | Signing key for API tokens | `dev-change-me-in-production` |
| `TAXI_DATABASE_PATH` | SQLite file path | `backend/data/taxi.db` |
| `OWNER_PASSWORD` | Owner login (code flow) | `NabeulGold2026` |
| `DRIVER_CODE` | Driver login (code flow) | `Driver2026` |
| `B2B_CODE` | B2B login | `Biz2026` |
| `OPERATOR_CODE` | Operator login | `Operator2026` |
| `FLASK_DEBUG` | Set to `1` for debug | off |
| `PORT` | Listen port | `5000` |

### API overview

**Health & pricing**

- `GET /api/health`
- `GET /api/fares/airport`
- `POST /api/fares/quote`

**Auth**

- `POST /api/auth/login` — `{ "role": "owner|driver|b2b|operator", "secret": "..." }` → `access_token` (no `uid`; ops / legacy driver trip API).
- `POST /api/auth/register` — `{ "email", "password", "role": "user|driver" }` (app users).
- `POST /api/auth/login-app` — `{ "email", "password" }` → `access_token` with `uid` in token (for rides).

**Rides** (Bearer token from `login-app` only)

- `GET /api/rides` — passenger: own rides; driver: assigned + pending.
- `POST /api/rides` — `{ "pickup", "destination" }` (user).
- `POST /api/rides/<id>/accept` | `/reject` | `/start` | `/complete` (driver).
- `POST /api/rides/<id>/cancel` (user).

Statuses: `pending` → `accepted` → `ongoing` → `completed` (or `cancelled`). One active ride per passenger (`pending` | `accepted` | `ongoing`).

**Legacy / ops**

- `POST /api/trips` — code-login driver token.
- `GET /api/trips` — owner or operator.
- `GET /api/metrics/owner` — owner.
- `POST /api/ratings`

### Schema

Canonical DDL: `backend/schema.sql` — `users`, `drivers`, `rides` (foreign keys) + legacy `trips`, `ratings`.

## Flutter app

**Languages (UI):** Arabic, English, French, German, Chinese (Simplified), Italian, Spanish, Russian — use the **language icon** (AppBar) on the home screen. Strings live in `flutter/taxi_pro/lib/l10n/app_*.arb`.

```bash
cd flutter/taxi_pro
flutter pub get
flutter gen-l10n   # regenerates `lib/l10n/app_localizations*.dart` after ARB edits
flutter create .   # if platform folders missing
```

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

Use **`lib/services/taxi_app_service.dart`** from widgets (not `TaxiApiClient` directly). Maps (e.g. Google Maps) are not wired in this repo yet; pickup/destination are plain text fields in the API.

## Legacy Streamlit UI

Same **8 languages** in the sidebar (Google Translate via `deep-translator`; Arabic skips translation). `app.py` matches the `main` branch convention (Streamlit at repo root). You need Streamlit installed:

```bash
.venv/bin/pip install -r requirements-legacy.txt
python app.py
# or: .venv/bin/streamlit run legacy/streamlit_app.py
```

## Security

Default passwords are for development only. Change secrets via environment variables before production.
