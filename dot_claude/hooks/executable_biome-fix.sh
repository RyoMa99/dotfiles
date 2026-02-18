#!/bin/bash
# PostToolUse hook: Biome でフォーマット修正する
# matcher: Edit|Write
#
# JSON は editorconfig-checker に管轄を委譲するためスキップ

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# ファイルパスが取得できない場合はスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# JSON は editorconfig-checker 側で管理
case "$FILE_PATH" in
  *.json|*.jsonc) exit 0 ;;
esac

# 編集対象ファイルが CWD 配下にある Biome プロジェクトに属する場合のみ実行
PROJECT_DIR=$(pwd)
case "$FILE_PATH" in
  "$PROJECT_DIR"/*)
    command -v pnpm >/dev/null && [ -f package.json ] && grep -q '"fix"' package.json && pnpm fix 2>/dev/null || true
    ;;
esac
