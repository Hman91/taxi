#!/usr/bin/env bash
# Fixes: `source ~/.bashrc` prints `404:: command not found`
# Cause: /etc/bash_completion.d/docker-compose contained literal "404: Not Found" (corrupt file).
# Run once: sudo bash scripts/fix_bash_404.sh

set -euo pipefail
TARGET=/etc/bash_completion.d/docker-compose

if [[ ! -f "$TARGET" ]]; then
  echo "Missing $TARGET; nothing to fix."
  exit 0
fi

if grep -q '^404: Not Found' "$TARGET" 2>/dev/null; then
  cat >"$TARGET" <<'EOF'
# Placeholder: file was corrupted (HTTP 404 text). Reinstall docker-compose completion if needed.
# See: Docker docs for "bash completion" / docker compose.
:
EOF
  echo "Replaced corrupted $TARGET with a safe placeholder."
else
  echo "First line of $TARGET is not '404: Not Found'; not modifying. Inspect manually."
  exit 1
fi
