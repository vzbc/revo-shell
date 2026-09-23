#!/usr/bin/env bash

export WALLPIPER_PORTAL=hyprland
export WALLPIPER_STEAM_ROOT="/mnt/games"
export WALLPIPER_PROTON_BIN="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-1/proton"
export WALLPIPER_WINE_BIN="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-1/files/bin/wine"

WALLPIPERD="$HOME/.local/bin/wallpiperd"

# start wallpiperd if not running (it spawns the portal internally)
if ! pgrep -x wallpiperd > /dev/null 2>&1; then
    "$WALLPIPERD" > /dev/null 2>&1 &
    # wait for wallpiperd to be ready
    for i in $(seq 1 20); do
        if [ -S /tmp/wallpiper/wallpiperd-ctl.sock ]; then
            break
        fi
        sleep 0.25
    done
    # wait for renderer to spawn
    sleep 3
fi

# launch the QML browser (toggle: close if already open)
if pgrep -f "quickshell.*WallpaperEngineBrowser" > /dev/null 2>&1; then
    quickshell ipc --any-display -Q "quit" 2>/dev/null
else
    quickshell -p "$HOME/.config/hypr/scripts/quickshell/WallpaperEngineBrowser.qml"
fi
