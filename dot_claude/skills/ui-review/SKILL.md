---
name: ui-review
description: UIの包括的レビュー。技術的実装（アクセシビリティ、パフォーマンス）とビジュアルデザイン（スペーシング、階層）の両方をチェック。
argument-hint: "[file-or-pattern]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task", "WebFetch"]
---

# UI Review Skill

技術的実装とビジュアルデザインの両面からUIを包括的にレビューする統合スキル。

## When to Use This Skill

Trigger when user:
- `/ui-review` コマンドを実行
- 「UIを全面的にレビューして」「UIの品質をチェック」と依頼
- 包括的なUI監査を行いたい場合

## 構成

このスキルは2つの専門スキルを呼び出す：

| スキル | 観点 | 内容 |
|--------|------|------|
| `/web-design-guidelines` | 技術的実装 | アクセシビリティ、パフォーマンス、コード品質 |
| `/ui-design-principles` | ビジュアルデザイン | スペーシング、タイポグラフィ、視覚的階層 |

## 使用方法

```
/ui-review                        # 全ファイルを包括レビュー
/ui-review src/components/*.tsx   # 指定ファイルを包括レビュー
/ui-review --tech-only            # 技術的実装のみ
/ui-review --design-only          # ビジュアルデザインのみ
```

## 実行フロー

### Step 1: 対象ファイルの特定

引数でファイル/パターンが指定された場合はそのファイルを、指定がない場合はユーザーに確認。

### Step 2: 技術的実装レビュー

`/web-design-guidelines` を実行：

- アクセシビリティ（aria属性、キーボード操作）
- フォーム（autocomplete、ラベル、エラー表示）
- パフォーマンス（画像サイズ、リスト仮想化）
- アニメーション（prefers-reduced-motion）
- ナビゲーション（URL状態、確認ダイアログ）

### Step 3: ビジュアルデザインレビュー

`/ui-design-principles` を実行：

- スペーシング（8ptグリッド）
- コントラスト比（UI要素3:1、テキスト4.5:1）
- タッチターゲット（最小48×48px）
- ボタン階層（プライマリは1つ）
- タイポグラフィ（letter-spacing、font-weight）
- 視覚的階層（アライメントの一貫性）

### Step 4: 結果の統合

両方の結果を統合して優先度別に分類：

```markdown
## UI Review Summary

### Critical（必須修正）
- [技術] src/Button.tsx:15 - Missing aria-label on icon button
- [デザイン] src/Form.tsx:42 - コントラスト比が4.5:1未満

### Important（推奨修正）
- [技術] src/List.tsx:100 - 50件以上のリストが仮想化されていない
- [デザイン] src/Card.tsx:25 - 8ptグリッドに準拠していないスペーシング

### Suggestions（検討）
- [デザイン] src/Header.tsx:10 - 見出しのletter-spacingを狭くすると見栄えが向上

### 良い点
- アクセシビリティ属性が適切に設定されている
- 一貫したコンポーネント設計
```

## Tips

- **Critical優先**: アクセシビリティとコントラストは最優先
- **段階的に改善**: 一度に全て修正しようとしない
- **コンポーネント単位**: 共通コンポーネントを先に修正すると効率的
- **再レビュー**: 修正後は該当部分のみ再レビュー

## 個別実行

特定の観点のみレビューしたい場合は個別スキルを使用：

```
/web-design-guidelines src/components/  # 技術的実装のみ
/ui-design-principles src/components/   # ビジュアルデザインのみ
```
