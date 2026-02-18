---
name: record-business-knowledge
description: 業務知識をbusiness_knowledgeリポジトリに記録する。ビジネスドメイン単位で整理。議事録、スクリーンショットなど様々な形式に対応。
user-invocable: true
argument-hint: "[ドメイン名] [トピック]"
allowed-tools: ["Bash", "Read", "Write", "AskUserQuestion"]
---

# 業務知識の記録

業務に関する知識を `business_knowledge` リポジトリに記録・整理する。

## リポジトリ

```bash
$(ghq root)/github.com/h-rym/business_knowledge
```

## 対応するデータ形式

| 形式 | 用途 | 配置先 |
|------|------|--------|
| Markdown | 仕様、ルール、議事録 | `specs/`, `meetings/` |
| テキスト | メモ、ログ | `notes/` |
| 画像 | スクリーンショット、図 | `assets/images/` |
| PDF | 資料、ドキュメント | `assets/docs/` |
| その他 | 必要に応じて | `assets/` |

## ディレクトリ構造

**ビジネスドメイン単位**で整理する（リポジトリ単位ではない）。

```
business_knowledge/
├── [domain-a]/                  # ビジネスドメイン
│   ├── specs/                   # 仕様・業務ルール
│   ├── meetings/                # 議事録
│   ├── notes/                   # メモ・調査記録
│   └── assets/                  # 画像・PDF等
│       ├── images/
│       └── docs/
├── [domain-b]/
│   └── ...
└── shared/                      # ドメイン横断の共通知識
    └── ...
```

実際の整理方法はユーザーと相談して決定する。

## 実行フロー

### Step 1: コンテキストの確認

以下を特定する（不明な場合はユーザーに質問）：

1. **ドメイン**: どのビジネスドメインに関する知識か
2. **カテゴリ**: specs / meetings / notes / assets
3. **トピック**: 具体的な内容

```
質問例:
- 「これはどのドメインの仕様として記録しますか？」
- 「議事録として保存しますか、それとも仕様としてまとめますか？」
- 「新しいドメインを作成しますか？既存のドメインに追加しますか？」
```

### Step 2: 既存構造の確認

```bash
REPO="$(ghq root)/github.com/h-rym/business_knowledge"
ls -la "$REPO"
```

### Step 3: 配置先の決定

迷った場合はユーザーに相談する。

### Step 4: ファイルの作成/更新

#### Markdown形式（仕様・議事録）

```markdown
# [トピック名]

## 概要
[簡潔な説明]

## 詳細

### [サブトピック]
- 仕様の説明

## 背景・経緯
[なぜこうなっているかの説明があれば]

## 関連
- [関連トピックへのリンク]

## 更新履歴
- YYYY-MM-DD: 初版作成
```

#### 画像・PDFの場合

1. 適切なディレクトリに配置
2. 同名の `.md` ファイルで説明を追加

### Step 5: コミット & プッシュ

```bash
REPO="$(ghq root)/github.com/h-rym/business_knowledge"
cd "$REPO" && \
git add . && \
git commit -m "[ドメイン] トピックを追加" && \
git push
```

## 整理の原則

1. **ビジネスドメイン単位**
   - リポジトリではなく、業務概念で分類
   - 複数リポジトリにまたがる知識も1つのドメインにまとめる

2. **粒度**
   - 1トピック = 1ファイル（原則）
   - 関連が強いものはまとめてもOK

3. **命名**
   - ディレクトリ名: `kebab-case`
   - ファイル名: `kebab-case.md`
   - 日本語OK（内容は日本語推奨）

4. **機密情報の除外**
   - 認証情報、個人情報は記載しない
   - 必要ならプレースホルダーを使用

## 迷ったら相談

整理方法に迷った場合は、必ずユーザーに確認する。

このskillはブラッシュアップしていく想定なので、より良い整理方法があれば提案してください。
