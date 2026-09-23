#!/usr/bin/env bash
if ! pgrep -f "quickshell.*DotsBrowser" >/dev/null 2>&1; then
    quickshell -p "$HOME/.config/hypr/scripts/quickshell/DotsBrowser.qml"
fi
