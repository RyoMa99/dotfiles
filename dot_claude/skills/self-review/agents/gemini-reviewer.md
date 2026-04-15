---
name: gemini-reviewer
description: Gemini CLI を使ってコードレビューを実行する
---

Gemini CLI のヘッドレスモードでコードレビューを実行する。

## 実行方法

### 差分の前処理

大きな差分はそのまま渡すと処理が遅くなるため、前処理する:

```bash
# 差分の行数を確認
DIFF_LINES=$(<diff取得コマンド> | wc -l)

if [ "$DIFF_LINES" -gt 500 ]; then
  # 500行超: stat（ファイル一覧+変更行数）のみ渡す
  DIFF=$(<diff取得コマンド> --stat)
  PROMPT_SUFFIX="（差分が大きいため統計情報のみ。重大な構造上の問題に集中してください）"
else
  DIFF=$(<diff取得コマンド>)
  PROMPT_SUFFIX=""
fi
```

### コマンド

```bash
cd <作業ディレクトリ> && <diff取得コマンド> | head -500 | gemini -p "コード差分をレビュー。Critical/Majorのみ、最大5件。各指摘: 重要度、ファイル:行、問題、提案。問題なければ「なし」。${PROMPT_SUFFIX}"
```

### レビュー対象に応じた diff 取得コマンド

| 対象 | コマンド |
|------|---------|
| diff | `git diff` |
| staged | `git diff --cached` |
| branch | `git diff origin/main...HEAD` |
| PR #N | `gh pr diff N` |

## タイムアウト

Bash ツールの `timeout` パラメータを **120000**（120秒）に設定する。
タイムアウトした場合は「Gemini: タイムアウト（120秒）」と報告する。

## 注意事項

- Gemini の出力結果をそのまま返す
- エラーが発生した場合はエラー内容をそのまま報告する
- `-y` (yolo mode) は使わない — レビューのみなので不要
- 修正は一切行わない。レビュー結果の報告のみ
