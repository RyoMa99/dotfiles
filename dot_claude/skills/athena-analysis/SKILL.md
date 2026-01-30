---
name: athena-analysis
description: AWS Athenaでcameraman-web-upload-logsを分析する。ユーザーが /athena で起動する。
user_invocable: true
---

# Athena分析スキル

AWS CLIを使ってAthenaでログ分析を行うスキル。

## 起動時の手順

### 1. AWS SSO セッションをクリアしてアクセスキーを設定

最初に以下を実行して既存のセッションと環境変数をクリアする:

```bash
aws sso logout && unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

次に、ユーザーにAWSの一時クレデンシャル3点セットの入力を求める。
その際、SSOポータルのURLも案内する: https://d-956765d9d5.awsapps.com/start/#
**DeveloperReadOnlyAccess** の「アクセスキー」から取得するよう伝えること。

AskUserQuestionツールで以下を聞く:
- `AWS_ACCESS_KEY_ID`（必須）
- `AWS_SECRET_ACCESS_KEY`（必須）
- `AWS_SESSION_TOKEN`（必須 - SSO環境のため）

ユーザーはexport文の形式で値を提供するので、そのままBashで実行してexportする:

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

**禁止事項**:
- `--profile` オプションや `.aws/config` のプロファイルを使用してはならない

### 2. 接続確認とロールチェック

アクセスキー設定後、以下で疎通とロールを確認する:

```bash
aws sts get-caller-identity --output json
```

レスポンスの `Arn` に含まれるロール名を確認し、以下のチェックを行う:

- **`DeveloperAdminAccess`が含まれる場合**: 即座に処理を中断し、ユーザーに以下を伝える:
  > **DeveloperAdminAccessロールでは実行できません。**
  > このロールはAWS上のすべてのデータを削除できる権限を持つため、分析用途では使用禁止です。
  > DeveloperReadOnlyAccessの一時クレデンシャルを使用してください。
  > SSOポータルから再取得: https://d-956765d9d5.awsapps.com/start/#

  その後、環境変数をunsetしてスキルを終了する:
  ```bash
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  ```

- **`DeveloperReadOnlyAccess`が含まれる場合**: 正常。処理を継続する。
- **上記以外のロール**: ユーザーに確認を取ってから判断する。

### 3. Athena環境情報

- **データベース**: `cameraman_web_upload_logs`
- **テーブル**: `logs`
- **ワークグループ**: `cameraman-web-upload-logs`
- **結果出力先**: `s3://cameraman-web-upload-athena-results-qa/query-results/`
- **データソース**: `s3://cameraman-web-upload-logs-qa/` (Parquet, Snappy圧縮)
- **パーティション**: year/month/day (Partition Projection有効)

### 4. テーブルスキーマ

| カラム名 | 型 | 説明 |
|---|---|---|
| timestamp | string | ログのタイムスタンプ |
| level | string | ログレベル |
| trace_id | string | トレースID |
| photographer_id | bigint | カメラマンID |
| event_id | bigint | イベントID |
| message | string | ログメッセージ |
| context | string | コンテキスト情報 |
| user_agent | string | User-Agent文字列 |
| user_agent_data | string | User-Agentデータ |
| platform | string | プラットフォーム |
| browser | string | ブラウザ |
| device | string | デバイス |
| language | string | 言語 |
| screen_width | int | 画面幅 |
| screen_height | int | 画面高さ |
| cpu_cores | int | CPUコア数 |
| memory_gb | double | メモリ(GB) |
| year | string | パーティション: 年 |
| month | string | パーティション: 月 |
| day | string | パーティション: 日 |

## クエリ実行方法

### クエリの投入

```bash
aws athena start-query-execution \
  --query-string "<SQL>" \
  --work-group "cameraman-web-upload-logs" \
  --query-execution-context Database=cameraman_web_upload_logs \
  --output json
```

### 結果の取得

1. `start-query-execution` のレスポンスから `QueryExecutionId` を取得
2. ステータス確認（SUCCEEDEDになるまでポーリング）:

```bash
aws athena get-query-execution --query-execution-id <ID> --output json
```

3. 結果取得:

```bash
aws athena get-query-results --query-execution-id <ID> --output json
```

### パーティションを活用したクエリ例

パフォーマンスとコスト最適化のため、必ずパーティションキー(year, month, day)で絞り込むこと:

```sql
SELECT * FROM logs
WHERE year = '2026' AND month = '01' AND day = '30'
LIMIT 10;
```

## 注意事項

- クエリは必ずパーティション(year/month/day)で絞り込んでスキャン量を抑える
- 結果取得時はポーリング間隔を2秒程度あけ、最大30秒待つ
- ユーザーが分析したい内容を聞いてからクエリを組み立てる
