#!/bin/bash
# Claude Code hook: tmux ステータスバーの入力待ち表示をクリア
[ -n "$TMUX" ] || exit 0
tmux set-option -wu window-status-format 2>/dev/null
tmux set-option -wu window-status-style 2>/dev/null
