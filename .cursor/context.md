Project: Taxi app (like Bolt)

Stack:

* Flask backend (REST + WebSocket with SocketIO)
* Flutter frontend
* PostgreSQL database (migrated from SQLite)

Core Features:

* Auth (JWT)
* Roles (user/driver)
* Ride system
* Google Maps integration

New Features:

* Real-time chat between users and drivers (1-to-1)
* Automatic message translation based on user preferred language
* WebSocket communication for live updates (chat + ride status)

Architecture:

* Backend split into:

  * routes/ (API endpoints)
  * services/ (business logic)
  * models/ (database models)
  * sockets/ (real-time events)
* Translation system:

  * Store original message only
  * Translate on delivery
  * Cache translations in database

Database:

* PostgreSQL (production-ready)
* Core tables:

  * users (id, role, preferred_language, ...)
  * drivers
  * rides
  * conversations
  * messages (original_text, original_language, ...)
  * translations (cached translated messages)

Goals:

* Scalable real-time communication
* Clean separation of concerns
* Efficient translation (no duplicate API calls)
