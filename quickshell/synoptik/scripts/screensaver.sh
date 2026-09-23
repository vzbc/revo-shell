#!/usr/bin/env bash

# Synoptik Screensaver Launcher
# Controls the desktop Quickshell screensaver overlay via IPC
# or launches the terminal screensaver fallback.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if user requested the CLI/terminal version explicitly
if [[ "$1" == "--cli" ]] || [[ "$1" == "--terminal" ]] || [[ "$1" == "-t" ]] || [[ "$1" == "--text" ]] || [[ "$1" == "-b" ]] || [[ "$1" == "--banner" ]] || [[ "$1" == "-c" ]] || [[ "$1" == "--clock" ]]; then
    python3 "$DIR/screensaver.py" "$@"
    exit $?
fi

# If Quickshell is running, trigger the real desktop screensaver via IPC
if pgrep -x quickshell >/dev/null 2>&1 || pgrep -x qs >/dev/null 2>&1; then
    qs -c Synoptik ipc call screensaver toggle
else
    # Fallback to terminal screensaver
    if [ -t 0 ] && [ -t 1 ]; then
        python3 "$DIR/screensaver.py" "$@"
    elif command -v kitty >/dev/null 2>&1; then
        kitty --start-as=fullscreen --title="Synoptik Screensaver" python3 "$DIR/screensaver.py" "$@"
    else
        python3 "$DIR/screensaver.py" "$@"
    fi
fi
