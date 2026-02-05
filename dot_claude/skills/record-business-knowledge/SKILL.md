---
name: record-business-knowledge
description: 業務知識をbusiness_knowledgeリポジトリに記録する。フォルダ構造、命名規則、業務フロー、議事録、スクリーンショットなど様々な形式の知見を整理・蓄積。
user-invocable: true
argument-hint: "[プロジェクト名] [トピック]"
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

## ディレクトリ構造（提案）

```
business_knowledge/
├── projects/                    # プロジェクト別
│   ├── 8122_core/
│   │   ├── specs/              # 仕様・業務ルール
│   │   │   ├── reupload.md     # 再納品の仕様
│   │   │   └── photo-upload.md
│   │   ├── architecture/       # 設計・アーキテクチャ
│   │   ├── meetings/           # 議事録
│   │   ├── notes/              # メモ・調査記録
│   │   └── assets/             # 画像・PDF等
│   │       ├── images/
│   │       └── docs/
│   └── 8122-ec/
│       └── ...
├── domains/                     # 技術ドメイン（プロジェクト横断）
│   ├── backend/
│   ├── frontend/
│   └── infrastructure/
└── shared/                      # 会社共通の知識
    └── ...
```

**注意**: この構造は提案です。実際の整理方法はユーザーと相談して決定する。

## 実行フロー

### Step 1: コンテキストの確認

以下を特定する（不明な場合はユーザーに質問）：

1. **プロジェクト**: どのプロジェクトに関する知識か
2. **カテゴリ**: specs / architecture / meetings / notes / assets
3. **トピック**: 具体的な内容（例: 再納品、認証フロー）

```
質問例:
- 「これは8122_coreの仕様として記録しますか？」
- 「議事録として保存しますか、それとも仕様としてまとめますか？」
- 「プロジェクト横断の知識ですか？」
```

### Step 2: 既存構造の確認

```bash
REPO="$(ghq root)/github.com/h-rym/business_knowledge"
ls -la "$REPO"
# 既存のディレクトリ構造を確認
```

### Step 3: 配置先の決定

迷った場合はユーザーに相談：

```
「この情報は以下のどちらに配置するのが適切でしょうか？
A) projects/8122_core/specs/reupload.md（プロジェクト固有の仕様）
B) domains/backend/file-naming.md（プロジェクト横断の命名規則）」
```

### Step 4: ファイルの作成/更新

#### Markdown形式（仕様・議事録）

```markdown
# [トピック名]

## 概要
[簡潔な説明]

## 詳細

### [サブトピック]
- 仕様の説明
- 例: `【再納品1】/親カテゴリ/子カテゴリ/ファイル`

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

```markdown
# [ファイル名]

## 説明
[このファイルが何を示しているか]

## 関連
- 元ファイル: `./images/screenshot-xxx.png`
- 関連仕様: `../specs/xxx.md`
```

### Step 5: コミット & プッシュ

```bash
REPO="$(ghq root)/github.com/h-rym/business_knowledge"
cd "$REPO" && \
git add . && \
git commit -m "[プロジェクト/カテゴリ] トピックを追加" && \
git push
```

## 整理の原則

1. **プロジェクト固有 vs 横断**
   - 特定プロジェクトでしか使わない → `projects/[プロジェクト名]/`
   - 複数プロジェクトで共通 → `domains/` または `shared/`

2. **粒度**
   - 1トピック = 1ファイル（原則）
   - 関連が強いものはまとめてもOK

3. **命名**
   - ファイル名: `kebab-case.md`（例: `reupload-folder-structure.md`）
   - 日本語OK（内容は日本語推奨）

4. **機密情報の除外**
   - 認証情報、個人情報は記載しない
   - 必要ならプレースホルダーを使用

## 迷ったら相談

整理方法に迷った場合は、必ずユーザーに確認する：

```
「この情報の整理方法について相談させてください。
[選択肢A]と[選択肢B]のどちらが適切でしょうか？
理由: [それぞれのメリット・デメリット]」
```

このskillはブラッシュアップしていく想定なので、より良い整理方法があれば提案してください。