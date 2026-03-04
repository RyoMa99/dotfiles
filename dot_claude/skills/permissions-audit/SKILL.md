---
name: permissions-audit
description: "Use when auditing and refactoring .claude/settings.local.json permissions across ghq repositories and global settings. Identifies redundancies, empty arrays, and inconsistencies. Use this whenever the user mentions permissions cleanup, settings review, permission refactoring, redundant allow rules, or wants to check if project-level permissions overlap with global settings. Also trigger when the user says 'settings.local.json を見直して' or 'permissions を整理して'."
allowed-tools: ["Bash", "Read", "Edit", "Write", "Glob", "Grep", "AskUserQuestion"]
---

# Permissions Audit Skill

`ghq root` 配下のリポジトリとグローバルの `~/.claude/settings.local.json` の permissions を監査・リファクタリングする。

## 実行フロー

### Step 1: グローバル設定の読み込み

Read ツールで `~/.claude/settings.local.json` を読み込む。
グローバルの `permissions.allow` をベースラインとして記録する。

### Step 2: プロジェクト設定の収集

```bash
GHQ_ROOT=$(ghq root)
find "$GHQ_ROOT" -path '*/.claude/settings.local.json' -type f 2>/dev/null
```

列挙されたファイルを Read ツールで読み込み、各ファイルの `permissions` セクションを取得する。

### Step 3: 監査ルールに基づく分析

以下の監査ルールで各プロジェクトを分析し、レポートを作成する。

#### 監査ルール

| ID | ルール | 重要度 | 説明 |
|----|--------|--------|------|
| R1 | グローバルとの重複 | Major | グローバルの allow パターンで既にカバーされている権限 |
| R2 | 空配列の除去 | Minor | `"deny": []`, `"ask": []`, `"allow": []` など空の配列はノイズ |
| R3 | Read ツール推奨 | Minor | `Bash(cat:*)` は Read ツールの使用が推奨される。permission 自体が不要な可能性 |
| R4 | プロジェクト間の共通パターン | Info | 3つ以上のプロジェクトで同じ permission がある場合、グローバルへの昇格を検討 |
| R5 | ワイルドカード過剰 | Warning | `Write(*)`, `Edit(*)`, `WebFetch(domain:*)` など過度に広いワイルドカード |

#### R1: グローバルカバレッジの判定ロジック

以下の3パターンで冗長性を判定する:

**パターン A: 完全一致**
プロジェクトの permission がグローバルと完全に同じ文字列。

```
グローバル: WebFetch(domain:github.com)
冗長:       WebFetch(domain:github.com)  ← 完全一致
```

**パターン B: サブコマンドの個別指定**
グローバルに `Bash(X:*)` がある場合、`Bash(X <subcommand>:*)` は冗長。
コマンド名の先頭一致で判定する（`gh` は `gh pr view` をカバーするが `ghq` はカバーしない）。

```
グローバル: Bash(gh:*)
冗長:       Bash(gh pr view:*)    ← gh:* でカバー済み
冗長:       Bash(gh pr diff:*)    ← gh:* でカバー済み
非冗長:     Bash(ghq list:*)      ← gh:* では ghq はカバーされない
非冗長:     Bash(go test:*)       ← 別コマンド
```

判定時の注意: `Bash(gh:*)` のコマンド名は `gh` であり、`gh` の後にスペースが続くか文字列が終わる場合のみマッチする。`ghq` や `gha` は別コマンドとして扱う。

**パターン C: ワイルドカードの包含**
グローバルの permission がワイルドカード付きで、プロジェクトのそれを包含する場合。

```
グローバル: Bash(npm:*)
冗長:       Bash(npm run lint:*)  ← npm:* でカバー済み
```

### Step 4: レポート出力

以下のフォーマットでレポートを出力する:

```markdown
## Permissions Audit Report

### サマリー
- 対象リポジトリ: N 個
- 指摘総数: N 件（Major: N / Warning: N / Minor: N / Info: N）

### 指摘一覧

#### [リポジトリ名]
| ID | 重要度 | 対象 | 説明 | 推奨アクション |
|----|--------|------|------|----------------|
| R1 | Major | `Bash(gh pr view:*)` | グローバル `Bash(gh:*)` でカバー済み | 削除 |
| R2 | Minor | `"deny": []` | 空配列 | 削除 |

### グローバル昇格の候補（R4）
| permission | 使用リポジトリ数 | リポジトリ |
|------------|-----------------|-----------|
| `Bash(terraform:*)` | 3 | leader-notification-extraction, leader-mailer, 8122-core-iac |
```

### Step 5: リファクタリングの実行

レポートを確認後、ユーザーに修正方針を確認する:

```
修正方針を選んでください:
1. Major のみ自動修正（冗長な permission の削除）
2. Major + Minor を自動修正（空配列の削除も含む）
3. 全件自動修正（Warning も含む）
4. レポートのみ（修正しない）
```

#### 修正時の注意

- **必ずバックアップを取る**: 修正前に `settings.local.json.bak` を作成
- **空になった permissions は削除**: `"permissions": { "allow": [] }` まで削れたら permissions キー自体を削除
- **env や additionalDirectories は触らない**: permissions 以外のキーは保持
- **修正後に JSON の妥当性を検証**: `python3 -c "import json; json.load(open('file'))"` で検証

### Step 6: 修正結果の報告

```markdown
## 修正完了

### 変更されたファイル
- `path/to/settings.local.json`: R1 x2, R2 x1 を修正
  - 削除: `Bash(gh pr view:*)`, `Bash(gh pr diff:*)`
  - 削除: 空の `deny` 配列

### バックアップ
`*.bak` ファイルとして保存済み。問題があれば復元可能:
```bash
mv path/to/settings.local.json.bak path/to/settings.local.json
```
```

## permissions のマージ仕様

Claude Code の `permissions.allow` は**加算的に動作する**:
- グローバルの allow + プロジェクトの allow が最終的な許可リスト
- プロジェクト側でグローバルの allow を再宣言する必要はない

これは `env` の挙動（トップレベルキーの shallow merge = プロジェクト側が丸ごと上書き）とは異なる。permissions は加算なので、グローバルで許可した権限はすべてのプロジェクトに継承される。
