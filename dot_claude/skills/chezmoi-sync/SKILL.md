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

Step 1 の pull で `~/.config/mise/config.toml` または `~/.tool-versions` に変更があった場合、未インストールのツールをインストールする。

```bash
# mise 関連ファイルに変更があったか確認（pull 前後の diff）
git -C ~/.local/share/chezmoi diff HEAD~1..HEAD -- dot_config/mise/config.toml dot_tool-versions
```

差分がある場合：

```bash
mise install
```

### Step 5: パッケージインストール（Brewfile）

Step 1 の pull で `~/.Brewfile` に変更があった場合、Brewfile を元にパッケージをインストールする。

```bash
# Brewfile に変更があったか確認（pull 前後の diff）
git -C ~/.local/share/chezmoi diff HEAD~1..HEAD -- dot_Brewfile
```

差分がない場合はスキップ。差分がある場合：

```bash
brew bundle install --file=~/.Brewfile
```

インストール結果を報告する。`brew bundle install` は未インストールのパッケージのみをインストールし、既存パッケージのアップグレードは行わない。

### Step 6: 孤立ファイル検出

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

差分があるファイルを一覧表示する。

**IMPORTANT: `chezmoi diff` の出力方向**:
`chezmoi diff` は「ソース（chezmoi リポジトリ）をローカルに適用したらどうなるか」を示す。
Push モードではローカルが正（ローカルの変更を chezmoi に反映する）なので、diff の意味は**逆に読む**必要がある：
- `-` 行（赤）= chezmoi ソースにあるがローカルにない → ローカルで**削除された**
- `+` 行（緑）= ローカルにあるが chezmoi ソースにない → ローカルで**追加された**

コミットメッセージはローカル側の変更を基準に記述すること（Step 5 参照）。

### Step 1.5: 未管理ファイルの検出

chezmoi が管理対象としている各ディレクトリについて、ローカルに存在するが chezmoi 未追跡のファイルを検出する。

```bash
# スキル（.chezmoiexternal.toml で外部管理 + ~/.agents/skills/ 由来の symlink を除外）
diff <(ls ~/.claude/skills/ | sort) <(cat <(ls ~/.local/share/chezmoi/dot_claude/skills/ | sort) <(grep '^\[' ~/.local/share/chezmoi/.chezmoiexternal.toml 2>/dev/null | grep 'skills/' | sed 's/.*skills\///' | tr -d '"]') <(ls ~/.agents/skills/ 2>/dev/null) | sort -u) || true

# ルール
diff <(ls ~/.claude/rules/ | sort) <(ls ~/.local/share/chezmoi/dot_claude/rules/ | sort) || true

# ローカルスクリプト
diff <(ls ~/.local/bin/ | sort) <(ls ~/.local/share/chezmoi/dot_local/bin/ | sed 's/^executable_//' | sort) || true

# nvim プラグイン設定
diff <(ls ~/.config/nvim/lua/plugins/ | sort) <(ls ~/.local/share/chezmoi/dot_config/nvim/lua/plugins/ | sort) || true
```

未管理ファイルがあればユーザーに `chezmoi add` するか確認する。
Step 1 の `chezmoi diff` に差分がなくても、未管理ファイルがあれば続行する。
両方とも差分なし・未管理なしの場合のみ終了。

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

### Step 4: Brewfile の差分検出

Brewfile と実際の brew 状態を比較し、差分があればユーザーに提示する。

```bash
# Brewfile に記載されているが未インストール or outdated のパッケージを取得
# 出力例: "→ Cask claude-code needs to be installed or updated."
#         "→ pnpm needs to be installed or updated."
PKGS=$(brew bundle check --file=~/.Brewfile --verbose 2>&1 \
  | grep "needs to be installed" \
  | sed 's/ needs to be installed or updated\.//' \
  | sed 's/^→ Cask //' \
  | sed 's/^→ Formula //' \
  | sed 's/^→ //')

# 未インストールと outdated を分離
for pkg in $PKGS; do
  if brew list "$pkg" &>/dev/null || brew list --cask "$pkg" &>/dev/null; then
    echo "outdated: $pkg"
  else
    echo "missing: $pkg"
  fi
done

# インストール済みだが Brewfile に未記載のパッケージ（追加候補）
brew bundle cleanup --file=~/.Brewfile 2>&1
```

**IMPORTANT**: `brew bundle check` は未インストールと outdated を区別しない（両方 "needs to be installed or updated" と表示する）。
`brew list` / `brew list --cask` で実際にインストール済みか確認し、ユーザーへの表示を分ける。
Cask パッケージは `brew list` では検出できないため `brew list --cask` でもチェックする。

#### 差分がある場合

検出結果をユーザーに表示し、対応を `AskUserQuestion` で確認する：

