---
name: verification-loop
description: 機能完成後・PR作成前に6フェーズの品質検証を実行。ビルド、型、リント、テスト、セキュリティ、差分を包括的にチェック。
argument-hint: "[quick|full]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task"]
---

# Verification Loop Skill

機能完成後やPR作成前に、プロジェクトの健全性を多角的に検証する品質保証スキル。

## When to Use This Skill

Trigger when user:
- `/verify` または `/verification-loop` コマンドを実行
- 「検証して」「チェックして」「PR準備できてる？」と依頼
- `/TDD` 完了後、PRを作成する前
- 長時間のセッション中に定期チェックしたい時

## 使用タイミング

```
/planning → /TDD → /verify → PR作成
                      ↑
              ここで品質ゲート
```

**推奨:**
- 機能実装完了後
- PR作成前（必須）
- 長時間セッションでは15分ごと
- 大きな変更の後

## 使用方法

```bash
/verify         # クイック検証（ビルド、型、テスト）
/verify quick   # クイック検証
/verify full    # フル検証（6フェーズすべて）
```

---

## 6フェーズ検証プロセス

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: ビルド検証        コンパイル・ビルドが通るか     │
│       ↓                                                     │
│  Phase 2: 型チェック        型エラーがないか               │
│       ↓                                                     │
│  Phase 3: リント検査        コード規約違反がないか         │
│       ↓                                                     │
│  Phase 4: テストスイート    テストが通り、カバレッジ十分か │
│       ↓                                                     │
│  Phase 5: セキュリティ      認証情報漏洩、脆弱性がないか   │
│       ↓                                                     │
│  Phase 6: 差分レビュー      意図しない変更がないか         │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: ビルド検証

プロジェクトが正常にコンパイルされるか確認。

```bash
# パッケージマネージャーを自動検出
if [ -f "pnpm-lock.yaml" ]; then
  pnpm build
elif [ -f "yarn.lock" ]; then
  yarn build
elif [ -f "bun.lockb" ]; then
  bun run build
else
  npm run build
fi
```

**失敗時:** 即座に修正が必要。次のフェーズに進まない。

---

## Phase 2: 型チェック

TypeScript/Python等の型エラーを検出。

```bash
# TypeScript
npx tsc --noEmit

# Python (mypy)
mypy .

# Python (pyright)
pyright
```

**重大度:**
- エラー: 必ず修正
- 警告: 可能な限り修正

---

## Phase 3: リント検査

コード規約違反やスタイル問題を特定。

```bash
# JavaScript/TypeScript
npm run lint
# または
npx eslint . --ext .js,.jsx,.ts,.tsx

# Python
ruff check .
# または
flake8 .
```

**対応:**
- エラー: 修正必須
- 警告: 検討

---

## Phase 4: テストスイート

テスト実行とカバレッジ測定。

```bash
# Jest
npm test -- --coverage

# Vitest
npx vitest run --coverage

# pytest
pytest --cov=. --cov-report=term-missing
```

**目標:**
- 全テストパス
- カバレッジ 80% 以上
- 新規コードは 90% 以上

---

## Phase 5: セキュリティスキャン

認証情報の漏洩やセキュリティ問題を検査。

### 5.1 秘密情報の検出

```bash
# APIキー、トークンなどのパターン検索
grep -rn --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" \
  -E "(api[_-]?key|secret|password|token|credential).*['\"][a-zA-Z0-9]{16,}['\"]" .

# .env ファイルがコミットされていないか
git status --porcelain | grep -E "\.env"
```

### 5.2 デバッグコードの検出

```bash
# console.log, debugger 等
grep -rn --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" \
  -E "(console\.(log|debug|info)|debugger)" src/
```

### 5.3 セキュリティチェックリスト

| チェック項目 | 確認内容 |
|-------------|---------|
| ハードコードされた秘密 | APIキー、パスワード、トークンが直接記述されていないか |
| 入力検証 | ユーザー入力が適切にバリデーションされているか |
| SQLインジェクション | パラメータ化クエリを使用しているか |
| XSS | HTML出力がサニタイズされているか |
| CSRF | 保護が有効になっているか |
| 認証・認可 | 適切に実装されているか |
| エラーメッセージ | 機密情報が露出していないか |

---

## Phase 6: 差分レビュー

変更内容を確認し、意図しない修正がないかチェック。

```bash
# ステージングされた変更
git diff --cached --stat

# 全変更（未ステージング含む）
git diff HEAD --stat

# 詳細な差分
git diff HEAD
```

**確認項目:**
- [ ] 意図しないファイルが変更されていないか
- [ ] デバッグコードが残っていないか
- [ ] コメントアウトされたコードが残っていないか
- [ ] TODO/FIXME が放置されていないか
- [ ] エッジケースへの対応漏れがないか

---

## 出力フォーマット

```markdown
## 検証結果

### サマリー
| フェーズ | 状態 | 詳細 |
|---------|------|------|
| ビルド | ✅ Pass | - |
| 型チェック | ✅ Pass | - |
| リント | ⚠️ Warning | 3件の警告 |
| テスト | ✅ Pass | カバレッジ 85% |
| セキュリティ | ✅ Pass | - |
| 差分 | ✅ Pass | 5ファイル変更 |

### 要対応項目

#### Critical（PR前に必須修正）
なし

#### Warning（修正推奨）
- `src/utils/helper.ts:45` - console.log が残っている

#### Info（参考）
- カバレッジが目標の80%を超えています（85%）

### 判定
✅ **PR作成可能** - Critical な問題はありません
```

---

## 判定基準

| 状態 | 条件 | アクション |
|------|------|-----------|
| ✅ Pass | Critical/Warning なし | PR作成可能 |
| ⚠️ Warning | Warning のみ | 修正推奨、PR可能 |
| ❌ Block | Critical あり | 修正必須、PR不可 |

---

## クイック検証 vs フル検証

| フェーズ | Quick | Full |
|---------|-------|------|
| ビルド検証 | ✅ | ✅ |
| 型チェック | ✅ | ✅ |
| リント検査 | - | ✅ |
| テストスイート | ✅ | ✅ |
| セキュリティ | - | ✅ |
| 差分レビュー | - | ✅ |

**推奨:**
- 開発中: `/verify quick`
- PR作成前: `/verify full`

---

## 長時間セッションでの使用

15分ごと、または大きな変更後にメンタルチェックポイントを設定：

```
作業開始
    ↓
[15分経過] → /verify quick
    ↓
機能実装完了 → /verify full
    ↓
PR作成
```

---

## TDDスキルとの連携

```
/TDD
  │
  ├── Phase 1-5: RED-GREEN-REFACTOR
  │
  └── Phase 6: タスク完了前に...
         │
         └── /verify full を実行
                │
                ├── Pass → TaskUpdate: completed
                │
                └── Fail → 問題を修正して再検証
```
