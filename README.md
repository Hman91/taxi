# taxi

> **Taxi Pro Tunisia** — Flask REST API + PostgreSQL (SQLAlchemy) + Flutter (see `.cursor/context.md` for product scope).

## Repository layout (aligned with `main` + stack)

| Path | Role |
|------|------|
| `app.py` | Same entry idea as `main`: run Streamlit prototype (`python app.py` → `legacy/streamlit_app.py`). |
| `backend/` | Flask app factory, blueprints, services, SQLAlchemy models, Alembic migrations under `backend/migrations/`. |
| `flutter/taxi_pro/` | Flutter client; API calls go through `lib/services/taxi_app_service.dart`. |
| `legacy/` | Streamlit UI (heavy prototype). |

## Backend (API)

```bash
cd /path/to/taxi
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/alembic upgrade head
.venv/bin/python -m backend
```

Defaults: `http://127.0.0.1:5000`. **Database:** PostgreSQL — set `DATABASE_URL`, then run **`alembic upgrade head`** once from the repo root before starting the server.

Run the API with **`python -m backend`** so **Flask-SocketIO** uses `socketio.run` (not plain `flask run`). Socket.IO shares the same host/port (e.g. `http://localhost:5000`).

### Real-time (Socket.IO)

Connect as an app user (`user` or `driver` JWT from `login-app` with `uid`):

- **Auth:** pass `token` in the handshake `auth` object (`{ "token": "<access_token>" }`) **or** query param `?token=...`.
- **`join_conversation`** — `{ "conversation_id": <int> }` → server joins room `conversation:<id>`; ack event **`joined_conversation`**.
- **`leave_conversation`** — `{ "conversation_id": <int> }`.
- **`send_message`** — `{ "conversation_id": <int>, "text": "..." }` → server persists via `chat_service`, then emits **`receive_message`** and **`message`** to each participant’s **`user:<id>`** room with **`display_text`** / **`translated_text`** (see translation below). Errors: **`error`** `{ "code": "..." }`.

On connect, the server joins the client to **`user:<user_id>`** for targeted pushes.

**Ride lifecycle:** **`ride_status`** `{ "ride": { ... } }` is emitted to the passenger and (if assigned) the driver after create/accept/reject/start/complete/cancel (same shape as REST ride JSON).

**Translation (delivery):** `services/translation_service.py` uses the **`translations`** table as cache. Set **`TRANSLATION_PROVIDER=none`** (or `stub` / `off`) to skip outbound Google calls; default is **`google`** via **`deep-translator`**. **`TRANSLATION_TIMEOUT_SECONDS`** caps vendor latency (fallback: original text).

### Environment variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `DATABASE_URL` | PostgreSQL (SQLAlchemy / psycopg2) | `postgresql+psycopg2://postgres:postgres@127.0.0.1:5432/taxi` |
| `TAXI_SQLITE_PATH` | Legacy SQLite file for one-off import (optional) | `backend/data/taxi.db` |
| `FLASK_SECRET_KEY` | Signing key for API tokens | `dev-change-me-in-production` |
| `OWNER_PASSWORD` | Owner login (code flow) | `NabeulGold2026` |
| `DRIVER_CODE` | Driver login (code flow) | `Driver2026` |
| `B2B_CODE` | B2B login | `Hotel2026` |
| `OPERATOR_CODE` | Operator login | `Op2026` |
| `FLASK_DEBUG` | Set to `1` for debug | off |
| `PORT` | Listen port | `5000` |
| `TRANSLATION_PROVIDER` | `google` \| `none` \| `stub` \| `off` | `google` |
| `TRANSLATION_TIMEOUT_SECONDS` | Vendor call timeout | `5` |
| `SMOKE_API_BASE` | Default base URL for `smoke_api.py` (optional) | `http://127.0.0.1:5000` |

### Runbook: `DATABASE_URL`, Socket URL, workers

**`DATABASE_URL` (PostgreSQL)**  
Use an SQLAlchemy URL, e.g. `postgresql+psycopg2://USER:PASSWORD@HOST:5432/DBNAME`. **URL-encode** reserved characters in the password (e.g. `@` → `%40`, `#` → `%23`) so the parser does not treat them as host or fragment delimiters—this matters often on **Windows** when pasting connection strings.

