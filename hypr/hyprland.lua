require("colors")
require("configs.monitors")
require("configs.env")
require("configs.input")
require("configs.general")
require("configs.animations")
require("configs.debug")
require("configs.hyprcolors")
require("configs.windowrule")

-- Startup plugins: loaded BEFORE keybinds/autostart (they reference hl.plugin.hypr3d).
-- pcall guards: a missing or ABI-mismatched .so just degrades to off.
pcall(hl.plugin.load, "/home/revo/Hypr3D/build/hypr3d.so")
--DISABLED--pcall(hl.plugin.load, "/home/revo/.local/lib/minimize-hooks.so")

require("configs.keybinds")
require("configs.autostart")
-- Load liquid-glass plugin before its config; guarded so a missing or ABI-mismatched .so degrades to off
-- hyprliquid (switch back to HyprGlass: "/var/cache/hyprpm/revo/HyprGlass/hyprglass.so" + require("configs.hyprglass"))
pcall(hl.plugin.load, "/home/revo/.local/lib/hyprliquid.so")
require("configs.hyprliquid")
require("configs.hypr3d")

-- Brain_ShellKeybinds (guarded — the file is user-specific and may not exist)
pcall(dofile, "/home/revo/.config/Brain_Shell/Brain_ShellKeybinds.lua")
