---
name: implementation
description: "Use when executing an approved implementation plan in the current session"
allowed-tools: ["Skill", "Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "AskUserQuestion"]
---

# Implementation Skill

Plan モードで承認された計画に基づいてコードを変更する際のワークフロー。

関連: `artifacts.md`（成果物の耐久性と管理方針）

## When to Use

- `/implementation` コマンドを実行
- Plan モードで計画が承認された後（plan-mode.md Phase 4 の ExitPlanMode 後）
- 「計画に沿って実装して」「実装フェーズに入って」と依頼

## 実装フロー

### Step 0: 作業ブランチ作成 + 計画ファイルコミット

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

#### 計画ファイルのコミット

計画ファイルを `docs/plan/` に保存し、実装前のスナップショットとしてコミットする。
git 履歴に残すことで、後から「何を計画して実装したか」を追跡できる。

```bash
git add docs/plan/
git commit -m "plan: [計画タイトル]"
```

> 計画ファイルは実装完了後に削除する（Step 4-4 参照）。削除後も `git log --diff-filter=D -- docs/plan/` で履歴を追える。

---

### Step 1: ガードレール先行

個別タスクの実装に入る前に、プロジェクト全体のガードレールを整備する。

- 型定義・スキーマ定義を先に作成（計画の I/O シグネチャに基づく）
- テスト環境の確認（テストランナー、テストダブルの準備）

> 個別タスクのテスト作成は `/TDD` スキル内で行う。ここではプロジェクト全体の基盤を整備する。

---

### Step 2: タスク単位で TDD 実装

計画の各タスクを依存関係に基づく順序で実装する。

#### タスク実行前の準備

- タスクに**リスク・軽減策**がある場合、TDD サイクルに入る前にセットアップする（例: ロールバック手順の準備、バックアップ、フィーチャーフラグの設置）
- タスクの**依存関係**に基づき実行順序を決定する。依存先タスクが完了するまで着手しない

#### 通常タスク → `/TDD` で実装

- タスクの**受入条件**を TDD のテストリスト（Phase 1）として使用する
- `/TDD` の Phase 0（終了条件）は計画のタスク定義（変更対象・I/O シグネチャ含む）から導出する

#### Spike タスク → TDD を適用しない

計画に Spike タスク（時間制限付き調査、成果物は判断材料）がある場合、TDD ではなく調査・検証を実施する。結果をユーザーに報告し、後続タスクへの影響を判断する。

#### 計画外の設計判断が発生した場合

実装中に計画になかった設計判断を迫られた場合（技術的制約の発見、想定外のエッジケース等）、判断が不可逆または複数選択肢の比較を伴うなら `/adr` での記録を提案する。

#### 共通

- 独立したタスクが複数ある場合は `Task` ツールで並列実行を検討
- 各タスク完了時に `AskUserQuestion` でユーザーの確認を取る
- 各タスク完了時にユーザーの OK を得てから次へ進む（手戻りコストを最小化するため）
- 確認時には変更差分・テスト結果など具体的な情報を提示する

> `/TDD` の各サイクルで型チェック・リント・テスト実行が行われる（VERIFY ループ）。

---

### Step 3: レビュー + コード簡素化

全タスク完了後、`/review` → `/simplify` の順で実行する。

#### 3-1. `/review`（読み取り専用）

`/review` は以下を一括実行する:
1. 変更ファイルの特定（git diff）
2. Naming Review（常に実行）
3. UI Check（UI 変更時のみ）
4. Security Review（常に実行）

Critical/Major の指摘があればユーザーに報告し、修正するか確認する。
Critical 指摘がある場合は `/simplify` に進まず、修正を先に行う。

#### 3-2. コミット（push しない）

`/review` の指摘が解消された後、`/simplify` に入る前に現時点の変更をコミットする。
`/simplify` の自動修正が意図しない結果になった場合に `git reset` で戻せるようにするため。

```bash
git add <変更ファイル>
git commit -m "feat: [タスク内容の要約]"
# push はしない
```

#### 3-3. `/simplify`（自動修正あり）

コミット後、`/simplify` を実行する。

`/simplify` は3つの並列エージェントで変更差分を分析し、問題を自動修正する:
1. Code Reuse Review（既存ユーティリティとの重複検出）
2. Code Quality Review（冗長な状態、コピペ、抽象化漏れ等）
3. Efficiency Review（不要な計算、並列化の見落とし、メモリリーク等）

> `/review` で修正 → `/simplify` で修正 → Step 4 で検証、の流れにより安全に品質を担保する。

---

### Step 4: 検証 → コミット → PR 作成

#### 4-1. 全体の整合性確認

プロジェクトの検証コマンドを実行する。以下の優先順で検出:

1. `package.json` の scripts に `typecheck`, `lint`, `test` があれば実行
2. なければ一般的なコマンド（`tsc --noEmit`, `eslint`, `vitest run` 等）を試行

```bash
pnpm typecheck && pnpm lint && pnpm test
```

実際のコマンド出力を提示する（出力があることで、検証が確実に実施されたことを確認できる）。

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
| simplify | ✅ クリーン / ⚠️ N件修正済み |
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

PR 作成時、計画の内容を PR description の `## Plan` セクションに統合する。
これにより計画ファイルを永続的に保持する必要がなくなる（`artifacts.md` 参照）。

```bash
# 計画ファイルを削除（git 履歴には Step 0 のコミットで残っている）
git rm -r docs/plan/ 2>/dev/null && git commit -m "chore: 計画ファイルを削除（実装完了）"

git push -u origin <branch-name>
gh pr create --title "<タイトル>" --body "<本文>"
```

- PR タイトルは70文字以内、変更内容を簡潔に
- 本文には以下を含める:

```markdown
## Summary
- [変更内容の箇条書き]

## Plan
- **ゴール**: [計画のゴール]
- **タスク性質**: [探索的 / 既知パターン / 高リスク]
- **関連要件**: REQ-xxx（RDRA がある場合）

### タスク一覧
1. [タスク名]: [概要]
2. ...

## Test plan
- [検証チェックリスト]
```

- Step 0 で作成した作業ブランチからデフォルトブランチ向けに作成する

---

### Step 5: セッション後の振り返り

ユーザーが完了を確認した後、`/session-retrospective` を実行する。

7つの観点（ドメイン知識・技術的学び・自動化機会・既存知識の更新・プロジェクト CLAUDE.md・較正の妥当性・設計負債）で
セッションを1回で振り返り、保存先を振り分ける。

> ユーザー承認なしに保存しない。提案のみ行い、不要なら即スキップ。

## 注意事項

- Step 3 で `/review` の Critical 指摘があり修正した場合、`/simplify` から再開する
- Step 3 で `/simplify` がコードを修正した場合、Step 4 の検証で安全性を確認する
- CLAUDE.md にプロジェクト固有の検証手順がある場合はそれも実行する
- `/review` は読み取り専用（指摘のみ）。コード編集はユーザー承認後に行う
- `/simplify` は自動修正あり。修正結果は Step 4 の typecheck/lint/test で検証される
