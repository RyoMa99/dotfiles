return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<Leader>gv", "<cmd>DiffviewOpen<cr>", desc = "差分を表示" },
    { "<Leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "ファイル履歴" },
    { "<Leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "ブランチ履歴" },
  },
  opts = {
    keymaps = {
      view = {
        { "n", "<leader>E", "<cmd>DiffviewToggleFiles<cr>", { desc = "ファイルパネル切替" } },
      },
      file_panel = {
        { "n", "<leader>E", "<cmd>DiffviewToggleFiles<cr>", { desc = "ファイルパネル切替" } },
      },
    },
  },
}
