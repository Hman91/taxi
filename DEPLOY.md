# Deploy Taxi Pro (Render + Supabase + Vercel)

This repo is wired for:

- **API**: [Render](https://render.com) Web Service (Gunicorn + Eventlet, Flask-SocketIO)
- **DB**: [Supabase](https://supabase.com) PostgreSQL (`DATABASE_URL`)
- **Flutter web**: [Vercel](https://vercel.com) (static `build/web`)
- **Android APK**: build locally, attach to a [GitHub Release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)

---

## 1) Supabase — database

1. Create a project and open **Project Settings → Database**.
2. Copy the **connection string** (URI). Use the **Session** or **Transaction** pooler if you prefer; ensure the password is correct.
3. You will set it on Render as **`DATABASE_URL`** (see below). **Session pooler** (URI type) is a good default for Render.

**You do not need Render Shell** to migrate. Do one of the following:

1. **Automatic (recommended for Render):** the **`Procfile`** runs `python -m alembic upgrade head` before Gunicorn on every start. As long as **`DATABASE_URL`** is set in the service environment, new migrations apply on deploy without using Shell.

2. **From your PC (free):** point at Supabase the same way the server does, then run Alembic locally:

```bash
cd /path/to/taxi
# Windows (cmd):  set DATABASE_URL=postgresql+psycopg2://...
# PowerShell:     $env:DATABASE_URL = "postgresql+psycopg2://..."
pip install -r requirements.txt
python -m alembic upgrade head
```

On Render, add **`DATABASE_URL`** in the service **Environment** before the app or Alembic can talk to the DB (see §3).

**Quick DB connectivity test** (after `pip install -r requirements.txt`, with `DATABASE_URL` in a `.env` file at the repo root or exported in the shell):

```bash
python -c "from dotenv import load_dotenv; load_dotenv(); import os, psycopg2; from backend.config import _normalize_database_url; u=_normalize_database_url(os.environ['DATABASE_URL']); c=psycopg2.connect(u.replace('postgresql+psycopg2://','postgresql://',1) if u.startswith('postgresql+psycopg2://') else u); print('Connected'); c.close()"
```

---

## 2) Render — environment variables

Set these in the Render service **Environment**:

| Variable | Required | Notes |
|----------|----------|--------|
| `DATABASE_URL` | **Yes** | Supabase Session pooler URI. **Required** for the running app. If you run Alembic during build, it must be set before that step or Alembic falls back to `127.0.0.1:5432` and the build fails. |
| `SECRET_KEY` or `FLASK_SECRET_KEY` | Yes (prod) | Long random string for sessions/JWT (`SECRET_KEY` is the usual Render/docs name; either works). |
| `SOCKETIO_ASYNC_MODE` | Auto in Procfile | Procfile sets `eventlet` for Gunicorn; do not override unless you know why. |
| `GOOGLE_OAUTH_CLIENT_ID` | For Google login | Same Web client ID as in Flutter `config.dart`. |
| `OWNER_PASSWORD`, `OPERATOR_CODE`, `B2B_CODE`, etc. | Optional | Override defaults from `backend/config.py`. |

**CORS** is already enabled in `backend/__init__.py` for `/api/*` and `/socket.io/*`.

---

## 3) Render — build & start

**Root directory**: repository root (where `wsgi.py`, `requirements.txt`, `alembic.ini` live).

**Build command** must install **`requirements.txt`** (Flask, gunicorn, eventlet).  
If your build log only shows **Streamlit / pandas / numpy**, you are installing **`requirements-legacy.txt`** by mistake — change it to `requirements.txt` or the service will fail with `gunicorn: command not found`.

**Build command (recommended — no database required during build):**

```bash
pip install -r requirements.txt
```

**Why not `alembic upgrade head` in the build?** If **`DATABASE_URL`** is missing in Render’s environment, Alembic uses the dev default `127.0.0.1:5432` and the build fails with *connection refused*. **Recommended:** keep the build to `pip install -r requirements.txt` only; migrations run at **web start** via the `Procfile` (see above) once `DATABASE_URL` is set.

**If you really want migrations in the build** (not required): set **`DATABASE_URL`** in Render first, then:

```bash
pip install -r requirements.txt && python -m alembic upgrade head
```

**Start command** is defined in the **`Procfile`**: it runs `python -m alembic upgrade head`, then Gunicorn with `python -m gunicorn` (reliable on PATH). Equivalent:

```bash
python -m alembic upgrade head && env SOCKETIO_ASYNC_MODE=eventlet python -m gunicorn -w 1 -k eventlet -b 0.0.0.0:$PORT wsgi:app
```

If you ever need **Render Shell** (optional, paid on some plans), you can run `python -m alembic upgrade head` from the project root the same way; it is not required for normal deploys.

After deploy, your API base URL is:

`https://<your-service>.onrender.com`

(No trailing slash; the Flutter client adds `/api/...`.)

**Free tier**: the service may sleep; first request can take ~30–60 seconds.

---

## 4) Local smoke test (Gunicorn)

```bash
pip install -r requirements.txt
set DATABASE_URL=... 
set SOCKETIO_ASYNC_MODE=eventlet
python -m gunicorn -w 1 -k eventlet -b 127.0.0.1:5000 wsgi:app
```

Open `http://127.0.0.1:5000/api/health`.

### Windows: Gunicorn does not run locally

**Gunicorn is Unix-only** (it uses `fcntl`, which does not exist on Windows). You will see:

`ModuleNotFoundError: No module named 'fcntl'`

That is expected. Do this instead:

| Goal | Command |
|------|--------|
| Local API on Windows (dev) | From repo root: `python -m backend` (uses Socket.IO + threading; `.env` loaded via `config.py`) |
| Production-like HTTP on Windows | Use [WSL2](https://learn.microsoft.com/windows/wsl/) and run the Gunicorn command inside Linux, or deploy to Render and test there |

Check: `http://127.0.0.1:5000/api/health` (default port from `backend/__main__.py`).

---

## 5) Flutter — point to production API

Build with your Render URL (HTTPS, no trailing slash):

```bash
cd flutter/taxi_pro
flutter build web --dart-define=API_BASE_URL=https://your-api.onrender.com
```

For Android release:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.onrender.com
```

Default `API_BASE_URL` is documented in `lib/config.dart`.

---

## 6) Vercel — Flutter web

1. Build: `flutter build web --dart-define=API_BASE_URL=https://your-api.onrender.com`
2. Deploy the **`build/web`** folder (Vercel project root = `flutter/taxi_pro/build/web`, or copy `vercel.json` next to the uploaded output).
3. `vercel.json` in `flutter/taxi_pro` rewrites all routes to `index.html` for SPA routing.

Install CLI: `npm i -g vercel`, then from `build/web`: `vercel`.

**Important**: In Vercel, set your production domain. Add that origin to CORS if you ever restrict origins (currently `*` for API and Socket.IO).

---

## 7) GitHub Releases — APK

1. Run `flutter build apk --release --dart-define=API_BASE_URL=...`
2. Upload `flutter/taxi_pro/build/app/outputs/flutter-apk/app-release.apk` to a GitHub Release.

---

## What you must provide

- **Supabase** `DATABASE_URL` (and run `alembic upgrade head` at least once).
- **Render** account + GitHub connection (or deploy from Git).
- **`FLASK_SECRET_KEY`** (generate e.g. `python -c "import secrets; print(secrets.token_hex(32))"`).
- **Vercel** account to host `build/web`.
- **Optional**: production `GOOGLE_OAUTH_CLIENT_ID` if you use Google sign-in (must match Flutter and backend).

If you want, share (privately) only: **Render service URL** and whether **Google login** is required in production so we can double-check OAuth redirect and CORS.
