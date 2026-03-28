-- YAML 配列要素の `- ` を改行時に自動継続
vim.opt_local.comments = ":#,fb:-"
vim.opt_local.formatoptions:append("r") -- Enter で継続
vim.opt_local.formatoptions:append("o") -- o/O で継続
