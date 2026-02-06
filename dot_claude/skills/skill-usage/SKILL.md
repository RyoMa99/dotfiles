---
name: skill-usage
description: セッションログからスキルの利用状況を分析し、使われていないスキルを特定する。
user-invocable: true
disable-model-invocation: true
allowed-tools: ["Bash", "Glob", "Read"]
---

# Skill Usage Analysis

セッションログを分析し、スキルの実際の利用状況を可視化する。

## When to Use

- `/skill-usage` コマンドを実行
- 定期メンテナンス時（月1回程度）
- 「使ってないスキルある？」と聞かれた時

## 実行フロー

### Step 1: 全プロジェクトのログからスキル呼び出しを集計

```bash
grep -roh '"name":"Skill","input":{"skill":"[^"]*"' \
  ~/.claude/projects/ 2>/dev/null \
  | sed 's/.*"skill":"//' | sed 's/"//' \
  | sort | uniq -c | sort -rn
```

### Step 2: 登録スキル一覧の取得

ローカルスキルを列挙：

```bash
ls ~/.claude/skills/
```

### Step 3: 利用状況の照合

各スキルについて：
- 呼び出し回数
- 最終呼び出し日（可能であれば）
- 呼び出し元（ユーザー明示 or Claude 自動）

### Step 4: レポート出力

```markdown
## Skill Usage Report

### 期間: [ログの日付範囲]

### よく使われるスキル
| スキル | 回数 |
|--------|------|
| grepai | 5 |
| suggest-automation | 4 |

### 使われていないローカルスキル
| スキル | 最終使用 | 推奨アクション |
|--------|---------|---------------|
| xxx | なし | 削除検討 or ルール化 |

### 外部プラグインスキル（参考）
- superpowers:* - 利用状況
- sentry:* - 利用状況
```

### Step 5: 改善提案

- 使われていないスキルの削除 or ルール化を提案
- `disable-model-invocation: true` で使われていないスキルは見直し候補
