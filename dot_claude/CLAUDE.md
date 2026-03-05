# グローバル設定

## 作業フロー

### 設計・計画（Plan モード）

`plan-mode.md` に従う（意図の明確化 → コードベース調査 → 計画策定）

### 実装・完了

計画承認後は `/implementation` スキルを実行する（ガードレール先行 → タスク単位実装 → 検証 → 完了）

## コード品質

### 常時参照（`~/.claude/rules/` から自動ロード）

- `robust-code.md` - 堅牢なコードの設計原則
- `layered-architecture.md` - 三層＋ドメインモデルの設計原則

### スキル起動時に参照

- テストの原則 → `/TDD` スキル内の `testing-principles.md`
- セキュリティルール → `/review` スキル内の `security-checklist.md`

## コミット規約

- コミットメッセージは日本語で書く
- 末尾に `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` を付ける
- コミットメッセージは `git commit -F -` で stdin から渡す（サブシェル `$(...)` は heredoc のネストでパース不具合を起こすため避ける）:
  ```bash
  # GOOD: -F - で stdin から渡す
  git commit -F - <<'EOF'
  feat: 機能追加

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  ```
  ```bash
  # BAD: サブシェル $(cat <<'EOF' ...) を使わない
  git commit -m "$(cat <<'EOF'
  feat: 機能追加

  Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  EOF
  )"
  ```

## ツール

- HTTP リクエストは `curl` ではなく `xh` を使用
- ブラウザ操作の優先順位:
  1. **Playwright CLI**（認証不要時）- Bash 1回で完結、コンテキスト最小
  2. **Claude in Chrome**（認証必要時）- ユーザーのセッション活用
  3. **chrome-devtools MCP**（Claude in Chrome が使えない時のフォールバック）
- mise で管理するツール（playwright 等）は直接コマンド名で実行する（`.zshenv` で shims が PATH に設定済み）
- Bash コマンドでダッシュ文字列をクォートしない。`echo "---"` のように `-` のみの文字列をクォートすると「Command contains quoted characters in flag names」警告が出る。`echo ---` や `printf '%s\n' ---` のようにクォートなしで書く。`"--foo"` 等の `-` 始まりリテラルも同様
- サブシェル `$(...)` を避ける（heredoc ネスト時のパースエラー防止）。以下を優先する:
  - stdin 経由で渡す（`-F -` + heredoc、パイプ）
  - `mise exec --` でラップする
  - Bash ツールを複数回に分けて実行し、前回の出力を次の引数に使う

## コミュニケーション

- 日本語で応答
- 技術用語は英語のまま使用可
- 曖昧な要件は確認してから進める

## Learning モードのカスタマイズ

- IMPORTANT: 「Learn by Doing」（TODO(human) をコードに埋め込んでユーザーにコード記述を求める）は**行わない**。コードは Claude が書き切る
- 「★ Insight」は引き続き出力する
