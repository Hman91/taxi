# Step 1 - Deployment Environment Setup

Use this file to prepare all required environment values before deploying.

Template files now available:
- `.env.example` for local development
- `config.production.tpl` for deployment/production secret setup

## 1) Target domains (decide first)

- API (Render): `https://<your-api-service>.onrender.com`
- Web (Firebase Hosting): `https://<your-firebase-project>.web.app`

Keep these two URLs ready because they are needed for CORS and Flutter web build.

## 2) Backend env vars (Render)

Set these in Render Environment Variables:

```env
# Required
DATABASE_URL=postgresql+psycopg2://<user>:<url_encoded_password>@<host>:5432/<db_name>
FLASK_SECRET_KEY=<strong-random-secret>
OWNER_PASSWORD=<owner-login-secret>
DRIVER_CODE=<driver-login-secret>
B2B_CODE=<b2b-login-secret>
OPERATOR_CODE=<operator-login-secret>

# Recommended for free test environment
TRANSLATION_PROVIDER=none
TRANSLATION_TIMEOUT_SECONDS=5
PORT=5000

# Optional
FLASK_DEBUG=0
TOKEN_MAX_AGE_SECONDS=86400
GOOGLE_OAUTH_CLIENT_ID=<google-client-id-if-you-use-google-login>
```

Notes:
- `DATABASE_URL` must be SQLAlchemy format (`postgresql+psycopg2://...`).
- URL-encode password characters like `@`, `#`, `:` as `%40`, `%23`, `%3A`.
- Do not keep defaults from `backend/config.py` in deployed environments.

## 3) Flutter build-time env var

When building Flutter web and APK, pass:

```bash
--dart-define=API_BASE_URL=https://<your-api-service>.onrender.com
```

This must match your deployed backend origin.

## 4) CORS/Socket policy check (current code)

Current backend CORS/socket settings are open (`*`) in `backend/__init__.py`.
For strict production, replace `*` with your web domain (`.web.app` / custom domain), but for initial free-tier testing this is acceptable.

## 5) Step 1 completion checklist

- [ ] Render API domain chosen
- [ ] Firebase web domain chosen
- [ ] Neon `DATABASE_URL` converted to `postgresql+psycopg2://...`
- [ ] All secrets generated (no default passwords)
- [ ] `TRANSLATION_PROVIDER=none` set for cost-safe testing
- [ ] `API_BASE_URL` value decided for Flutter web/APK builds
- [ ] `.env.example` copied to `.env.local` (local only, not committed)
- [ ] `config.production.tpl` copied to your deployment secret manager values
- [ ] Flutter web/APK: follow **`DEPLOYMENT_FLUTTER.md`** so `API_BASE_URL` points at the deployed API
