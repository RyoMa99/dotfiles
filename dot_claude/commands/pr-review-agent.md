PR #$ARGUMENTS をサブエージェントでレビューしてください。

Taskツールを使って以下を実行：

```
subagent_type: "general-purpose"
prompt: |
  PR #$ARGUMENTS をレビューしてください。

  1. gh pr view $ARGUMENTS --json number,title,body,headRefName,baseRefName,url でPR情報取得
  2. gh pr checkout $ARGUMENTS でブランチ切り替え
  3. gh pr diff $ARGUMENTS で差分確認
  4. gh pr view $ARGUMENTS --json comments,reviews でコメント確認
  5. コードレビュー（バグ、セキュリティ、パフォーマンス、規約）
  6. pnpm fix を実行
  7. レビュー結果をサマリーで報告

  問題があれば指摘し、承認可否を判断してください。
```
