# Project Rules — Taxi App

## Backend (Flask)

* Use Flask with Blueprints
* Separate routes from business logic (services layer required)
* Add WebSocket support using Flask-SocketIO
* All REST endpoints must return JSON
* Use JWT for authentication
* Do not mix business logic inside routes
* Real-time logic must be handled in sockets/ (not routes)

## Real-Time (WebSocket)

* Use SocketIO events for:

  * send_message
  * receive_message
  * ride status updates
* Do not block WebSocket events with heavy processing
* Use async or background jobs for translation if needed

## Translation System

* Store ONLY original messages in database
* Translate messages on delivery (not on save)
* Cache translations in translations table
* Avoid duplicate translation API calls
* Translation logic must be inside services/translation_service.py

## Frontend (Flutter)

* Use clean architecture (UI / services / models)
* No business logic inside widgets
* API & WebSocket calls must go through service layer
* Handle real-time updates via WebSocket
* Keep UI simple and readable

## Database (PostgreSQL)

* Use PostgreSQL (NOT SQLite)
* Use ORM (SQLAlchemy recommended)
* Tables:

  * users, drivers, rides
  * conversations, messages, translations
* Use foreign keys and proper indexing
* Avoid duplicated data
* Optimize queries for chat history and real-time usage

## Domain Logic

* Users can request rides
* Drivers accept/reject rides
* One active ride per user
* Ride statuses: pending, accepted, ongoing, completed
* Each ride can have an associated conversation (chat)

## Performance & Scaling

* Avoid blocking API or WebSocket calls
* Use caching for translations
* Consider background workers (Celery + Redis) if needed
* Design for scalability from MVP stage

## General Rules

* Do not rewrite entire files unless asked
* Modify only necessary parts
* Keep code simple (no over-engineering)
* Add comments for important logic
* All newly added texts must be available in these languages:
  [Arabic, French, English, German, Spanish, Chinese, Russian, Italian]
