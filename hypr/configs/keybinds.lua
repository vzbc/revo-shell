local terminal = "kitty"
local fileManager = "thunar"
local menu = "wofi --show drun"
local clipboard = "cliphist list"
local shiftMod = "SHIFT"
local wallpapers = "bash ~/.config/hypr/scripts/wallpapers/wallpaper-matugen.sh"
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("bash -c 'echo applauncher > ${XDG_RUNTIME_DIR}/skwd/cmd'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/quickshell/toggle_wallpaper_browser.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/macos_lock.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/rofi_show.sh drun"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle music"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/ryoku_settings.sh"))
hl.bind("ALT + TAB", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/rofi_show.sh window"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/wallpapers/wallpaper-matugen.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/quickshell/toggle_wallpaper_engine_browser.sh"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/quickshell/toggle_dots_browser.sh"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ workspace = "+1" }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }))

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { locked = true, repeating = true })

hl.bind(mainMod .. " + minus", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(shiftMod .. " + K", hl.dsp.exec_cmd("hyprshot -m region"))

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/show_desktop.sh"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("zen-browser"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("bash -c 'echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd'"))
-- hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle_waffle.sh"))
hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:wallpaperSelectorToggle"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle settings"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle movies"))
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle anime"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("quickshell -p ~/.config/quickshell/TypewriterSplash.qml"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call shell toggle spotlight"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("~/.local/bin/steam-gamescope"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/quickshell/toggle_screenshot_browser.sh"))
-- hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle_macos.sh"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/macos_lock.sh"), { locked = true })
-- زر للتبديل السريع بين الـ 2D التقليدي وعالم الـ 3D الحر
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd("hyprctl hypr3d"))
