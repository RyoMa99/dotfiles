---
alwaysApply: true
---

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

---

## プロジェクトの settings.local.json に env を定義すると OTLP が送信されなくなる

**状況**: グローバルの `~/.claude/settings.local.json` で OTLP の ENDPOINT / HEADERS を設定しているが、プロジェクトの `.claude/settings.local.json` に `env` キーを定義すると OTLP テレメトリが送信されなくなる

**原因**: Claude Code の settings マージはトップレベルキーごとの shallow merge。プロジェクトの `settings.local.json` に `env` が存在すると、グローバルの `settings.local.json` の `env` が**丸ごと置き換え**られる。個別の環境変数単位のマージではない

```json
// ~/.claude/settings.local.json（グローバル）
"env": {
  "OTEL_EXPORTER_OTLP_ENDPOINT": "https://...",  // ← これが消える
  "OTEL_EXPORTER_OTLP_HEADERS": "Authorization=Bearer ...",  // ← これも消える
  "OTEL_RESOURCE_ATTRIBUTES": "repository=global"
}

// .claude/settings.local.json（プロジェクト）
"env": {
  "OTEL_RESOURCE_ATTRIBUTES": "repository=my-project"  // ← これだけが env 全体になる
}
```

**解決策**: プロジェクトの `settings.local.json` の `env` にも ENDPOINT / HEADERS を含める

**ポイント**: 新しいプロジェクトで `.claude/settings.local.json` に `env` を追加する際は、グローバルで必要な環境変数（特に OTLP 関連）も忘れずに含めること

---
