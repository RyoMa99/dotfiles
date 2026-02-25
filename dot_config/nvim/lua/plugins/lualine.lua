return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      theme = "auto",
      component_separators = { left = "|", right = "|" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = {
        {
          function()
            local path = vim.fn.expand("%:p")
            if path == "" then return "[No Name]" end
            local git_root = vim.fs.root(0, ".git")
            if git_root then
              local rel = path:sub(#git_root + 2)
              if rel ~= "" then return rel end
            end
            return vim.fn.fnamemodify(path, ":~:.")
          end,
        },
      },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
