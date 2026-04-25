---
name: Free Deployment Steps
overview: Deploy the taxi project for testing on free platforms by provisioning Postgres, deploying Flask API with migrations, publishing Flutter web, and distributing Android APK with a repeatable validation checklist.
todos:
  - id: collect-env
    content: Consolidate production/test env vars and target domains for API and web.
    status: pending
  - id: provision-db
    content: Create Neon Postgres and prepare SQLAlchemy DATABASE_URL for deployment secrets.
    status: pending
  - id: deploy-backend
    content: Deploy Flask API on Render with python -m backend and configured secrets.
    status: pending
  - id: migrate-db
    content: Run alembic upgrade head against hosted database and verify schema.
    status: pending
  - id: verify-api
    content: Validate health, smoke API routes, and basic Socket.IO connectivity.
    status: pending
  - id: deploy-web
    content: Build Flutter web with hosted API URL and deploy build/web to Firebase Hosting.
    status: pending
  - id: ship-apk
    content: Build release APK with API_BASE_URL and distribute to testers.
    status: pending
  - id: e2e-check
    content: Run end-to-end ride/chat/admin validation and document free-tier caveats.
    status: pending
  - id: redeploy-runbook
    content: Maintain an isolated redeploy runbook (DB, backend, web, APK) usable from another PC after fixes.
    status: pending
isProject: false
---

# Deployment Plan (Free Tier, Test Environment)

## Target Stack
- PostgreSQL: Neon (free)
- Flask API + Socket.IO: Render Web Service (free/dev)
- Flutter Web (Chrome build output): Firebase Hosting (free)
- Android APK tester distribution: Firebase App Distribution (or GitHub Releases fallback)

## 1) Prepare Production-like Environment Variables
- Create a single checklist of required backend env vars from [`README.md`](/home/dell-f2xz953/Desktop/projects/taxi/README.md) and [`backend/config.py`](/home/dell-f2xz953/Desktop/projects/taxi/backend/config.py):
  - `DATABASE_URL`, `FLASK_SECRET_KEY`, `OWNER_PASSWORD`, `DRIVER_CODE`, `B2B_CODE`, `OPERATOR_CODE`
  - `TRANSLATION_PROVIDER` (recommend `none` for free-test), `TRANSLATION_TIMEOUT_SECONDS`, `PORT`
- Decide final test domains early:
  - API URL (Render): `https://<api-service>.onrender.com`
  - Web URL (Firebase): `https://<project>.web.app`
- Confirm CORS policy in backend allows the chosen web host (and optional localhost for local testing).

## 2) Provision Managed Postgres (Neon)
- Create Neon project and database.
- Copy pooled/direct connection string and convert it to SQLAlchemy format expected by this project:
  - `postgresql+psycopg2://...`
- URL-encode special characters in DB password.
- Save as `DATABASE_URL` secret for Render deployment.

## 3) Deploy Flask Backend on Render
- Create a new Render Web Service connected to this repository.
- Runtime/build settings:
  - Install command: `pip install -r requirements.txt`
  - Start command: `python -m backend`
- Add all required environment variables in Render dashboard.
- Ensure instance type/free tier supports long-running HTTP service (for Socket.IO compatibility).

## 4) Run Database Migrations in Hosted Environment
- Execute Alembic migration against Neon using deployment env:
  - `alembic upgrade head`
- Prefer one of these patterns:
  - Render one-off shell/job after first deploy, or
  - temporary release command/script for first rollout.
- Validate schema creation (`users`, `drivers`, `rides`, `conversations`, `messages`, etc.) per migration expectations in [`backend/migrations`](/home/dell-f2xz953/Desktop/projects/taxi/backend/migrations).

## 5) Verify Backend Health + Core APIs
- Test `GET /api/health` on the Render URL.
- Run smoke checks using existing script in [`backend/scripts/smoke_api.py`](/home/dell-f2xz953/Desktop/projects/taxi/backend/scripts/smoke_api.py) against deployed API base URL.
- Validate auth + rides + chat REST routes return expected statuses.
- Do one manual Socket.IO check (connect, join room, send message) to confirm real-time path works in hosted mode.

## 6) Build Flutter Web with Hosted API URL
- From [`flutter/taxi_pro`](/home/dell-f2xz953/Desktop/projects/taxi/flutter/taxi_pro):
  - `flutter pub get`
  - `flutter build web --dart-define=API_BASE_URL=https://<api-service>.onrender.com`
- Confirm generated `build/web` uses the hosted API endpoint.

## 7) Deploy Flutter Web to Firebase Hosting
- Create/select Firebase project.
- Initialize hosting in Flutter app folder and set `build/web` as public directory.
- Deploy hosting and obtain public URL.
- Update backend CORS allowlist to include Firebase domain if needed, then redeploy backend.

