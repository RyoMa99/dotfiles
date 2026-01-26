return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<Leader>op", "<cmd>Octo pr search review-requested:@me is:open<cr>", desc = "レビュー依頼PR一覧" },
    { "<Leader>oc", "<cmd>Octo pr create<cr>", desc = "PR 作成" },
    { "<Leader>ok", "<cmd>Octo pr checkout<cr>", desc = "PRブランチにチェックアウト" },
    { "<Leader>oi", "<cmd>Octo issue list<cr>", desc = "Issue 一覧" },
    { "<Leader>or", "<cmd>Octo review start<cr>", desc = "レビュー開始" },
    { "<Leader>oR", "<cmd>Octo review resume<cr>", desc = "レビュー再開" },
    { "<Leader>od", "<cmd>Octo review discard<cr>", desc = "レビュー破棄" },
    { "<Leader>os", "<cmd>Octo review submit<cr>", desc = "レビュー送信" },
  },
  config = function()
    -- diffview中にgfで新しいタブにファイルを開く
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "octo://*",
      callback = function()
        vim.keymap.set("n", "gf", function()
          local bufname = vim.api.nvim_buf_get_name(0)
          local filepath = bufname:match("/file/[^/]+/(.+)$")
          if filepath then
            local matches = vim.fn.glob(filepath .. ".*", false, true)
            if #matches > 0 then
              vim.cmd("tabnew " .. matches[1])
            else
              vim.cmd("tabnew " .. filepath)
            end
          end
        end, { buffer = true, desc = "ファイルを新しいタブで開く" })
      end,
    })

    require("octo").setup({
      suppress_missing_scope = {
        projects_v2 = true,
      },
      mappings_disable_default = false,
      mappings = {
        review_diff = {
          add_review_comment = { lhs = "<Leader>ca", desc = "コメント追加" },
          add_review_suggestion = { lhs = "<Leader>cs", desc = "サジェスト追加" },
          select_next_entry = { lhs = "]q", desc = "次のファイル" },
          select_prev_entry = { lhs = "[q", desc = "前のファイル" },
          close_review_tab = { lhs = "<Leader>oq", desc = "レビュータブを閉じる" },
          toggle_viewed = { lhs = "<Leader>ov", desc = "閲覧済みトグル" },
        },
        review_thread = {
          add_comment = { lhs = "<Leader>ca", desc = "コメント追加" },
          add_suggestion = { lhs = "<Leader>cs", desc = "サジェスト追加" },
        },
        issue = {
          open_in_browser = { lhs = "<Leader>ob", desc = "ブラウザで開く" },
        },
        pull_request = {
          open_in_browser = { lhs = "<Leader>ob", desc = "ブラウザで開く" },
        },
        submit_win = {
          approve_review = { lhs = "<C-a>", desc = "Approve" },
          comment_review = { lhs = "<C-m>", desc = "Comment のみ" },
          request_changes = { lhs = "<C-r>", desc = "Request changes" },
        },
      },
    })
  end,
}
