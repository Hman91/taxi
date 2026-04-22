"""
WSGI entry for Gunicorn on Render and other Unix hosts.

    gunicorn -w 1 -k eventlet -b 0.0.0.0:5000 wsgi:app

Set SOCKETIO_ASYNC_MODE=eventlet when using the eventlet worker (see Procfile).

Note: Gunicorn does not run on Windows (missing fcntl). On Windows use:
    python -m backend
Or use WSL2 / deploy to Render.
"""
from __future__ import annotations

from backend import create_app

app = create_app()
