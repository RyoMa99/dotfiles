return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local nvim_dir = vim.fn.expand("~/.config/nvim")

    -- プロジェクト設定ファイルの検出
    local function find_config(patterns)
      local path = vim.fn.expand("%:p:h")
      while path ~= "/" do
        for _, pattern in ipairs(patterns) do
          if vim.fn.filereadable(path .. "/" .. pattern) == 1 then
            return path
          end
        end
        path = vim.fn.fnamemodify(path, ":h")
      end
      return nil
    end

    local function has_biome()
      return find_config({ "biome.json", "biome.jsonc" }) ~= nil
    end

    local function has_eslint()
      return find_config({ ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js", "eslint.config.mjs" }) ~= nil
    end

    local function has_prettier()
      return find_config({ ".prettierrc", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.json", ".prettierrc.yml", "prettier.config.js", "prettier.config.cjs" }) ~= nil
    end

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

    -- biome のカスタム定義
    lint.linters.biome = {
      cmd = nvim_dir .. "/node_modules/.bin/biome",
      stdin = false,
      args = { "lint", "--reporter", "json" },
      stream = "stdout",
      ignore_exitcode = true,
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
        for _, diag in ipairs(decoded.diagnostics or {}) do
          local severity = vim.diagnostic.severity.WARN
          if diag.severity == "error" then
            severity = vim.diagnostic.severity.ERROR
          end
          table.insert(diagnostics, {
            lnum = (diag.location and diag.location.span and diag.location.span[1] and diag.location.span[1].line or 1) - 1,
            col = (diag.location and diag.location.span and diag.location.span[1] and diag.location.span[1].character or 1) - 1,
            severity = severity,
            message = diag.message or diag.description or "biome error",
            source = "biome",
          })
        end
        return diagnostics
      end,
    }

    -- eslint のカスタム定義
    lint.linters.eslint_nvim = {
      cmd = nvim_dir .. "/node_modules/.bin/eslint",
      stdin = false,
      args = { "--format", "json" },
      stream = "stdout",
      ignore_exitcode = true,
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
          for _, msg in ipairs(file.messages or {}) do
            local severity = vim.diagnostic.severity.WARN
            if msg.severity == 2 then
              severity = vim.diagnostic.severity.ERROR
            end
            table.insert(diagnostics, {
              lnum = (msg.line or 1) - 1,
              col = (msg.column or 1) - 1,
              end_lnum = (msg.endLine or msg.line or 1) - 1,
              end_col = (msg.endColumn or msg.column or 1) - 1,
              severity = severity,
              message = msg.message,
              source = "eslint",
            })
          end
        end
        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      markdown = { "textlint" },
    }

    -- 自動でlintを実行（プロジェクト設定に応じて切替）
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        local ft = vim.bo.filetype
        if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
          if has_biome() then
            lint.try_lint({ "biome" })
          elseif has_eslint() then
            lint.try_lint({ "eslint_nvim" })
          end
        else
          lint.try_lint()
        end
      end,
    })

    -- TypeScript/JavaScript: 保存時にフォーマット（プロジェクト設定に応じて切替）
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(bufnr)
        local cmd

        if has_biome() then
          cmd = nvim_dir .. "/node_modules/.bin/biome format --write " .. vim.fn.shellescape(filename)
        elseif has_prettier() then
          cmd = nvim_dir .. "/node_modules/.bin/prettier --write " .. vim.fn.shellescape(filename)
        else
          return
        end

        vim.fn.system(cmd)
        vim.cmd("edit!")
      end,
    })
  end,
}
