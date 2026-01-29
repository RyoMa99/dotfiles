---
name: katana-links
description: URLを渡してkatanaでリンクを全列挙し、結果をクリップボードにコピーする。
---

# Katana Links Skill

[katana](https://github.com/projectdiscovery/katana)を使用してURLからリンクを全列挙し、クリップボードにコピーする。

## When to Use This Skill

Trigger when user:
- `/katana-links <URL>` コマンドを実行
- 「リンクを列挙して」「URLのリンク一覧を取得」と依頼
- 「katanaで調べて」と依頼

## 前提条件

katanaがインストールされていること:
```bash
CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest
```

## 実行フロー

### Step 1: URLの確認

ユーザーからURLを受け取る。URLがない場合は確認する。

### Step 2: katana実行

以下のコマンドを実行:

```bash
katana -u <URL> -d 2 -silent | pbcopy
```

**オプション説明:**
- `-u <URL>`: 対象URL
- `-d 2`: クロール深度（デフォルト2、必要に応じて調整）
- `-silent`: 進捗表示を抑制、結果のみ出力

### Step 3: 結果をクリップボードにコピー

`pbcopy`でクリップボードにコピー。

### Step 4: 結果を報告

```
## 完了

[URL] からリンクを取得しました。

取得件数: X件
クリップボードにコピー済み

### 取得したリンク（一部）
- https://example.com/page1
- https://example.com/page2
- ...
```

## オプション

ユーザーが追加オプションを指定した場合:

| オプション | 説明 | 例 |
|-----------|------|-----|
| `-d N` | クロール深度を変更 | `深く調べて` → `-d 5` |
| `-headless` | JSレンダリング有効 | `JS含めて` → `-headless` |
| `-jc` | JSファイルも解析 | `JSファイルも` → `-jc` |

## コマンド例

```bash
# 基本
katana -u https://example.com -d 2 -silent | pbcopy

# 深くクロール
katana -u https://example.com -d 5 -silent | pbcopy

# ヘッドレス（JS対応）
katana -u https://example.com -d 2 -headless -silent | pbcopy

# JSファイルも解析
katana -u https://example.com -d 2 -jc -silent | pbcopy
```

## 使用例

```
/katana-links https://example.com
```

または

```
https://example.com のリンクを全部列挙して
```
