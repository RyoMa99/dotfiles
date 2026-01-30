return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local npairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")

    npairs.setup({
      -- カーソルの後ろに何があってもautopairsを有効にする
      ignored_next_char = "",
    })

    npairs.add_rules({
      -- デフォルトだと "not_add_quote_inside_quote" により
      -- クオートの中でautopairできないので自前で定義する
      Rule('"', '"'),
      Rule("'", "'"),
    })
  end,
}
