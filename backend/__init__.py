from __future__ import annotations

import os

from flask import Flask
from flask_cors import CORS

from .config import Config
from .extensions import db as orm_db, socketio
from . import models  # noqa: F401 — register models on metadata
from . import db as db  # compatibility: expose backend.db helper module at package level



def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)
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

    return app


def main() -> None:
    app = create_app()
    port = int(os.environ.get("PORT", "5000"))
    debug = os.environ.get("FLASK_DEBUG", "").lower() in ("1", "true", "yes")
    socketio.run(
        app,
        host="0.0.0.0",
        port=port,
        debug=debug,
        allow_unsafe_werkzeug=True,
    )


if __name__ == "__main__":
    main()
