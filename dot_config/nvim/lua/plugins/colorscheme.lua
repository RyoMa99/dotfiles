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
          FloatBorder = { bg = "none", fg = colors.palette.sumiInk6 },
          -- CursorLineの背景を明示的に設定
          CursorLine = { bg = colors.palette.sumiInk4 },
          -- Telescope のボーダーを明示的に表示
          TelescopeBorder = { bg = "none", fg = colors.palette.sumiInk6 },
          TelescopePromptBorder = { bg = "none", fg = colors.palette.sumiInk6 },
          TelescopeResultsBorder = { bg = "none", fg = colors.palette.sumiInk6 },
          TelescopePreviewBorder = { bg = "none", fg = colors.palette.sumiInk6 },
        }
      end,
    })
    vim.cmd([[colorscheme kanagawa]])
  end,
}
