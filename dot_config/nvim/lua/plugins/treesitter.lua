return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- 自動インストールする言語
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "javascript",
        "typescript",
        "python",
        "rust",
        "go",
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
        "html",
        "css",
        "tsx",
      },

      -- 自動インストールを有効化
      auto_install = true,

      -- ハイライトを有効化
      highlight = {
        enable = true,
      },

      -- インデントを有効化
      indent = {
        enable = true,
      },

      -- incremental selection（段階的選択）
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "+",
          node_incremental = "+",
          node_decremental = "-",
        },
      },

      -- textobjects
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            -- 関数
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            -- クラス
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            -- 条件文
            ["ai"] = "@conditional.outer",
            ["ii"] = "@conditional.inner",
            -- ループ
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
          },
        },
      },
    })
  end,
}
