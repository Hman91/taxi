---
name: Chat admin operator rides
overview: "Execution follows .cursor/rules.md and .cursor/context.md. Scalable real-time chat (Flask-SocketIO), translate-on-delivery with DB cache, PostgreSQL + SQLAlchemy from SQLite, operator/owner admin (owner-only money metrics), enable/disable + 8-locale Flutter copy."
todos:
  - id: step-1-pg-orm
    content: "Step 1 — PostgreSQL + SQLAlchemy + Alembic; DATABASE_URL; replace SQLite db session in HTTP layer"
    status: completed
  - id: step-2-migrate-data
    content: "Step 2 — One-off SQLite → PostgreSQL migration script; verify core tables"
    status: completed
  - id: step-3-chat-schema
    content: "Step 3 — conversations, messages, translations; preferred_language, is_enabled, driver geo, b2b_tenants"
    status: completed
  - id: step-4-rest-chat
    content: "Step 4 — REST chat history + PATCH preferred_language (blueprints + services only)"
    status: completed
  - id: step-5-socketio
    content: "Step 5 — Flask-SocketIO; JWT connect; sockets/ send_message + ride updates; thin handlers"
    status: completed
  - id: step-6-translate
    content: "Step 6 — services/translation_service.py; translate-on-delivery; translations table cache"
    status: completed
  - id: step-7-admin
    content: "Step 7 — Admin blueprint; operator vs owner; owner-only metrics; toggles + API errors for disabled accounts"
    status: completed
  - id: step-8-flutter
    content: "Step 8 — Flutter socket + ChatMessage; chat UI; operator/owner; 8-language ARB for new strings"
    status: completed
  - id: step-9-docs
    content: "Step 9 — README/runbook env vars; smoke tests"
    status: completed
isProject: false
---

# Real-time chat, translation cache, PostgreSQL, and admin/operator oversight

## Plan governance

- **Source of truth:** All work must follow [`.cursor/rules.md`](rules.md) (Flask blueprints, services layer, JWT, SocketIO in `sockets/`, PostgreSQL + SQLAlchemy, translation rules, Flutter layering, **8 locales** for any new user-facing copy) and [`.cursor/context.md`](context.md) (stack, features, folder split).
- **Progress tracking:** When a step is done, mark it **`[x]`** in **Execution checklist** below. Optionally mirror status in the YAML `todos` at the top of this file (`pending` → `completed`).

---

## Execution checklist (step by step)

Complete in order unless noted.

- [x] **Step 1 — PostgreSQL + ORM baseline:** SQLAlchemy (Flask-SQLAlchemy), Alembic, `DATABASE_URL`; models mirroring current app tables; route handlers use DB session from extensions — retire ad-hoc SQLite where rules require PostgreSQL.
- [x] **Step 2 — Data migration:** Script: SQLite (`backend/data` or current path) → PostgreSQL; order: users → drivers → rides → trips → ratings; verify counts and spot-check IDs.
- [x] **Step 3 — Chat schema:** `conversations` (ride-scoped), `messages` (original only + `original_language`), `translations` (cache, unique per message + target language); `users.preferred_language`, `users.is_enabled`; driver `last_lat` / `last_lng` / `last_seen_at`; `b2b_tenants` with `is_enabled`; indexes per roadmap below.
- [x] **Step 4 — REST chat + profile:** Blueprint `routes/`, logic in `services/`; JWT auth; JSON-only responses; conversation open when ride is accepted (or as specified); `GET` paginated message history; `PATCH /me` (or equivalent) for `preferred_language`.
- [x] **Step 5 — Flask-SocketIO:** `create_app` wires SocketIO; JWT on connect; **`send_message`** / receive path and **ride status** events implemented under `sockets/` (no business logic stuffed in event handlers — delegate to services).
- [x] **Step 6 — Translation:** `services/translation_service.py` only; on delivery, read/write `translations` table; no duplicate vendor calls; timeout + fallback to original; optional Celery + Redis later per rules.
- [x] **Step 7 — Admin REST:** `routes/admin.py` (or equivalent blueprint); `require_roles` for operator vs **owner-only** money metrics; list rides, driver locations, read-only conversations; enable/disable users and B2B; API signals for disabled accounts.
- [x] **Step 8 — Flutter:** `socket_io_client` (or match server); **ChatSocketService** + repository; **`ChatMessage`** (`displayText`); chat screens; operator/owner dashboards; **every new string** in all eight ARBs: Arabic, French, English, German, Spanish, Chinese, Russian, Italian (`flutter/taxi_pro/lib/l10n/`).
- [x] **Step 9 — Docs & verification:** README: `DATABASE_URL`, Socket URL, workers; smoke test auth, rides, chat, admin, disabled-user flow.

