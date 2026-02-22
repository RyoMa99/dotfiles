---
name: security-review
description: 変更差分に対してセキュリティ観点のレビューを実行する。秘密情報・入力検証・インジェクション・認証漏れ等を検出。
argument-hint: "[file-or-directory]"
disable-model-invocation: false
allowed-tools: ["Glob", "Grep", "Read", "Bash", "Task"]
---

# Security Review Skill

変更差分を対象にセキュリティ観点でレビューするスキル。

- セキュリティルール: `checklist.md` を Read して参照

## When to Use

- `/finish` の Step 3 として自動実行
- `/security-review` で単体実行
- PR 作成前のセキュリティチェック

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

ソースファイル（`.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.toml`, `.yaml`, `.yml`, `.json`, `.env*` 等）のみ対象。

### 2. 自動検出チェック

変更ファイルに対して以下の観点で Grep / Read を実行する。

#### 2a. 秘密情報のハードコード

検出パターン:
- API キー・シークレット・パスワード・トークンの文字列リテラル代入
- Bearer トークンのハードコード
- 秘密鍵の埋め込み
- `.env` ファイルのコミット対象への混入

#### 2b. 入力検証の欠如

検出パターン:
- パラメータの型が `any` / `unknown` で検証なし
- `req.body` / `req.params` / `req.query` の直接使用（zod 等の検証なし）
- `JSON.parse` の結果を型アサーションのみで使用

#### 2c. インジェクション

検出パターン:
- SQL: テンプレートリテラル / 文字列連結でのクエリ構築
- OS コマンド: `exec` / `spawn` に外部入力を直接渡す
- パストラバーサル: ユーザー入力をファイルパスに直接結合

#### 2d. XSS

検出パターン:
- 未サニタイズの HTML 直接挿入（React の unsafe 系 API 等）
- `innerHTML` への代入
- DOM への未検証文字列の書き込み

#### 2e. 認証・認可

検出パターン:
- 新規 API エンドポイント（route / handler）に認証ミドルウェアがない
- Bearer token の検証で `replace` を使用（`match` を使うべき）
- フロントエンドのみの認可チェック（バックエンド検証なし）

#### 2f. エラーハンドリング

検出パターン:
- `catch` 内で `error.stack` / `error.message` をレスポンスに含める
- 500 エラーで内部情報を露出

#### 2g. 依存関係

新規パッケージが追加されている場合（package.json の変更を検出）:

```bash
pnpm audit --prod 2>/dev/null || true
```

### 3. コンテキスト分析

自動検出で引っかかったものに加え、変更ファイルを Read して以下を確認:

- RLS / アクセス制御の設定漏れ（Supabase, DB マイグレーション等）
- Cookie 属性の設定（httpOnly, secure, sameSite）
- CORS 設定（ワイルドカード `*` の使用）
- セキュリティヘッダの設定

### 4. 指摘の出力

各問題について以下の形式で出力:

```
[Critical/Major/Minor] ファイル:行番号
  問題: 何が問題か
  理由: なぜ危険か（攻撃シナリオ）
  修正案: どう修正すべきか
```

#### 重要度の基準

| 重要度 | 基準 | 例 |
|--------|------|-----|
| **Critical** | 即座に悪用可能、データ漏洩リスク | 秘密情報のハードコード、SQL インジェクション、RLS 未設定 |
| **Major** | 攻撃の前提条件が必要だが危険 | XSS、認証チェック漏れ、エラー情報の露出 |
| **Minor** | ベストプラクティス違反 | CORS の過度な許可、非推奨な暗号化方式 |

### 5. サマリー出力

```markdown
## セキュリティレビュー結果

| 観点 | 結果 |
|------|------|
| 秘密情報 | ✅ / ⚠️ N件 |
| 入力検証 | ✅ / ⚠️ N件 |
| インジェクション | ✅ / ⚠️ N件 |
| XSS | ✅ / ⚠️ N件 |
| 認証・認可 | ✅ / ⚠️ N件 |
| エラーハンドリング | ✅ / ⚠️ N件 |
| 依存関係 | ✅ / ⚠️ N件 |
```

## 注意事項

- レビューのみ。コード編集は行わない
- Critical 指摘がある場合、`/finish` では後続ステップをブロックする
- 自動検出は誤検知の可能性がある。パターンマッチで引っかかっても安全な場合は「問題なし」と判断してよい（例: テストコードのモック値、コメント内のサンプル）
- このスキルは security.md のルールに基づく静的チェック。動的テスト（ペネトレーション等）は対象外
