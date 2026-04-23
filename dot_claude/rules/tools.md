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

## Web ページ取得: WebFetch / jina.ai / agent-browser

フォールバックチェーン（上から順に試す）。**重要: r.jina.ai で不完全取得だった場合に即「取れない」と諦めない**。Step 3 の DOM 調査を1回は必ず行う。

### Step 1: WebFetch

基本は WebFetch ツール。SSR された HTML や静的ページはここで完結する。

### Step 2: r.jina.ai

WebFetch で本文が取得できない（HTML/CSS のみ返る、JS レンダリング後の内容が欠ける）場合、`r.jina.ai` を経由。

```
https://r.jina.ai/[元のURL]
```

jina.ai の Reader API が JavaScript レンダリング後のコンテンツをマークダウン形式で返す。note などで有効。

### Step 3: agent-browser で DOM 構造を探る

r.jina.ai でも本文が不完全な場合（画像のみ、セリフが画像化されたフォトコミック、SPA で iframe 内配信、API 経由のデータ等）は、agent-browser で DOM 構造を調査して本文の在処を特定する。

```bash
agent-browser open <url> && agent-browser wait --load networkidle
```

以下を eval で確認:

- **iframe**: `document.querySelectorAll('iframe')` — 本文が別ドメイン / 別 HTML に分離されているか
- **API エンドポイント**: `performance.getEntriesByType('resource')` で `api` / `article` / `json` を含むリクエスト — データが JSON API 経由で取れるか
- **background-image**: `getComputedStyle(el).backgroundImage` が `none` でない要素
- **記事ルート要素**: `[class*="article"]`, `[class*="detail"]`, `[class*="content"]` 等で本文コンテナを特定し innerText / innerHTML を取る

### Step 4: Step 3 で判明したソースを直接取得

- **iframe の src**: r.jina.ai 経由で取得し直す（静的 HTML なら大抵取れる）
- **API エンドポイント**: `xh --ignore-stdin GET <api-url>` で直接叩く（JSON データ）
- **innerHTML が取れる場合**: agent-browser eval で直接ダンプ

### Step 5: 画像ベースが残る場合

セリフや本文の一部が完全に画像化されている場合は、`agent-browser screenshot --full` で該当領域をキャプチャして Read で画像として読む。全文取得を諦める判断は、Step 3-4 を経てから行う。

### 判断基準

- **「r.jina.ai で取れない = 取得不可」は短絡**。Step 3 の DOM 調査を省かない
- 記事が画像 / 動画 / Canvas で描画されていることが確定してから諦める
- ただし Step 3-4 に15分以上かかる場合はユーザーに状況を共有して判断を仰ぐ（闇雲に探り続けない）

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