**Socket.IO URL (same host as HTTP)**  
The browser/Flutter client connects to the **same origin** as the REST API (scheme + host + port). The Engine.IO path is **`/socket.io/`** (default). Set Flutter’s **`API_BASE_URL`** to that origin (e.g. `http://127.0.0.1:5000`); **`socket_io_client`** uses it for both REST and Socket.IO. Behind a reverse proxy, proxy HTTP **and** WebSocket upgrades for `/socket.io/` to the app.

**Workers / process model**  
The app is started with **`python -m backend`**, which runs **`socketio.run(...)`** (see `backend/__init__.py`). **`async_mode`** is currently **`threading`**, which is fine for local development and moderate traffic. For heavier production loads, plan a deployment that matches **Flask-SocketIO** expectations (e.g. **gunicorn** with compatible **`eventlet`** or **`gevent`** workers and the matching **`async_mode`** in `socketio.init_app`, per the upstream deployment docs)—that swap is an infrastructure change, not required for the default dev command.

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

**Chat & profile** (Bearer token from `login-app` only)

- `GET /api/rides/<id>/conversation` — `{ "conversation_id", "ride_id" }` when the ride has chat (`accepted`+ or existing thread after cancel); errors: `chat_not_open`, `forbidden`, `not_found`.
- `GET /api/conversations/<id>/messages?before_id=&limit=` — paginated history (newest page first). Each message includes `original_text`, `original_language`, **`display_text`**, and optional **`translated_text`** for the authenticated user’s `preferred_language` (cache in `translations`).
- `PATCH /api/me` — `{ "preferred_language": "en" }` (ISO-style tag, max 10 chars); returns `user` object. Disabled accounts get `{ "error": "account_disabled" }` with 403 on ride/chat/me routes.

**Admin** (Bearer token from **`/api/auth/login`** with role **`owner`** or **`operator`**)

- `GET /api/admin/rides?limit=` — app rides (passenger/driver lifecycle), operator + owner.
- `GET /api/admin/drivers/locations` — driver ids, email, `last_lat` / `last_lng` / `last_seen_at`, operator + owner.
- `GET /api/admin/conversations/<id>/messages?lang=&before_id=&limit=` — read-only transcript; optional `lang` / `target_lang` for `display_text` (translation cache), operator + owner.
- `GET /api/admin/users?limit=&offset=` — app users (`user` / `driver`), operator + owner.
- `PATCH /api/admin/users/<id>` — `{ "is_enabled": true|false }`, operator + owner.
- `GET /api/admin/b2b-tenants` — B2B tenants, operator + owner.
- `PATCH /api/admin/b2b-tenants/<id>` — `{ "is_enabled": true|false }`, operator + owner.
- `GET /api/admin/metrics` — same money/rating aggregate as legacy owner metrics (**owner only**). Existing `GET /api/metrics/owner` remains.

**Legacy / ops**

- `POST /api/trips` — code-login driver token.
- `GET /api/trips` — owner or operator.
- `GET /api/metrics/owner` — owner.
- `POST /api/ratings`

**Disabled app accounts:** `POST /api/auth/login-app` returns **`403`** with `{ "error": "account_disabled" }` if `users.is_enabled` is false (staff can re-enable via admin `PATCH`).

### Schema

Alembic revision `001_initial` creates `users`, `drivers`, `rides` (foreign keys) + legacy `trips`, `ratings`. Revision `002_chat_b2b` adds chat (`conversations`, `messages`, `translations`), `users.preferred_language` / `is_enabled`, driver `last_lat` / `last_lng` / `last_seen_at`, and `b2b_tenants`. The file `backend/schema.sql` is a legacy SQLite reference only.

### SQLite → PostgreSQL (one-off)

After `alembic upgrade head`, you can copy an old `taxi.db` into PostgreSQL (same table order and IDs as SQLite, then sequence sync):

```bash
# Preview counts (needs DATABASE_URL; optional SQLite path via TAXI_SQLITE_PATH)
python -m backend.scripts.migrate_sqlite_to_pg --dry-run

# Import into an empty database
python -m backend.scripts.migrate_sqlite_to_pg

# Replace existing rows in those five tables (TRUNCATE … CASCADE) then import
python -m backend.scripts.migrate_sqlite_to_pg --replace
```

Use `--sqlite-path /path/to/taxi.db` to override the default `backend/data/taxi.db`.

## Smoke tests (verification)

With **PostgreSQL** migrated (`alembic upgrade head`) and the API **already running** (`python -m backend`):

```bash
# from repo root; optional: --base-url https://your-host or SMOKE_API_BASE=...
python -m backend.scripts.smoke_api
```

