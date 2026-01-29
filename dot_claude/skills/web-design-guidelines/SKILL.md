---
name: web-design-guidelines
description: Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices".
argument-hint: "[file-or-pattern]"
---

# Web Design Guidelines Skill

UIコードをWeb Interface Guidelinesに照らしてレビューする。

## When to Use This Skill

Trigger when user:
- `/web-design-guidelines` コマンドを実行
- 「UIをレビューして」「アクセシビリティをチェック」と依頼
- 「デザインを監査して」「UXをレビュー」と依頼
- 「ベストプラクティスに沿っているか確認」と依頼

## 実行フロー

### 1. ガイドラインの取得

最新のガイドラインをフェッチ:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

WebFetchを使用して最新のルールを取得。

### 2. 対象ファイルの特定

- 引数でファイル/パターンが指定された場合: そのファイルを読み込み
- 指定がない場合: ユーザーにどのファイルをレビューするか確認

### 3. ルールの適用

取得したガイドラインの全ルールに対してチェック

### 4. 結果の出力

`file:line` 形式で発見事項を出力:

```
src/components/Button.tsx:15 - Missing aria-label on icon button
src/pages/index.tsx:42 - Color contrast ratio below 4.5:1
```

## ガイドラインのカテゴリ

- アクセシビリティ
- カラーコントラスト
- キーボードナビゲーション
- セマンティックHTML
- レスポンシブデザイン
- パフォーマンス

## 使用例

```
/web-design-guidelines src/components/**/*.tsx
/web-design-guidelines src/pages/index.tsx
/web-design-guidelines  # ファイル指定を促す
```
