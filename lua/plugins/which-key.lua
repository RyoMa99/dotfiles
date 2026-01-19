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
      { "<leader>f", group = "検索" },
      { "<leader>g", group = "Git" },
      { "<leader>x", group = "診断" },
      { "<leader>o", group = "GitHub" },
      { "<leader>b", group = "バッファ" },
      { "<leader>m", group = "Markdown" },
      { "<leader>a", group = "AI" },
      { "<leader>c", group = "コード" },
      { "<leader>r", group = "リファクタ" },
      { "<leader>t", group = "トグル" },
    })
  end,
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "キーマップ一覧",
    },
  },
}
