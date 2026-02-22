---
name: implementation
description: "Use when executing an approved implementation plan - manages branch, TDD, review, and commit workflow"
allowed-tools: ["Skill", "Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "AskUserQuestion"]
---

# Implementation Skill

Plan モードで承認された計画に基づいてコードを変更する際のワークフロー。

## When to Use

- `/implementation` コマンドを実行
- Plan モードで計画が承認された後（plan-mode.md Phase 4 の ExitPlanMode 後）
- 「計画に沿って実装して」「実装フェーズに入って」と依頼

## 実装フロー

### Step 0: 計画ファイル保存 + 作業ブランチ作成

計画が承認されたら、最初に実行するステップ。

#### 作業ブランチの作成

```bash
# ベースブランチを最新化（Phase 0 で確認済みの状態を前提）
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
git checkout $DEFAULT_BRANCH && git pull origin $DEFAULT_BRANCH

# 作業ブランチを作成
git checkout -b <prefix>/<slug>
```

#### ブランチ命名規則

| prefix | 用途 | 例 |
|--------|------|-----|
| `feature/` | 新機能追加 | `feature/user-auth` |
| `fix/` | バグ修正 | `fix/login-redirect` |
| `refactor/` | リファクタリング | `refactor/api-layer` |
| `chore/` | CI, docs, 依存更新等の雑務 | `chore/ci-workflow` |

slug はケバブケースで簡潔に。計画の内容から適切な prefix と slug を選択する。

#### 計画ファイルの保存

プロジェクトに `docs/plan/` がある場合、承認された計画をバージョニングして保存する。

---

### Step 1: ガードレール先行

個別タスクの実装に入る前に、プロジェクト全体のガードレールを整備する。

- 型定義・スキーマ定義を先に作成（計画の I/O シグネチャに基づく）
- テスト環境の確認（テストランナー、テストダブルの準備）

> 個別タスクのテスト作成は `/TDD` スキル内で行う。ここではプロジェクト全体の基盤を整備する。

---

### Step 2: タスク単位で TDD 実装

計画の各タスクを `/TDD` スキルで実装する。

- タスクの**受入条件**を TDD のテストリスト（Phase 1）として使用する
- `/TDD` の Phase 0（終了条件）は計画のタスク定義から導出する
- 独立したタスクが複数ある場合は `Task` ツールで並列実行を検討
- 各タスク完了時に `AskUserQuestion` でユーザーの確認を取る
- **ユーザーの OK なしに次タスクへ進まない**
- 確認時には変更差分・テスト結果など具体的な情報を提示する

> `/TDD` の各サイクルで型チェック・リント・テスト実行が行われる（VERIFY ループ）。

---

### Step 3: レビュー

全タスク完了後、変更ファイルを特定してレビューを実行する。

#### 3-1. 変更ファイルの特定

```bash
git diff --name-only HEAD
git diff --name-only --cached
git ls-files --others --exclude-standard
```

変更ファイル一覧をユーザーに提示する。

#### 3-2. /naming-review（常に実行）

変更されたソースファイル（テストファイル除外）を対象に `/naming-review` を実行する。
Critical/Major の指摘があればユーザーに報告し、修正するか確認する。

#### 3-3. /ui-check（UI 変更時のみ）

変更ファイルに UI コンポーネント（`.tsx`, `.jsx`, `.vue`, `.svelte` 等）が含まれる場合のみ実行。
該当ファイルがなければスキップし、スキップした旨を明記する。

#### 3-4. /security-review（常に実行）

変更ファイルを対象に `/security-review` を実行する。
Critical 指摘がある場合は後続ステップをブロックし、修正を求める。

> レビューで Critical/Major 指摘があり修正した場合、Step 4 の検証を再実行する。

---

### Step 4: 検証 → コミット → PR 作成

#### 4-1. 全体の整合性確認

プロジェクトの検証コマンドを実行する。以下の優先順で検出:

1. `package.json` の scripts に `typecheck`, `lint`, `test` があれば実行
2. なければ一般的なコマンド（`tsc --noEmit`, `eslint`, `vitest run` 等）を試行

```bash
pnpm typecheck && pnpm lint && pnpm test
```

**実際のコマンド出力を提示する。証拠なき「通りました」は禁止。**

#### 4-2. 開発サーバーの停止確認

検証のために起動した開発サーバーが残っていないか確認する。

```bash
lsof -i :8787 -i :8788 -i :5173 -i :3000 -P 2>/dev/null | grep LISTEN
```

残っている場合はポート指定で停止: `lsof -ti :{port} | xargs kill`

#### 4-3. 結果サマリーとコミット方法確認

全 Step の結果をまとめて提示する。

```markdown
## 完了前検証サマリー

| Step | 結果 |
|------|------|
| naming-review | ✅ 問題なし / ⚠️ N件の指摘（修正済み） |
| ui-check | ✅ 問題なし / ⏭️ スキップ（UI変更なし） |
| security-review | ✅ 問題なし / ⚠️ N件の指摘（修正済み） |
| typecheck | ✅ |
| lint | ✅ |
| test | ✅ N tests passed |
| 開発サーバー | ✅ 停止済み / ✅ 起動なし |
```

AskUserQuestion でコミット方法を確認:
- コミットのみ
- コミット + プッシュ
- コミット + プッシュ + PR 作成
- コミットしない（変更のみ残す）

#### 4-4. PR 作成（選択時）

```bash
git push -u origin <branch-name>
gh pr create --title "<タイトル>" --body "<本文>"
```

- PR タイトルは70文字以内、変更内容を簡潔に
- 本文には `## Summary`（箇条書き）と `## Test plan`（検証チェックリスト）を含める
- Step 0 で作成した作業ブランチからデフォルトブランチ向けに作成する

---

### Step 5: セッション後の振り返り

ユーザーが完了を確認した後、`/session-retrospective` を実行する。

6つの観点（ドメイン知識・技術的学び・自動化機会・既存知識の更新・プロジェクト CLAUDE.md・較正の妥当性）で
セッションを1回で振り返り、保存先を振り分ける。

> ユーザー承認なしに保存しない。提案のみ行い、不要なら即スキップ。

## 注意事項

- Step 3 で Critical 指摘があり修正した場合、Step 4 を再実行する
- CLAUDE.md にプロジェクト固有の検証手順がある場合はそれも実行する
- レビューはレビュー+検証のみ。コード編集は各レビュースキルの指摘に基づいてユーザー承認後に行う