---

## Goals (product + engineering)

- **Real-time 1-to-1 chat** (passenger ↔ driver) tied to a **ride** (conversation opens when ride is `accepted` or later).
- **Automatic translation** per recipient **preferred_language**; **no duplicate vendor API calls** (DB cache).
- **Scalable path**: PostgreSQL, optional async translation (Celery + Redis), SocketIO for push.
- **Operator + owner (admin)** see rides, driver locations, and conversations; **only owner** sees money flow / earnings.
- **Operator + owner** can enable/disable **app drivers** and **B2B tenants**; disabled users see a **contact admin** message (localized in Flutter).

**Constraints:** Keep **Flask** and **Flutter**. **Admin = existing `owner` role** in code (`/api/metrics/owner`).

---

## Text-based architecture

```
[Flutter Passenger] ----REST----> [Flask HTTP : routes/*]
[Flutter Driver]    ----REST----> [Flask HTTP]
[Flutter Op/Owner]  ----REST----> [Flask HTTP : routes/admin.py]

[Flutter Passenger] --WebSocket--> [Flask-SocketIO : sockets/chat.py]
[Flutter Driver]    --WebSocket--> [Flask-SocketIO]
                        |
                        v
              [ChatService] --> INSERT messages (original only)
                        |
                        v
              [TranslationService]
                 - lookup translations (message_id, target_lang)
                 - on miss: call Google/DeepL/deep-translator
                 - INSERT translations row
                        |
                        v
              emit `message` (or `message_translated`) to recipient room(s)

[PostgreSQL]
  users | drivers | rides | b2b_tenants
  conversations (1:1 ride-scoped or participant-pair)
  messages (original_text, original_language, sender_id, conversation_id)
  translations (message_id, target_language, translated_text)  -- cache
  legacy: trips, ratings (migrated)
```

**Delivery rule:** Store **only** the original in `messages`. For **each** active recipient socket (or on emit path), resolve `target_lang = user.preferred_language`; if `target_lang != original_language`, **read cache** `(message_id, target_lang)`; if absent, **translate**, **insert** `translations`, then send payload containing both `original` and `translated` (client chooses `displayText`).

**Optional async path:** After INSERT message, enqueue **Celery** task `translate_for_recipients(message_id)` so HTTP/Socket handler returns fast; task writes `translations` and emits via SocketIO. **MVP without Celery:** translate synchronously in Socket handler with a **short timeout** and fallback to original text.

---

## Target folder structure (backend)

```
backend/
  __init__.py              # create_app(): Flask + SocketIO + CORS + teardown
  __main__.py
  config.py                # DATABASE_URL, REDIS_URL, TRANSLATION_PROVIDER keys
  extensions.py            # db = SQLAlchemy(), socketio = SocketIO(), optional celery
  models/
    __init__.py
    user.py
    driver.py
    ride.py
    conversation.py
    message.py
    translation.py
    b2b_tenant.py
    trip.py                # legacy
  services/
    chat_service.py        # create conversation for ride, authorize participant
    translation_service.py # translate + cache read/write
    rides_service.py       # existing domain (moved from services/rides.py)
  routes/
    api.py                 # HTTP REST (auth, fares, trips legacy, metrics owner-only)
    rides.py               # HTTP ride CRUD if kept separate
    admin.py               # operator + owner oversight REST
    users.py               # PATCH /me preferred_language
  sockets/
    __init__.py
    chat.py                # connect (JWT), join_conversation, send_message
  migrations/              # Alembic versions
```

**Sockets vs REST:** REST retains **history pagination** (`GET /api/conversations/<id>/messages?before_id=&limit=`) for cold start and Flutter fallback; SocketIO handles **live** `send_message` + server push.

---

## Database schema (PostgreSQL, ready to implement)

**users**

| column | type | notes |
|--------|------|--------|
| id | BIGSERIAL PK | |
| email | TEXT UNIQUE | |
| password_hash | TEXT | |
| role | TEXT CHECK (user, driver) | app roles |
| preferred_language | VARCHAR(10) | e.g. `en`, `ar`, `zh-CN` |
| is_enabled | BOOLEAN DEFAULT true | staff can disable |
| created_at | TIMESTAMPTZ | |

**drivers**

| column | type | notes |
|--------|------|--------|
| id | BIGSERIAL PK | |
| user_id | BIGINT FK users UNIQUE | |
| display_name | TEXT | |
| vehicle_info | TEXT | |
| is_available | BOOLEAN | on-shift |
| last_lat, last_lng | DOUBLE PRECISION NULL | |
| last_seen_at | TIMESTAMPTZ NULL | |

