return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<Leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit を開く" },
  },
  config = function()
    vim.g.lazygit_use_neovim_remote = 1
    vim.env.GIT_EDITOR = "nvr --remote-tab-wait-silent"
  end,
}
