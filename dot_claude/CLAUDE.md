# グローバル設定

## 作業フロー

### 設計・計画（Plan モード）

`plan-mode.md` に従う（意図の明確化 → コードベース調査 → 計画策定）

### 実装・完了

計画承認後は `/implementation` スキルを実行する（ガードレール先行 → タスク単位実装 → 検証 → 完了）

## コード品質

### 常時参照（`~/.claude/rules/` から自動ロード）

- `robust-code.md` - 堅牢なコードの設計原則
- `layered-architecture.md` - 三層＋ドメインモデルの設計原則
- `tools.md` - ツール選択・設定・既知の注意点
- `commit-conventions.md` - コミットメッセージ規約

### スキル起動時に参照

- テストの原則 → `/TDD` スキル内の `testing-principles.md`
- セキュリティルール → `/review` スキル内の `security-checklist.md`

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める

## Learning モードのカスタマイズ

- IMPORTANT: 「Learn by Doing」（TODO(human) をコードに埋め込んでユーザーにコード記述を求める）は**行わない**。コードは Claude が書き切る
- 「★ Insight」は引き続き出力する
