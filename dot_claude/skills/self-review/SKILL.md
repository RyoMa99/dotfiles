---
name: self-review
description: "アドホック実装後のセルフレビュー＋自動修正スキル。複数のレビュアー（Claude subagent, CodeRabbit, Copilot, Gemini）を並列実行し、指摘を批判的に精査した上で妥当なものだけ自動修正する。`/self-review` で実行。「レビューして」「セルフレビュー」「実装を見直して」「コード改善して」など、アドホックに書いたコードの品質改善を求められた時に使う。Plan モード→/implementation の正規フローを経ずに実装した場合に特に有効。"
argument-hint: "[レビュー対象] [reviewer名...]"
user_invocable: true
allowed-tools: ["Bash(git:*)", "Bash(gh:*)", "Bash(copilot:*)", "Bash(gemini:*)", "Read", "Edit", "Write", "Glob", "Grep", "Agent", "Skill(coderabbit:review)"]
---

# Self-Review

複数の異なる視点を持つレビュアーで並列レビューし、指摘を批判的に精査して妥当なものだけ自動修正する。

レビュアーの指摘は必ずしも正しくない。的外れな指摘を鵜呑みにすると品質が逆に下がるため、「生成（レビュー）」と「評価（精査）」を分離する。

## ステップ 1: 引数の解釈

$ARGUMENTS を以下のルールで解釈する:

- 第一引数: レビュー対象（省略時は `diff`）
- 第二引数以降: reviewer名（省略時は全 reviewer を並列実行）

### レビュー対象の指定方法

| 指定 | 取得方法 |
|------|---------|
| 指定なし / `diff` | `git diff` + `git ls-files --others --exclude-standard` |
| `staged` | `git diff --cached` |
| `branch` | `git diff origin/main...HEAD` |
| `PR #123` / `pr 123` | `gh pr diff 123` |

### 利用可能な reviewer

| 名前 | 説明 |
|------|------|
| `reviewer` | Claude subagent — `robust-code.md` / `layered-architecture.md` ベースの設計・品質レビュー |
| `coderabbit` | CodeRabbit AI — 外部コードレビューサービス |
| `copilot` | GitHub Copilot CLI — GitHub の AI によるレビュー |
| `gemini` | Gemini CLI — Google の AI によるレビュー |

reviewer 名が上記に一致しない場合は、利用可能な名前を案内する。

## ステップ 2: レビュー実行

reviewer 名が指定された場合はそのレビュアーのみ、省略された場合は全レビュアーを**同時に並列起動**する。

各レビュアーの起動方法は `agents/` ディレクトリ内の対応ファイルを参照:

- `reviewer` → @agents/reviewer.md を読み、Agent ツールで subagent を起動
- `coderabbit` → @agents/coderabbit-reviewer.md を読み、`coderabbit:review` スキルを実行
- `copilot` → @agents/copilot-reviewer.md を読み、Agent ツールで subagent を起動（Bash で copilot CLI を実行）
- `gemini` → @agents/gemini-reviewer.md を読み、Agent ツールで subagent を起動（Bash で gemini CLI を実行）

各レビュアーには「レビュー対象の差分情報」を渡す。

### 差分の渡し方

- **tracked ファイルの変更**: `git diff` の出力をそのまま渡す
- **untracked ファイル（新規追加）**: `git diff` では取得できないため、`git ls-files --others --exclude-standard` でファイル一覧を取得し、各ファイルの内容を直接読み込んで渡す。subagent には Read ツールでファイルを読むよう指示する

### レビュアー失敗時のリトライ

レビュアーが失敗した場合（権限エラー、CLI 未インストール、タイムアウト等）:

1. **即座にリトライを試みる**: エラー内容を確認し、回避可能なら修正して再実行する（例: フラグ修正、パスの修正）
2. **リトライ不可なら代替手段を試す**: CLI が使えない場合、ファイル内容を直接 subagent に渡して Agent ツール内でレビューさせる
3. **それでも失敗したら、失敗した旨をサマリーに記載して残りのレビュアーの結果で続行する**

失敗を通知だけして放置しない。最低1回はリカバリーを試みる。

## ステップ 3: レビュー指摘の批判的精査と修正

全レビュアーの完了後（またはリトライ含め全レビュアーが確定後）、以下のフローで指摘を処理する。

### 3-1. 指摘の一覧化

全レビュアーの指摘を統合し、一覧化する。重複する指摘（複数レビュアーが同じ問題を指摘）はマージする。

### 3-2. 各指摘の妥当性を評価

各指摘に対して以下の観点で批判的に評価する:

- **技術的に正しいか**: 指摘の根拠は正確か、誤解に基づいていないか
- **プロジェクトの方針と合致するか**: `CLAUDE.md`、`robust-code.md`、`layered-architecture.md` の設計方針に照らして妥当か
- **意図的な設計ではないか**: 要件やアーキテクチャ上の理由で意図的にその実装にしている可能性
- **修正のリスク**: 修正によって新たな問題（既存テストの破壊、挙動変更）が発生しないか
- **費用対効果**: 修正の労力に対して得られる品質改善が十分か

### 3-3. 修正の実行

妥当と判断した指摘のみ修正を実施する。修正後、変更が既存テストを壊していないか確認する（テストランナーが利用可能な場合）。

### 3-4. サマリー出力

修正完了後、以下の形式でサマリーを出力する。サマリーの目的は「修正判断が適切だったかをユーザーがダブルチェックできること」。

各指摘について以下の 3 点を記載する:

1. **見出し**: 「レビュアー名 #番号: 指摘の要点」— 複数レビュアーが同じ指摘をしている場合は「reviewer #1 / gemini #3」のようにスラッシュで併記
2. **指摘内容**: レビュアーが何を問題視したか
3. **修正内容 or 対応しない理由**: 何をどう変えたか、またはなぜ対応不要と判断したかの根拠

```markdown
## セルフレビュー結果

### 対応した指摘

#### reviewer #1 / copilot #2: [指摘の要点]
- **指摘内容**: ...
- **修正内容**: ...

### 対応しなかった指摘

#### gemini #1: [指摘の要点]
- **指摘内容**: ...
- **対応しない理由**: ...
```
