from __future__ import annotations

import os
from typing import Optional

from flask import Flask
from flask_cors import CORS

from .config import Config
from . import db as db_module


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(
        app,
        resources={r"/api/*": {"origins": "*"}},
        supports_credentials=True,
    )

    @app.teardown_appcontext
    def teardown_db(exception: Optional[BaseException]) -> None:
        db_module.close_db(exception)

    with app.app_context():
        db_module.init_db()

    from .routes.api import bp as api_bp

    app.register_blueprint(api_bp)

    return app


def main() -> None:
    app = create_app()
    port = int(os.environ.get("PORT", "5000"))
    debug = os.environ.get("FLASK_DEBUG", "").lower() in ("1", "true", "yes")
    app.run(host="0.0.0.0", port=port, debug=debug)


if __name__ == "__main__":
    main()