**rides** (existing fields + timestamps)

- Keep status machine: `pending` → `accepted` → `ongoing` → `completed` / `cancelled`.

**conversations**

| column | type | notes |
|--------|------|--------|
| id | BIGSERIAL PK | |
| ride_id | BIGINT FK rides UNIQUE | one conversation per ride (1:1 pair implied) |
| created_at | TIMESTAMPTZ | |

**messages**

| column | type | notes |
|--------|------|--------|
| id | BIGSERIAL PK | |
| conversation_id | BIGINT FK | |
| sender_user_id | BIGINT FK users | |
| original_text | TEXT | **only** stored content |
| original_language | VARCHAR(10) | ISO; set from sender profile or detect once |
| created_at | TIMESTAMPTZ | |
| INDEX (conversation_id, id DESC) | | history |

**translations** (cache)

| column | type | notes |
|--------|------|--------|
| id | BIGSERIAL PK | |
| message_id | BIGINT FK messages ON DELETE CASCADE | |
| target_language | VARCHAR(10) | |
| translated_text | TEXT | |
| UNIQUE (message_id, target_language) | | dedupe |

**b2b_tenants**

| column | type | notes |
|--------|------|--------|
| id | BIGSERIAL PK | |
| code | TEXT UNIQUE | or store hash |
| label | TEXT | |
| is_enabled | BOOLEAN | |

**Legacy:** `trips`, `ratings` — migrate as-is for owner metrics.

---

## Real-time flow (SocketIO) — sequence

1. Client connects with **JWT** (query param or `auth` payload). Server validates, loads `user_id`, joins room `user:{id}` and, after join, `conversation:{cid}`.
2. Client emits **`send_message`** `{conversation_id, text}`.
3. Server: authorize user is participant of `conversation_id` (via `ride` linkage); ride status in `accepted|ongoing` (configurable).
4. **INSERT** `messages` (original_text, original_language from `users.preferred_language` or quick detect).
5. **Emit** to conversation room a **`message`** event with **minimal** payload `{message_id, conversation_id, sender_id, original_text, original_language, created_at}`.
6. **For each other participant** (or for each subscribed socket in conversation):
   - `target = other_user.preferred_language`
   - if `target == original_language` → payload `displayText = original_text`
   - else **SELECT** from `translations` WHERE `message_id` AND `target_language`
   - if miss → **TranslationService.translate** → **INSERT** `translations`
   - emit **`message_for_recipient`** (or same event with personalized payload) `{..., translated_text, displayText}` to that user’s room.

**Operator/owner read-only:** separate HTTP `GET /api/admin/conversations/...` that returns messages + optional translated view for staff `preferred_language` without going through recipient rooms.

---

## Translation service (reusable module)

- **Interface:** `get_or_translate(message_id, text, source_lang, target_lang) -> str`
- **Provider:** env `TRANSLATION_PROVIDER=google|deepl|deep_translator` with API keys; **MVP:** `deep-translator` (already in legacy stack) behind a thin adapter.
- **Cache:** **primary** = `translations` table; optional in-memory LRU for hot `(text, src, tgt)` within a single process.
- **Failure:** return `original_text` and log; never block forever (timeout ~2–5s MVP).

---

## Performance and scaling

- **Indexes:** `(conversation_id, id DESC)` on `messages`; unique `(message_id, target_language)` on `translations`.
- **Non-blocking:** prefer **Celery + Redis** for `translate_and_emit` after message insert; MVP can stay sync with timeouts.
- **Connection scaling:** run **gunicorn + gevent/eventlet** workers compatible with Flask-SocketIO, or use **message queue** later; document single-node MVP limits.

---

## SQLite → PostgreSQL migration (step-by-step)

1. **Add dependencies:** `SQLAlchemy`, `Flask-SQLAlchemy`, `Alembic`, `psycopg2-binary` (or `asyncpg` if you move async later).
2. **Introduce `DATABASE_URL`** (e.g. `postgresql://user:pass@localhost:5432/taxi`).
3. **Define models** mirroring current SQLite tables; run `alembic revision --autogenerate` for initial PG schema.
4. **One-off data script** (management command or `scripts/migrate_sqlite_to_pg.py`):
   - Read old `backend/data/taxi.db` with `sqlite3` or SQLAlchemy SQLite engine.
   - Insert in **dependency order:** `users` → `drivers` → `rides` → `trips` → `ratings` → (no messages yet if new feature).
   - Map old integer IDs to new BIGINTs consistently **or** use same IDs if bulk insert allows.
