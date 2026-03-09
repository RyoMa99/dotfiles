return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Oil",
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "親ディレクトリを開く" },
  },
  opts = {
    -- ファイルシステムの変更を監視して自動更新
    watch_for_changes = true,
    -- 隠しファイルを表示
    view_options = {
      show_hidden = true,
    },
    -- ゴミ箱を使う (macOSの場合)
    delete_to_trash = true,
    -- デフォルトのファイル操作
    use_default_keymaps = true,
    -- カラム設定
    columns = {
      "icon",
    },
    keymaps = {
      -- qで閉じる
      ["q"] = "actions.close",
    },
  },
}
