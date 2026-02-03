---
name: url-digest
description: 複数のURLを読み取り、コアメッセージがわかるように要約してideasリポジトリに保存する
argument-hint: "[URLs]"
disable-model-invocation: true
user-invocable: true
---

## URL要約

複数のURLを読み取り、コアメッセージがわかるように要約する。

### 入力

$ARGUMENTS からURLを抽出する（改行区切りまたはスペース区切り）。

### URL種別判定とコンテンツ取得

| 種別 | 判定 | 取得方法 |
|------|------|----------|
| 通常記事 | 上記以外 | WebFetchツール |
| X/Twitter | x.com, twitter.com | ブラウザ自動化（claude-in-chrome）|
| Hacker News | news.ycombinator.com | Algolia API |
| Reddit | reddit.com | curl + JSON |

**Hacker News**: `curl -s "https://hn.algolia.com/api/v1/items/{item_id}" | jq '.'`
**Reddit**: `curl -s -H "User-Agent: url-digest/1.0" "https://old.reddit.com/r/{subreddit}/comments/{post_id}.json" | jq '.[0].data.children[0].data'`

**WebFetchで本文取得できない場合**: `https://r.jina.ai/{元のURL}` 経由でアクセスする。

### 要約生成

各URLについて以下を作成:
- **タイトル**: 元タイトル（英語は日本語翻訳）
- **要約**: コアメッセージ3-5行。HN/Redditはコミュニティ反応も記載
- **URL**: 入力されたURL

### 出力

リポジトリ: `!`ghq root`/github.com/RyoMa99/ideas/`

パス: `daily/YYYYMMDD/{概要}.md`
- YYYYMMDD: 今日の日付
- {概要}: 記事の内容を表す短い日本語（例: `LLMエージェント設計パターン`）

ファイル形式:
```markdown
# {日本語タイトル}

{要約本文 3-5行}

{URL}
```

1つのURLにつき1ファイル作成する。

### 保存後

1. `git add` で追加
2. `git commit -m "add: YYYY-MM-DD digest"` でコミット（Co-Authored-By 付き）
3. `git push` でリモートにプッシュ

### 注意事項

- すべての記事にURLを含める必須
- 英語タイトルは日本語翻訳
- HN/Redditは元記事とコメント両方確認
- Reddit APIレート制限注意（1分60リクエスト程度）
