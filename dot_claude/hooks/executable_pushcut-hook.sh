#!/bin/bash
set -euo pipefail

# Claude Code PermissionRequest Hook: Pushcut + ntfy.sh ハイブリッド方式
# Pushcut: 通知配信（Apple Watch のネイティブアクションボタン対応）
# ntfy.sh: 応答チャネル（ポーリング方式で安定性を確保）

CONFIG_FILE="$HOME/.config/claude-watch/config.json"

# 設定ファイルの読み込み（存在しなければ CLI フォールバック）
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

PUSHCUT_API_KEY=$(jq -r '.pushcut_api_key' "$CONFIG_FILE")
PUSHCUT_NOTIFICATION=$(jq -r '.pushcut_notification' "$CONFIG_FILE")
NTFY_TOPIC=$(jq -r '.ntfy_topic' "$CONFIG_FILE")
NTFY_SERVER=$(jq -r '.ntfy_server // "https://ntfy.sh"' "$CONFIG_FILE")
TIMEOUT=$(jq -r '.timeout // 120' "$CONFIG_FILE")

# 応答用トピック名（リクエスト用トピックに -response を付けたもの）
RESPONSE_TOPIC="${NTFY_TOPIC}-response"

# Claude Code から stdin で受け取る PermissionRequest JSON を読み取る
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "Unknown"')

# ツール種別に応じて通知に表示する情報を組み立てる（最大 200 文字）
case "$TOOL_NAME" in
  Bash)
    TOOL_INFO=$(echo "$INPUT" | jq -r '.tool_input.command // (.tool_input | tostring)' | head -c 200)
    ;;
  Read|Write|Edit)
    TOOL_INFO=$(echo "$INPUT" | jq -r '.tool_input.file_path // (.tool_input | tostring)' | head -c 200)
    ;;
  *)
    TOOL_INFO=$(echo "$INPUT" | jq -r '.tool_input | tostring' | head -c 200)
    ;;
esac

# 通知テンプレート名を URL エンコード（Pushcut API の URL パスに含めるため）
ENCODED_NOTIFICATION=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${PUSHCUT_NOTIFICATION}'))")

# ntfy.sh の since パラメータ用にタイムスタンプを記録（通知送信前に取る）
START_TS=$(date +%s)

# Pushcut API で通知を送信（タイトルとテキストのみ動的、アクションはアプリ側で固定）
PUSHCUT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "https://api.pushcut.io/v1/notifications/${ENCODED_NOTIFICATION}" \
  -H "API-Key: ${PUSHCUT_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg title "Claude Code: ${TOOL_NAME}" \
    --arg text "$TOOL_INFO" \
    '{
      title: $title,
      text: $text
    }')" 2>&1)

# HTTP ステータスコードを確認（200/201/204 以外はエラー → CLI フォールバック）
HTTP_CODE=$(echo "$PUSHCUT_RESPONSE" | tail -1)

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ] && [ "$HTTP_CODE" != "204" ]; then
  PUSHCUT_BODY=$(echo "$PUSHCUT_RESPONSE" | sed '$d')
  echo "Pushcut API エラー (HTTP $HTTP_CODE): $PUSHCUT_BODY" >&2
  exit 0
fi

# ntfy.sh を 2 秒ごとにポーリングしてユーザーの応答を待つ
# poll=1: キャッシュ済みメッセージを返して即接続を閉じる
# since: 通知送信後のメッセージだけを取得する
RESPONSE=""
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep 2
  ELAPSED=$(( $(date +%s) - START_TS ))

  # 通知送信後のメッセージを取得し、allow/deny に一致するものだけ採用
  RESULT=$(curl -s "${NTFY_SERVER}/${RESPONSE_TOPIC}/json?poll=1&since=${START_TS}" 2>/dev/null | \
    jq -r 'select(.event == "message") | .message // empty' 2>/dev/null | \
    grep -E '^(allow|deny)$' | tail -1) || true

  if [ -n "$RESULT" ]; then
    RESPONSE="$RESULT"
    break
  fi
done

# Claude Code に結果を JSON 形式で返す
case "$RESPONSE" in
  allow)
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: "allow" }
      }
    }'
    ;;
  deny)
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: {
          behavior: "deny",
          message: "Apple Watch / Pushcut 経由で拒否されました"
        }
      }
    }'
    ;;
  *)
    # タイムアウトまたは不明な応答 → CLI の通常プロンプトにフォールバック
    exit 0
    ;;
esac
