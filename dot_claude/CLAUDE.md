# グローバル設定

## 作業フロー

### 設計・計画（Plan モード）

@~/.claude/rules/plan-mode.md に従う（意図の明確化 → コードベース調査 → 計画策定）

### 実装・完了

@~/.claude/rules/implementation.md に従う（ガードレール先行 → タスク単位実装 → 検証 → 完了）

## コード品質

詳細なガイドラインは `~/.claude/rules/` を参照：
- @~/.claude/rules/robust-code.md - 堅牢なコードの設計原則
- @~/.claude/rules/testing.md - テストの原則
- @~/.claude/rules/security.md - セキュリティルール

## コミット規約

- コミットメッセージは日本語で書く
- 末尾に `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` を付ける

## ツール

- HTTP リクエストは `curl` ではなく `xh` を使用
- ブラウザ操作の優先順位:
  1. **Playwright CLI**（認証不要時）- Bash 1回で完結、コンテキスト最小
  2. **Claude in Chrome**（認証必要時）- ユーザーのセッション活用
  3. **chrome-devtools MCP**（Claude in Chrome が使えない時のフォールバック）
- Playwright CLI は `$(mise which playwright)` でパスを解決して実行する

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める
