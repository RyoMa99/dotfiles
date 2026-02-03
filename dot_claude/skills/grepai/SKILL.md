---
name: grepai
description: セマンティックコード検索にgrepaiを活用する。「〜のような」「〜する処理」「パターン」「似たコード」など意味ベースの検索で発動。
user_invocable: true
---

# grepai Skill

自然言語でコードを検索するセマンティック検索スキル。

## When to Use This Skill

以下のような**意味ベース**の検索で発動：

- 概念検索: 「エラーハンドリング」「認証処理」「バリデーション」
- 類似検索: 「〜のような」「〜みたいな」「似たコード」「similar」
- パターン検索: 「パターン」「どうやって」「how to」
- 機能検索: 「〜する処理」「〜を行うコード」「handles」「processes」

## Serenaとの棲み分け

```
┌─────────────────────────────────────────────────────────────┐
│  検索の種類による使い分け                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  【Serena を使う場合】                                       │
│  ・具体的なシンボル名がわかっている                          │
│    例: 「validateEmail関数はどこ？」                         │
│  ・定義・参照の追跡                                          │
│    例: 「UserServiceの呼び出し元は？」                       │
│  ・クラス/関数の構造把握                                     │
│    例: 「このクラスのメソッド一覧」                          │
│                                                             │
│  【grepai を使う場合】                                       │
│  ・概念・意味での検索                                        │
│    例: 「エラーハンドリングのパターンは？」                  │
│  ・自然言語での検索                                          │
│    例: 「ユーザー認証を行っている箇所」                      │
│  ・類似コードの検索                                          │
│    例: 「このコードに似た処理はある？」                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## grepai コマンド

### 1. セマンティック検索

```bash
grepai search "検索クエリ"
```

例:
```bash
grepai search "error handling patterns"
grepai search "user authentication"
grepai search "database connection pooling"
```

### 2. コールグラフ追跡

```bash
grepai trace callers "関数名"   # 呼び出し元を追跡
grepai trace callees "関数名"   # 呼び出し先を追跡
```

### 3. インデックス状態確認

```bash
grepai status
```

## MCP サーバーモード

Claude Codeから直接使う場合：

```bash
grepai mcp-serve
```

## 検索フロー

```
ユーザー: 「認証処理はどこにある？」
    ↓
grepai search "authentication handling"
    ↓
関連ファイル・行番号のリスト
    ↓
必要に応じてSerenaでシンボル詳細を取得
```

## 初回セットアップ（プロジェクトごと）

```bash
cd /path/to/project
grepai init              # 初期化
grepai watch             # インデックス開始（バックグラウンド）
```

## 設定ファイル

`.grepai/config.yaml`:
```yaml
embedder:
  provider: ollama
  model: mxbai-embed-large  # デフォルトのnomic-embed-textより高精度
  endpoint: http://localhost:11434
  dimensions: 1024          # mxbai-embed-largeの次元数
```

## 使用例

### 例1: 概念検索
```
ユーザー: 「エラーハンドリングのパターンを探して」

grepai search "error handling patterns"
→ 関連コードの一覧

必要ならSerenaで詳細を取得
```

### 例2: 機能検索
```
ユーザー: 「ファイルアップロードを処理している箇所」

grepai search "file upload processing"
→ 該当ファイル・行番号

Serenaで呼び出し元を追跡
```

### 例3: 組み合わせ検索
```
ユーザー: 「Userクラスの認証関連メソッド」

1. Serena: find_symbol("User") → クラス構造を把握
2. grepai: search "User authentication" → 認証関連の実装を特定
```

## 注意事項

- **Ollama起動必須**: `brew services start ollama`
- **初回インデックス**: プロジェクトで `grepai init && grepai watch` が必要
- **モデル変更時**: インデックス再構築が必要
