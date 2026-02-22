---
name: nvim-plugin-management
description: Neovimプラグインの追加・削除手順。lazy.nvimを使用したプラグイン管理で、プラグインファイル作成とlazy.luaへのimport追加/削除を行う。
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(git *)
  - Glob
  - Grep
---

# Neovim Plugin Management

lazy.nvimを使用したNeovimプラグイン管理スキル。

## 対象リポジトリ

`~/.config/nvim`

## プラグイン追加手順

1. `lua/plugins/<plugin-name>.lua`を作成
2. `lua/config/lazy.lua`のspec配列にimportを追加
3. コミット&プッシュ

### 手順1: プラグインファイル作成

```lua
-- lua/plugins/<plugin-name>.lua
return {
  "<github-user>/<repo-name>",
  event = { "BufReadPre", "BufNewFile" }, -- 遅延読み込み（任意）
  cmd = { "Command" }, -- コマンドで遅延読み込み（任意）
  dependencies = { ... }, -- 依存プラグイン（任意）
  keys = {
    { "<Leader>xx", "<cmd>Command<cr>", desc = "説明" },
    { "<Leader>xx", function() ... end, mode = "v", desc = "説明" },
  },
  opts = { ... }, -- setup()に渡すオプション
  config = function()
    -- カスタム設定が必要な場合
  end,
}
```

### 手順2: lazy.luaにimport追加

```lua
-- lua/config/lazy.lua
require("lazy").setup({
  spec = {
    -- ... 既存のimport ...
    { import = "plugins.<plugin-name>" }, -- ← 追加
  },
})
```

### 手順3: コミット&プッシュ

**重要**: 2つのリモートに両方pushすること

```bash
git add lua/plugins/<plugin-name>.lua lua/config/lazy.lua
git commit -m "Add <plugin-name> plugin

- <機能の説明>"
git push origin head
git push sub head
```

## プラグイン削除手順

1. `lua/plugins/<plugin-name>.lua`を削除
2. `lua/config/lazy.lua`から該当のimport行を削除
3. コミット&プッシュ

### 手順1: プラグインファイル削除

```bash
rm lua/plugins/<plugin-name>.lua
```

### 手順2: lazy.luaからimport削除

`{ import = "plugins.<plugin-name>" },`の行を削除

### 手順3: コミット&プッシュ

**重要**: 2つのリモートに両方pushすること

```bash
git add -A lua/plugins/ lua/config/lazy.lua
git commit -m "Remove <plugin-name> plugin"
git push origin head
git push sub head
```

## 注意事項

- **リモート**: `origin`と`sub`の2つに両方pushすること
- **lazy-lock.json**: 自動更新される。変更があればコミットに含める
- **node_modules/**: textlint/docsify用。.gitignoreで除外済み
- **Mason**: LSPサーバーは別途`:MasonInstall <name>`でインストールが必要
- **キーマップ**: `<Leader>`はスペースキー。説明は日本語で記述

## よく使う遅延読み込みパターン

| パターン | 用途 |
|----------|------|
| `event = "VeryLazy"` | 起動後に読み込み |
| `event = { "BufReadPre", "BufNewFile" }` | ファイル開いた時 |
| `cmd = { "Command" }` | コマンド実行時 |
| `keys = { ... }` | キーマップ使用時 |
| `ft = { "lua", "typescript" }` | 特定ファイルタイプ |