| 差分の種類 | 選択肢 |
|-----------|--------|
| **未記載のパッケージ** | Brewfile に追加 / 無視（意図的に管理外） |
| **未インストールのパッケージ** | `brew install` する / Brewfile から削除 |
| **outdated のパッケージ** | `brew upgrade` する / スキップ（情報提示のみ） |

Brewfile に追加する場合：
1. `~/.local/share/chezmoi/dot_Brewfile` に `brew "パッケージ名"` / `cask "アプリ名"` を追加
2. サードパーティ tap が必要なら `brew info <パッケージ名>` で tap を特定し、`tap "タップ名"` も追加
3. `chezmoi apply ~/.Brewfile` でローカルにも反映

差分がなければそのまま Step 5 に進む。

### Step 5: コミット & プッシュ

```bash
git -C ~/.local/share/chezmoi add -A && git -C ~/.local/share/chezmoi status
```

コミットメッセージは日本語で、変更内容を簡潔に記述する。
**確認は取らずにそのままコミット＆プッシュする**（ユーザーが `/chezmoi-sync push` を実行した時点でプッシュの意図は明確）。

**コミットメッセージの生成ルール**:
Step 1 の `chezmoi diff` 出力を参照し、**ローカル側の変更**を基準に記述する（diff の方向に注意）。
- `chezmoi diff` の `-` 行 → ローカルで削除されたもの
- `chezmoi diff` の `+` 行 → ローカルで追加されたもの

例: diff で `-"ralph-loop@claude-plugins-official": true` と表示された場合、ローカルでは削除済みなので「ralph-loop プラグインを削除」と記述する。

```bash
git -C ~/.local/share/chezmoi commit -F - <<'EOF'
<メッセージ>
EOF
git -C ~/.local/share/chezmoi push
```

---

## Drift モード（差分レポート）

### Step 1: chezmoi diff で全体差分確認

```bash
chezmoi diff
```

### Step 2: ディレクトリ構造の比較

```bash
# スキル（.chezmoiexternal.toml で外部管理 + ~/.agents/skills/ 由来の symlink を除外）
diff <(ls ~/.claude/skills/ | sort) <(cat <(ls ~/.local/share/chezmoi/dot_claude/skills/ | sort) <(grep '^\[' ~/.local/share/chezmoi/.chezmoiexternal.toml 2>/dev/null | grep 'skills/' | sed 's/.*skills\///' | tr -d '"]') <(ls ~/.agents/skills/ 2>/dev/null) | sort -u) || true

# ルール
diff <(ls ~/.claude/rules/ | sort) <(ls ~/.local/share/chezmoi/dot_claude/rules/ | sort) || true

# ローカルスクリプト
diff <(ls ~/.local/bin/ | sort) <(ls ~/.local/share/chezmoi/dot_local/bin/ | sed 's/^executable_//' | sort) || true

# nvim プラグイン設定
diff <(ls ~/.config/nvim/lua/plugins/ | sort) <(ls ~/.local/share/chezmoi/dot_config/nvim/lua/plugins/ | sort) || true
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

# ローカルスクリプト
diff \
  <(cd ~/.local/bin && find . -type f -exec md5 {} \; | sort) \
  <(cd ~/.local/share/chezmoi/dot_local/bin && find . -type f -exec md5 {} \; | sed 's/executable_//' | sort) || true
```

### Step 4: Brewfile の差分検出

Brewfile と実際の brew 状態を比較する。

```bash
# Brewfile に記載されているが未インストール or outdated のパッケージを取得
PKGS=$(brew bundle check --file=~/.Brewfile --verbose 2>&1 \
  | grep "needs to be installed" \
  | sed 's/ needs to be installed or updated\.//' \
  | sed 's/^→ Cask //' \
  | sed 's/^→ Formula //' \
  | sed 's/^→ //')

# 未インストールと outdated を分離
for pkg in $PKGS; do
  if brew list "$pkg" &>/dev/null || brew list --cask "$pkg" &>/dev/null; then
    echo "outdated: $pkg"
  else
    echo "missing: $pkg"
  fi
done

# インストール済みだが Brewfile に未記載のパッケージ（追加候補）
brew bundle cleanup --file=~/.Brewfile 2>&1
```

レポートの「差分あり」セクションに結果を含める。

### Step 5: 外部管理スキルの確認

```bash
grep -A2 '^\[' ~/.local/share/chezmoi/.chezmoiexternal.toml
```

外部管理のスキルはローカルにのみ存在して正常。

### Step 6: chezmoi ソースリポジトリの状態

```bash
git -C ~/.local/share/chezmoi status && git -C ~/.local/share/chezmoi log --oneline -5
```

### Step 7: レポート出力

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
- scripts (.local/bin): N/N
- nvim plugins: N/N

### 推奨アクション
- `/chezmoi-sync push` で変更を反映
```
