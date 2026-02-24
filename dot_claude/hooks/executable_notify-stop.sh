#!/bin/bash
# Claude Code hook: エージェント名付きでイベント種別に応じた通知を表示
# stdin から JSON を受け取り、hook_event_name でメッセージを分岐
# teammate イベントは teammate_name を使用し、それ以外は tmux ウィンドウ名を使用

INPUT=$(timeout 2 cat 2>/dev/null || true)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Stop hook の無限ループ防止
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# ラベルを決定: teammate イベントは teammate_name、それ以外は tmux ウィンドウ名
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty' 2>/dev/null)
if [ -n "$TEAMMATE" ]; then
  LABEL="$TEAMMATE"
elif [ -n "$TMUX" ]; then
  LABEL=$(tmux display-message -p -t "$TMUX_PANE" '#{window_name}')
else
  LABEL="?"
fi

case "${HOOK_EVENT}" in
  Stop)
    msg="作業が完了しました"
    ;;
  TeammateIdle)
    msg="入力待ちです"
    ;;
  TaskCompleted)
    TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty' 2>/dev/null)
    msg="タスク完了: ${TASK_SUBJECT:-?}"
    ;;
  *)
    msg="入力待ちです"
    ;;
esac

osascript - "${LABEL}" "${msg}" <<'APPLESCRIPT'
on run argv
  display notification "[" & item 1 of argv & "] " & item 2 of argv with title "Claude Code"
end run
APPLESCRIPT

# tmux ステータスバーに入力待ち表示（teammate イベントではスキップ）
if [ -n "$TMUX" ] && [ -z "$TEAMMATE" ]; then
  tmux set-option -w -t "$TMUX_PANE" window-status-format " #I:#W 🤖 "
  tmux set-option -w -t "$TMUX_PANE" window-status-style 'fg=black,bg=yellow'
fi
