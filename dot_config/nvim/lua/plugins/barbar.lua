return {
  "romgrk/barbar.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  event = "BufEnter",
  keys = {
    { "<A-,>", "<cmd>BufferPrevious<cr>", desc = "前のバッファ" },
    { "<A-.>", "<cmd>BufferNext<cr>", desc = "次のバッファ" },
    { "<A-c>", "<cmd>BufferClose<cr>", desc = "バッファを閉じる" },
    { "<A-p>", "<cmd>BufferPin<cr>", desc = "バッファをピン留め" },
    { "<A-1>", "<cmd>BufferGoto 1<cr>", desc = "バッファ1へ" },
    { "<A-2>", "<cmd>BufferGoto 2<cr>", desc = "バッファ2へ" },
    { "<A-3>", "<cmd>BufferGoto 3<cr>", desc = "バッファ3へ" },
    { "<A-4>", "<cmd>BufferGoto 4<cr>", desc = "バッファ4へ" },
    { "<A-5>", "<cmd>BufferGoto 5<cr>", desc = "バッファ5へ" },
    { "<leader>bc", "<cmd>BufferCloseAllButCurrent<cr>", desc = "他のバッファを全て閉じる" },
    { "<leader>ba", "<cmd>BufferCloseAll<cr>", desc = "全てのバッファを閉じる" },
  },
  opts = {
    animation = false,
    auto_hide = 1,
    exclude_ft = { "NvimTree" },
    exclude_name = { "" },
    no_name_title = nil,
  },
}
