return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "classic",
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- グループのプレフィックス設定
    wk.add({
      { "<leader>f", group = "Find (Telescope)" },
      { "<leader>g", group = "Git" },
      { "<leader>x", group = "Diagnostics (Trouble)" },
      { "<leader>o", group = "GitHub (Octo)" },
      { "<leader>b", group = "Buffer" },
      { "<leader>m", group = "Markdown" },
      { "<leader>a", group = "AI (Claude)" },
    })
  end,
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps",
    },
  },
}
