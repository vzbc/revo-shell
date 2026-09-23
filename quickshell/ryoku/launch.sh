#!/usr/bin/env bash
# Launch the Ryoku shell (dev/isolated mode) — repo stays the source of truth.
# Nothing under ~/.config is touched; QML modules live in ~/.local/lib/qt6/qml.
set -euo pipefail

REPO="$HOME/.local/src/ryoku-arch"
LOG="$HOME/.local/state/ryoku-shell.log"

mkdir -p "$HOME/.local/state"

if [[ -d "$REPO" ]]; then
    cd "$REPO"
    export PATH="$HOME/.local/bin:$PATH"
    setsid -f bash -c "./ryoku/shell/dev-run.sh" >"$LOG" 2>&1
else
    notify-send -a "Ryoku" -u critical "Error" "Repository not found at $REPO"
    exit 1
fi
