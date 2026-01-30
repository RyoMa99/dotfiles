return {
  "WilliamHsieh/overlook.nvim",
  opts = {
    border = "rounded",
  },
  keys = {
    { "gp", function() require("overlook.api").peek_definition() end, desc = "定義をプレビュー" },
    { "gP", function() require("overlook.api").close_all() end, desc = "プレビューを全て閉じる" },
  },
}