## 8) Build and Share Android APK for Testers
- Build APK from [`flutter/taxi_pro`](/home/dell-f2xz953/Desktop/projects/taxi/flutter/taxi_pro):
  - `flutter build apk --release --dart-define=API_BASE_URL=https://<api-service>.onrender.com`
- Distribute via Firebase App Distribution:
  - Create Android app in Firebase project
  - Upload APK and invite tester emails/group
- Fallback: upload APK asset to GitHub Release for direct download.

## 9) End-to-End Validation Checklist
- Passenger flow: register/login-app, create ride, open chat.
- Driver flow: login-app, accept/start/complete ride.
- Admin flow: rides/users/metrics endpoints (owner/operator role behavior).
- Web app loads over HTTPS and can call API without CORS errors.
- APK can login and hit production API.
- Database receives expected rows for users/rides/messages.

## 10) Free-Tier Operations Guardrails
- Document free-tier limits (sleep/cold start/monthly quotas) and expected delays.
- Disable costly translation provider in test (`TRANSLATION_PROVIDER=none`).
- Rotate secrets before any public demo and avoid default passwords from docs.
- Add a simple rollback path: previous backend deploy + known-good web artifact.

## 11) Redeploy After Fixes (Any PC, Step-by-Step Isolation)

Use this runbook when you patch code and need to redeploy from your current machine or a different PC. Keep each surface independent so you can redeploy only what changed.

### 11.0) One-time prerequisites on another PC
- Install: `git`, Python 3.10+, `pip`, Flutter SDK, Android Studio + Android SDK command-line tools, Firebase CLI.
- Clone repo and checkout target branch/commit.
- Prepare secrets outside git (`.env.local` for local usage only; Render/Firebase/Neon secrets in their dashboards).
- Validate toolchain:
  - `python3 --version`
  - `flutter doctor -v`
  - `firebase --version`

### 11.1) Database-only redeploy (Neon)
- Use this when migrations/schema changed.
- Set production DB URL in shell:
  - `export DATABASE_URL='postgresql+psycopg2://...'`
- From repo root:
  - `alembic upgrade head`
- Validate migration state:
  - `alembic current`
- Optional API-level check after migration:
  - `GET https://<api-service>.onrender.com/api/health`

### 11.2) Backend-only redeploy (Render)
- Use this when backend code/env changed.
- Push fix branch/commit to repository connected to Render.
- In Render service:
  - Confirm env vars still set (`DATABASE_URL`, auth codes, secrets).
  - Trigger redeploy (or wait for auto-deploy on commit).
- Post-deploy checks:
  - `GET /api/health`
  - `python -m backend.scripts.smoke_api --base-url https://<api-service>.onrender.com`
- If DB models changed, execute section 11.1 before/after backend deploy as needed.

### 11.3) Web-only redeploy (Flutter Web, Chrome build -> Firebase Hosting)
- Use this when Flutter web UI/client logic changed.
- From [`flutter/taxi_pro`](/home/dell-f2xz953/Desktop/projects/taxi/flutter/taxi_pro):
  - `flutter pub get`
  - `flutter build web --dart-define=API_BASE_URL=https://<api-service>.onrender.com`
- Quick local sanity (Chrome):
  - `flutter run -d chrome --dart-define=API_BASE_URL=https://<api-service>.onrender.com`
- Deploy to Firebase Hosting:
  - `firebase deploy --only hosting`
- Validate hosted web:
  - open `https://<project>.web.app`
  - verify login + one API call succeeds.

### 11.4) APK-only redeploy (Android testers)
- Use this when mobile app logic changed.
- Ensure Android SDK licenses accepted:
  - `flutter doctor --android-licenses`
- Build release APK from [`flutter/taxi_pro`](/home/dell-f2xz953/Desktop/projects/taxi/flutter/taxi_pro):
  - `flutter build apk --release --dart-define=API_BASE_URL=https://<api-service>.onrender.com`
- Output artifact:
  - `build/app/outputs/flutter-apk/app-release.apk`
- Distribute:
  - Firebase App Distribution upload, or GitHub Release asset fallback.
- Validate on device:
  - login, create ride, chat message send/receive.

### 11.5) Redeploy decision matrix (what to run)
- Backend Python/API changes -> 11.2 (+11.1 if schema changed).
- Alembic/migrations/model schema changes -> 11.1 then 11.2.
- Flutter web-only changes -> 11.3.
- Flutter Android-only changes -> 11.4.
- Shared API contract changes (backend + Flutter) -> 11.1 (if needed), 11.2, 11.3, 11.4 in order.

## Delivery Order (Practical Sequence)
1. Neon DB
2. Render backend + env vars
3. Alembic migration
4. API health/smoke test
5. Flutter web build/deploy
6. CORS recheck + socket check
7. APK build/distribution
8. Full E2E validation
