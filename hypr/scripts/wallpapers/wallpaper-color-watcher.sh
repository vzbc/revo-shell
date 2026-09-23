#!/bin/bash

WALLPAPER_FILE="$HOME/wallpaper/wallpaper.jpg"
WAL_CACHE="$HOME/.cache/wal/wal"
QS_DIR="$HOME/.config/hypr/scripts/quickshell"
MATUGEN_RELOAD="$QS_DIR/wallpaper/matugen_reload.sh"

LAST_TIME=""

while [ ! -f "$WALLPAPER_FILE" ]; do
    sleep 2
done

while true; do
    if command -v inotifywait &>/dev/null; then
        inotifywait -e close_write,moved_to "$(dirname "$WALLPAPER_FILE")" 2>/dev/null
    else
        sleep 2
    fi

    CUR_TIME=$(stat -c "%Y" "$WALLPAPER_FILE" 2>/dev/null)
    [ "$CUR_TIME" = "$LAST_TIME" ] && continue
    LAST_TIME="$CUR_TIME"

    sleep 0.5

    echo "$WALLPAPER_FILE" > "$WAL_CACHE" 2>/dev/null
    wal -i "$WALLPAPER_FILE" 2>/dev/null

    matugen image "$WALLPAPER_FILE" --source-color-index 0 2>/dev/null

    [ -f "$MATUGEN_RELOAD" ] && bash "$MATUGEN_RELOAD"

    kill $(pgrep -f "Main.qml") 2>/dev/null || true
    kill $(pgrep -f "TopBar.qml") 2>/dev/null || true

    sleep 0.5

    nohup quickshell -p "$QS_DIR/Main.qml" >/dev/null 2>&1 &
    nohup quickshell -p "$QS_DIR/TopBar.qml" >/dev/null 2>&1 &
done
