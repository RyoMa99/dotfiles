---
name: tmuxinator
description: "Use when modifying tmuxinator configurations - adding/removing/editing windows, changing pane ratios, or updating pane commands"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Glob", "AskUserQuestion"]
---

# Tmuxinator Configuration Skill

tmuxinator の設定ファイル（`~/.config/tmuxinator/*.yml`）を編集する。

## When to Use This Skill

Trigger when user:
- `/tmuxinator` コマンドを実行
- 「tmux の設定を変更して」「window を追加して」「ペイン比率を変えて」と依頼
- tmuxinator の yml について言及

## 設定ファイルの場所

```
~/.config/tmuxinator/*.yml
```

## 実行フロー

### Step 1: 対象ファイルの特定

引数でファイル名が指定されていればそれを使う。なければ一覧を表示して選択させる。

```bash
ls ~/.config/tmuxinator/*.yml
```

### Step 2: 現在の設定を読み込み

対象ファイルを Read で読み込み、現在の構成を把握する。

### Step 3: ユーザーの指示に応じて編集

Edit ツールで yml を修正する。

### Step 4: 変更確認

変更後の yml 全体を表示し、ユーザーに確認する。

### Step 5: debug で検証

```bash
tmuxinator debug <session-name>
```

生成されたシェルスクリプトを確認し、意図通りか検証する。

## 重要な制約（tmuxinator 3.x）

### post キーは使わない

**CRITICAL**: tmuxinator 3.3+ では window レベルの `post` キーが無視される。リサイズコマンドは実行されない。

### ペイン比率の制御方法

`layout: main-vertical` + `on_project_start` で `main-pane-width` を設定する。

```yaml
# GOOD: 確実に動作する
on_project_start: tmux set-option -g main-pane-width 90%

windows:
  - main:
      layout: main-vertical
      panes:
        - claude
        - nvim
```

```yaml
# BAD: post は無視される
windows:
  - main:
      layout: main-vertical
      panes:
        - claude
        - nvim
      post: tmux resize-pane -t 0 -x 90%  # ← 実行されない
```

### 比率の指定

ユーザーが「8:2」「9:1」のように指定した場合、左ペインのパーセンテージに変換する:

| 指定 | main-pane-width |
|------|-----------------|
| 9:1  | 90%             |
| 8:2  | 80%             |
| 7:3  | 70%             |

### レイアウトの種類

| レイアウト | 用途 |
|-----------|------|
| `main-vertical` | 左右分割（左がメイン）。`main-pane-width` で比率制御 |
| `main-horizontal` | 上下分割（上がメイン）。`main-pane-height` で比率制御 |
| `tiled` | 均等タイル配置 |
| `even-horizontal` | 均等左右分割 |
| `even-vertical` | 均等上下分割 |

### window 固有の root

window ごとに異なるディレクトリを設定できる:

```yaml
root: ~/  # セッション全体のデフォルト

windows:
  - main:
      panes:
        - claude
  - project:
      root: ~/repo/my-project  # この window だけ別ディレクトリ
      panes:
        - nvim
```

## yml の構造テンプレート

```yaml
name: <session-name>
root: <default-directory>

on_project_start: tmux set-option -g main-pane-width <percentage>

windows:
  - <window-name>:
      layout: main-vertical
      panes:
        - <command-1>
        - <command-2>
```

## 操作パターン

### Window 追加

既存の `windows:` リストの末尾に追加する。

### Window 削除

対象の window ブロックを yml から削除する。

### ペイン変更

`panes:` リスト内のコマンドを変更する。空ペイン（シェル起動のみ）は `-` で表記。

### 比率変更

`on_project_start` の `main-pane-width` の値を変更する。

## 注意事項

- 編集後は `tmuxinator debug <name>` で必ず検証する
- セッションが既に起動中の場合、変更を反映するには `tmuxinator stop <name> && tmuxinator start <name>` が必要
- `on_project_start` の `main-pane-width` はグローバル設定（`-g`）なので、複数セッションで異なる比率が必要な場合は最後に起動したセッションの値が適用される
