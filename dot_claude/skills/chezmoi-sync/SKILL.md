---
name: chezmoi-sync
description: "Use when syncing dotfiles via chezmoi - supports pull, push, and drift detection modes"
user-invocable: true
disable-model-invocation: true
allowed-tools: ["Bash", "Glob", "Read", "Grep", "AskUserQuestion"]
argument-hint: "pull | push | drift"
---

# chezmoi-sync

chezmoi で管理されているファイルの同期操作を統合管理するスキル。

## 基本情報

- **ソースディレクトリ**: `~/.local/share/chezmoi`
- **設定ファイル**: `~/.config/chezmoi/chezmoi.toml`
- **外部管理定義**: `.chezmoiexternal.toml`（git-repo 等で外部管理されるスキル）
- **管理対象**: `chezmoi managed` で取得可能

## モード判定

引数に応じてモードを選択する：

| 引数 | モード | 用途 |
|------|--------|------|
| `pull` | Pull モード | 作業開始前にリモートの最新を取得・適用 |
| `push` | Push モード | `.claude/` 等の編集後に chezmoi へ反映・コミット・プッシュ |
| `drift` | Drift モード | ローカルと chezmoi ソースの差分レポート |
| なし | - | ユーザーにモードを質問 |

---

## Pull モード（作業前のローカルリフレッシュ）

### Step 1: リモートから最新取得

```bash
chezmoi git pull -- --rebase
```

### Step 2: 適用される変更の確認

```bash
chezmoi diff
```

差分があればユーザーに内容を表示し、適用してよいか確認する。
差分がなければ「最新です」と報告して終了。

### Step 3: 変更の適用

ユーザーの承認後：

```bash
chezmoi apply
```

### Step 4: ツールインストール（mise）

Step 1 の pull で `~/.config/mise/config.toml` に変更があった場合、未インストールのツールをインストールする。

```bash
# mise config に変更があったか確認（pull 前後の diff）
cd ~/.local/share/chezmoi && git diff HEAD~1..HEAD -- dot_config/mise/config.toml
```

差分がある場合：

```bash
mise install
```

### Step 5: 孤立ファイル検出

リモートで削除されたがローカルに残っているファイルを検出する。

```bash
# chezmoi が管理しているファイルの一覧
chezmoi managed --include=files --path-style=absolute

# 実際のローカルファイル（.claude/ 配下）
find ~/.claude -type f -name "*.md" | sort
```

`chezmoi managed` に含まれないローカルファイルがあれば：
- `.chezmoiexternal.toml` で外部管理されているか確認
- 外部管理でなければ、ユーザーに削除を提案

---

## Push モード（.claude 編集後の反映）

### Step 1: 変更の検出

```bash
chezmoi diff
```

差分があるファイルを一覧表示する。差分がなければ終了。

### Step 2: 変更ファイルの反映

差分のあるファイルそれぞれに対して：

```bash
chezmoi add <ファイルパス>
```

**パスワード誤検知への対応**:
`chezmoi add` が「パスワードを含む可能性がある」と警告した場合：
1. ユーザーに「パスワードではなくテンプレート等の誤検知です」と説明
2. `chezmoi add --force <ファイルパス>` で強制追加
3. 頻発する場合は `~/.config/chezmoi/chezmoi.toml` の `[secret].excludePatterns` への追加を提案

### Step 3: 削除ファイルの反映

ローカルで削除されたファイルがある場合：

```bash
chezmoi forget <ファイルパス>
```

### Step 4: Brewfile の更新（該当時のみ）

`brew install` / `brew uninstall` を実行した場合：
1. `~/.local/share/chezmoi/dot_Brewfile` に `brew "パッケージ名"` や `cask "アプリ名"` を追加・削除
2. 必要なら `tap "タップ名"` も追加

### Step 5: コミット & プッシュ

```bash
cd ~/.local/share/chezmoi && git add -A && git status
```

コミットメッセージは日本語で、変更内容を簡潔に記述する。
**確認は取らずにそのままコミット＆プッシュする**（ユーザーが `/chezmoi-sync push` を実行した時点でプッシュの意図は明確）。

```bash
cd ~/.local/share/chezmoi && git commit -m "<メッセージ>" && git push
```

---

## Drift モード（差分レポート）

### Step 1: chezmoi diff で全体差分確認

```bash
chezmoi diff
```

### Step 2: ディレクトリ構造の比較

```bash
# スキル
diff <(ls ~/.claude/skills/ | sort) <(ls ~/.local/share/chezmoi/dot_claude/skills/ | sort) || true

# ルール
diff <(ls ~/.claude/rules/ | sort) <(ls ~/.local/share/chezmoi/dot_claude/rules/ | sort) || true
```

### Step 3: ファイル内容の比較

```bash
# スキルの .md ファイルハッシュ比較
diff \
  <(cd ~/.claude/skills && find . -name "*.md" -exec md5 {} \; | sort) \
  <(cd ~/.local/share/chezmoi/dot_claude/skills && find . -name "*.md" -exec md5 {} \; | sort) || true

# ルールも同様
diff \
  <(cd ~/.claude/rules && find . -name "*.md" -exec md5 {} \; | sort) \
  <(cd ~/.local/share/chezmoi/dot_claude/rules && find . -name "*.md" -exec md5 {} \; | sort) || true
```

### Step 4: 外部管理スキルの確認

```bash
grep -A2 '^\[' ~/.local/share/chezmoi/.chezmoiexternal.toml
```

外部管理のスキルはローカルにのみ存在して正常。

### Step 5: chezmoi ソースリポジトリの状態

```bash
cd ~/.local/share/chezmoi && git status && git log --oneline -5
```

### Step 6: レポート出力

以下の形式でレポートを表示：

```markdown
## Chezmoi Drift Report

### 差分あり（要対応）
- `path/to/file` - 内容が異なる（chezmoi add が必要）

### 外部管理（正常）
- `skills/notebooklm` - .chezmoiexternal.toml で管理

### 同期済み
- skills: N/N
- rules: N/N

### 推奨アクション
- `/chezmoi-sync push` で変更を反映
```
