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
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlight TODO comments |
| [nvim-various-textobjs](https://github.com/chrisgrieser/nvim-various-textobjs) | Additional text objects |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP server installer |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Completion engine |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine |
| [fidget.nvim](https://github.com/j-hui/fidget.nvim) | LSP progress UI |
| [trouble.nvim](https://github.com/folke/trouble.nvim) | Diagnostics list |

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
| `<Space>ft` | Find TODOs |

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

### TODO Comments

| Key | Action |
|-----|--------|
| `]t` | Next TODO |
| `[t` | Previous TODO |

### Text Objects (various-textobjs)

| Key | Object |
|-----|--------|
| `ii`/`ai` | Indentation block |
| `iS`/`aS` | Subword (camelCase) |
| `in`/`an` | Number |
| `iu`/`au` | URL |
| `ik`/`ak` | Key |
| `iv`/`av` | Value |

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | Go to references |
| `K` | Hover documentation |
| `<Space>rn` | Rename symbol |
| `<Space>ca` | Code action |
| `<Space>f` | Format |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

### Completion

| Key | Action |
|-----|--------|
| `<Tab>` | Next item / expand snippet |
| `<S-Tab>` | Previous item |
| `<CR>` | Confirm |
| `<C-Space>` | Trigger completion |
| `<C-e>` | Abort |

### Trouble

| Key | Action |
|-----|--------|
| `<Space>xx` | Toggle all diagnostics |
| `<Space>xd` | Toggle buffer diagnostics |
| `<Space>xq` | Toggle quickfix |

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
        ├── cmp.lua
        ├── colorscheme.lua
        ├── fidget.lua
        ├── flash.lua
        ├── lspconfig.lua
        ├── lualine.lua
        ├── mason.lua
        ├── nvim-tree.lua
        ├── oil.lua
        ├── sleuth.lua
        ├── surround.lua
        ├── targets.lua
        ├── telescope.lua
        ├── todo-comments.lua
        ├── treesitter.lua
        ├── trouble.lua
        ├── ufo.lua
        └── various-textobjs.lua
```
