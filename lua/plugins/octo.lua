return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Leader>op", "<cmd>Octo pr list<cr>", desc = "PR 一覧" },
    { "<Leader>oi", "<cmd>Octo issue list<cr>", desc = "Issue 一覧" },
    { "<Leader>or", "<cmd>Octo review start<cr>", desc = "レビュー開始" },
  },
  opts = {},
}