5. **Cutover:** point `.env` `DATABASE_URL` to Postgres; keep SQLite file read-only backup.
6. **Remove** raw `sqlite3` usage in app code (`backend/db.py` replaced by SQLAlchemy session).

---

## Admin / operator REST (unchanged intent, PG-backed)

| Capability | Owner | Operator |
|------------|-------|----------|
| List app rides + status | yes | yes |
| Driver locations | yes | yes |
| Read conversation messages | yes | yes |
| Enable/disable user (driver/passenger) | yes | yes |
| Enable/disable B2B tenant | yes | yes |
| Money / commission / metrics | **yes** | **no** |

Implement under `backend/routes/admin.py` with `require_roles("owner","operator")` vs `require_roles("owner")` for financial endpoints.

---

## Flutter changes

**Dependencies:** `web_socket_channel` or `socket_io_client` (match server Socket.IO version).

**Model (e.g. `lib/models/chat_message.dart`):**

```dart
class ChatMessage {
  final String id;
  final String originalText;
  final String? translatedText;
  String get displayText => translatedText ?? originalText;
}
```

**Layers:**

- **`ChatSocketService`**: connect, reconnect, subscribe to conversation, expose `Stream<ChatMessage>`.
- **`ChatRepository` / `TaxiAppService`**: REST `GET` history merge with socket stream; **fallback** if socket down → polling REST only.
- **UI:** Passenger/Driver chat screen uses **displayText**; optional “show original” toggle.

**Operator/owner:** tabs for rides list, map/list of driver locations, conversation viewer (REST or read-only socket subscription if you add staff rooms later).

**Disabled account:** handle `account_disabled` from API + ARB string `contactAdminDisabled` (8 languages).

---

## Implementation roadmap (phased)

Map to **Execution checklist**: P0 ≈ Steps 1–2, P1 ≈ Steps 3–4, P2–P3 ≈ Steps 5–6, P4 ≈ Step 7, P5 ≈ Step 8, P6 ≈ Step 9.

| Phase | Scope |
|-------|--------|
| **P0** | Add PostgreSQL + SQLAlchemy + Alembic; migrate schema; one-off SQLite→PG script; replace `db.py` session usage in existing HTTP routes. |
| **P1** | Models: `conversations`, `messages`, `translations`; create conversation when ride → `accepted`; REST history endpoint. |
| **P2** | Integrate Flask-SocketIO in `create_app`; JWT connect auth; `send_message` / server push with translate-on-delivery + DB cache. |
| **P3** | TranslationService adapters + env config; optional Celery + Redis for async translate+emit. |
| **P4** | Admin REST (rides, locations, read chat, toggles); owner-only metrics enforced. |
| **P5** | Flutter WebSocket client + `ChatMessage` model + chat UI + operator/owner dashboards + l10n disable message. |
| **P6** | Docs (`README.md`): `DATABASE_URL`, Socket URL, worker process, scaling notes. |

---

## Key code snippets (illustrative)

**Socket handler (conceptual):**

```python
@socketio.on("send_message")
def handle_send(data):
    user_id = request.user_id  # set in connect after JWT
    msg = chat_service.save_message(conversation_id=data["conversation_id"], sender_id=user_id, text=data["text"])
    for recipient_id in chat_service.other_participants(msg.conversation_id, user_id):
        tgt_lang = user_service.preferred_language(recipient_id)
        text_out = translation_service.get_or_translate(msg.id, msg.original_text, msg.original_language, tgt_lang)
        emit("message", {...}, room=f"user:{recipient_id}")
```

**Unique cache constraint (SQL):**

```sql
CREATE UNIQUE INDEX ux_translations_msg_lang ON translations (message_id, target_language);
```

---

## Deliverables checklist

Track **Execution checklist** as the primary progress list; use this as a closing gate before release.

- [ ] Architecture diagram (this doc + optional Mermaid in README).
- [ ] Folder structure (backend + Flutter) as above — matches **rules.md** (routes / services / models / sockets).
- [ ] PostgreSQL schema + Alembic migrations.
- [ ] Phased roadmap P0–P6 aligned with execution steps 1–9.
- [ ] Snippets for Socket + translation cache (`services/translation_service.py`).
- [ ] All new UI copy present in **8 languages** per **rules.md**.

---

## Out of scope (later)

- End-to-end encryption of message content.
- Multi-device read receipts / typing indicators (easy add-ons on same Socket layer).
- Full Google Maps in Flutter (locations can still be lat/lng list for MVP).
