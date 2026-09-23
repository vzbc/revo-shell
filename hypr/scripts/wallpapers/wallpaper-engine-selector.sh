#!/bin/bash

WE_DIR="/mnt/games/steamapps/workshop/content/431960"
CACHE_DIR="$HOME/.cache/wallpiper-selector"
mkdir -p "$CACHE_DIR"

if ! pgrep -f wallpiperd > /dev/null 2>&1; then
    notify-send "Wallpiper" "wallpiperd is not running!" -i dialog-error
    exit 1
fi

ENTRY=""
for dir in "$WE_DIR"/*/; do
    [ -d "$dir" ] || continue
    ID=$(basename "$dir")
    [ "$ID" = "wallpaper.jpg" ] && continue

    PREVIEW=$(find "$dir" -maxdepth 1 -name "preview.*" -print -quit 2>/dev/null)
    [ -z "$PREVIEW" ] && continue

    PROJECT_JSON="$dir/project.json"
    if [ -f "$PROJECT_JSON" ]; then
        TITLE=$(python3 -c "import json,sys; d=json.load(open('$PROJECT_JSON')); print(d.get('title','Unknown'))" 2>/dev/null)
    else
        TITLE="Unknown"
    fi

    CACHED_PREVIEW="$CACHE_DIR/${ID}.jpg"
    if [ ! -f "$CACHED_PREVIEW" ] || [ "$PREVIEW" -nt "$CACHED_PREVIEW" ]; then
        cp "$PREVIEW" "$CACHED_PREVIEW" 2>/dev/null
    fi

    ENTRY+="img:${CACHED_PREVIEW}:text:${TITLE} (${ID})\n"
done

[ -z "$ENTRY" ] && {
    notify-send "Wallpiper" "No wallpapers found in $WE_DIR"
    exit 1
}

SELECTED=$(echo -e "$ENTRY" | wofi \
    --dmenu \
    --prompt "Wallpaper Engine" \
    --allow-images \
    --width 600 \
    --height 500 \
    --cache-file /dev/null \
    --insensitive \
    -I 2>/dev/null)

[ -z "$SELECTED" ] && exit 0

WORKSHOP_ID=$(echo "$SELECTED" | grep -oP '\(\K[0-9]+(?=\))')

[ -z "$WORKSHOP_ID" ] && exit 1

WALLPIPERCTL="$HOME/.local/bin/wallpiperctl"
if [ ! -x "$WALLPIPERCTL" ]; then
    WALLPIPERCTL="wallpiperctl"
fi

"$WALLPIPERCTL" set "$WORKSHOP_ID"
notify-send "Wallpiper" "Wallpaper set: $WORKSHOP_ID" -i preferences-desktop-wallpaper
