return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "BufReadPost",
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "次の TODO" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "前の TODO" },
    { "<Leader>ft", "<cmd>TodoTelescope<cr>", desc = "TODO 検索" },
  },
  opts = {},
}
