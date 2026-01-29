---
name: context7
description: 最新のライブラリドキュメントを動的に取得する。外部ライブラリやフレームワークを使用する際に自動で発動し、正確なAPIリファレンスを提供。
---

# Context7 Documentation Skill

ライブラリやフレームワークの最新ドキュメントをContext7 MCPから取得する。

## When to Use This Skill

以下の場面で自動的に発動：

- 外部ライブラリを使用したコード作成時
- ライブラリのAPIリファレンス参照時
- フレームワークのセットアップ時
- 特定パッケージのコード例リクエスト時
- 「〇〇の使い方」「〇〇のAPI」といった質問時

## 使用可能なMCPツール

### 1. resolve-library-id

ライブラリ名からContext7のライブラリIDを解決する。

```
resolve-library-id: { "libraryName": "react" }
```

### 2. get-library-docs

ライブラリIDを指定してドキュメントを取得する。

```
get-library-docs: { "context7CompatibleLibraryID": "/facebook/react", "topic": "hooks" }
```

## ワークフロー

1. ユーザーがライブラリ関連の質問をする
2. `resolve-library-id` でライブラリIDを取得
3. `get-library-docs` で関連ドキュメントを取得
4. 取得した最新情報を基に回答

## 使用例

**ユーザー**: 「Next.js 15のApp Routerでデータフェッチングする方法は？」

**Claude の動作**:
1. `resolve-library-id: { "libraryName": "next.js" }` を実行
2. `get-library-docs: { "context7CompatibleLibraryID": "/vercel/next.js", "topic": "data fetching app router" }` を実行
3. 取得したドキュメントを基に最新の方法を回答

## 重要な原則

1. **明示的な指示は不要** - ライブラリ関連の作業時に自動で発動
2. **最新情報を優先** - トレーニングデータより Context7 の情報を優先
3. **バージョン対応** - 特定バージョンの情報が必要な場合はtopicに含める
