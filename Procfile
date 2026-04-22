# Apply DB migrations on each deploy/start (uses Render DATABASE_URL). No Render Shell required.
# If you scale to multiple web instances, run migrations from CI or a one-off job to avoid parallel upgrades.
web: python -m alembic upgrade head && env SOCKETIO_ASYNC_MODE=eventlet python -m gunicorn -w 1 -k eventlet -b 0.0.0.0:$PORT wsgi:app
