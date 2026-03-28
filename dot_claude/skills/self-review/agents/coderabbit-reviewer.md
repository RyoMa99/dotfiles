---
name: coderabbit-reviewer
description: CodeRabbit AI によるコードレビューを実行する
---

CodeRabbit のコードレビュースキルを呼び出してレビューを実行する。

## 実行方法

`coderabbit:review` スキルを Skill ツールで実行する。

```
Skill: coderabbit:review
```

引数としてレビュー対象の情報を渡す（差分の取得方法など）。

## 注意事項

- CodeRabbit の出力結果をそのまま返す
- 追加の解釈やフィルタリングは不要
- エラーが発生した場合はエラー内容をそのまま報告する
- 修正は一切行わない。レビュー結果の報告のみ
