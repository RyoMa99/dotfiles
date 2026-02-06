---
name: naming-review
description: コードの命名を7段階プロセスに沿ってレビューし、改善提案を行う。
argument-hint: "[file-or-directory]"
disable-model-invocation: false
allowed-tools: ["Glob", "Grep", "Read", "Task"]
---

# Naming Review Skill

命名の進化的プロセスに基づいてコードをレビューするスキル。

- 詳細な命名原則: @~/.claude/rules/naming.md
- レビュー例と出力フォーマット: @reference.md

## 実行フロー

### 1. 対象の特定

```
対象: $ARGUMENTS
```

引数がない場合はユーザーに確認。

### 2. コード読み取り

対象ファイル/ディレクトリの公開API（関数、クラス、メソッド）を特定。

### 3. 各識別子を7段階で評価

| 段階 | 名前 | 問題の兆候 |
|------|------|-----------|
| 1 | Missing | 抽出すべき概念が埋もれている |
| 2 | Nonsense | temp, data, info 等の汎用名 |
| 3 | Honest | 副作用が名前に反映されていない |
| 4 | Honest and Complete | 名前が長い（責務過多のサイン） |
| 5 | Does the Right Thing | 単一責務 |
| 6 | Intent | 目的を表現 |
| 7 | Domain Abstraction | ドメイン用語として統一 |

### 4. 問題パターンの検出

- 誤解を招く名前
- プリミティブ型への執着（Value Object化の候補）
- Manager/Handler/Processor 等の曖昧なサフィックス
- Feature Envy（他オブジェクトへの過度なアクセス）

### 5. 改善提案の出力

各問題について：
- 現在の段階
- 問題点
- 改善案（複数オプション提示）
- 推奨案と理由

### 6. サマリー出力

- 評価した識別子数と問題数
- 優先度高の改善項目
- ドメイン抽象化の候補

## 注意事項

- レビューのみ。編集は行わない
- 大規模な変更は段階的実施を推奨
