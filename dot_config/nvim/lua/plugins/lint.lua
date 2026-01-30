return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local nvim_dir = vim.fn.expand("~/.config/nvim")

    -- プロジェクトルートの検出
    local function find_project_root(patterns)
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

    -- プロジェクトのnode_modules/.binからバイナリを探す
    local function find_bin(name, config_patterns)
      local project_root = find_project_root(config_patterns)
      if project_root then
        local project_bin = project_root .. "/node_modules/.bin/" .. name
        if vim.fn.executable(project_bin) == 1 then
          return project_bin, project_root
        end
      end
      return nil, nil
    end

    local function has_biome()
      return find_project_root({ "biome.json", "biome.jsonc" }) ~= nil
    end

    local function has_eslint()
      return find_project_root({ ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js", "eslint.config.mjs" }) ~= nil
    end

    local function has_prettier()
      return find_project_root({ ".prettierrc", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.json", ".prettierrc.yml", "prettier.config.js", "prettier.config.cjs" }) ~= nil
    end

    local function has_phpstan()
      return find_project_root({ "phpstan.neon", "phpstan.neon.dist", "phpstan.dist.neon" }) ~= nil
    end

    -- プロジェクトのvendor/binからPHPバイナリを探す
    local function find_php_bin(name)
      local project_root = find_project_root({ "composer.json" })
      if project_root then
        local vendor_bin = project_root .. "/vendor/bin/" .. name
        if vim.fn.executable(vendor_bin) == 1 then
          return vendor_bin, project_root
        end
      end
      return nil, nil
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

    -- biome のカスタム定義（cmdは動的に設定）
    lint.linters.biome = {
      cmd = "biome",
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

    -- phpstan のカスタム定義（cmdは動的に設定）
    lint.linters.phpstan = {
      cmd = "phpstan",
      stdin = false,
      args = { "analyze", "--error-format=json", "--no-progress" },
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
        for _, file in pairs(decoded.files or {}) do
          for _, msg in ipairs(file.messages or {}) do
            table.insert(diagnostics, {
              lnum = (msg.line or 1) - 1,
              col = 0,
              severity = msg.ignorable and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR,
              message = msg.message,
              source = "phpstan",
            })
          end
        end
        return diagnostics
      end,
    }

    -- eslint のカスタム定義（cmdは動的に設定）
    lint.linters.eslint_nvim = {
      cmd = "eslint",
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

    -- 自動でlintを実行（プロジェクトのnode_modules/vendorを使用）
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        local ft = vim.bo.filetype
        if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
          if has_biome() then
            local bin = find_bin("biome", { "biome.json", "biome.jsonc" })
            if bin then
              lint.linters.biome.cmd = bin
              lint.try_lint({ "biome" })
            end
          elseif has_eslint() then
            local bin = find_bin("eslint", { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js", "eslint.config.mjs" })
            if bin then
              lint.linters.eslint_nvim.cmd = bin
              lint.try_lint({ "eslint_nvim" })
            end
          end
        elseif ft == "php" then
          if has_phpstan() then
            local bin, project_root = find_php_bin("phpstan")
            if bin and project_root then
              lint.linters.phpstan.cmd = bin
              lint.linters.phpstan.cwd = project_root
              lint.try_lint({ "phpstan" })
            end
          end
        else
          lint.try_lint()
        end
      end,
    })

    -- TypeScript/JavaScript: 保存時にフォーマット（プロジェクトのnode_modulesを使用）
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(bufnr)
        local bin

        -- 現在のバッファ内容を一時ファイルに書き出してフォーマット
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local content = table.concat(lines, "\n")

        if has_biome() then
          bin = find_bin("biome", { "biome.json", "biome.jsonc" })
          if bin then
            local formatted = vim.fn.system(bin .. " format --stdin-file-path=" .. vim.fn.shellescape(filename), content)
            if vim.v.shell_error == 0 then
              local new_lines = vim.split(formatted, "\n", { plain = true })
              if new_lines[#new_lines] == "" then
                table.remove(new_lines)
              end
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
            end
          end
        elseif has_prettier() then
          bin = find_bin("prettier", { ".prettierrc", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.json", ".prettierrc.yml", "prettier.config.js", "prettier.config.cjs" })
          if bin then
            local formatted = vim.fn.system(bin .. " --stdin-filepath " .. vim.fn.shellescape(filename), content)
            if vim.v.shell_error == 0 then
              local new_lines = vim.split(formatted, "\n", { plain = true })
              if new_lines[#new_lines] == "" then
                table.remove(new_lines)
              end
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
            end
          end
        end
      end,
    })
  end,
}
