#!/bin/bash

SCRIPTS="$HOME/.config/hypr/scripts"
QS_DIR="$SCRIPTS/quickshell"
WALL_SCRIPTS="$SCRIPTS/wallpapers"

bash "$WALL_SCRIPTS/random.sh"

WALLPAPER=$(cat "$HOME/.cache/wal/wal" 2>/dev/null)
[ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && exit 1

matugen image "$WALLPAPER" --source-color-index 0

MATUGEN_RELOAD="$QS_DIR/wallpaper/matugen_reload.sh"
[ -f "$MATUGEN_RELOAD" ] && bash "$MATUGEN_RELOAD"

sleep 0.5

kill $(pgrep -f "Main.qml") 2>/dev/null || true
kill $(pgrep -f "TopBar.qml") 2>/dev/null || true

sleep 0.5

nohup quickshell -p "$QS_DIR/Main.qml" >/dev/null 2>&1 &
nohup quickshell -p "$QS_DIR/TopBar.qml" >/dev/null 2>&1 &
