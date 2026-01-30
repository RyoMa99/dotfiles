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

-- lazy.nvim
require("config.lazy")
