---
name: tbls-doc
description: "Use when generating database schema documentation, ER diagrams, or table definitions via tbls. Also use when the user mentions 'DB docs', 'schema docs', 'ER diagram', or 'table definitions'"
allowed-tools: ["Bash", "AskUserQuestion", "Read"]
---

# tbls Doc Skill

[tbls](https://github.com/k1LoW/tbls)を使用してデータベースのスキーマドキュメントを生成する。

## When to Use This Skill

Trigger when user:
- `/tbls-doc` コマンドを実行
- 「DBのドキュメントを生成して」「スキーマドキュメントを書き出して」と依頼
- 「tblsで出力して」と依頼

## 前提条件

tbls がインストールされていること:
```bash
brew install tbls
```

または:
```bash
go install github.com/k1LoW/tbls@latest
```

## 実行フロー

### Step 1: 接続情報の確認

ユーザーからDB接続情報を受け取る。引数がない場合は確認する。

対応形式:
- DSN: `postgres://user:pass@localhost:5432/dbname`
- DSN: `mysql://user:pass@localhost:3306/dbname`
- DSN: `sqlite:///path/to/db.sqlite`
- `.tbls.yml` が存在する場合はそれを使用

```bash
# .tbls.yml の存在チェック
ls .tbls.yml 2>/dev/null || ls .tbls.yaml 2>/dev/null
```

### Step 2: 出力先の確認

デフォルト: `./docs/schema`

ユーザーが指定した場合はそちらを使用。

### Step 3: tbls 実行

```bash
tbls doc <DSN> <出力先> --force
```

**オプション説明:**
- `--force`: 既存ドキュメントを上書き
- DSN がない場合は `.tbls.yml` から読み取り: `tbls doc --force`

### Step 4: 結果を報告

生成されたファイル一覧を表示:

```bash
ls <出力先>/
```

報告フォーマット:

```
## 完了

スキーマドキュメントを生成しました。

出力先: <出力先>/
テーブル数: X 件

### 生成ファイル
- README.md（テーブル一覧 + ER図）
- <table_name>.md（各テーブルの定義）

### 次のステップ
- `tbls lint` でスキーマの品質チェック
- `tbls diff` で既存ドキュメントとの差分確認
```

### Step 5（任意）: ドキュメント内容の確認

ユーザーが希望すれば、生成された README.md を読んで概要を共有する。

## オプション

ユーザーが追加指示をした場合:

| 指示 | コマンド | 説明 |
|------|---------|------|
| 「lintもして」 | `tbls lint <DSN>` | スキーマの品質チェック |
| 「差分見せて」 | `tbls diff <DSN> <出力先>` | DB とドキュメントの差分 |
| 「設定ファイル作って」 | `tbls config` | `.tbls.yml` のひな型生成 |
| 「ER図だけ」 | `tbls out <DSN> -t mermaid` | Mermaid形式でER図出力 |
| 「JSON で」 | `tbls out <DSN> -t json` | JSON形式で出力 |

## .tbls.yml の例

プロジェクトに設定ファイルがある場合、DSN指定が不要になる:

```yaml
dsn: postgres://user:pass@localhost:5432/dbname
docPath: docs/schema
er:
  format: mermaid
lint:
  requireTableComment:
    enabled: true
  requireColumnComment:
    enabled: true
```

## コマンド例

```bash
# 基本（DSN指定）
tbls doc postgres://user:pass@localhost:5432/mydb ./docs/schema --force

# 設定ファイルから
tbls doc --force

# lint
tbls lint postgres://user:pass@localhost:5432/mydb

# 差分確認
tbls diff postgres://user:pass@localhost:5432/mydb ./docs/schema

# Mermaid ER図出力
tbls out postgres://user:pass@localhost:5432/mydb -t mermaid

# JSON出力
tbls out postgres://user:pass@localhost:5432/mydb -t json
```

## 使用例

```
/tbls-doc postgres://user:pass@localhost:5432/mydb
```

または

```
DBのスキーマドキュメントを生成して
```
