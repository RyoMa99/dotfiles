local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- フォント
config.font = wezterm.font_with_fallback({
  "Hack Nerd Font Mono",
  "Hiragino Kaku Gothic ProN",
})
config.font_size = 16.0

-- カラースキーム（Light/Dark自動切替）
-- iTerm2のライトモードの色を再現したカスタムスキーム
local kanagawa_light = {
  foreground = "#101010",
  background = "#fafafa",
  cursor_bg = "#000000",
  cursor_fg = "#ffffff",
  selection_bg = "#b3d7ff",
  selection_fg = "#000000",
  ansi = {
    "#14191e", -- black
    "#b43c29", -- red
    "#00c200", -- green
    "#c7c400", -- yellow
    "#2744c7", -- blue
    "#c040be", -- magenta
    "#00c5c7", -- cyan
    "#c7c7c7", -- white
  },
  brights = {
    "#686868", -- bright black
    "#dd7975", -- bright red
    "#58e790", -- bright green
    "#ece100", -- bright yellow
    "#a7abf2", -- bright blue
    "#e17ee1", -- bright magenta
    "#60fdff", -- bright cyan
    "#ffffff", -- bright white
  },
}

local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Kanagawa (Gogh)"
  else
    return nil -- カスタムスキームを使用
  end
end

local function apply_appearance(window)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)

  if scheme then
    overrides.color_scheme = scheme
    overrides.colors = { background = "#050508" }
  else
    overrides.color_scheme = nil
    overrides.colors = kanagawa_light
  end
  window:set_config_overrides(overrides)
end

wezterm.on("window-config-reloaded", function(window)
  apply_appearance(window)
end)

-- 初期値（ダークモードをデフォルト）
config.color_scheme = "Kanagawa (Gogh)"

-- 透明度
config.window_background_opacity = 0.75
config.macos_window_background_blur = 20

-- カーソル
config.default_cursor_style = "SteadyBar"

-- スクロールバック
config.scrollback_lines = 5000

-- ウィンドウ
config.native_macos_fullscreen_mode = true

-- Option Key を Alt として使用（Esc+ 送信）
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- ターミナル
config.term = "xterm-256color"
config.default_prog = { wezterm.home_dir .. "/.local/bin/tmux-start" }

-- キーバインド
config.keys = {
  -- Send Hex / Escape Sequences
  { key = "$", mods = "ALT|SHIFT", action = wezterm.action.SendString("\x05") },  -- Ctrl+E（行末）
  { key = "0", mods = "ALT", action = wezterm.action.SendString("\x01") },  -- Ctrl+A（行頭）
  { key = "b", mods = "ALT", action = wezterm.action.SendString("\x1bb") },  -- 単語後退
  { key = "w", mods = "ALT", action = wezterm.action.SendString("\x1bf") },  -- 単語前進
  -- デフォルトキーバインド無効化（OS/Raycastに委譲）
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
  -- フォントサイズ変更（Command+/-のデフォルトを無効化してAlt+/-に移動）
  { key = "=", mods = "SUPER", action = wezterm.action.DisableDefaultAssignment },
  { key = "+", mods = "SUPER|SHIFT", action = wezterm.action.DisableDefaultAssignment },
  { key = "+", mods = "ALT|SHIFT", action = wezterm.action.IncreaseFontSize },
  { key = "-", mods = "ALT", action = wezterm.action.DecreaseFontSize },
  -- Alt+Enterの全画面トグルを無効化（Claude Codeの改行に使用）
  { key = "Enter", mods = "ALT", action = wezterm.action.SendKey({ key = "Enter", mods = "ALT" }) },
-- tmux ペインを閉じる（prefix + x を直接送信）
  { key = "w", mods = "SUPER", action = wezterm.action.SendString("\x02x") },
  -- tmux ペイン入れ替え（prefix + }/{ を直接送信）
  { key = "s", mods = "SUPER", action = wezterm.action.SendString("\x02}") },
  { key = "s", mods = "SUPER|SHIFT", action = wezterm.action.SendString("\x02{") },
  -- tmux ペイン分割（prefix + -/| を直接送信）
  { key = "-", mods = "SUPER", action = wezterm.action.SendString("\x02-") },
  { key = "|", mods = "SUPER|SHIFT", action = wezterm.action.SendString("\x02|") },
  -- tmux ペインリサイズ（prefix + HJKL を直接送信）
  { key = "h", mods = "ALT|SHIFT", action = wezterm.action.SendString("\x02H") },
  { key = "j", mods = "ALT|SHIFT", action = wezterm.action.SendString("\x02J") },
  { key = "k", mods = "ALT|SHIFT", action = wezterm.action.SendString("\x02K") },
  { key = "l", mods = "ALT|SHIFT", action = wezterm.action.SendString("\x02L") },
  -- tmux ペイン移動（prefix + hjkl を直接送信）
  { key = "h", mods = "ALT|SUPER", action = wezterm.action.SendString("\x02h") },
  { key = "j", mods = "ALT|SUPER", action = wezterm.action.SendString("\x02j") },
  { key = "k", mods = "ALT|SUPER", action = wezterm.action.SendString("\x02k") },
  { key = "l", mods = "ALT|SUPER", action = wezterm.action.SendString("\x02l") },
  -- tmux ウィンドウ追加・削除（prefix + c/& を直接送信）
  { key = "n", mods = "CTRL", action = wezterm.action.SendString("\x02c") },
  { key = "w", mods = "CTRL", action = wezterm.action.SendString("\x02&") },
  -- tmux ウィンドウ移動（prefix + n/p を直接送信）
  { key = "Tab", mods = "CTRL", action = wezterm.action.SendString("\x02n") },
  { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x02p") },
}

return config
