return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "mason.nvim",
    "mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- キーマップ設定
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<Leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      end,
    })

    -- Lua LSP
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
  end,
}
