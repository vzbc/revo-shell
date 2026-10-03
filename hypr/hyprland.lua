require("colors")
require("configs.monitors")
require("configs.env")
require("configs.input")
require("configs.general")
require("configs.animations")
require("configs.debug")
require("configs.hyprcolors")
require("configs.windowrule")

-- Resolve every path from $HOME/$USER — this file must work on any machine
-- without editing, and without the installer rewriting it.
local HOME_DIR = (os and os.getenv and os.getenv("HOME")) or ""
local USER_NAME = (os and os.getenv and os.getenv("USER")) or ""
local io_open = (io and io.open) or nil

local function exists(path)
    local ok, f = pcall(io_open, path, "r")
    if ok and f then
        f:close()
        return true
    end
    return false
end

-- first candidate that is actually on disk wins
local function first_existing(paths)
    for i = 1, #paths do
        if exists(paths[i]) then
            return paths[i]
        end
    end
    return nil
end

-- Startup plugins: loaded BEFORE keybinds/autostart (they reference hl.plugin.hypr3d).
-- pcall guards: a missing or ABI-mismatched .so just degrades to off.
local hypr3d_so = first_existing({
    "/var/cache/hyprpm/" .. USER_NAME .. "/Hypr3D/hypr3d.so",
    HOME_DIR .. "/Hypr3D/build/hypr3d.so",
    HOME_DIR .. "/.local/lib/hypr3d.so",
})
if hypr3d_so then pcall(hl.plugin.load, hypr3d_so) end
--DISABLED--pcall(hl.plugin.load, HOME_DIR .. "/.local/lib/minimize-hooks.so")

require("configs.keybinds")
require("configs.autostart")

-- Load liquid-glass plugin before its config; guarded so a missing or ABI-mismatched .so degrades to off
-- liquid engine (switch back to HyprGlass: put its .so first + require("configs.hyprglass"))
local liquid_so = first_existing({
    "/var/cache/hyprpm/" .. USER_NAME .. "/hyprliquid/hyprliquid.so",
    "/var/cache/hyprpm/" .. USER_NAME .. "/HyprGlass/hyprglass.so",
    HOME_DIR .. "/.local/lib/hyprliquid.so",
})
if liquid_so then pcall(hl.plugin.load, liquid_so) end
require("configs.hyprliquid")
require("configs.hypr3d")

-- Brain_ShellKeybinds (guarded — the file is user-specific and may not exist)
pcall(dofile, HOME_DIR .. "/.config/Brain_Shell/Brain_ShellKeybinds.lua")
