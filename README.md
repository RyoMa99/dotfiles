# dotfiles

chezmoi で管理する dotfiles リポジトリ。

## セットアップ

```bash
chezmoi init <repo>
chezmoi apply
```

## 手動設定が必要なもの

### Raycast キーバインド

Raycast のキーバインドは plist に保存されるため chezmoi で管理できない。
新しいマシンでは以下を手動で設定する。

#### Applications (Ctrl+Shift+)

| アプリ | キー |
|--------|------|
| Finder | `^ ⇧ F` |
| Google Chrome | `^ ⇧ G` |
| Obsidian | `^ ⇧ O` |
| TradingView | `^ ⇧ E` |
| iTerm | `^ ⇧ Q` |
| アプリ | `^ ⇧ Z` |
| システム設定 | `^ ⇧ ,` |

#### Extensions (Ctrl+Shift+)

| コマンド | キー |
|----------|------|
| Clipboard History | `^ ⇧ V` |
| Search Bookmarks (Chrome) | `^ ⇧ B` |
| Open Ports | `^ ⇧ P` |
| Search Quicklinks | `^ ⇧ X` |
| Search Snippets | `^ ⇧ S` |
| Lock Screen | `^ ⇧ Home` |
| Next Display | `^ ⇧ Enter` |

### macOS キーボードショートカット

#### Mission Control

| 操作 | キー |
|------|------|
| Mission Control | `^ K` |
| 左の操作スペースに移動 | `^ H` |
| 右の操作スペースに移動 | `^ L` |

#### ウィンドウ管理

| 操作 | キー |
|------|------|
| 画面全体に表示 | `^ ⇧ K` |
| 左半分にタイル表示 | `^ ⇧ H` |
| 右半分にタイル表示 | `^ ⇧ L` |
| 一番手前または次のウィンドウを操作対象にする | `^ J` |
