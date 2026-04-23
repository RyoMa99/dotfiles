---
name: dependabot-review
description: "Dependabot が作成した PR をローカルから一括レビュー・マージするスキル。実行ディレクトリのリポジトリに対して走査する。`/dependabot-review` で起動。Dependabot PR の棚卸し、依存アップデートの一括処理、セキュリティアップデートの確認にも使う。"
argument-hint: "[patch|minor|major|all]"
allowed-tools: ["Bash(gh:*)", "Bash(git:*)", "Bash(jq:*)", "Grep", "Glob", "Read", "WebFetch", "AskUserQuestion"]
---

# Dependabot PR Review

実行ディレクトリのリポジトリにある Dependabot PR を一つずつレビューし、更新種別に応じた戦略で処理する。

## 戦略

| 更新種別 | 動作 |
|---------|------|
| **patch** | diff を軽く確認 → `gh pr review --approve` → `gh pr merge --auto --merge` |
| **minor** | diff + リリースノートをレビュー → 問題なければ approve + merge、懸念があればコメントのみ |
| **major** | diff + リリースノート + breaking changes を精査 → `gh pr comment` でレビューコメントのみ（マージしない） |

## 実行フロー

### 1. 対象リポジトリの特定と PR の収集

```bash
# カレントディレクトリのリポジトリを特定（以降すべての gh コマンドで -R を使用）
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

# 対象 PR を収集
gh pr list -R "$REPO" --author "app/dependabot" --state open --json number,title,labels,body
```

以降のすべての `gh` コマンドは `-R "$REPO"` を付けて実行する。

引数でフィルタ可能:
- `$ARGUMENTS` が `patch` / `minor` / `major` → その種別のみ処理
- `$ARGUMENTS` が `all` または未指定 → 全件処理

### 2. 各 PR の更新種別を判定

PR タイトルから semver 更新種別を判定する。タイトルの `from X.Y.Z to A.B.C` を抽出し、各桁を比較する:
- メジャーが異なる（X ≠ A）→ **major**
- メジャーが同じでマイナーが異なる（X = A, Y ≠ B）→ **minor**
- メジャー・マイナーが同じでパッチが異なる（X = A, Y = B, Z ≠ C）→ **patch**

判定できない場合は **major**（最も慎重な戦略）にフォールバックする。

### 3. PR ごとにレビュー実行

各 PR について以下の手順を**この順序で**実行する:

#### Step 1: 情報収集

```bash
# diff を取得
gh pr diff <number>

# PR の詳細（body にリリースノートが含まれることが多い）
gh pr view <number>

# CI ステータスを確認
gh pr checks <number>
```

#### Step 2: レビュー判断

**確認観点（全種別共通）:**
- リリースノート / コミットログから変更内容を把握する（patch でも省略しない）
- 変更された関数・メソッド・型・設定がプロジェクト内で使用されているか Grep で確認する
  - 使用している場合: 互換性に問題がないか確認し、コメントに「使用箇所: ファイル:行」を記載
  - 使用していない場合: コメントに「本プロジェクトでは未使用」と明記
- lockfile の差分が妥当か
- 依存パッケージのバージョン制約に矛盾がないか

**minor 以上で追加確認:**
- CHANGELOG / リリースノートに breaking change が含まれていないか（minor でも含まれるケースがある。例: Terraform provider）
- breaking change がある場合、プロジェクト内で該当リソース/API を使用しているか grep で確認
- API の非互換変更の有無
- Deprecation 警告の有無

**major で追加確認:**
- マイグレーションガイドの有無
- 自プロジェクトでの使用箇所への影響（変更された全 API について grep で網羅確認）

PR body に含まれる Dependabot のリリースノート抜粋を活用する。情報が不足している場合は、パッケージの GitHub リリースページを `gh` や `WebFetch` で確認してもよい。

#### Step 3: アクション実行

> **コメント投稿の書式**: 複数行・Markdown を含むレビューコメントは `--body-file -` で stdin から渡す。`--body` は単一行の文字列用フラグで、`--body "..."` にサブシェル `$(...)` や heredoc を埋め込むとクォートの扱いが壊れやすい。`--body -` と書くと **フラグ引数として「-」1 文字が渡り、本文が破損する**（エラーは出ないので見逃しやすい）。詳細は「注意事項」参照。

**patch の場合:**
```bash
gh pr comment <number> --body-file - <<'EOF'
<レビュー結果のサマリ（Markdown 可）>
EOF
gh pr review <number> --approve
gh pr merge <number> --auto --merge
# auto merge が無効なリポジトリでは失敗する → approve のみで止め、ユーザーに報告
```

