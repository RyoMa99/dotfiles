return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Leader>op", "<cmd>Octo pr list<cr>", desc = "List PRs" },
    { "<Leader>oi", "<cmd>Octo issue list<cr>", desc = "List issues" },
    { "<Leader>or", "<cmd>Octo review start<cr>", desc = "Start review" },
  },
  opts = {},
}
