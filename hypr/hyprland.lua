require("colors")
require("configs.monitors")
require("configs.env")
require("configs.input")
require("configs.general")
require("configs.animations")
require("configs.debug")
require("configs.hyprcolors")
require("configs.windowrule")
require("configs.keybinds")
require("configs.autostart")
-- Load liquid-glass plugin before its config; guarded so a missing or ABI-mismatched .so degrades to off
-- hyprliquid (switch back to HyprGlass: "/var/cache/hyprpm/revo/HyprGlass/hyprglass.so" + require("configs.hyprglass"))
pcall(hl.plugin.load, "/home/revo/.local/lib/hyprliquid.so")
require("configs.hyprliquid")
require("configs.hypr3d")

-- Brain_ShellKeybinds
dofile("/home/revo/.config/Brain_Shell/Brain_ShellKeybinds.lua")
