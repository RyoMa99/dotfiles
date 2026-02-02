# chezmoi管理ファイルの変更ルール

**対象**: chezmoi で管理されているファイルを変更した場合すべて

**ルール**: 変更完了後、必ずchezmoi側に反映 → コミット → プッシュ を一連の作業として完了する

---

## 基本: chezmoi add を使う

ファイルの追加・変更は `chezmoi add` で反映する：

```bash
chezmoi add <変更ファイルのパス>
```

例：
```bash
chezmoi add ~/.config/wezterm/wezterm.lua
chezmoi add ~/.claude/CLAUDE.md
```

削除した場合は chezmoi 側も削除：
```bash
chezmoi forget <パス>
```

## brew install/uninstall 実行後

Brewfile（`~/.Brewfile` → chezmoi: `dot_Brewfile`）を更新する：

1. `dot_Brewfile` に `brew "パッケージ名"` または `cask "アプリ名"` を追加/削除
2. tap が必要な場合は `tap "タップ名"` も追加

## 共通: コミット & プッシュ

すべての変更後、必ず実行：

```bash
cd ~/.local/share/chezmoi && git add . && git commit -m "メッセージ" && git push
```

**注意**:
- 削除前にchezmoi gitに履歴があるか確認すること（`git log --all -- <path>` で復元可能か確認）
- ユーザーに「コミットした？」と聞かれる前に、変更→反映→コミット→プッシュまでを一連の作業として完了する
