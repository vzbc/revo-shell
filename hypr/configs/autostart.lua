hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

local HOME_DIR = os.getenv("HOME") or ""

-- Shell chosen by the installer (marker: ~/.config/hypr/.revo_default_shell).
-- nil → no explicit choice, fall back to the legacy shells further down.
local function read_default_shell()
    local ok, fh = pcall(io.open, HOME_DIR .. "/.config/hypr/.revo_default_shell", "r")
    if not ok or not fh then
        return nil
    end
    local id = (fh:read("*l") or ""):match("^%s*(.-)%s*$")
    fh:close()
    if id == "" or id == "default" then
        return nil
    end
    return id
end

hl.on("hyprland.start", function()
    local shell = read_default_shell()

    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon & sleep 1; " .. HOME_DIR .. "/.config/hypr/scripts/wallpapers/set-random.sh")
    hl.exec_cmd("hyprshade on vibrance")
    hl.exec_cmd("skwd")
    hl.exec_cmd("~/.config/skwd/scripts/bash/restore-wallpaper")

    -- selected shell (installer marker) vs. the legacy rice shells
    if shell then
        hl.exec_cmd("bash " .. HOME_DIR .. "/.config/hypr/scripts/toggle_qs_dots.sh " .. shell .. " &")
    else
        hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/Main.qml")
        hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/TopBar.qml")
    end

    hl.exec_cmd("python3 ~/.config/hypr/scripts/quickshell/focustime/focus_daemon.py &")
    hl.exec_cmd("~/.config/hypr/scripts/init.sh")
    hl.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle guide &")
    hl.exec_cmd("playerctld")
    hl.exec_cmd("swayosd-server --top-margin 0.9")
    hl.exec_cmd("~/.config/hypr/scripts/volume_listener.sh")
    hl.exec_cmd("~/.config/hypr/scripts/settings_watcher.sh &")
    hl.exec_cmd("~/.config/hypr/scripts/update_notifier.sh &")
    hl.exec_cmd("systemctl --user enable --now easyeffects")
    if not shell then
        hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/Powermenu.qml")
    end
    hl.exec_cmd("powerprofilesctl set performance")
    hl.exec_cmd("hyprctl setcursor QingyiBLZ 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'QingyiBLZ'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd(HOME_DIR .. "/.config/hypr/sounds/keysound.py")

    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("hyprctl eval 'hl.plugin.hypr3d.toggle()'")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal")
end)
