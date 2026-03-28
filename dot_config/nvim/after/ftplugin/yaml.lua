-- YAML 配列要素の `- ` を改行時に自動継続
vim.opt_local.comments = ":#,b:-"
vim.opt_local.formatoptions:append("r") -- Enter で継続
vim.opt_local.formatoptions:append("o") -- o/O で継続

-- treesitter indent は `- ` の次行をネストするため無効化
vim.schedule(function()
  vim.bo.indentexpr = ""
end)
