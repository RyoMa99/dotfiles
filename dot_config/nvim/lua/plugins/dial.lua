return {
  "monaqa/dial.nvim",
  event = "VeryLazy",
  keys = {
    { "<C-a>", function() require("dial.map").manipulate("increment", "normal") end, desc = "インクリメント" },
    { "<C-x>", function() require("dial.map").manipulate("decrement", "normal") end, desc = "デクリメント" },
    { "g<C-a>", function() require("dial.map").manipulate("increment", "gnormal") end, desc = "インクリメント(連番)" },
    { "g<C-x>", function() require("dial.map").manipulate("decrement", "gnormal") end, desc = "デクリメント(連番)" },
    { "<C-a>", function() require("dial.map").manipulate("increment", "visual") end, mode = "v", desc = "インクリメント" },
    { "<C-x>", function() require("dial.map").manipulate("decrement", "visual") end, mode = "v", desc = "デクリメント" },
    { "g<C-a>", function() require("dial.map").manipulate("increment", "gvisual") end, mode = "v", desc = "インクリメント(連番)" },
    { "g<C-x>", function() require("dial.map").manipulate("decrement", "gvisual") end, mode = "v", desc = "デクリメント(連番)" },
  },
  config = function()
    local augend = require("dial.augend")
    require("dial.config").augends:register_group({
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.constant.alias.bool,
        augend.date.alias["%Y/%m/%d"],
        augend.date.alias["%Y-%m-%d"],
        augend.semver.alias.semver,
        augend.constant.new({ elements = { "&&", "||" }, word = false }),
        augend.constant.new({ elements = { "let", "const" } }),
        augend.constant.new({ elements = { "public", "private", "protected" } }),
        augend.constant.new({ elements = { "pick", "omit" } }),
      },
    })
  end,
}
