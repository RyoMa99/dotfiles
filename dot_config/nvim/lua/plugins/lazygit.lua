return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = { "LazyGit" },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<Leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit を開く" },
    { "<Leader>gf", "<cmd>!git fetch --all<cr>", desc = "全リモートを取得" },
  },
  config = function()
    vim.g.lazygit_use_neovim_remote = 1

    local tmpfile = "/tmp/lazygit_edit_file"

    local function cleanup()
      pcall(function() require("noice").cmd("dismiss") end)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
        if ok and cfg.relative and cfg.relative ~= "" then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end

    -- e で開いたファイルにフォーカス＆フローティングウィンドウを閉じる
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local f = io.open(tmpfile, "r")
        if not f then return end
        local filepath = f:read("*l")
        f:close()
        if filepath == vim.fn.expand("%:p") then
          os.remove(tmpfile)
          for _, delay in ipairs({ 0, 100, 300 }) do
            vim.defer_fn(cleanup, delay)
          end
        end
      end,
    })

    vim.g.lazygit_on_exit_callback = cleanup
  end,
}
