#!/bin/bash
set -euo pipefail

TARGET="$HOME/.claude/settings.local.json"

if [ -f "$TARGET" ]; then
  echo "[skip] $TARGET already exists"
  exit 0
fi

mkdir -p "$HOME/.claude"

ENDPOINT=$(op read 'op://Personal/CC Dashboard/endpoint' 2>/dev/null || echo 'REPLACE_ME')
TOKEN=$(op read 'op://Personal/CC Dashboard/token' 2>/dev/null || echo 'REPLACE_ME')
USERNAME=$(whoami)

cat > "$TARGET" << EOF
{
  "env": {
    "OTEL_EXPORTER_OTLP_ENDPOINT": "$ENDPOINT",
    "OTEL_EXPORTER_OTLP_HEADERS": "Authorization=Bearer $TOKEN",
    "OTEL_RESOURCE_ATTRIBUTES": "repository=$USERNAME-global"
  }
}
EOF

echo "[created] $TARGET"
if [ "$ENDPOINT" = "REPLACE_ME" ] || [ "$TOKEN" = "REPLACE_ME" ]; then
  echo "[warn] 1Password CLI unavailable. Update REPLACE_ME values manually."
fi
