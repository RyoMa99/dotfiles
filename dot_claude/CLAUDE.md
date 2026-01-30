# グローバル設定

## 作業フロー

1. **設計**: `superpowers:brainstorming` でアイデアを設計に変換
2. **調査**: 既存プロジェクトの場合、`/planning` でコードベース調査（Serena + grepai）
3. **計画**: `superpowers:writing-plans` で実装計画を作成
4. **承認**: ユーザーの承認を得てから実装開始
5. **実装**: `superpowers:subagent-driven-development` または `/TDD` で実装
6. **検証**: 完了前に `superpowers:verification-before-completion` で品質チェック
7. **完了**: `superpowers:finishing-a-development-branch` でマージ/PR

## コード品質

詳細なガイドラインは `~/.claude/rules/` を参照：
- @~/.claude/rules/robust-code.md - 堅牢なコードの設計原則
- @~/.claude/rules/testing.md - テストの原則
- @~/.claude/rules/security.md - セキュリティルール

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める
