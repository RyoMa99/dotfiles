return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<Leader>e", "<cmd>NvimTreeToggle<cr>", desc = "ファイルツリー切替" },
  },
  config = function()
    require("nvim-tree").setup({
      filters = {
        dotfiles = false,
      },
      git = {
        enable = true,
        ignore = false,
      },
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      renderer = {
        indent_markers = {
          enable = true,
        },
        highlight_git = true,
      },
      diagnostics = {
        enable = true,
      },
      view = {
        float = {
          enable = true,
          open_win_config = {
            relative = "editor",
            col = vim.o.columns,
            row = 0,
            width = 40,
            height = vim.o.lines - 4,
            anchor = "NE",
          },
        },
      },
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
    })
  end,
}
