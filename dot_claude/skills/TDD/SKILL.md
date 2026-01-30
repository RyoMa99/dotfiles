---
name: TDD
description: TDDで開発を進める。RED-GREEN-REFACTORサイクルを厳格に適用し、コンテキスト汚染を防止。
disable-model-invocation: true
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
---

# TDD Skill

テスト駆動開発（TDD）のワークフローを厳格にガイドするスキル。

詳細なテスト原則は @reference.md と @~/.claude/rules/testing.md を参照。

## When to Use This Skill

Trigger when user:
- `/TDD` コマンドを実行
- 「TDDで開発して」「テスト駆動で」と依頼
- `/planning` 完了後の実装フェーズ

## 核心原則

### TDDの目的（t_wada）

> 信頼性の高い実行結果に短時間で到達する状態を保つことで、
> 開発者に**根拠ある自信**を与え、ソフトウェアの成長を持続可能にすること

### Kent Beck の TDD 5ステップ

1. **テストリストを書く** - 網羅したいシナリオをリストアップ
2. **1つ選んでテストを書く** - 具体的で実行可能なテストコード、失敗を確認
3. **テストを通す** - 最小限の実装で成功させる
4. **リファクタリング** - 設計を改善（テストは成功を維持）
5. **繰り返す** - テストリストが空になるまで

### コンテキスト汚染を防ぐ

> "テストが実装後に書かれると、テストは実装に合わせて書かれる。
> テストはコードが何をするかを証明するだけ — 完璧なトートロジー（同語反復）である"

**対策**: テストは**要件**に基づいて書く、実装を見ない

### RED-GREEN-REFACTOR サイクル

```
RED: テストを書く → 失敗を確認（必須）
  ↓
GREEN: 最小限の実装 → 成功を確認
  ↓
REFACTOR: リファクタ → 成功を維持
  ↓
次のテストへ（繰り返し）
```

---

## 実装フロー

### Phase 0: 終了条件の明確化

**⚠️ 必須: TDDサイクルを開始する前に、終了条件を明確にする**

```markdown
## 終了条件

### 実装する機能
（1文で説明）

### 成功の定義（全て満たしたら完了）
- [ ] 全テストケースがパス
- [ ] カバレッジ80%以上
- [ ] 品質検証がパス（`superpowers:verification-before-completion` 参照）

### スコープ外（今回やらないこと）
- （明示的に除外する機能）
```

### Phase 1: テスト設計（実装を見ない）

#### 1.1 ユーザージャーニーの作成

```markdown
### シナリオ1: 新規ユーザー登録
As a 新規ユーザー
I want to メールアドレスで登録
So that サービスを利用できる
```

#### 1.2 テストケースの列挙

```markdown
### 正常系（ユーザーが見える動作）
- [ ] 有効なメールアドレスでtrueを返すこと

### 異常系（エッジケース）
- [ ] @がない場合falseを返すこと
- [ ] 空文字でfalseを返すこと
```

**⚠️ 重要: 実装の詳細ではなく、ユーザーが見える動作をテストする**

#### 1.3 テストファイルの準備

テストリスト（1.2のチェックリスト）をもとに、空の `describe` ブロックだけ作成する。
`it.skip` でテストを先に全部コード化しない — テストは1つずつREDフェーズで書く。

```typescript
describe('validateEmail', () => {
  // テストリストから1つずつ RED-GREEN-REFACTOR で追加していく
});
```

### Phase 2: RED-GREEN-REFACTOR（1テストずつ）

#### 2.1 RED: テストを書く

```typescript
it('有効なメールアドレスの場合にtrueを返すこと', () => {
  const result = validateEmail('test@example.com');
  expect(result).toBe(true);
});
```

**必須**: テスト実行、**失敗を確認**

#### 2.2 GREEN: 最小限の実装

```typescript
function validateEmail(email: string): boolean {
  return email.includes('@');
}
```

**必須**: テスト実行、**成功を確認**

#### 2.3 VERIFY: 自動検証ループ（GREEN後に必須）

GREEN完了後、自動的に検証を実行する：

```
GREEN成功 → 検証実行 → 失敗 → 修正 → 検証 → ...（最大3回）
                         ↓
                    成功 → REFACTOR へ
                         ↓
                    3回失敗 → [TDD:BLOCKED] ユーザーに確認
```

**検証内容**:
- 型チェック（`tsc --noEmit` など）
- リント（`eslint` など）
- 関連テストの実行

**iteration limit**: 3回（無限ループ防止）

```markdown
## 検証ループ状態

| 試行 | 結果 | 対応 |
|------|------|------|
| 1回目 | ❌ lint error | 修正して再実行 |
| 2回目 | ❌ type error | 修正して再実行 |
| 3回目 | ✅ 成功 | REFACTORへ進む |
```

**3回失敗時**:
```
[TDD:BLOCKED]
検証が3回連続で失敗しました。

## 失敗履歴
1. lint: unused variable
2. type: Type 'string' is not assignable to 'Email'
3. test: Expected true, received false

ユーザーの判断を求めます：
- 続行（手動で修正を指示）
- スキップ（このテストを後回し）
- 中断（計画を見直し）
```

#### 2.4 REFACTOR: リファクタ

- 重複の除去、可読性の向上
- **テストは変更しない**（成功を維持）

#### 2.5 コミット

各サイクル完了後にコミット

### Phase 3: 繰り返し

テストリスト（Phase 1.2）から次のケースを選び、Phase 2 を繰り返す。

### Phase 4: 最終検証

**⚠️ タスク完了前に `superpowers:verification-before-completion` に従い、ビルド・型・リント・全テストを実行して証拠を示す**

### Phase 5: タスク完了

**全ての終了条件を満たした場合のみ**：

1. `TaskUpdate` で status を `completed` に更新
2. 成功マーカーを出力：

```
<tdd-success/>
```

---

## チェックリスト

- [ ] REDフェーズ: テストが失敗することを確認したか？
- [ ] GREENフェーズ: 最小限の実装か？（先取りしていないか）
- [ ] VERIFYフェーズ: 型・リント・テストが通過したか？（最大3回）
- [ ] REFACTORフェーズ: テストが成功を維持しているか？
- [ ] 検証: `superpowers:verification-before-completion` に従い証拠を示したか？

## コミットルール

- **prefix**:
  - `test` - テストの追加（REDフェーズ）
  - `feat` - 機能実装（GREENフェーズ）
  - `refactor` - リファクタ（REFACTORフェーズ）

## エラー時の対応

### 2回以上連続でテスト失敗

1. 現状を整理
2. ユーザーに確認
3. 必要に応じてテストケースを見直し

### テストが最初から成功する（REDで失敗しない）

既存の実装がテストを満たしている場合:
- **テストが既存の振る舞いを検証しているだけ** → テストを修正し、未実装の振る舞いをテストする

実装を先に書いてしまった場合:
- **実装を削除し、テストから書き直す** — 参考にすることも禁止
- 「参考として残す」「少し調整する」は実装先行と同じ。削除は削除
