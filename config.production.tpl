# Copy to .env.production in your deployment secrets manager.
# This template is committed; replace all placeholders with real values.

# Backend (Flask)
DATABASE_URL=postgresql+psycopg2://neondb_owner:npg_TFRmEG5n7wSo@ep-square-field-anrygocl.c-6.us-east-1.aws.neon.tech/neondb?sslmode=require
FLASK_SECRET_KEY=;P6UgN5}K6+]ISU+
OWNER_PASSWORD=NabeulGold2026
DRIVER_CODE=Driver2026
B2B_CODE=Hotel2026
OPERATOR_CODE=Op2026
TRANSLATION_PROVIDER=none
TRANSLATION_TIMEOUT_SECONDS=5
TOKEN_MAX_AGE_SECONDS=86400
FLASK_DEBUG=0
PORT=5000

GOOGLE_OAUTH_CLIENT_ID=962065998165-o2v10060s3l65ve7n8leee7hn28ddh6d.apps.googleusercontent.com


SMOKE_USER_PHONE='50111222' OPERATOR_CODE='Op2026' OWNER_PASSWORD='NabeulGold2026 \
python3 -m backend.scripts.smoke_api --base-url https://taxi-hbi9.onrender.com
OPERATOR_CODE='Op2026' \
OWNER_PASSWORD='NabeulGold2026' \
python3 -m backend.scripts.smoke_api --base-url https://taxi-hbi9.onrender.com