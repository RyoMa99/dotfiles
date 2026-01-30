---
name: planning
description: コードベース調査（Serena + grepai）を実行し、superpowers:brainstorming の設計に必要な技術的コンテキストを提供する。
disable-model-invocation: true
---

# Planning Skill

## When to Use This Skill

Trigger when user:
- `/planning` または `/plan` コマンドを実行
- 既存プロジェクトへの変更で、コードベース調査が必要な場合
- `superpowers:brainstorming` の前後で技術的コンテキストが必要な場合

## 役割

このスキルは **superpowers:brainstorming** を補完する。

- **brainstorming**: アイデア → 設計（対話・アプローチ比較・設計ドキュメント）
- **planning**: コードベース調査（Serena + grepai で既存コードの構造・パターン・影響範囲を把握）

設計・アプローチ比較・タスク分解は brainstorming と writing-plans に委譲する。

## 全体フロー

```
superpowers:brainstorming（設計）
    ↓
/planning（コードベース調査） ← このスキル
    ↓
superpowers:writing-plans（実装計画）
    ↓
superpowers:subagent-driven-development（実装）
    ↓
superpowers:finishing-a-development-branch（完了）
```

## 実行手順

### Step 1: 全体構造の把握（Serena）

```
mcp__serena__get_symbols_overview
→ プロジェクト全体の構造を把握
```

### Step 2: 関連概念の検索（grepai）

```bash
grepai search "実装したい機能に関連するキーワード"
→ 類似機能や参考になる既存実装を発見
```

例:
- 認証機能を追加 → `grepai search "authentication handling"`
- エラー処理を改善 → `grepai search "error handling patterns"`

### Step 3: 具体的なシンボルの調査（Serena）

```
mcp__serena__find_symbol "関連クラス/関数名"
mcp__serena__find_referencing_symbols "シンボル名"
→ 定義と参照を追跡し、影響範囲を特定
```

### Step 4: 調査結果を整理

```markdown
## コードベース調査結果

### 関連する既存コード（Serena で特定）
- `src/auth/login.ts`: 認証ロジック
- `src/components/LoginForm.tsx`: UIコンポーネント

### 類似パターン（grepai で発見）
- `src/services/payment.ts`: 同様のバリデーションパターン
- `src/utils/errorHandler.ts`: エラーハンドリングの参考実装

### 影響範囲
- 変更が必要なファイル: 3件
- 依存しているコード: 5箇所

### 既存パターン
- 認証: JWT + Cookie
- バリデーション: zod
- テスト: vitest
```

> この調査結果を brainstorming / writing-plans で活用する

## 重要な原則

1. **調査に集中** - 設計やアプローチ比較はしない（brainstorming の役割）
2. **Serena + grepai の使い分け** - シンボルベース vs セマンティックベース
3. **影響範囲の特定** - 変更対象と依存関係を明確にする
4. **既存パターンの尊重** - プロジェクトの慣習を把握し、設計に反映できるようにする
