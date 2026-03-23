#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Colors
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'

# Context bar with color threshold
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# Helper: build a mini bar (5 chars wide)
mini_bar() {
  local pct=$1
  local filled=$((pct / 20)); local empty=$((5 - filled))
  local bar=""
  [ "$filled" -gt 0 ] && printf -v f "%${filled}s" && bar="${f// /█}"
  [ "$empty" -gt 0 ] && printf -v e "%${empty}s" && bar="${bar}${e// /░}"
  echo "$bar"
}

# Rate limits with bars
LIMITS=""
if [ -n "$FIVE_H" ]; then
  FIVE_H_INT=$(printf '%.0f' "$FIVE_H")
  if [ "$FIVE_H_INT" -ge 80 ]; then RL_COLOR="$RED"
  elif [ "$FIVE_H_INT" -ge 50 ]; then RL_COLOR="$YELLOW"
  else RL_COLOR="$GREEN"; fi
  LIMITS="${RL_COLOR}5h $(mini_bar "$FIVE_H_INT") ${FIVE_H_INT}%${RESET}"
fi
if [ -n "$WEEK" ]; then
  WEEK_INT=$(printf '%.0f' "$WEEK")
  if [ "$WEEK_INT" -ge 80 ]; then RL_COLOR="$RED"
  elif [ "$WEEK_INT" -ge 50 ]; then RL_COLOR="$YELLOW"
  else RL_COLOR="$GREEN"; fi
  LIMITS="${LIMITS:+$LIMITS }${RL_COLOR}7d $(mini_bar "$WEEK_INT") ${WEEK_INT}%${RESET}"
fi

# Duration
MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))
if [ "$MINS" -ge 60 ]; then
  HOURS=$((MINS / 60)); MINS=$((MINS % 60))
  DURATION="${HOURS}h${MINS}m"
else
  DURATION="${MINS}m${SECS}s"
fi

# Output
LINE="${CYAN}${MODEL}${RESET} ${BAR_COLOR}${BAR}${RESET} ${PCT}%"
[ -n "$LIMITS" ] && LINE="${LINE} ${DIM}|${RESET} ${LIMITS}"
LINE="${LINE} ${DIM}|${RESET} ${DIM}${DURATION}${RESET}"
echo -e "$LINE"
