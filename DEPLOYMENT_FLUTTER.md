# Flutter deploy (one step at a time)

After the backend is on Render, the **web and mobile clients must be rebuilt** with the same public API origin. The app does not read the API URL from Render at runtime; it is **compiled in** as `API_BASE_URL` (see `flutter/taxi_pro/lib/config.dart`).

---

## Step 1 — Web: bake `API_BASE_URL` and host on Firebase

1. Copy `flutter/taxi_pro/api_base.production.json.example` to `flutter/taxi_pro/api_base.production.json` and set `API_BASE_URL` to your Render URL, e.g. `https://your-service.onrender.com` (https, no trailing slash).  
   Or skip the file and pass the URL when you run the script (next step).
2. From `flutter/taxi_pro`, run:

   ```powershell
   .\build_web_production.ps1 -ApiBase "https://your-service.onrender.com"
   ```

   Or, if you use `api_base.production.json` only:

   ```powershell
   .\build_web_production.ps1
   ```
3. Deploy the new files:

   ```bash
   firebase deploy --only hosting
   ```

   (Run from a directory where your Firebase project is linked, usually `flutter/taxi_pro`.)

**Result:** REST calls, Socket.IO, Google login, and post-login language sync all use your Render host.

---

## Step 2 — Google Sign-In (web)

1. In [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → your **Web client** (same client ID as `GOOGLE_OAUTH_CLIENT_ID` / `web/index.html` meta `google-signin-client_id`).
2. Under **Authorized JavaScript origins**, add:
   - `https://<your-project-id>.web.app`
   - `https://<your-project-id>.firebaseapp.com`  
   Add a custom domain here too if you use one.
3. Save, wait a few minutes, then test Sign-In on the deployed site.

**Result:** The Google button works on the real Firebase origin (not just localhost).

---

## Step 3 — Android (and iOS) release builds

Release APK/IPA also needs the same define, or they still point at the emulator/loopback defaults:

```powershell
cd flutter/taxi_pro
flutter build apk --release --dart-define=API_BASE_URL=https://your-service.onrender.com
```

---

## Step 4 — Render checklist (no Flutter redeploy)

- **Database:** Run migrations against Neon if you have not: `alembic upgrade head` (with `DATABASE_URL` set) before relying on production.
- **Pre-deploy command (optional):** e.g. `alembic upgrade head` on Render if you want schema applied on each deploy.
- **PORT:** Prefer the `PORT` that Render sets automatically. Only override if you know the platform’s expectations; the app uses `os.environ["PORT"]` in `backend/__init__.py`.
- **Build filters on Render** ignoring `flutter/**` only means Flutter commits do not rebuild the **API** service. You still run Step 1 locally (or in CI) to update Firebase.

---

## Why chat “only broke after deploy”

Socket.IO and HTTP share the same base URL in `ChatSocketService` and `TaxiApiClient`. A web build that still embeds `http://localhost:5000` never reaches Render, so chat and login fail together. Step 1 fixes that class of issue.
