---
name: review
description: "Use when reviewing code changes for naming quality, UI accessibility, and security vulnerabilities"
argument-hint: "[file-or-directory]"
disable-model-invocation: false
allowed-tools: ["Glob", "Grep", "Read", "Bash", "Task", "WebFetch", "AskUserQuestion"]
---

# Code Review Skill

変更差分を対象に、命名・UI・セキュリティの3観点でレビューするスキル。

関連:
- `robust-code.md` ルール（型による予防的設計）

## When to Use

- `/implementation` の Step 3 として自動実行
- `/review` で単体実行
- PR 作成前のコードレビュー

---

## 実行フロー

### 1. 対象の特定

```
対象: $ARGUMENTS
```

引数がない場合は git diff で変更ファイルを検出:

```bash
git diff --name-only HEAD
git diff --name-only --cached
git ls-files --others --exclude-standard
```

変更ファイル一覧をユーザーに提示する。

---

### 2. Naming Review（常に実行）

変更されたソースファイル（テストファイル除外）を対象に、命名を7段階で評価する。

| 段階 | 名前 | 問題の兆候 |
|------|------|-----------|
| 1 | Missing | 抽出すべき概念が埋もれている |
| 2 | Nonsense | temp, data, info 等の汎用名 |
| 3 | Honest | 副作用が名前に反映されていない |
| 4 | Honest and Complete | 名前が長い（責務過多のサイン） |
| 5 | Does the Right Thing | 単一責務 |
| 6 | Intent | 目的を表現 |
| 7 | Domain Abstraction | ドメイン用語として統一 |

検出対象: Manager/Handler 等の曖昧サフィックス、Feature Envy、プリミティブ執着

詳細な進化プロセスとリファクタリング手法: @naming.md
判断基準と出力フォーマット例: @naming-reference.md

---

### 3. UI Check（UI 変更時のみ）

変更ファイルに UI コンポーネント（`.tsx`, `.jsx`, `.vue`, `.svelte` 等）が含まれる場合のみ実行。
該当ファイルがなければスキップし、スキップした旨を明記する。

チェック項目:
- **a11y**: aria 属性、キーボード操作、disabled vs aria-disabled パターン、フォームラベル紐づけ
- **スペーシング**: 8pt グリッド準拠
- **コントラスト比**: UI要素 3:1、小テキスト 4.5:1
- **タッチターゲット**: 最小 48x48px
- **タイポグラフィ**: 見出し letter-spacing、サイズジャンプ 3x 以上

Web Interface Guidelines を参照:
```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

詳細なチェック項目とコード例: @ui.md

---

### 4. Security Review（常に実行）

変更ファイルに対して以下の観点で自動検出 + コンテキスト分析を実行する。

| 観点 | 検出対象 |
|------|---------|
| 秘密情報 | API キー・パスワードのハードコード、.env のコミット |
| 入力検証 | `any` / `unknown` の未検証使用、`req.body` 直接使用 |
| インジェクション | SQL 文字列連結、OS コマンド注入、パストラバーサル |
| XSS | `innerHTML`、unsafe 系 API の無検証使用 |
| 認証・認可 | 認証ミドルウェア欠如、Bearer token の replace 使用 |
| エラー情報露出 | `error.stack` のレスポンス含有 |
| 依存関係 | 新規パッケージの `pnpm audit` |

Critical 指摘がある場合は後続ステップをブロックし、修正を求める。

詳細なチェックリストとコード例: @security.md
セキュリティルール全体: @security-checklist.md

---

### 5. 指摘の出力

各問題について:
```
[Critical/Major/Minor] ファイル:行番号
  問題: 何が問題か
  理由: なぜ危険か
  修正案: どう修正すべきか
```

---

### 6. サマリー出力

```markdown
## レビュー結果

| 観点 | 結果 |
|------|------|
| naming-review | ✅ 問題なし / ⚠️ N件の指摘 |
| ui-check | ✅ 問題なし / ⏭️ スキップ（UI変更なし） |
| security-review | ✅ 問題なし / ⚠️ N件の指摘 |
```

## 注意事項

- レビューのみ。コード編集は行わない
- Critical 指摘がある場合、`/implementation` では後続ステップをブロックする
- 自動検出は誤検知の可能性がある。テストコードのモック値やコメント内のサンプルは「問題なし」と判断してよい
