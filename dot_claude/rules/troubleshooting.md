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

## ~/.claude/ 変更後のchezmoi反映

**状況**: `~/.claude/` 配下のskills、rules、CLAUDE.md等を変更した場合

**ルール**: 変更完了後、必ずchezmoi側に反映してコミットする

**手順**:
1. 変更・追加したファイルをコピー
   ```bash
   cp <変更ファイル> ~/.local/share/chezmoi/dot_claude/<対応パス>
   ```
2. 削除した場合はchezmoi側も削除
   ```bash
   rm -r ~/.local/share/chezmoi/dot_claude/skills/<削除したskill>/
   ```
3. コミット
   ```bash
   cd ~/.local/share/chezmoi && git add . && git commit -m "メッセージ"
   ```

**注意**:
- 削除前にchezmoi gitに履歴があるか確認すること（`git log --all -- <path>` で復元可能か確認）
- ユーザーに「コミットした？」と聞かれる前に、変更→反映→コミットまでを一連の作業として完了する

---
