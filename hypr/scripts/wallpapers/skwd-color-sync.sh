#!/bin/bash

WALLPAPER_DIR="$HOME/wallpaper"
WALLPAPER_FILE="$WALLPAPER_DIR/wallpaper.jpg"
WAL_CACHE="$HOME/.cache/wal/wal"
QS_DIR="$HOME/.config/hypr/scripts/quickshell"
MATUGEN_RELOAD="$QS_DIR/wallpaper/matugen_reload.sh"

mkdir -p "$WALLPAPER_DIR"

LAST_MOD=$(stat -c "%Y" "$WALLPAPER_FILE" 2>/dev/null || echo "0")
LAST_SIZE=$(stat -c "%s" "$WALLPAPER_FILE" 2>/dev/null || echo "0")

echo wallpaper > "${XDG_RUNTIME_DIR}/skwd/cmd"

DETECTED=0
for i in $(seq 1 120); do
    sleep 0.3
    CUR_MOD=$(stat -c "%Y" "$WALLPAPER_FILE" 2>/dev/null || echo "0")
    CUR_SIZE=$(stat -c "%s" "$WALLPAPER_FILE" 2>/dev/null || echo "0")
    if [ "$CUR_MOD" != "$LAST_MOD" ] || [ "$CUR_SIZE" != "$LAST_SIZE" ]; then
        [ "$CUR_MOD" != "0" ] && DETECTED=1 && break
    fi
done

[ "$DETECTED" = "0" ] && exit 0

for i in $(seq 1 10); do
    PREV_MOD=$CUR_MOD
    PREV_SIZE=$CUR_SIZE
    sleep 0.3
    CUR_MOD=$(stat -c "%Y" "$WALLPAPER_FILE" 2>/dev/null || echo "0")
    CUR_SIZE=$(stat -c "%s" "$WALLPAPER_FILE" 2>/dev/null || echo "0")
    [ "$CUR_MOD" = "$PREV_MOD" ] && [ "$CUR_SIZE" = "$PREV_SIZE" ] && break
done

echo wallpaper > "${XDG_RUNTIME_DIR}/skwd/cmd"

echo "$WALLPAPER_FILE" > "$WAL_CACHE" 2>/dev/null
wal -i "$WALLPAPER_FILE" 2>/dev/null &

matugen image "$WALLPAPER_FILE" --source-color-index 0 2>/dev/null

[ -f "$MATUGEN_RELOAD" ] && bash "$MATUGEN_RELOAD"

wait
