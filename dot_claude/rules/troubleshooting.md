# トラブルシューティング

プロジェクトで遭遇した問題と解決策のパターン集。

---

<!-- 以下に学習内容を追記 -->

## jina.aiでWebページ本文を取得

**状況**: noteなど、WebFetchで本文が取得できないサイト（HTML/CSSのみ返る）

**解決策**: `r.jina.ai` を経由してアクセス

```
https://r.jina.ai/[元のURL]
```

**例**:
```
# Before（本文取得できない）
https://note.com/user/n/xxxxx

# After（本文取得できる）
https://r.jina.ai/https://note.com/user/n/xxxxx
```

**ポイント**: jina.aiのReader APIがJavaScriptレンダリング後のコンテンツをマークダウン形式で返す

---
