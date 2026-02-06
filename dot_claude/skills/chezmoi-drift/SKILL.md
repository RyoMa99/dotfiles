---
name: chezmoi-drift
description: ローカルの~/.claude/とchezmoiの状態を比較し、差分を検出する。定期メンテナンス用。
user-invocable: true
disable-model-invocation: true
allowed-tools: ["Bash", "Glob", "Read", "AskUserQuestion"]
---

# Chezmoi Drift Detection

ローカルの `~/.claude/` と chezmoi ソースの整合性をチェックする。

## When to Use

- `/chezmoi-drift` コマンドを実行
- 定期メンテナンス時
- 「chezmoi と同期できてる？」と聞かれた時

## 実行フロー

### Step 1: スキルディレクトリの比較

```bash
# ローカルのスキル一覧
ls ~/.claude/skills/ | sort > /tmp/local-skills.txt

# chezmoiのスキル一覧
ls ~/.local/share/chezmoi/dot_claude/skills/ | sort > /tmp/chezmoi-skills.txt

# 差分
diff /tmp/local-skills.txt /tmp/chezmoi-skills.txt
```

ローカルにあって chezmoi にないものは、外部スキル（`.chezmoiexternal.toml`）か未同期。

### Step 2: ルールディレクトリの比較

```bash
ls ~/.claude/rules/ | sort > /tmp/local-rules.txt
ls ~/.local/share/chezmoi/dot_claude/rules/ | sort > /tmp/chezmoi-rules.txt
diff /tmp/local-rules.txt /tmp/chezmoi-rules.txt
```

### Step 3: ファイル内容の比較

```bash
# 全 .md ファイルのハッシュを比較
diff \
  <(cd ~/.claude/skills && find . -name "*.md" -exec md5 {} \; | sort) \
  <(cd ~/.local/share/chezmoi/dot_claude/skills && find . -name "*.md" -exec md5 {} \; | sort)
```

ルールも同様に比較。

### Step 4: 外部スキルの確認

```bash
grep -A2 '^\[' ~/.local/share/chezmoi/.chezmoiexternal.toml
```

外部管理のスキルはローカルにのみ存在して正常。

### Step 5: 結果レポート

```markdown
## Chezmoi Drift Report

### 差分あり（要対応）
- `skills/xxx` - ローカルにあるが chezmoi にない（chezmoi add が必要）
- `rules/yyy.md` - 内容が異なる（chezmoi add で更新）

### 外部管理（正常）
- `skills/notebooklm` - .chezmoiexternal.toml で管理

### 同期済み
- skills: 15/15
- rules: 12/12
```

### Step 6: 修正提案

差分がある場合、`chezmoi add` + コミット + プッシュを提案。
