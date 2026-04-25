from __future__ import annotations

import json
import logging
import os
import time

from flask import Flask, g, request
from flask_cors import CORS

from .config import Config
from .extensions import db as orm_db, socketio
from . import models  # noqa: F401 — register models on metadata
from . import db as db  # compatibility: expose backend.db helper module at package level



def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)
    app.logger.setLevel(logging.INFO)
    orm_db.init_app(app)
    socketio.init_app(
        app,
        cors_allowed_origins="*",
        async_mode="threading",
    )
    CORS(
        app,
        resources={r"/api/*": {"origins": "*"}, r"/socket.io/*": {"origins": "*"}},
        supports_credentials=True,
    )

    from .sockets import register_socket_handlers

    register_socket_handlers(socketio)

    from .routes.admin import bp as admin_bp
    from .routes.api import bp as api_bp
    from .routes.chat import bp as chat_bp
    from .routes.rides import bp as rides_bp
    from .routes.users import bp as users_bp

    app.register_blueprint(api_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(rides_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(users_bp)

    @app.before_request
    def _request_timer_start() -> None:
        g._request_started_at = time.perf_counter()

    @app.after_request
    def _log_http_access(response):  # type: ignore[no-untyped-def]
        started = getattr(g, "_request_started_at", None)
        elapsed_ms = (time.perf_counter() - started) * 1000.0 if started else 0.0
        suffix = ""
        if response.status_code >= 400 and response.mimetype == "application/json":
            try:
                payload = json.loads(response.get_data(as_text=True) or "{}")
                err = payload.get("error")
                if err:
                    suffix = f" error={err}"
            except Exception:
                pass
        msg = (
            f"{request.method} {request.path} -> {response.status_code} "
            f"({elapsed_ms:.1f}ms){suffix}"
        )
        app.logger.info(msg)
        print(msg, flush=True)
        return response

    return app


def main() -> None:
    app = create_app()
    port = int(os.environ.get("PORT", "5000"))
    debug = os.environ.get("FLASK_DEBUG", "").lower() in ("1", "true", "yes")
    use_reloader = os.environ.get("FLASK_USE_RELOADER", "").lower() in ("1", "true", "yes")
    socketio.run(
        app,
        host="0.0.0.0",
        port=port,
        debug=debug,
        use_reloader=use_reloader,
        allow_unsafe_werkzeug=True,
    )


if __name__ == "__main__":
    main()
