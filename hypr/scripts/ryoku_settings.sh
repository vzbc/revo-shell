#!/usr/bin/env bash
# Open Ryoku Settings (the Hub) if the ryoku dot is running,
# otherwise nudge the user to switch to it first.
BIN="$HOME/.local/src/ryoku-arch/ryoku/shell/ipc/ryoku-shell"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ryoku-shell.sock"

if [[ -S "$SOCK" ]]; then
    PATH="$HOME/.local/bin:$PATH" "$BIN" hub open >/dev/null 2>&1
else
    notify-send -a "Ryoku" -i "preferences-desktop-theme" \
        "Ryoku غير شغّال" "فعّل ثيم Ryoku من سوبر + B الأول"
fi
