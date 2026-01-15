# My Neovim Config

## Requirements

- Neovim >= 0.9
- ripgrep (for telescope live_grep)
- Nerd Font (for icons)

## Plugins

| Plugin | Description |
|--------|-------------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | Colorscheme |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [barbar.nvim](https://github.com/romgrk/barbar.nvim) | Buffer tabline |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting |
| [nvim-ufo](https://github.com/kevinhwang91/nvim-ufo) | Folding |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | File explorer (buffer style) |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | File explorer (tree style) |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [flash.nvim](https://github.com/folke/flash.nvim) | Navigation / jump |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | Surround text objects |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto close brackets |
| [targets.vim](https://github.com/wellle/targets.vim) | Enhanced text objects |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim) | Auto save |
| [vim-sleuth](https://github.com/tpope/vim-sleuth) | Auto detect indent |

## Keymaps

### General

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `jk` | Escape (insert/visual mode) |

### File Explorer

| Key | Action |
|-----|--------|
| `-` | Open Oil (buffer file explorer) |
| `<Space>e` | Toggle nvim-tree (floating) |

### Telescope

| Key | Action |
|-----|--------|
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep |
| `<Space>fb` | Buffers |
| `<Space>fh` | Help tags |
| `<Space>fr` | Recent files |

### Buffer (barbar)

| Key | Action |
|-----|--------|
| `<Option-,>` | Previous buffer |
| `<Option-.>` | Next buffer |
| `<Option-c>` | Close buffer |
| `<Option-p>` | Pin buffer |
| `<Option-1~5>` | Go to buffer 1~5 |

### Navigation (flash)

| Key | Action |
|-----|--------|
| `s` | Flash jump |
| `S` | Flash treesitter |
| `f/t/F/T` | Enhanced with labels |

### Surround

| Key | Action |
|-----|--------|
| `ys{motion}{char}` | Add surround |
| `cs{old}{new}` | Change surround |
| `ds{char}` | Delete surround |
| `S{char}` | Surround visual selection |

### Folding

| Key | Action |
|-----|--------|
| `za` | Toggle fold |
| `zR` | Open all folds |
| `zM` | Close all folds |

## Directory Structure

```
~/.config/nvim/
├── init.lua              # Entry point
├── lazy-lock.json        # Plugin versions
└── lua/
    ├── config/
    │   └── lazy.lua      # Lazy.nvim setup
    └── plugins/          # Plugin configurations
        ├── autopairs.lua
        ├── autosave.lua
        ├── barbar.lua
        ├── colorscheme.lua
        ├── flash.lua
        ├── lualine.lua
        ├── nvim-tree.lua
        ├── oil.lua
        ├── sleuth.lua
        ├── surround.lua
        ├── targets.lua
        ├── telescope.lua
        ├── treesitter.lua
        └── ufo.lua
```
