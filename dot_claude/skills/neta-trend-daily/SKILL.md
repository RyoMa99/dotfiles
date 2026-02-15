---
name: neta-trend-daily
description: "トレンドネタ収集"
disable-model-invocation: true
user-invocable: true
---

# トレンドネタ収集

はてなブックマークIT人気エントリー、Hacker News、Reddit からトレンド情報を収集し、JVN・GitHub Advisory から脆弱性情報を収集して、ideas リポジトリに保存する。

## 実行手順

### 0. ユーザープロファイル

興味領域：
- AI（開発とセキュリティへの応用）
- Webセキュリティ/脆弱性報告（OWASP、脆弱性、サプライチェーン攻撃、CVE）
- OSS開発/コミュニティ
- 個人開発/SaaS運営（Technical SEO、グロースハック、収益化）
- キャリア/人生哲学（経済的自由、外資転職、Build in Public）
- JavaScript/TypeScript、React
- Go
- PHP/Laravel
- Kotlin
- Docker/コンテナ技術

### 1. トレンド情報の収集

以下のサイトから最新のトレンド情報を取得：

**日本市場（はてブIT）**
- https://b.hatena.ne.jp/hotentry/it
- https://b.hatena.ne.jp/hotentry/it/%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0
- https://b.hatena.ne.jp/hotentry/it/AI%E3%83%BB%E6%A9%9F%E6%A2%B0%E5%AD%A6%E7%BF%92
- https://b.hatena.ne.jp/hotentry/it/%E3%81%AF%E3%81%A6%E3%81%AA%E3%83%96%E3%83%AD%E3%82%B0%EF%BC%88%E3%83%86%E3%82%AF%E3%83%8E%E3%83%AD%E3%82%B8%E3%83%BC%EF%BC%89
- https://b.hatena.ne.jp/hotentry/it/%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E6%8A%80%E8%A1%93
- https://b.hatena.ne.jp/hotentry/it/%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%8B%E3%82%A2
- 各エントリーの**タイトル、元記事URL、ブックマーク数**を必ず取得
- はてブのエントリーページURLではなく、リンク先の元記事URLを抽出

**グローバル（Hacker News）**
- https://news.ycombinator.com/
- 各記事の**タイトル、HNコメントページURL（`https://news.ycombinator.com/item?id=XXXXX`形式）、ポイント数**を取得
- **元記事URLではなくHNのコメントページURLを使用**
- **タイトルは日本語に翻訳**

**セキュリティ（追加ソース）**
- https://www.aikido.dev/blog
- https://www.wiz.io/blog
- 最新1-3記事をチェックし、興味度★★★のものがあれば注目トピックに含める

**脆弱性情報（JVN）**
- https://jvn.jp/ のトップページから直近の注意喚起・脆弱性レポートを取得
- 対象: macOS, Windows, Linux, 広く使われるインフラ系ツール/ライブラリ（OpenSSL, OpenSSH, curl, glibc, sudo, Git, nginx, PostgreSQL, Docker/containerd 等）、Node.js, Go, Python, PHP, Kotlin/JVM に関連するもの
- 各エントリーの**タイトル、JVN識別番号（JVNVU#等）、対象ソフトウェア、CVSS スコア（記載がある場合）**を取得
- ユーザーの技術スタックに無関係なもの（産業制御系、医療機器等）はスキップ

**脆弱性情報（GitHub Advisory Database）** — gh api 使用

取得例:
```bash
YESTERDAY=$(date -v-1d +%Y-%m-%d)
for eco in npm go pip composer maven; do
  gh api "/advisories?ecosystem=${eco}&type=reviewed&per_page=5&sort=published&direction=desc&published=${YESTERDAY}.." \
    --jq '.[] | "\(.cve_id // .ghsa_id)|\(.severity)|\(.summary)|\(.html_url)"'
done
```

対象エコシステム:
- npm（React, Next.js, Express 等）
- go（Go モジュール）
- pip（Python パッケージ）
- composer（PHP/Laravel パッケージ）
- maven（Kotlin/JVM パッケージ）

severity が critical / high のものを優先的に注目トピックに含める。

**Reddit（15サブレッド）** — WebFetchはreddit.comをブロックするため**Bashツールでcurl使用**

取得例:
```bash
curl -s -H "User-Agent: neta-trend-collector/1.0 (trend analysis tool)" \
  "https://old.reddit.com/r/programming/hot.json?t=day&limit=10" | \
  jq -r '.data.children[] | "\(.data.title)|\(.data.ups)|\(.data.num_comments)|https://www.reddit.com\(.data.permalink)"'
```

対象サブレッド:

