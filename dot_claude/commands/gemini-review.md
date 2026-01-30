gemini-code-assistantのPRレビューコメントに対応してください。

## 手順

1. 現在のブランチに紐づくPRを取得する：
   ```bash
   gh pr view --json number,title,url
   ```

2. gemini-code-assistantのレビューコメントを取得する：
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
   ```

3. コメントの内容を確認し、指摘事項をリストアップする

4. 各指摘事項に対して：
   - 指摘内容を要約
   - 対応方針を説明
   - コードを修正

5. 修正完了後、型チェックとlintを実行して確認する

## 注意事項

- 指摘の妥当性を判断し、必要に応じてユーザーに相談する
- 過度な変更は避け、指摘事項に絞って対応する
- 修正後は変更点をサマリーとして報告する
