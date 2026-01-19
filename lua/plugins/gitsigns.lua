return {
  "lewis6991/gitsigns.nvim",
  event = "VeryLazy",
  opts = {
    current_line_blame = true,
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")
      local opts = { buffer = bufnr }

      -- Navigation
      vim.keymap.set("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, { buffer = bufnr, desc = "次の変更へ" })

      vim.keymap.set("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, { buffer = bufnr, desc = "前の変更へ" })

      -- Actions
      vim.keymap.set("n", "<Leader>gs", gitsigns.stage_hunk, { buffer = bufnr, desc = "変更をステージ" })
      vim.keymap.set("n", "<Leader>gr", gitsigns.reset_hunk, { buffer = bufnr, desc = "変更をリセット" })
      vim.keymap.set("v", "<Leader>gs", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { buffer = bufnr, desc = "選択範囲をステージ" })
      vim.keymap.set("v", "<Leader>gr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { buffer = bufnr, desc = "選択範囲をリセット" })
      vim.keymap.set("n", "<Leader>gS", gitsigns.stage_buffer, { buffer = bufnr, desc = "バッファをステージ" })
      vim.keymap.set("n", "<Leader>gu", gitsigns.undo_stage_hunk, { buffer = bufnr, desc = "ステージを取消" })
      vim.keymap.set("n", "<Leader>gR", gitsigns.reset_buffer, { buffer = bufnr, desc = "バッファをリセット" })
      vim.keymap.set("n", "<Leader>gp", gitsigns.preview_hunk, { buffer = bufnr, desc = "変更をプレビュー" })
      vim.keymap.set("n", "<Leader>gb", function()
        gitsigns.blame_line({ full = true })
      end, { buffer = bufnr, desc = "Blame を表示" })
      vim.keymap.set("n", "<Leader>gB", gitsigns.toggle_current_line_blame, { buffer = bufnr, desc = "インライン Blame 切替" })
      vim.keymap.set("n", "<Leader>gd", gitsigns.diffthis, { buffer = bufnr, desc = "差分を表示" })

      -- Text object
      vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { buffer = bufnr, desc = "Hunk を選択" })
    end,
  },
}