セキュリティ系:
- r/netsec
- r/cybersecurity

AI系:
- r/OpenAI
- r/LocalLLaMA
- r/ClaudeCode

コア技術系:
- r/programming
- r/technology
- r/golang
- r/PHP
- r/kotlin

OSS/個人開発系:
- r/opensource
- r/indiehackers
- r/webdev
- r/reactjs

キャリア/実践系:
- r/cscareerquestions

### 2. 分析

**興味度の定義**:
- ★★★: 興味領域に直接関連
- ★★: 間接的に関連
- ★: 一般的なIT/技術ニュース

投票数・ブクマ数・コメント数で影響度を評価。議論が活発なトピックを優先。

### 3. 出力

**まず「ネタ収集完了。」と返してから、ファイルに保存する。**

リポジトリ: `!`ghq root`/github.com/RyoMa99/ideas/`
パス: `daily/YYYYMMDD/trends.md`

フォーマット:

```markdown
# トレンドネタ: YYYY-MM-DD

## はてブIT（日本市場）

### 注目トピック

| タイトル | ブクマ数 | 興味度 | カテゴリ | メモ |
|---------|---------|--------|---------|------|
| [タイトル](元記事URL) | XXX users | ★★★/★★/★ | AI/開発/キャリア等 | 発信に活用できるポイント |

### 全エントリー

1. [タイトル](元記事URL) (XXX users) - 概要
2. ...

## Hacker News（グローバル）

### 注目トピック

| タイトル | ポイント | 興味度 | カテゴリ | メモ |
|---------|---------|--------|---------|------|
| [タイトル](HNコメントページURL) | XXXpt | ★★★/★★/★ | AI/Security/Dev等 | 発信に活用できるポイント |

### 全エントリー

1. [タイトル](HNコメントページURL) (XXXpt) - 概要
2. ...

## Reddit（15サブレッド）

### 注目トピック

| タイトル | 投票数 | コメント数 | 興味度 | カテゴリ | サブレッド | メモ |
|---------|--------|-----------|--------|---------|-----------|------|
| [タイトル](RedditコメントページURL) | XXX ups | XXX | ★★★/★★/★ | Security/AI/OSS等 | r/subreddit | 発信に活用できるポイント |

### カテゴリ別エントリー

#### セキュリティ系
1. [タイトル](URL) (XXX ups, XXX comments) - r/netsec - 概要

#### AI系
1. [タイトル](URL) (XXX ups, XXX comments) - r/OpenAI - 概要

#### コア技術系
1. [タイトル](URL) (XXX ups, XXX comments) - r/golang - 概要

#### OSS/個人開発系
1. [タイトル](URL) (XXX ups, XXX comments) - r/opensource - 概要

#### キャリア/実践系
1. [タイトル](URL) (XXX ups, XXX comments) - r/cscareerquestions - 概要

## 脆弱性情報（JVN / GitHub Advisory）

### 注目（Critical / High）

| CVE / ID | 対象 | 深刻度 | 概要 | ソース |
|----------|------|--------|------|--------|
| [CVE-YYYY-XXXXX](URL) | Node.js 24.x | Critical | 概要 | JVN |
| [GHSA-xxxx-xxxx](URL) | express 4.x | High | 概要 | GitHub Advisory |

### JVN 新着

1. [JVNVU#XXXXXXXX: タイトル](URL) - 対象ソフトウェア - CVSS X.X
2. ...

### GitHub Advisory（エコシステム別）

#### npm
1. [GHSA-xxxx: 概要](URL) - severity - 対象パッケージ

#### go
1. ...

#### pip / composer / maven
1. ...（該当がなければ「該当なし」）
```

### 4. 保存後

ideasリポジトリで git add → commit → push を実行。

```bash
cd "$(ghq root)/github.com/RyoMa99/ideas" && git add . && git commit -m "add: YYYY-MM-DD trend" && git push
```

Co-Authored-By を付与すること。

## 注意事項

- **すべての記事にURLリンクを必ず含める**
- **はてブは元記事のURL**（はてブページURLではなく）
- **HNはコメントページURL**（`item?id=`形式）
- **Redditは完全URL**（`https://www.reddit.com/r/...`形式）
- **HN・Redditのタイトルは日本語に翻訳**
- WebFetchで取得できない場合は `https://r.jina.ai/{URL}` 経由でアクセス
- **JVNはユーザーの技術スタックに関連するもののみ抽出**（産業制御系、医療機器等はスキップ）
- **GitHub Advisory は直近24時間の published を対象**（`date -v-1d` で前日を算出）
- **Critical/High の脆弱性は必ず注目トピックに含める**（severity が medium 以下は全エントリーのみ）
