#!/usr/bin/env bash
if ! pgrep -f "quickshell.*WallpaperBrowser" >/dev/null 2>&1; then
    quickshell -p "$HOME/.config/hypr/scripts/quickshell/WallpaperBrowser.qml"
fi
