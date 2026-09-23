#!/usr/bin/env bash
if ! pgrep -f "quickshell.*ScreenshotBrowser" >/dev/null 2>&1; then
    quickshell -p "$HOME/.config/hypr/scripts/quickshell/ScreenshotBrowser.qml"
fi
