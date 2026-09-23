#!/bin/bash
set -eu

WALL_DIR="$HOME/.config/wallpapers"


if [ ! -d "$WALL_DIR" ]; then
    echo "Cannot find directory with wallpapers: $WALL_DIR"
    exit 1
fi

FILE_LIST=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" \) -exec echo "img:{}:text:{}" \;)

SELECTED_FILE=$(echo "$FILE_LIST" | wofi --dmenu --prompt "Select wallpaper" --allow-images --cache-file /dev/null | sed 's/.*text://')

[ -z "$SELECTED_FILE" ] && exit 1

WALL="$SELECTED_FILE"
echo "Setting wallpaper: $SELECTED_FILE"
awww img --transition-type center --transition-step 90 "$WALL"
echo "Wallpaper set successfully"

export PATH="$HOME/.local/bin:$PATH:/usr/local/bin"

if command -v wal >/dev/null 2>&1; then
    echo "Applying pywal colors..."
    wal -i "$WALL"
    echo "Pywal applied successfully"
    
    if command -v pywalfox >/dev/null 2>&1; then
        echo "Updating pywalfox..."
        pywalfox update &
    fi
    
    MAKO_SCRIPT="$HOME/.config/mako/update-colors.sh"
    if [ -x "$MAKO_SCRIPT" ]; then
        echo "Updating mako colors..."
        bash "$MAKO_SCRIPT" &
    fi
    
    KEYBOARD_SCRIPT="$HOME/.config/keyboard/set-color-keyboard.sh"
    if [ -x "$KEYBOARD_SCRIPT" ]; then
        echo "Updating keyboard colors..."
        bash "$KEYBOARD_SCRIPT" &
    fi
    
    wait
else
    echo "Pywal not installed, skipping"
fi

# ─── Matugen + Quickshell reload (top bar, system colors) ───
QS_DIR="$HOME/.config/hypr/scripts/quickshell"
MATUGEN_RELOAD="$QS_DIR/wallpaper/matugen_reload.sh"
MAIN_QML="$QS_DIR/Main.qml"
TOPBAR_QML="$QS_DIR/TopBar.qml"

echo "Generating matugen colors..."
matugen image "$WALL" --source-color-index 0

[ -f "$MATUGEN_RELOAD" ] && bash "$MATUGEN_RELOAD"

sleep 0.5

kill $(pgrep -f "Main.qml") 2>/dev/null || true
kill $(pgrep -f "TopBar.qml") 2>/dev/null || true

sleep 0.5

nohup quickshell -p "$MAIN_QML" >/dev/null 2>&1 &
nohup quickshell -p "$TOPBAR_QML" >/dev/null 2>&1 &

echo "All done!"
