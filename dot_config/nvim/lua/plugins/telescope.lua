return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<Leader>ff", "<cmd>Telescope find_files<cr>", desc = "ファイル検索" },
    { "<Leader>fg", "<cmd>Telescope live_grep<cr>", desc = "文字列検索" },
    { "<Leader>fb", "<cmd>Telescope buffers<cr>", desc = "バッファ一覧" },
    { "<Leader>fh", "<cmd>Telescope help_tags<cr>", desc = "ヘルプ検索" },
    { "<Leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近のファイル" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            preview_width = 0.5,
          },
        },
        file_ignore_patterns = {
          "node_modules",
          ".git/",
          "%.lock",
        },
      },
    })
    telescope.load_extension("fzf")
  end,
}
