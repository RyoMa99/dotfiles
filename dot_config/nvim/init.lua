-- リーダーキー
vim.g.mapleader = " "

-- 行番号を表示
vim.opt.number = true

-- 相対行番号を表示
vim.opt.relativenumber = true

-- クリップボード連携 (MacのCommand+C/Vと共有するのに必須)
vim.opt.clipboard = "unnamedplus"

-- インデント設定 (スペース2つ分)
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- 検索時に大文字小文字を区別しない
vim.opt.ignorecase = true
-- 検索パターンに大文字を含む時は区別する
vim.opt.smartcase = true

-- マウス操作を有効にする
vim.opt.mouse = "a"

-- カーソル行をハイライト
vim.opt.cursorline = true

-- スクロール時に上下に余白を確保
vim.opt.scrolloff = 8

-- 永続的なundo履歴
vim.opt.undofile = true

-- 24bitカラーサポート
vim.opt.termguicolors = true

-- 常にsigncolumnを表示
vim.opt.signcolumn = "yes"

-- CursorHold高速化
vim.opt.updatetime = 250

-- 垂直分割を右に
vim.opt.splitright = true

-- 水平分割を下に
vim.opt.splitbelow = true

-- which-key高速表示
vim.opt.timeoutlen = 300

-- 行折り返し無効
vim.opt.wrap = false

-- swap無効
vim.opt.swapfile = false

-- keymap
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('v', 'jk', '<Esc>')

-- 折り返しトグル
vim.keymap.set("n", "<Leader>tw", "<cmd>set wrap!<cr>", { desc = "折り返し切替" })

-- カーソル行のMarkdownリンクをブラウザで開く
vim.keymap.set("n", "gx", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- カーソル位置を含む [text](url) を探す
  local start = 1
  while start <= #line do
    local ms, me, url = line:find("%[.-%]%((.-)%)", start)
    if not ms then break end
    if col >= ms and col <= me then
      vim.ui.open(url)
      return
    end
    start = me + 1
  end

  -- 見つからなければカーソル下のURLを開く（デフォルト動作）
  local url = vim.fn.expand("<cfile>")
  if url:match("^https?://") then
    vim.ui.open(url)
  end
end, { desc = "リンクをブラウザで開く" })

-- lazy.nvim
require("config.lazy")
