#!/bin/bash
# PostToolUse hook: Biome でフォーマット修正する
# matcher: Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# ファイルパスが取得できない場合はスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 編集対象ファイルが CWD 配下にある Biome プロジェクトに属する場合のみ実行
PROJECT_DIR=$(pwd)
case "$FILE_PATH" in
  "$PROJECT_DIR"/*)
    command -v pnpm >/dev/null && [ -f package.json ] && grep -q '"fix"' package.json && pnpm fix 2>/dev/null || true
    ;;
esac