**minor で問題なしの場合:**
```bash
gh pr comment <number> --body-file - <<'EOF'
<レビュー結果のサマリ（Markdown 可）>
EOF
gh pr review <number> --approve
gh pr merge <number> --auto --merge
# auto merge が無効なリポジトリでは失敗する → approve のみで止め、ユーザーに報告
```

**minor で懸念ありの場合:**
```bash
gh pr comment <number> --body-file - <<'EOF'
<懸念点の詳細>
EOF
```
→ マージしない。ユーザーに判断を委ねる。

**major の場合:**
```bash
gh pr comment <number> --body-file - <<'EOF'
<詳細なレビューコメント>
EOF
```
→ マージしない。approve もしない。

### 4. サマリ報告

全 PR の処理後、結果をテーブルで報告する:

```
| # | タイトル | 種別 | アクション | 備考 |
|---|---------|------|----------|------|
| 42 | Bump foo from 1.0.0 to 1.0.1 | patch | approved + merged | |
| 43 | Bump bar from 1.2.0 to 1.3.0 | minor | approved + merged | リリースノート確認済 |
| 44 | Bump baz from 2.0.0 to 3.0.0 | major | commented | breaking changes あり |
```

## コメントのフォーマット

レビューコメントは日本語で記述する。**全種別で「変更内容」セクションを必ず含める**。コメントを読んだ人がリリースノートを見に行かなくても何が変わったか把握できるようにする。

```markdown
## Dependabot Review

**種別**: patch / minor / major
**パッケージ**: <name> <old-version> → <new-version>

### 変更内容

- [ リリースノート / コミットログから主な変更を要約 ]
- [ Breaking changes がある場合は明記 ]
- [ Deprecations がある場合は明記 ]

### プロジェクト内の使用箇所

- [ パッケージの import 箇所と使用している API を列挙 ]
- [ 変更された関数・型が使用されているか: 使用あり → ファイル:行 / 未使用 ]
- [ 間接依存の場合はその旨を明記 ]

### 確認結果

- [ 確認した観点と結果 ]
- [ Breaking change がある場合: プロジェクトでの使用有無を grep で確認した結果 ]

### 判断

[ approve / コメントのみ の理由 ]
```

## 注意事項

- **CI 失敗時**: 種別に関わらず approve・merge しない。失敗している check 名とエラー概要を `gh pr comment` で報告し、次の PR に進む
- `--auto` フラグを使うため、branch protection rules の required checks を通過するまで実際のマージは発生しない
- **Auto merge 無効時**: `gh pr merge --auto` が `Pull request Auto merge is not allowed for this repository` で失敗した場合、approve のみ実行しマージはスキップする。サマリ報告で「Auto merge 無効のため approve のみ。リポジトリの Settings > General > Allow auto-merge の有効化を推奨」と報告する
- 同一パッケージの複数バージョン更新がある場合、最新の PR のみ処理し、古い PR はスキップする
- **同一 lockfile のコンフリクト**: 同じ `go.mod` / `package.json` 等を変更する PR は、1件マージすると残りがコンフリクトする。全件に `--auto` をセットしておけば Dependabot が自動 rebase → CI 再走 → 順次マージしてくれる。長時間 rebase されない場合のみ `@dependabot rebase` を手動コメントする
- **`gh pr comment` の stdin 読み込み**: 長文・複数行のコメント本文は `--body-file -` + heredoc で渡す。`--body` は単一行文字列用のフラグ。誤って `--body -` と書くと **フラグ値として「-」1 文字が渡り、本文が壊れる**（エラーは出ず投稿も成功するため発見が遅れる）。投稿後に `gh api /repos/{owner}/{repo}/issues/comments/{id} -q '.body'` で本文を検証することを推奨
  - ❌ BAD: `gh pr comment 42 --body - <<'EOF' ... EOF`（本文が「-」になる）
  - ❌ BAD: `gh pr comment 42 --body "$(cat <<'EOF' ... EOF)"`（heredoc ネストでパース不具合）
  - ✅ GOOD: `gh pr comment 42 --body-file - <<'EOF' ... EOF`
- **投稿後の検証**: 長文コメント投稿後は URL を出力した後に `gh api /repos/{owner}/{repo}/issues/comments/{id} -q '.body' | head -5` で本文先頭を確認し、破損がないかチェックする習慣を付ける
