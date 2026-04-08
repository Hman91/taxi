# Taxi Pro Tunisia

Stack: **Flask** (REST API) + **SQLite** + **Flutter** client. The original Streamlit prototype lives under `legacy/` for reference.

## Backend (API)

```bash
cd /path/to/taxi
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python -m backend
```

Defaults: listens on `http://127.0.0.1:5000`. SQLite database file: `backend/data/taxi.db` (created automatically).

### Environment variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `FLASK_SECRET_KEY` | Signing key for API tokens | `dev-change-me-in-production` |
| `TAXI_DATABASE_PATH` | SQLite file path | `backend/data/taxi.db` |
| `OWNER_PASSWORD` | Owner login | `NabeulGold2026` |
| `DRIVER_CODE` | Driver login | `Driver2026` |
| `B2B_CODE` | B2B login | `Biz2026` |
| `OPERATOR_CODE` | Operator login | `Operator2026` |
| `FLASK_DEBUG` | Set to `1` for debug | off |
| `PORT` | Listen port | `5000` |

### API overview

- `GET /api/health`
- `GET /api/fares/airport`
- `POST /api/fares/quote` — body: `{ "mode": "airport", "route_key": "..." }` or `{ "mode": "gps", "distance_km": 12.5 }`
- `POST /api/auth/login` — `{ "role": "owner|driver|b2b|operator", "secret": "..." }` → `access_token`
- `POST /api/trips` — driver only, `Authorization: Bearer <token>`
- `GET /api/trips` — owner or operator
- `GET /api/metrics/owner` — owner only
- `POST /api/ratings` — `{ "stars": 1..5 }` (public)

## Flutter app

Install [Flutter](https://docs.flutter.dev/get-started/install), then:

```bash
cd flutter/taxi_pro
flutter pub get
# If android/ios/web folders are missing:
flutter create .
```

Run against the API (adjust URL for your device):

- **Linux desktop / web (Chrome):**  
  `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000`
- **Android emulator:** API on host:  
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000`
- **Physical phone:** use your PC’s LAN IP, e.g.  
  `--dart-define=API_BASE_URL=http://192.168.1.10:5000`

Default in code is `http://127.0.0.1:5000`.

## Legacy Streamlit UI

```bash
.venv/bin/pip install -r requirements-legacy.txt
.venv/bin/streamlit run legacy/streamlit_app.py
```

## Security note

Default passwords are for development only. Change all secrets via environment variables before any production deployment.
