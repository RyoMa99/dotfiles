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

## xh を非対話環境（Claude Code）で使うと stdin 競合エラー

**状況**: Claude Code の Bash ツールから `xh POST ... --raw '{...}'` を実行すると `Request body from stdin and --raw cannot be mixed` エラー

**解決策**: `--ignore-stdin` フラグを付ける

```bash
# Before（エラー）
xh POST http://localhost:8788/v1/logs Authorization:"Bearer token" --raw '{"resourceLogs":[]}'

# After（成功）
xh --ignore-stdin POST http://localhost:8788/v1/logs Authorization:"Bearer token" --raw '{"resourceLogs":[]}'
```

**ポイント**: Claude Code の Bash ツールは stdin が接続された状態で実行されるため、xh が stdin からもボディを読もうとして `--raw` と競合する

---

## 1Password CLI が Claude Code の Bash 環境から接続できない

**状況**: `op` コマンドを Claude Code の Bash ツールから実行すると `1Password CLI couldn't connect to the 1Password desktop app` エラー

**原因**: 1Password CLI はデスクトップアプリと Unix ソケット（`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock`）で通信するが、Claude Code のサンドボックスがソケットへのアクセスを制限する

**解決策**: `op` コマンドを使う操作（アイテム作成、シークレット読み取り等）はユーザーのターミナルで直接実行してもらう。Claude Code からは実行不可。

**chezmoi テンプレートでの回避策**: `onepasswordRead` の代わりに `output` + フォールバックチェーンを使う。`op read` が失敗した場合、既存ファイルから値を読み取る。

```
{{ output "sh" "-c" "op read 'op://vault/item/field' 2>/dev/null || jq -r '.key' existing_file.json 2>/dev/null || echo ''" | trim }}
```

---
