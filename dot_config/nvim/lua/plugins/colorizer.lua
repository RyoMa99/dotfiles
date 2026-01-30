return {
  "norcalli/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    "css",
    "scss",
    "html",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    tailwind = {
      names = false,
      RGB = true,
      RRGGBB = true,
      RRGGBBAA = true,
      css = true,
      css_fn = true,
      tailwind = true,
    },
  },
}
