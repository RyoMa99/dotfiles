---
alwaysApply: true
---

# ツール運用ガイド

Claude Code 環境でのツール選択・設定・既知の注意点。

---

## HTTP クライアント: xh

- `curl` ではなく `xh` を使用（`curl` は `xh` へのエイリアス設定済み）
- Claude Code の Bash 環境では `--ignore-stdin` を必ず付ける（stdin が接続された状態で実行されるため `--raw` と競合する）

```bash
# GOOD
xh --ignore-stdin POST http://localhost:8788/v1/logs Authorization:"Bearer token" --raw '{"resourceLogs":[]}'

# BAD（stdin 競合エラー）
xh POST http://localhost:8788/v1/logs Authorization:"Bearer token" --raw '{"resourceLogs":[]}'
```

---

## Web ページ取得: WebFetch / jina.ai

- 基本は WebFetch ツールを使用
- note など、WebFetch で本文が取得できないサイト（HTML/CSS のみ返る）は `r.jina.ai` を経由

```
https://r.jina.ai/[元のURL]
```

jina.ai の Reader API が JavaScript レンダリング後のコンテンツをマークダウン形式で返す。

---

## ブラウザ操作

優先順位:
1. **agent-browser**（認証不要時）- Bash 1コマンド = 1アクション、snapshot でアクセシビリティツリー取得
2. **Claude in Chrome**（認証必要時）- ユーザーのセッション活用
3. **chrome-devtools MCP**（Claude in Chrome が使えない時のフォールバック）

---

## ランタイム管理: mise

- mise で管理するツール（agent-browser 等）は直接コマンド名で実行する（`.zshenv` で shims が PATH に設定済み）

---

## Bash ツールの注意点

### ダッシュ文字列をクォートしない

`echo "---"` のように `-` のみの文字列をクォートすると「Command contains quoted characters in flag names」警告が出る。

```bash
# GOOD
echo ---
printf '%s\n' ---

# BAD（警告）
echo "---"
echo "--foo"
```

### サブシェル `$(...)` を避ける

heredoc ネスト時のパースエラー防止。以下を優先する:
- stdin 経由で渡す（`-F -` + heredoc、パイプ）
- `mise exec --` でラップする
- Bash ツールを複数回に分けて実行し、前回の出力を次の引数に使う

---

## Claude Code 環境の制約

### 1Password CLI

`op` コマンドは Claude Code の Bash 環境から実行不可。デスクトップアプリとの Unix ソケット通信がサンドボックスで制限される。`op` を使う操作はユーザーのターミナルで直接実行してもらう。

### settings.local.json の env マージ

Claude Code の settings マージはトップレベルキーごとの shallow merge。プロジェクトの `.claude/settings.local.json` に `env` を定義すると、グローバルの `env` が丸ごと置き換えられる。

```json
// グローバル ~/.claude/settings.local.json
"env": {
  "OTEL_EXPORTER_OTLP_ENDPOINT": "https://...",
  "OTEL_EXPORTER_OTLP_HEADERS": "Authorization=Bearer ..."
}

// プロジェクト .claude/settings.local.json に env を追加すると
// グローバルの ENDPOINT / HEADERS が消える
```

プロジェクトの `env` には、グローバルで必要な環境変数（特に OTLP 関連）も含めること。
