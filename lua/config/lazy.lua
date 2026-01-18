-- https://eiji.page/blog/neovim-lazy-nvim-intro/
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins.colorscheme" },
    { import = "plugins.autopairs" },
    { import = "plugins.lualine" },
    { import = "plugins.autosave" },
    { import = "plugins.treesitter" },
    { import = "plugins.ufo" },
    { import = "plugins.targets" },
    { import = "plugins.oil" },
    { import = "plugins.nvim-tree" },
    { import = "plugins.barbar" },
    { import = "plugins.telescope" },
    { import = "plugins.flash" },
    { import = "plugins.surround" },
    { import = "plugins.sleuth" },
    { import = "plugins.todo-comments" },
    { import = "plugins.various-textobjs" },
    { import = "plugins.mason" },
    { import = "plugins.lspconfig" },
    { import = "plugins.cmp" },
    { import = "plugins.fidget" },
    { import = "plugins.trouble" },
    { import = "plugins.lazygit" },
    { import = "plugins.gitsigns" },
    { import = "plugins.diffview" },
    { import = "plugins.octo" },
    { import = "plugins.peek" },
    { import = "plugins.lint" },
    { import = "plugins.noice" },
    { import = "plugins.claudecode" },
    { import = "plugins.which-key" },
  },
})
