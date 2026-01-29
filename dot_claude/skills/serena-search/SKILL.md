---
name: serena-search
description: シンボルレベルのコード検索にSerena MCPを活用する。「定義」「参照」「呼び出し元」「クラス」「関数名」など具体的なシンボル検索で発動。
user_invocable: true
---

# Serena Search Skill

シンボルレベルでコードを検索・探索するスキル。

## When to Use This Skill

以下のような**シンボルベース**の検索で発動：

- 具体名検索: 「〇〇関数」「〇〇クラス」「〇〇メソッド」
- 定義検索: 「定義」「definition」「どこで定義」
- 参照検索: 「参照」「呼び出し元」「使用箇所」「reference」「who calls」
- 構造検索: 「構造」「メソッド一覧」「プロパティ」

## grepaiとの棲み分け

```
┌─────────────────────────────────────────────────────────────┐
│  検索の種類による使い分け                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  【Serena を使う場合】（このスキル）                         │
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

## Serena ツールの使い分け

### 1. プロジェクト構造の把握

```
mcp__serena__get_symbols_overview
```
- ファイルやディレクトリ内のシンボル一覧を取得
- 「このファイルに何がある？」「構造を見せて」

### 2. シンボル検索

```
mcp__serena__find_symbol
  - name_path: "検索するシンボル名"
  - substring_matching: true（部分一致）
  - include_body: false（定義のみ）or true（本体も）
```
- 「〇〇という関数はどこ？」「UserServiceクラスを探して」

### 3. 参照の追跡

```
mcp__serena__find_referencing_symbols
  - name_path: "シンボル名"
```
- 「この関数はどこから呼ばれている？」「影響範囲は？」

### 4. ファイル検索

```
mcp__serena__find_file
  - file_name: "ファイル名"
```
- 「〇〇.tsはどこ？」「設定ファイルを探して」

### 5. パターン検索

```
mcp__serena__search_for_pattern
  - pattern: "検索パターン（正規表現）"
  - relative_path: "検索範囲（オプション）"
```
- 「TODO コメントを探して」「特定の文字列を検索」

## 検索フロー

```
ユーザー: 「validateEmail関数の定義と呼び出し元」
    ↓
1. mcp__serena__find_symbol("validateEmail")
   → 定義の場所を特定
    ↓
2. mcp__serena__find_referencing_symbols("validateEmail")
   → 全ての呼び出し元をリスト
    ↓
3. 必要に応じて include_body: true で詳細確認
```

## 使用例

### 例1: 関数を探す
```
ユーザー: 「validateEmail関数はどこにある？」

mcp__serena__find_symbol(name_path="validateEmail")
→ ファイルパスと行番号を取得
```

### 例2: 影響範囲を調べる
```
ユーザー: 「UserServiceを変更したら何に影響する？」

1. mcp__serena__find_symbol(name_path="UserService")
2. mcp__serena__find_referencing_symbols(name_path="UserService")
→ 全ての参照箇所をリストアップ
```

### 例3: クラス構造を把握
```
ユーザー: 「Userクラスのメソッド一覧」

mcp__serena__find_symbol(name_path="User", depth=1, include_body=false)
→ クラス内の全メソッドをリスト
```

## 重要な原則

1. **具体名がわかっている → Serena**
2. **概念・意味で検索 → grepai**
3. **段階的に深掘り**: 概要→詳細の順で情報を取得
4. **トークン節約**: `include_body: false` で概要だけ先に取得

## Serenaが使えない場合のフォールバック

Serena MCPが利用できない場合は、従来のツールを使用：
- `Glob` - ファイルパターン検索
- `Grep` - テキスト検索
- `Read` - ファイル読み込み
