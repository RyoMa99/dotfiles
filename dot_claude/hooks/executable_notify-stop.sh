#!/bin/bash
# Claude Code hook: タブ番号付きでイベント種別に応じた通知を表示
# stdin から JSON を受け取り、hook_event_name でメッセージを分岐

INPUT=$(timeout 2 cat 2>/dev/null || true)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Stop hook の無限ループ防止
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

tab_num=$(wezterm cli list --format json 2>/dev/null | python3 -c "
import json, sys, os
items = json.load(sys.stdin)
seen = []
for i in items:
    if i['tab_id'] not in seen:
        seen.append(i['tab_id'])
pane_id = int(os.environ.get('WEZTERM_PANE', -1))
for i in items:
    if i['pane_id'] == pane_id:
        print(seen.index(i['tab_id']) + 1)
        break
" 2>/dev/null)

case "${HOOK_EVENT}" in
  Stop)
    msg="作業が完了しました"
    ;;
  *)
    msg="入力待ちです"
    ;;
esac

osascript -e "display notification \"タブ${tab_num:-?}: ${msg}\" with title \"Claude Code\""