The script exercises **health**, **register + login-app**, **rides** (create + accept), **chat REST** (conversation + message list), **`PATCH /api/me`**, **admin** (`/api/admin/rides`, owner-only **`/api/admin/metrics`**, operator denied), **disable user** via **`PATCH /api/admin/users/<id>`**, **`login-app` → 403 `account_disabled`**, then **re-enables** the test user. It uses unique emails per run. **`OPERATOR_CODE`** and **`OWNER_PASSWORD`** must match the server (defaults align with dev `backend/config.py`).

Socket.IO is **not** exercised here (no extra Python deps); use the Flutter app or a Socket.IO client to validate **`join_conversation`** / **`send_message`** / **`receive_message`** manually if needed.

## Flutter app

**Languages (UI):** Arabic, English, French, German, Chinese (Simplified), Italian, Spanish, Russian — use the **language icon** (AppBar) on the home screen. Strings live in `flutter/taxi_pro/lib/l10n/app_*.arb`.

```bash
cd flutter/taxi_pro
flutter pub get
flutter gen-l10n   # regenerates `lib/l10n/app_localizations*.dart` after ARB edits
flutter create . --platforms=android   # if android/ (or other platform folders) are missing
```

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

**Android Studio / Android emulator**

1. Open **`flutter/taxi_pro`** in Android Studio (or run from a terminal with the Flutter SDK on `PATH`).
2. Start an **emulator** (Device Manager) or connect a **physical device** with USB debugging.
3. Run the Flask API on your PC: **`python -m backend`** from the repo root (it listens on **`0.0.0.0:5000`**).
4. **Emulator → your PC’s API:** use host loopback alias **`10.0.2.2`**, not `127.0.0.1`:
   ```bash
   cd flutter/taxi_pro
   flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:5000
   ```
5. **Physical phone (same Wi‑Fi):** use your computer’s LAN IP (e.g. `http://192.168.1.x:5000` from `ipconfig` / `hostname -I`).
6. Dev API is **HTTP**; the Android manifest includes **`INTERNET`** and **`android:usesCleartextTraffic="true"`** so cleartext calls to the API are allowed.
7. In **Android Studio** run configuration, add **additional args**:  
   `--dart-define=API_BASE_URL=http://10.0.2.2:5000` (emulator) or your LAN URL (device).

**pgAdmin + PostgreSQL (where app data is stored)**

1. Install and start **PostgreSQL**. In **pgAdmin**, register a **server** (usually host `localhost`, port `5432`, user `postgres`, your password).
2. Create a database named **`taxi`** (empty). You **do not** create tables manually in pgAdmin for normal setup.
3. Set **`DATABASE_URL`** if credentials differ from the default in `README` / `backend/config.py`.
4. From the **repository root**, run **`alembic upgrade head`** — this creates **`users`**, **`drivers`**, **`rides`**, **`conversations`**, **`messages`**, etc.
5. After using the app, refresh **pgAdmin → taxi → Schemas → public → Tables** and use **View/Edit Data** to see rows (e.g. `users`, `rides`).

If **`alembic upgrade head`** fails on Windows with **psycopg2 `UnicodeDecodeError`**, use a **`DATABASE_URL` with only ASCII**, confirm the Postgres service is running, and avoid special characters in related env paths; reinstall **`psycopg2-binary`** inside your venv if needed.

Use **`lib/services/taxi_app_service.dart`** from widgets (not `TaxiApiClient` directly). **App rides & chat:** home entries *Passenger (rides & chat)* and *Driver (app shifts)* use JWT (`/api/auth/login-app`); real-time chat uses **`socket_io_client`** against the **same base URL** as `API_BASE_URL` (Socket.IO on the Flask server). **`lib/services/chat_socket_service.dart`** + **`lib/repositories/chat_repository.dart`** wrap history + socket events; UI uses **`ChatMessage.displayText`**. Operator/owner screens can load **`/api/admin/rides`**, **`/api/admin/drivers/locations`**, and (owner) **`/api/admin/metrics`**.

Maps (e.g. Google Maps) are not wired in this repo yet; pickup/destination are plain text fields in the API.

## Legacy Streamlit UI

Same **8 languages** in the sidebar (Google Translate via `deep-translator`; Arabic skips translation). `app.py` matches the `main` branch convention (Streamlit at repo root). You need Streamlit installed:

```bash
.venv/bin/pip install -r requirements-legacy.txt
python app.py
# or: .venv/bin/streamlit run legacy/streamlit_app.py
```

## Security

Default passwords are for development only. Change secrets via environment variables before production.
