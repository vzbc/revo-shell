#!/usr/bin/env bash
# Tell the user once per new revo-shell commit that an update is ready
# (revo-shell-update --check compares the installed commit with the repo).
# Applying it: System Settings › General › Software Update, or `revo-shell-update`.

INTERVAL=1800                                    # 30 min
CACHE_FILE="$HOME/.cache/revo-shell-notified-commit"
UPDATER="$HOME/.local/bin/revo-shell-update"

sleep 120                                        # let the session settle first
while true; do
    if [[ -x "$UPDATER" ]]; then
        out="$("$UPDATER" --check 2>/dev/null)"
        latest="$(sed -n 's/^latest: //p' <<<"$out")"
        if grep -q '^status: available' <<<"$out" && [[ -n "$latest" ]] \
            && [[ "$(cat "$CACHE_FILE" 2>/dev/null)" != "$latest" ]]; then
            n="$(grep -c '^- ' <<<"$out")"
            first="$(grep -m1 '^- ' <<<"$out" | cut -c3-)"
            body="Open System Settings › Software Update to update all shells."
            [[ "$n" -gt 0 ]] && body="$n new change$([[ $n -gt 1 ]] && echo s): $first"$'\n'"$body"
            notify-send -t 60000 -a 'Revo Shell' -u normal 'Shell update available' "$body"
            mkdir -p "$(dirname "$CACHE_FILE")" && echo "$latest" > "$CACHE_FILE"
        fi
    fi
    sleep "$INTERVAL"
done
