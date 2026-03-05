return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("kanagawa").setup({
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      overrides = function(colors)
        return {
          -- 背景を透過してWezTermの背景・透明度をそのまま活かす
          Normal = { bg = "none" },
          NormalFloat = { bg = "none" },
          -- CursorLineの背景を明示的に設定
          CursorLine = { bg = colors.palette.sumiInk4 },
        }
      end,
    })
    vim.cmd([[colorscheme kanagawa]])
  end,
}
