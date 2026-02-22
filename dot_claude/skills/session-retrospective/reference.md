## 保存先マッピング（技術的学び）

### 振り分けの原則

**知見の対象技術・ツールに応じたファイルに保存する。**
エラー解決・トラブルシューティングでも、対象がツール固有なら当該ツールのルールファイルに記載する。
`troubleshooting.md` は **Claude Code 環境固有のワークアラウンド**（stdin 制約、WebFetch の制限等）にのみ使用する。

### マッピング表

| カテゴリ | ファイル |
|---------|---------|
| React/Next.js | `~/.claude/rules/react-nextjs.md` |
| TypeScript | `~/.claude/rules/typescript.md` |
| JS/TS エコシステム（パッケージ管理, bundler, runtime） | `~/.claude/rules/javascript.md` |
| テスト | `~/.claude/rules/testing.md` |
| API設計 | `~/.claude/rules/api-design.md` |
| DB | `~/.claude/rules/database.md` |
| Cloudflare | `~/.claude/rules/cloudflare.md` |
| DevOps | `~/.claude/rules/devops.md` |
| Terraform | `~/.claude/rules/terraform-guidelines.md` |
| mise | `~/.claude/rules/mise.md` |
| セキュリティ | `~/.claude/rules/security.md` |
| フロントエンド | `~/.claude/rules/web-frontend.md` |
| 命名 | `~/.claude/rules/naming.md` |
| 型設計 | `~/.claude/rules/type-granularity.md` |
| ドメインモデリング | `~/.claude/rules/domain-modeling.md` |
| プランレビュー | `~/.claude/rules/plan-review-learnings.md` |
| Claude Code 環境固有の回避策 | `~/.claude/rules/troubleshooting.md` |
| その他 | 既存ファイルに該当なければ新規ファイルを提案 |

---

## プロジェクト CLAUDE.md の振り分け基準

### 対象ファイルの検索

プロジェクトルートで `./CLAUDE.md` と `.claude.local.md` を探す。
存在しない場合は観点5をスキップする（新規作成は提案しない）。

### CLAUDE.md vs .claude.local.md の振り分け

| 振り分け先 | 内容 |
|-----------|------|
| `CLAUDE.md` | チームで共有すべきコンテキスト（アーキテクチャ、テスト実行方法、コード規約） |
| `.claude.local.md` | 個人の環境固有（ローカルのポート設定、個人のツール設定） |

### 記載スタイル

- **1行1概念** — CLAUDE.md はプロンプトの一部なので簡潔さが重要
- `<コマンド or パターン>` - `<簡潔な説明>` の形式

### 書くべきもの / 書くべきでないもの

CLAUDE.md は「書いた瞬間から劣化し始める」前提で運用する。

| 書くべき | 書くべきでない |
|---------|--------------|
| コードから推測できないプロジェクト固有の判断 | コードスタイルルール（リンターに委譲） |
| 非自明なビルド・テスト・デプロイコマンド | ディレクトリ構造の説明（すぐ変わる） |
| 重要な gotcha / footgun | 汎用的なプログラミングアドバイス |
| ドメイン固有の用語 | catch-all セクション（「Important Context」等） |

### 追記と同時に削除も提案する

- エージェントが推測できるようになった情報 → 削除提案
- コマンドが変わった → 旧コマンドの記述を更新提案
- 冗長な説明、自明な情報、再発しない一回限りの修正 → 削除提案

---

## 自動化機会の信頼度基準

| スコア | 条件 |
|--------|------|
| 0.9 | 3回以上の繰り返し + 明確なパターン |
| 0.7 | 2回の繰り返し or 明示的なユーザーの要望 |
| 0.5 | 1回だが一般的に有用と判断 |
| 0.3 | 仮説段階、要検証 |

## 自動化機会の検出と提案

### パターンの分類

| 種類 | 検出シグナル | 保存先 |
|------|-------------|--------|
| **Hook** | 同じチェックを毎回手動実行 / 「〜する前に確認して」パターン / エラー後の定型修正 | `settings.json` |
| **Skill** | 3ステップ以上の連続操作 / 条件分岐を含む判断フロー / 「いつもこの手順でやる」パターン | `~/.claude/skills/` |
| **Rule** | エラー解決後の「次回から気をつけること」 / 技術的な発見（→ 観点2と重複する場合は観点2に統合） | `~/.claude/rules/` |

### Hook の種類

| Hook | タイミング | 用途 |
|------|-----------|------|
| UserPromptSubmit | プロンプト送信時 | 入力検証、スキル提案 |
| PreToolUse | ツール実行前 | 確認、ブロック |
| PostToolUse | ツール実行後 | 検証、通知 |
| Notification | 通知時 | フィルタリング |

### 提案時のフォーマット

```markdown
### A1: [提案名] (信頼度: 0.7)

**種類**: hook / skill / rule
**トリガー**: [何がトリガーになったか]
**アクション**: [何をするか]
**根拠**: [このセッションでの具体例]

**実装案:**
[hooks なら JSON、skills なら SKILL.md テンプレート、rules なら追記内容]
```
