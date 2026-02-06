# グローバル設定

## 作業フロー

### 設計・計画（Plan モード）

@~/.claude/rules/plan-mode.md に従う（意図の明確化 → コードベース調査 → 計画策定）

### 実装以降

1. **実装**: `superpowers:subagent-driven-development` または `/TDD` で実装
2. **検証**: 完了前に `superpowers:verification-before-completion` で品質チェック
3. **完了**: `superpowers:finishing-a-development-branch` でマージ/PR

## コード品質

詳細なガイドラインは `~/.claude/rules/` を参照：
- @~/.claude/rules/robust-code.md - 堅牢なコードの設計原則
- @~/.claude/rules/testing.md - テストの原則
- @~/.claude/rules/security.md - セキュリティルール

## コミット規約

- コミットメッセージは日本語で書く
- 末尾に `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` を付ける

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める
