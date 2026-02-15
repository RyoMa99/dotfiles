#!/bin/bash
# Claude Code Stop hook: タブ番号付きで入力待ち通知を表示

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

osascript -e "display notification \"タブ${tab_num:-?}: 入力待ちです\" with title \"Claude Code\""
