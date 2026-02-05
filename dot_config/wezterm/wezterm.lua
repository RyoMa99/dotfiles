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

-- 非アクティブペインの視覚的区別
config.inactive_pane_hsb = {
  saturation = 0.5,
  brightness = 0.4,
}

-- Option Key を Alt として使用（Esc+ 送信）
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- ターミナル
config.term = "xterm-256color"

-- キーバインド（iTerm2から移植）
config.keys = {
  -- ペイン分割（Cmd+D: 縦分割、Cmd+Shift+D: 横分割）
  { key = "d", mods = "CMD", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  -- ペイン選択（Alt+Cmd+hjkl）
  { key = "h", mods = "ALT|CMD", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "j", mods = "ALT|CMD", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k", mods = "ALT|CMD", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l", mods = "ALT|CMD", action = wezterm.action.ActivatePaneDirection("Right") },
  -- スクロール（Cmd+j/k）
  { key = "j", mods = "CMD", action = wezterm.action.ScrollByLine(1) },
  { key = "k", mods = "CMD", action = wezterm.action.ScrollByLine(-1) },
  -- ペイン入れ替え
  { key = "s", mods = "CMD", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },
  -- Send Hex / Escape Sequences
  { key = "$", mods = "ALT|SHIFT", action = wezterm.action.SendString("\x05") },  -- Ctrl+E（行末）
  { key = "0", mods = "ALT", action = wezterm.action.SendString("\x01") },  -- Ctrl+A（行頭）
  { key = "b", mods = "ALT", action = wezterm.action.SendString("\x1bb") },  -- 単語後退
  { key = "w", mods = "ALT", action = wezterm.action.SendString("\x1bf") },  -- 単語前進
  -- ペインを閉じる（Cmd+W）
  { key = "w", mods = "CMD", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
  -- デフォルトキーバインド無効化（OS/Raycastに委譲）
  { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
  { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
  -- Alt+Enterの全画面トグルを無効化（Claude Codeの改行に使用）
  { key = "Enter", mods = "ALT", action = wezterm.action.SendKey({ key = "Enter", mods = "ALT" }) },
}

return config
