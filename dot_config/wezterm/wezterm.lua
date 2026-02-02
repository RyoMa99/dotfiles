local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- フォント
config.font = wezterm.font("Hack Nerd Font Mono")
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
    overrides.colors = nil
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
config.window_background_opacity = 0.55
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

-- キーバインド（iTerm2から移植）
config.keys = {
  -- ペイン分割
  { key = "h", mods = "CMD|CTRL", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "v", mods = "CMD|CTRL", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- ペイン移動
  { key = "j", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l", mods = "CMD|CTRL", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "h", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Left") },
}

return config
