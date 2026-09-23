#!/usr/bin/env bash

if pgrep -f "quickshell.*macos/shell\.qml" >/dev/null 2>&1; then
    echo lock > /tmp/macos_cmd
elif [ -n "$1" ]; then
    bash -c "$1"
else
    bash ~/.config/hypr/scripts/lock.sh
fi
