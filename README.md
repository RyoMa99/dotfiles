# My Neovim Config

## Requirements

- Neovim >= 0.9
- ripgrep (for telescope live_grep)
- lazygit (for lazygit.nvim)
- neovim-remote (for lazygit.nvim integration)
- gh CLI (for octo.nvim)
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
| [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) | Git UI |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git signs / blame |
| [diffview.nvim](https://github.com/sindrets/diffview.nvim) | Git diff / history viewer |
| [octo.nvim](https://github.com/pwntester/octo.nvim) | GitHub PR / Issue manager |

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

#### Inside Trouble panel

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate |
| `Enter` | Jump and close |
| `o` | Jump (keep open) |
| `p` | Preview |
| `q` | Close |
| `s` | Sort by severity |

### Git (lazygit)

| Key | Action |
|-----|--------|
| `<Space>gg` | Open LazyGit |

### Git (gitsigns)

| Key | Action |
|-----|--------|
| `]c` / `[c` | Next / previous hunk |
| `<Space>gs` | Stage hunk |
| `<Space>gr` | Reset hunk |
| `<Space>gS` | Stage buffer |
| `<Space>gu` | Undo stage hunk |
| `<Space>gR` | Reset buffer |
| `<Space>gp` | Preview hunk |
| `<Space>gb` | Blame line (popup) |
| `<Space>gB` | Toggle inline blame |
| `<Space>gd` | Diff this |
| `ih` | Hunk text object |

### Git (diffview)

| Key | Action |
|-----|--------|
| `<Space>gv` | Open Diffview |
| `<Space>gh` | File history |
| `<Space>gH` | Branch history |

### GitHub (octo)

| Key | Action |
|-----|--------|
| `<Space>op` | List PRs |
| `<Space>oi` | List issues |
| `<Space>or` | Start review |

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
        ├── diffview.lua
        ├── fidget.lua
        ├── flash.lua
        ├── gitsigns.lua
        ├── lazygit.lua
        ├── lspconfig.lua
        ├── lualine.lua
        ├── mason.lua
        ├── nvim-tree.lua
        ├── octo.lua
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
