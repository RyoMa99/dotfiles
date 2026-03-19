# グローバル設定

## 作業フロー

### 要求分析（新規システム・大規模新機能時）

`/rdra` スキルで RDRA 3.0 + EARS による上流分析を実施する（アクター → ゴール → 業務フロー → 要件）

### 設計・計画（Plan モード）

`plan-mode.md` に従う（上流チェック → 意図の明確化 → コードベース調査 → 計画策定）

### 実装・完了

計画承認後は `/implementation` スキルを実行する（ガードレール先行 → タスク単位実装 → 検証 → 完了）

### 成果物の管理方針

`artifacts.md` に従う。Why は残す（RDRA, ADR）、How は捨てる（計画ファイル → PR description に統合）

## コード品質

### 常時参照（`~/.claude/rules/` から自動ロード）

- `robust-code.md` - 堅牢なコードの設計原則
- `layered-architecture.md` - 三層＋ドメインモデルの設計原則
- `artifacts.md` - 成果物の耐久性と管理方針
- `tools.md` - ツール選択・設定・既知の注意点
- `commit-conventions.md` - コミットメッセージ規約

### スキル起動時に参照

- 要求分析 → `/rdra` スキル内の `ears-reference.md`
- 画面仕様 → `/screen-spec` スキル
- テストの原則 → `/TDD` スキル内の `testing-principles.md`
- セキュリティルール → `/review` スキル内の `security-checklist.md`
- 認可設計 → `/authorization` スキル（モデル選定・層配置・構造的強制）

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める
- セッションの目的が明確になったタイミングで `/rename` を引数なしで実行し、セッション名を自動設定する

## Learning モードのカスタマイズ

- IMPORTANT: 「Learn by Doing」（TODO(human) をコードに埋め込んでユーザーにコード記述を求める）は**行わない**。コードは Claude が書き切る
- 「★ Insight」は引き続き出力する
