#!/usr/bin/env bash

STORE="$HOME/.cache/hypr_show_desktop"
SPECIAL="special:showdesktop"

restore() {
    while IFS='|' read -r ws addr; do
        [ -n "$addr" ] && hyprctl dispatch movetoworkspace "$ws,address:$addr" >/dev/null 2>&1
    done < "$STORE"
    rm -f "$STORE"
}

hide() {
    CURRENT_WS=$(hyprctl -j activeworkspace | jq -r '.id')
    hyprctl -j clients | jq -r --argjson ws "$CURRENT_WS" '.[] | select(.workspace.id == $ws and .mapped) | "\(.workspace.id)|\(.address)"' > "$STORE"
    if [[ -s "$STORE" ]]; then
        awk -F'|' '{print $2}' "$STORE" | while read -r addr; do
            hyprctl dispatch movetoworkspacesilent "$SPECIAL,address:$addr" >/dev/null 2>&1
        done
    fi
}

if [[ -f "$STORE" ]]; then
    restore
else
    hide
fi
