"""
Root entry point (same layout as `main` branch).

- `python app.py` — runs the Streamlit prototype from `legacy/streamlit_app.py`.
- REST API: `python -m backend` (see README).

**Render / Gunicorn:** the Flask + Socket.IO app is **not** here. Use **`wsgi:app`** (see `wsgi.py`), never `gunicorn app:app`.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parent
    legacy_app = root / "legacy" / "streamlit_app.py"
    if not legacy_app.is_file():
        print("Missing legacy/streamlit_app.py", file=sys.stderr)
        sys.exit(1)
    os.chdir(root)
    cmd = [sys.executable, "-m", "streamlit", "run", str(legacy_app), *sys.argv[1:]]
    raise SystemExit(subprocess.call(cmd))


if __name__ == "__main__":
    main()
