#!/bin/bash

# Skill Evaluation Hook
# UserPromptSubmit時にプロンプトを分析し、関連スキルを提案する
# SerenaとgrepaiをIDを分けて適切なツールを推奨

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract user prompt from hook input
USER_PROMPT=$(echo "$HOOK_INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")

if [[ -z "$USER_PROMPT" ]]; then
  exit 0
fi

# Convert to lowercase for matching
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

# ============================================================
# Serena triggers: シンボルベースの検索
# 具体的なシンボル名、定義、参照、構造
# ============================================================
SERENA_TRIGGERS=(
  "定義" "参照" "呼び出し元" "呼び出し先" "使用箇所"
  "definition" "reference" "who calls" "called by"
  "クラス" "関数" "メソッド" "変数" "プロパティ"
  "class" "function" "method" "variable"
  "構造" "一覧" "リスト" "structure" "list"
  "シンボル" "symbol"
)

# ============================================================
# grepai triggers: セマンティック（意味）ベースの検索
# 概念、パターン、類似、自然言語での検索
# ============================================================
GREPAI_TRIGGERS=(
  "のような" "みたいな" "似た" "similar" "like"
  "パターン" "pattern" "どうやって" "how to"
  "処理" "ハンドリング" "handling" "processing"
  "実装" "implementation" "やり方"
  "エラー" "認証" "バリデーション" "ログ"
  "error" "auth" "validation" "logging"
)

# ============================================================
# 共通トリガー: 両方に適用される検索キーワード
# ============================================================
SEARCH_TRIGGERS=(
  "探して" "検索" "どこ" "見つけて" "locate" "find" "search" "where"
)

# Check triggers
SHOULD_USE_SERENA=false
SHOULD_USE_GREPAI=false
IS_SEARCH_QUERY=false

# Check search triggers first
for trigger in "${SEARCH_TRIGGERS[@]}"; do
  if [[ "$PROMPT_LOWER" == *"$trigger"* ]]; then
    IS_SEARCH_QUERY=true
    break
  fi
done

# Check Serena triggers
for trigger in "${SERENA_TRIGGERS[@]}"; do
  if [[ "$PROMPT_LOWER" == *"$trigger"* ]]; then
    SHOULD_USE_SERENA=true
    break
  fi
done

# Check grepai triggers
for trigger in "${GREPAI_TRIGGERS[@]}"; do
  if [[ "$PROMPT_LOWER" == *"$trigger"* ]]; then
    SHOULD_USE_GREPAI=true
    break
  fi
done

# Build suggestion message
SUGGESTIONS=""

# 両方のトリガーがある場合
if [[ "$SHOULD_USE_SERENA" == "true" ]] && [[ "$SHOULD_USE_GREPAI" == "true" ]]; then
  SUGGESTIONS="[Skill Suggestion] コード検索にはSerenaとgrepaiを組み合わせてください。

【Serena】具体的なシンボル検索
- mcp__serena__find_symbol: クラス/関数の定義
- mcp__serena__find_referencing_symbols: 参照・呼び出し元

【grepai】セマンティック検索
- grepai search \"キーワード\": 概念・意味での検索"

# Serenaのみ
elif [[ "$SHOULD_USE_SERENA" == "true" ]]; then
  SUGGESTIONS="[Skill Suggestion] シンボル検索にはSerenaを使ってください。
- mcp__serena__find_symbol: 定義を検索
- mcp__serena__find_referencing_symbols: 参照を追跡
- mcp__serena__get_symbols_overview: 構造を把握"

# grepaiのみ
elif [[ "$SHOULD_USE_GREPAI" == "true" ]]; then
  SUGGESTIONS="[Skill Suggestion] セマンティック検索にはgrepaiを使ってください。
- grepai search \"キーワード\": 意味ベースでコード検索
- grepai trace callers \"関数名\": コールグラフ追跡"

# 検索クエリだが具体的なツールが特定できない場合
elif [[ "$IS_SEARCH_QUERY" == "true" ]]; then
  SUGGESTIONS="[Skill Suggestion] コード検索ツールを選択してください。

【具体的なシンボル名がわかっている場合 → Serena】
- mcp__serena__find_symbol: 定義を検索

【概念・意味で検索したい場合 → grepai】
- grepai search \"キーワード\": セマンティック検索"
fi

# Output suggestion if any
if [[ -n "$SUGGESTIONS" ]]; then
  echo "$SUGGESTIONS"
fi

exit 0
