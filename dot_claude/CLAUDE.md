# グローバル設定

## 作業フロー

1. **計画**: 作業を始める前に `/planning` で計画を立てる
2. **タスク登録**: 計画をTaskCreate/TaskUpdateでタスク管理システムに登録
3. **承認**: ユーザーの承認を得てから実装開始
4. **実装**: `/TDD` でRED-GREEN-REFACTORサイクルを実行
5. **検証**: 完了前に `/verification-loop` で品質チェック

## コード品質

詳細なガイドラインは `~/.claude/rules/` を参照：
- @~/.claude/rules/robust-code.md - 堅牢なコードの設計原則
- @~/.claude/rules/testing.md - テストの原則
- @~/.claude/rules/security.md - セキュリティルール

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める
