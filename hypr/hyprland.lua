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
-- Load HyprGlass (liquid glass) plugin before its config; guarded so a missing or ABI-mismatched .so degrades to off
pcall(hl.plugin.load, "/var/cache/hyprpm/revo/HyprGlass/hyprglass.so")
require("configs.hyprglass")
require("configs.hypr3d")

-- Brain_ShellKeybinds
dofile("/home/revo/.config/Brain_Shell/Brain_ShellKeybinds.lua")
