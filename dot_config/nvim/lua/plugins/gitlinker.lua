return {
  "ruifm/gitlinker.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<Leader>gy", function() require("gitlinker").get_buf_range_url("n") end, desc = "GitHub permalink をコピー" },
    { "<Leader>gy", function() require("gitlinker").get_buf_range_url("v") end, mode = "v", desc = "GitHub permalink をコピー" },
  },
  opts = {},
}
