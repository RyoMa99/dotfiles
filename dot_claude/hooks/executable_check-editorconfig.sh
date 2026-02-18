#!/bin/bash
# PostToolUse hook: editorconfig-checker でファイルを検証する
# matcher: Edit|Write
#
# stdin: Claude Code が渡す JSON（tool_input.file_path を含む）
# exit 0: OK（続行）
# exit 2: ブロック（stderr のメッセージが Claude に表示される）

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# ファイルパスが取得できない場合はスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# editorconfig-checker が未インストールならスキップ
if ! command -v editorconfig-checker >/dev/null 2>&1; then
  exit 0
fi

# Biome 管轄の拡張子はスキップ（Biome の PostToolUse hook が検証する）
case "$FILE_PATH" in
  *.js|*.jsx|*.ts|*.tsx|*.css) exit 0 ;;
esac

# ~/.claude/ 配下のファイルは除外設定を適用
EC_OPTS=()
if [[ "$FILE_PATH" == */.claude/* ]]; then
  EC_CONFIG="$HOME/.claude/.editorconfig-checker.json"
  if [ -f "$EC_CONFIG" ]; then
    EC_OPTS=(-config "$EC_CONFIG")
  fi
fi

# editorconfig-checker を実行
if ! editorconfig-checker "${EC_OPTS[@]}" "$FILE_PATH" 2>&1; then
  echo "EditorConfig violations found in $FILE_PATH" >&2
  exit 2
fi

exit 0
