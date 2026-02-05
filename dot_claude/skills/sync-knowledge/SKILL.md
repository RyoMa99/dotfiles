---
name: sync-knowledge
description: プロジェクトの学習内容をグローバルなナレッジベース（~/.claude/rules/）に同期する。プロジェクト完了時や重要な学びがあった時に使用。
allowed-tools: ["Glob", "Grep", "Read", "Edit", "AskUserQuestion"]
---

# Sync Knowledge Skill

プロジェクトで得た学習内容を `~/.claude/rules/` に蓄積し、他のプロジェクトでも活用できるようにする。

## When to Use This Skill

Trigger when user:
- `/sync-knowledge` コマンドを実行
- 「学んだことを保存して」「ナレッジに追加して」と依頼
- プロジェクト完了時
- 重要な問題を解決した後

## ナレッジベースの構成

```
~/.claude/rules/
├── README.md          # ナレッジベースの説明
├── react-nextjs.md    # React/Next.js関連
├── typescript.md      # TypeScript関連
├── testing.md         # テスト関連
├── api-design.md      # API設計関連
├── database.md        # データベース関連
├── devops.md          # DevOps/CI/CD関連
├── troubleshooting.md # 問題解決のパターン
└── general.md         # その他
```

## 実行フロー

### Step 1: プロジェクトの学習内容を収集

以下のソースから学習内容を探す：

1. プロジェクトの `/docs` ディレクトリ
2. `KNOWLEDGE.md` や `LEARNINGS.md`
3. `README.md` の技術的な知見
4. 今回のセッションで解決した問題

### Step 2: 適切なファイルにマッチング

学習内容を適切なカテゴリに分類：

| カテゴリ | 対象 |
|---------|------|
| react-nextjs.md | React、Next.js、フロントエンド |
| typescript.md | TypeScript、型定義 |
| testing.md | テスト、Jest、Vitest |
| api-design.md | REST、GraphQL、API設計 |
| database.md | SQL、NoSQL、ORM |
| devops.md | CI/CD、Docker、デプロイ |
| troubleshooting.md | エラー解決、デバッグ |
| general.md | その他 |

該当するファイルがなければ新規作成を提案。

### Step 3: 既存の内容を確認

対象ファイルを読み、重複がないか確認。

### Step 4: 学習内容を追記

以下の形式で追記：

```markdown
## [タイトル]

**状況**: どんな場面で発生したか
**解決策**: どう解決したか
**コード例**:
\`\`\`typescript
// 具体的なコード
\`\`\`
**ポイント**: 覚えておくべきこと

---
```

### Step 5: レポート

追記した内容をユーザーに報告。

## 重要なルール

1. **プロジェクト固有の情報は除外**
   - 秘密情報（APIキー、トークン）
   - リソース名（S3バケット名、DB名など）
   - ユーザー名、パスワード

2. **再利用可能な形で記載**
   - 一般化された説明
   - 具体的なコード例

3. **既存の内容と重複しない**
   - 追記前に既存の内容を確認

## 使用例

```
/sync-knowledge
```

プロジェクトの学習内容を自動で収集し、適切なファイルに追記します。
