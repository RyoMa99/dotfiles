return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local npairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")

    npairs.setup({
      -- カーソルの後ろに何があってもautopairsを有効にする
      ignored_next_char = "",
      -- クオートの中でもautopairを有効にする
      enable_check_bracket_in_quote = true,
    })
  end,
}
