return {
  "romgrk/barbar.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufEnter",
  keys = {
    { "<A-,>", "<cmd>BufferPrevious<cr>", desc = "Previous buffer" },
    { "<A-.>", "<cmd>BufferNext<cr>", desc = "Next buffer" },
    { "<A-c>", "<cmd>BufferClose<cr>", desc = "Close buffer" },
    { "<A-p>", "<cmd>BufferPin<cr>", desc = "Pin buffer" },
    { "<A-1>", "<cmd>BufferGoto 1<cr>", desc = "Go to buffer 1" },
    { "<A-2>", "<cmd>BufferGoto 2<cr>", desc = "Go to buffer 2" },
    { "<A-3>", "<cmd>BufferGoto 3<cr>", desc = "Go to buffer 3" },
    { "<A-4>", "<cmd>BufferGoto 4<cr>", desc = "Go to buffer 4" },
    { "<A-5>", "<cmd>BufferGoto 5<cr>", desc = "Go to buffer 5" },
    { "<leader>bc", "<cmd>BufferCloseAllButCurrent<cr>", desc = "Close all but current" },
    { "<leader>ba", "<cmd>BufferCloseAll<cr>", desc = "Close all buffers" },
  },
  opts = {
    animation = false,
    auto_hide = 1,
    exclude_ft = { "NvimTree" },
    exclude_name = { "" },
    no_name_title = nil,
  },
}
