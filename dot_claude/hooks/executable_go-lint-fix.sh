#!/bin/bash
# PostToolUse hook: Go ファイルを gofmt + golangci-lint --fix で修正する
# matcher: Edit|Write

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# ファイルパスが取得できない場合はスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# .go ファイル以外はスキップ
case "$FILE_PATH" in
  *.go) ;;
  *) exit 0 ;;
esac

# 編集対象ファイルが CWD 配下にある Go プロジェクトに属する場合のみ実行
PROJECT_DIR=$(pwd)
case "$FILE_PATH" in
  "$PROJECT_DIR"/*)
    # go.mod が存在する Go プロジェクトであることを確認
    if [ -f go.mod ]; then
      # gofmt: 高速なフォーマット修正
      command -v gofmt >/dev/null && gofmt -w "$FILE_PATH" 2>/dev/null || true

      # golangci-lint: 自動修正可能な lint 問題を修正
      command -v golangci-lint >/dev/null && golangci-lint run --fix "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac
