return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  opts = {
    terminal = {
      provider = "none",
    },
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
    },
  },
  keys = {
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "選択範囲を送信" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "バッファを追加" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "差分を承認" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "差分を拒否" },
  },
}
