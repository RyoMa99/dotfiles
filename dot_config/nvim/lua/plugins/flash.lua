return {
  "folke/flash.nvim",
  event = "VeryLazy",
  keys = {
    { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "ジャンプ" },
    { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Treesitter 選択" },
  },
  opts = {
    modes = {
      char = {
        enabled = true,
        jump_labels = true,
      },
      search = {
        enabled = false,
      },
    },
  },
}
