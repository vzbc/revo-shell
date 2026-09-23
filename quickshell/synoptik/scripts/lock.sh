#!/usr/bin/env bash

# Synoptik Lockscreen Launcher
# Locks the Wayland session using Synoptik's quickshell lockscreen IPC

if pgrep -x quickshell >/dev/null 2>&1 || pgrep -x qs >/dev/null 2>&1; then
    qs -c Synoptik ipc call lockscreen lock
else
    # Fallback to direct quickshell invocation if daemon isn't active
    DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    quickshell -p "$DIR/shell.qml"
fi
