---
name: suggest-automation
description: やりとりを分析し、hooks、skills、rulesに昇華すべきパターンを検出して提案する。繰り返し作業の自動化や知識の形式化を支援。
---

# Suggest Automation Skill

会話のやりとりを分析し、再利用可能なパターンを検出。hooks、skills、rulesとして保存することを提案する。

## References

- [claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) - skill evaluation system
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) - continuous-learning-v2

## When to Use This Skill

Trigger when user:
- `/suggest-automation` コマンドを実行
- 「自動化できそう？」「パターン化して」と依頼
- セッション終了時の振り返り

## パターン検出モデル（Instinct Model参考）

```
Pattern = {
  type: "hook" | "skill" | "rule",
  trigger: string,           // 何がトリガーになったか
  action: string,            // どんな対応をしたか
  confidence: 0.3-0.9,       // 信頼度スコア
  evidence: [                // 根拠
    { session: "xxx", context: "..." }
  ],
  domain: string[]           // 関連ドメイン（react, typescript, etc）
}
```

### 信頼度スコアの基準

| スコア | 条件 |
|--------|------|
| 0.9 | 3回以上の繰り返し + 明確なパターン |
| 0.7 | 2回の繰り返し or 明示的なユーザーの要望 |
| 0.5 | 1回だが一般的に有用と判断 |
| 0.3 | 仮説段階、要検証 |

## 検出対象

### 1. Hook候補（自動実行したい処理）

**検出シグナル:**
- 同じチェックを毎回手動で実行
- 「〜する前に確認して」という依頼パターン
- エラー後の定型的な修正

**Hook種類:**
| Hook | タイミング | 用途 |
|------|-----------|------|
| UserPromptSubmit | プロンプト送信時 | 入力検証、スキル提案 |
| PreToolUse | ツール実行前 | 確認、ブロック |
| PostToolUse | ツール実行後 | 検証、通知 |
| Notification | 通知時 | フィルタリング |

### 2. Skill候補（複数ステップのワークフロー）

**検出シグナル:**
- 3ステップ以上の連続した操作
- 条件分岐を含む判断フロー
- 「いつもこの手順でやる」パターン

**Skill構造:**
```markdown
---
name: skill-name
description: 簡潔な説明
---

# Skill Name

## When to Use
トリガー条件

## Steps
1. Step 1
2. Step 2
...
```

### 3. Rule候補（知識・ベストプラクティス）

**検出シグナル:**
- エラー解決後の「次回から気をつけること」
- 技術的な発見や学び
- プロジェクト横断で使える知見

**保存先マッピング:**
| ドメイン | ファイル |
|---------|---------|
| React/Next.js | `~/.claude/rules/react-nextjs.md` |
| TypeScript | `~/.claude/rules/typescript.md` |
| テスト | `~/.claude/rules/testing.md` |
| API設計 | `~/.claude/rules/api-design.md` |
| DB | `~/.claude/rules/database.md` |
| DevOps | `~/.claude/rules/devops.md` |
| 問題解決 | `~/.claude/rules/troubleshooting.md` |
| その他 | `~/.claude/rules/general.md` |

## 実行フロー

### Step 1: セッション分析

現在のセッションを振り返り、以下を検出：

```
分析対象:
1. ユーザーの依頼パターン
2. 実行したツールの連鎖
3. エラーと解決策
4. 繰り返し出現したキーワード
5. ファイル操作のパターン
```

### Step 2: パターン抽出

検出したパターンを構造化：

```markdown
## 検出パターン

### パターン1: [名前]
- **種類**: hook / skill / rule
- **信頼度**: 0.7
- **トリガー**: [何が起きたとき]
- **アクション**: [何をするか]
- **根拠**:
  - [このセッションでの具体例1]
  - [このセッションでの具体例2]
```

### Step 3: 提案

```markdown
## 自動化の提案

### 1. [提案名] (信頼度: 0.7)

**種類**: hook
**概要**: [説明]

**実装:**
\`\`\`json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "tool == \"Edit\"",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'チェック実行'"
          }
        ]
      }
    ]
  }
}
\`\`\`

---

実装しますか？ [Yes / No / 修正]
```

### Step 4: 実装

ユーザー承認後、適切な場所に保存。

### Step 5: 確認方法を案内

```markdown
## 保存完了

### テスト方法
- **hook**: 該当アクション実行時に自動トリガー
- **skill**: `/[skill-name]` で呼び出し
- **rule**: 次セッションから自動参照
```

## 検出例

### 例1: Lint実行の自動化 → Hook

```
検出:
- ユーザーが「コミット前にlint確認して」と3回依頼
- 毎回 `npm run lint` を実行

提案:
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "tool == \"Bash\" && tool_input.command matches \"git commit\"",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint"
          }
        ]
      }
    ]
  }
}
```

### 例2: PRレビュー手順 → Skill

```
検出:
- PRレビュー時に毎回同じ観点でチェック
- diff確認 → 型チェック → テスト確認 → セキュリティ確認

提案:
~/.claude/skills/pr-review/SKILL.md を作成
```

### 例3: TypeScriptエラー解決 → Rule

```
検出:
- 「型 'X' を型 'Y' に割り当てることはできません」エラーを解決
- 原因: Optional型の扱い

提案:
~/.claude/rules/typescript.md に追記:
## Optional型のエラー解決
...
```

## 重要なルール

1. **ユーザー承認必須** - 自動保存しない
2. **信頼度0.5以上のみ提案** - 低信頼度は内部メモに留める
3. **秘密情報除外** - APIキー等は含めない
4. **既存重複確認** - 追加前に既存内容をチェック
5. **シンプルに** - 過度に複雑な自動化は避ける
6. **1セッション3提案まで** - 多すぎると負担になる

## 使用例

```
/suggest-automation
```

現在のセッションを分析し、自動化の提案を行います。
