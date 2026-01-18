return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  keys = {
    { "<Leader>xx", "<cmd>Trouble diagnostics toggle focus=true<cr>", desc = "全診断を表示" },
    { "<Leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0 focus=true<cr>", desc = "バッファの診断を表示" },
    { "<Leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix を表示" },
    { "<Leader>xf", "<cmd>Trouble focus<cr>", desc = "Trouble にフォーカス" },
  },
  opts = {},
}
