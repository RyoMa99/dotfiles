return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local nvim_dir = vim.fn.expand("~/.config/nvim")

    -- textlint のカスタム定義
    lint.linters.textlint = {
      cmd = nvim_dir .. "/node_modules/.bin/textlint",
      stdin = false,
      args = { "--format", "json", "--no-color" },
      stream = "stdout",
      ignore_exitcode = true,
      cwd = nvim_dir,
      append_fname = true,
      parser = function(output, bufnr)
        if output == "" then
          return {}
        end
        local ok, decoded = pcall(vim.json.decode, output)
        if not ok then
          return {}
        end
        local diagnostics = {}
        for _, file in ipairs(decoded) do
          for _, message in ipairs(file.messages or {}) do
            table.insert(diagnostics, {
              lnum = (message.line or 1) - 1,
              col = (message.column or 1) - 1,
              end_lnum = (message.line or 1) - 1,
              end_col = (message.column or 1) - 1,
              severity = vim.diagnostic.severity.WARN,
              message = message.message,
              source = "textlint",
            })
          end
        end
        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      markdown = { "textlint" },
    }

    -- 自動でlintを実行
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
