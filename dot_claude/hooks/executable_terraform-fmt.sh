#!/bin/bash
# PostToolUse hook: Terraform ファイルを terraform fmt で修正する
# matcher: Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# ファイルパスが取得できない場合はスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# .tf ファイル以外はスキップ
case "$FILE_PATH" in
  *.tf) ;;
  *) exit 0 ;;
esac

# 編集対象ファイルが CWD 配下にある Terraform プロジェクトに属する場合のみ実行
PROJECT_DIR=$(pwd)
case "$FILE_PATH" in
  "$PROJECT_DIR"/*)
    if ls "$PROJECT_DIR"/*.tf >/dev/null 2>&1; then
      command -v terraform >/dev/null && terraform fmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac
