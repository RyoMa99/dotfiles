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
    { "<Leader>gf", "<cmd>!git fetch --all<cr>", desc = "全リモートを取得" },
  },
  config = function()
    vim.g.lazygit_use_neovim_remote = 1
    vim.env.GIT_EDITOR = "nvr --remote-tab-wait-silent"
  end,
}
