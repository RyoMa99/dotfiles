# chezmoi管理ファイルの変更ルール

**対象**: chezmoi で管理されているファイルを変更した場合すべて

**ルール**: 変更完了後、必ずchezmoi側に反映 → コミット → プッシュ を一連の作業として完了する

---

## ~/.claude/ 配下の変更

skills、rules、CLAUDE.md、settings.json 等を変更した場合：

1. 変更・追加したファイルをコピー
   ```bash
   cp <変更ファイル> ~/.local/share/chezmoi/dot_claude/<対応パス>
   ```
2. 削除した場合はchezmoi側も削除
   ```bash
   rm -r ~/.local/share/chezmoi/dot_claude/skills/<削除したskill>/
   ```

## brew install/uninstall 実行後

Brewfile（`~/.Brewfile` → chezmoi: `dot_Brewfile`）を更新する：

1. `dot_Brewfile` に `brew "パッケージ名"` または `cask "アプリ名"` を追加/削除
2. tap が必要な場合は `tap "タップ名"` も追加

## .tool-versions の変更

mise（旧asdf）で管理するツールを追加/変更した場合：

1. `dot_tool-versions` にコピー
   ```bash
   cp ~/.tool-versions ~/.local/share/chezmoi/dot_tool-versions
   ```

## 共通: コミット & プッシュ

すべての変更後、必ず実行：

```bash
cd ~/.local/share/chezmoi && git add . && git commit -m "メッセージ" && git push
```

**注意**:
- 削除前にchezmoi gitに履歴があるか確認すること（`git log --all -- <path>` で復元可能か確認）
- ユーザーに「コミットした？」と聞かれる前に、変更→反映→コミット→プッシュまでを一連の作業として完了する
