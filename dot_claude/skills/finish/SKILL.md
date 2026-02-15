---
name: finish
description: 実装完了前の検証を一括実行。naming-review → ui-check → テスト・型チェック・lint → 開発サーバー停止 → コミット方法確認。implementation.md Step 3-4 を自動化。
allowed-tools: ["Skill", "Bash", "Glob", "Grep", "Read", "AskUserQuestion"]
---

# Finish Skill

implementation.md Step 3-4（完了前検証 → コミット方法確認）を一括実行するオーケストレーター。

## When to Use

- 全タスクの実装が完了し、コミット前の最終検証を行うとき
- `/finish` コマンド

## 実行フロー

### Step 1: 変更ファイルの特定

```bash
git diff --name-only HEAD
git diff --name-only --cached
git ls-files --others --exclude-standard
```

変更ファイル一覧をユーザーに提示する。

### Step 2: /naming-review（常に実行）

変更ファイルを対象に `/naming-review` を実行する。

```
Skill: naming-review
引数: 変更されたソースファイル（テストファイルは除外）
```

Critical/Major の指摘があればユーザーに報告し、修正するか確認する。

### Step 3: /ui-check（UI 変更時のみ）

変更ファイルに UI コンポーネント（`.tsx`, `.jsx`, `.vue`, `.svelte` 等）が含まれる場合のみ実行。

```
Skill: ui-check
引数: 変更された UI ファイル
```

該当ファイルがなければスキップし、スキップした旨を明記する。

### Step 4: 全体の整合性確認

プロジェクトの検証コマンドを実行する。以下の優先順で検出:

1. `package.json` の scripts に `typecheck`, `lint`, `test` があれば実行
2. なければ一般的なコマンド（`tsc --noEmit`, `eslint`, `vitest run` 等）を試行

```bash
pnpm typecheck && pnpm lint && pnpm test
```

**実際のコマンド出力を提示する。証拠なき「通りました」は禁止。**

### Step 5: 開発サーバーの停止確認

検証のために起動した開発サーバーが残っていないか確認する。

```bash
# プロジェクトで使われるポートを確認（wrangler: 8787/8788, vite: 5173, next: 3000 等）
lsof -i :8787 -i :8788 -i :5173 -i :3000 -P 2>/dev/null | grep LISTEN
```

残っている場合はポート指定で停止:

```bash
lsof -ti :{port} | xargs kill
```

### Step 6: 結果サマリーとコミット方法確認

全 Step の結果をまとめて提示し、コミット方法を確認する。

```markdown
## 完了前検証サマリー

| Step | 結果 |
|------|------|
| naming-review | ✅ 問題なし / ⚠️ N件の指摘（修正済み） |
| ui-check | ✅ 問題なし / ⏭️ スキップ（UI変更なし） |
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

## 注意事項

- Step 2-3 で Critical 指摘があり修正した場合、Step 4 を再実行する
- CLAUDE.md にプロジェクト固有の検証手順がある場合はそれも実行する
- このスキルはレビュー+検証のみ。コード編集は各レビュースキルの指摘に基づいてユーザー承認後に行う