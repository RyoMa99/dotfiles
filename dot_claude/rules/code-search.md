---
alwaysApply: true
---

# コード検索ツールの使い分け

コードベースを検索する際、目的に応じてツールを選択する。

---

## 判断フロー

```
検索したい内容
    ↓
具体的なシンボル名がわかっている？
    ├─ Yes → Serena（find_symbol, find_referencing_symbols）
    └─ No → 意味・概念での検索？
              ├─ Yes → grepai search（英語クエリ）
              └─ No → Grep / Glob（パターンマッチ）
```

## ツール別の適用場面

| ツール | 使う場面 | 例 |
|--------|----------|-----|
| **Serena** | シンボル名が既知、定義・参照の追跡 | 「validateEmail関数はどこ？」「UserServiceの呼び出し元」 |
| **grepai** | 概念・意味での検索、類似コード検索 | 「認証処理はどこ？」「エラーハンドリングのパターン」 |
| **Grep** | 正規表現・文字列の完全一致検索 | 特定の文字列リテラル、import文の検索 |
| **Glob** | ファイル名パターンでの検索 | 「*.test.tsx」「**/store.ts」 |

## grepai使用前の確認

grepai を使う前に `grepai status` で状態を確認する。

| 状態 | 対応 |
|------|------|
| `no grepai project found` | 未初期化。ユーザーに `grepai init` を提案する |
| status は返るが watch が停止中 | `grepai watch --background` の実行を提案する |
| 正常稼働中 | そのまま検索を実行 |

grepai が利用できない場合は Grep / Glob にフォールバックし、セマンティック検索が有効な旨をユーザーに伝える。

## grepai コマンド例

### セマンティック検索

```bash
grepai search "検索クエリ（英語）"
```

例:
```bash
grepai search "error handling patterns"
grepai search "user authentication"
grepai search "database connection pooling"
```

### コールグラフ追跡

```bash
grepai trace callers "関数名"   # 呼び出し元を追跡
grepai trace callees "関数名"   # 呼び出し先を追跡
```

### 組み合わせ検索

Serena でシンボル構造を把握 → grepai で意味検索を組み合わせる:

```
1. Serena: find_symbol("User") → クラス構造を把握
2. grepai: search "User authentication" → 認証関連の実装を特定
```

## grepai使用時の注意

- **クエリは必ず英語に翻訳してから渡す**（embeddingモデルの精度が英語で最も高いため）
- 日本語「再納品の処理」→ 英語 `"re-upload redelivery flow"`
- 日本語「認証処理」→ 英語 `"authentication handling"`
- **Ollama起動必須**: `brew services start ollama`
- **初回セットアップ**: `cd /path/to/project && grepai init && grepai watch`
