# Claude Code 拡張作成ガイドライン

rules、skills、hooks を作成・修正する際のベストプラクティス。

---

## スキル（Skills）

### ディレクトリ構造

```
~/.claude/skills/
└── skill-name/
    ├── SKILL.md        # 必須: メイン（500行以下）
    ├── reference.md    # 任意: 詳細ドキュメント
    └── templates/      # 任意: テンプレート
```

### SKILL.md フロントマター

```yaml
---
name: skill-name                    # 小文字・ハイフンのみ（最大64文字）
description: 説明（自動実行判定に使用）  # 必須
argument-hint: "[arg]"              # オートコンプリート時のヒント
disable-model-invocation: true      # タスク系は true 推奨
user-invocable: true                # false でスラッシュメニューから非表示
allowed-tools: ["Read", "Grep"]     # 使用可能ツールを制限
---
```

### スキルの種類と設定

| 種類 | disable-model-invocation | 用途 |
|------|--------------------------|------|
| 参照系 | false（デフォルト） | ガイドライン、知識ベース |
| タスク系 | true | 副作用のあるワークフロー |

### 引数の活用

```markdown
対象: $ARGUMENTS
# または
ファイル: $0
オプション: $1
```

### チェックリスト

- [ ] `name` は小文字・ハイフンのみか
- [ ] `description` は明確か（Claude の自動実行判定に使用）
- [ ] タスク系なら `disable-model-invocation: true` か
- [ ] 本文は500行以下か（超える場合は reference.md に分離）
- [ ] 詳細例やテンプレートはサポートファイルに分離したか

---

## ルール（Rules）

### ディレクトリ構造

```
~/.claude/rules/
├── topic-name.md       # トピック別に整理
└── subdomain/
    └── specific.md     # 必要に応じてサブディレクトリ
```

### パス固有ルール（任意）

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "tests/**/*.test.ts"
---
```

### 内容のガイドライン

**含めるべき**:
- 核心思想（引用ブロック）
- コード例（BAD/GOOD）
- チェックリスト
- 参考資料

**含めないべき**:
- Claude が推測できる言語の標準規約
- 頻繁に変わる情報
- 長いチュートリアル

### チェックリスト

- [ ] 既存ルールとスタイルが一貫しているか
- [ ] 関連ルールへの相互参照（`@~/.claude/rules/xxx.md`）があるか
- [ ] コード例は具体的か
- [ ] チェックリストが含まれているか
- [ ] 削除すると Claude が間違える内容のみか

---

## フック（Hooks）

### 設定ファイル

`~/.claude/settings.json` に記載:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "echo 'Bash tool used'"
      }
    ],
    "PostToolUse": [...],
    "Notification": [...],
    "Stop": [...]
  }
}
```

### フックタイプ

| タイプ | タイミング | 用途 |
|--------|----------|------|
| PreToolUse | ツール実行前 | 確認、ブロック |
| PostToolUse | ツール実行後 | ログ、検証 |
| Notification | 通知時 | 外部連携 |
| Stop | 停止時 | クリーンアップ |

### チェックリスト

- [ ] matcher は適切か（ツール名 or `*`）
- [ ] command はエラー時の挙動を考慮しているか
- [ ] 無限ループを引き起こさないか

---

## 共通原則

1. **簡潔さ優先**: 削除しても Claude が間違えないなら削除
2. **重複回避**: 既存の rules/skills と重複しない
3. **相互参照**: 関連コンテンツは `@path` でリンク
4. **段階的追加**: 一度に大量追加せず、必要に応じて拡張
5. **機密情報の除外**: 認証情報、APIキー、個人情報、プロジェクト固有のリソース名を含めない

---

## 参考資料

- [Skills Documentation](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Memory Management](https://docs.anthropic.com/en/docs/claude-code/memory)
- [Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)
