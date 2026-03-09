#!/bin/bash
set -euo pipefail

TARGET="$HOME/.config/claude-watch/config.json"

if [ -f "$TARGET" ]; then
  echo "[skip] $TARGET already exists"
  exit 0
fi

mkdir -p "$HOME/.config/claude-watch"

API_KEY=$(op read 'op://Personal/Claude Watch/API Key' 2>/dev/null || echo 'REPLACE_ME')
NTFY_TOPIC=$(op read 'op://Personal/Claude Watch/ntfy topic' 2>/dev/null || echo 'REPLACE_ME')

cat > "$TARGET" << EOF
{
  "pushcut_api_key": "$API_KEY",
  "pushcut_notification": "Claude Code Watch",
  "ntfy_topic": "$NTFY_TOPIC",
  "ntfy_server": "https://ntfy.sh",
  "timeout": 300
}
EOF

echo "[created] $TARGET"
if [ "$API_KEY" = "REPLACE_ME" ] || [ "$NTFY_TOPIC" = "REPLACE_ME" ]; then
  echo "[warn] 1Password CLI unavailable. Update REPLACE_ME values manually."
fi
