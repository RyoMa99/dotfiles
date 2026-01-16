return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  keys = {
    { "<Leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    { "<Leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    { "<Leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix (Trouble)" },
  },
  opts = {},
}
