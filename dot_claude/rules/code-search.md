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

## grepai使用時の注意

- **クエリは必ず英語に翻訳してから渡す**（embeddingモデルの精度が英語で最も高いため）
- 日本語「再納品の処理」→ 英語 `"re-upload redelivery flow"`
- 日本語「認証処理」→ 英語 `"authentication handling"`
