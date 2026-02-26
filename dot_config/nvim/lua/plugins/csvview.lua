return {
  "hat0uma/csvview.nvim",
  ft = { "csv", "tsv" },
  cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  opts = {
    parser = {
      comments = { "#" },
    },
    view = {
      display_mode = "border",
      min_column_width = 5,
      spacing = 2,
      sticky_header = {
        enabled = true,
        separator = "─",
      },
    },
    keymaps = {
      textobject_field_inner = { "if", mode = { "o", "x" } },
      textobject_field_outer = { "af", mode = { "o", "x" } },
      jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
      jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
      jump_next_row = { "<Enter>", mode = { "n", "v" } },
      jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
    },
  },
  config = function(_, opts)
    require("csvview").setup(opts)

    -- setup() 後にハイライトを上書き（kanagawa palette hex 値を直接指定）
    local hl = vim.api.nvim_set_hl
    hl(0, "CsvViewCol0", { fg = "#7E9CD8" }) -- crystalBlue
    hl(0, "CsvViewCol1", { fg = "#98BB6C" }) -- springGreen
    hl(0, "CsvViewCol2", { fg = "#FFA066" }) -- surimiOrange
    hl(0, "CsvViewCol3", { fg = "#D27E99" }) -- sakuraPink
    hl(0, "CsvViewCol4", { fg = "#7AA89F" }) -- waveAqua2
    hl(0, "CsvViewCol5", { fg = "#E6C384" }) -- carpYellow
    hl(0, "CsvViewCol6", { fg = "#957FB8" }) -- oniViolet
    hl(0, "CsvViewCol7", { fg = "#938AA9" }) -- springViolet1
    hl(0, "CsvViewCol8", { fg = "#FF5D62" }) -- peachRed

    -- CSV/TSV を開いたら自動で有効化
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "csv", "tsv" },
      callback = function(args)
        require("csvview").enable(args.buf)
      end,
    })
  end,
}
