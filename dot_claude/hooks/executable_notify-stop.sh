#!/bin/bash
# Claude Code hook: tmux ウィンドウ名付きでイベント種別に応じた通知を表示
# stdin から JSON を受け取り、hook_event_name でメッセージを分岐

INPUT=$(timeout 2 cat 2>/dev/null || true)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Stop hook の無限ループ防止
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# tmux ウィンドウ名を取得
if [ -n "$TMUX" ]; then
  WIN=$(tmux display-message -p '#{window_name}')
fi

case "${HOOK_EVENT}" in
  Stop)
    msg="作業が完了しました"
    ;;
  *)
    msg="入力待ちです"
    ;;
esac

osascript - "${WIN:-?}" "${msg}" <<'APPLESCRIPT'
on run argv
  display notification "[" & item 1 of argv & "] " & item 2 of argv with title "Claude Code"
end run
APPLESCRIPT

# tmux ステータスバーに入力待ち表示
if [ -n "$TMUX" ]; then
  tmux set-option -w window-status-format " #I:#W 🤖 "
  tmux set-option -w window-status-style 'fg=black,bg=yellow'
fi
