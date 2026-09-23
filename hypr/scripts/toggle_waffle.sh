#!/usr/bin/env bash

MY_QML_DIR="$HOME/.config/hypr/scripts/quickshell"
WAFFLE_DIR="$HOME/.config/quickshell/ii"

waffle_running() {
    pgrep -f "qs -p .*quickshell/ii" >/dev/null 2>&1 || pgrep -f "quickshell.*-p .*quickshell/ii" >/dev/null 2>&1
}

my_shell_running() {
    pgrep -f "quickshell.*Main\.qml" >/dev/null 2>&1 || pgrep -f "quickshell.*TopBar\.qml" >/dev/null 2>&1
}

stop_my_shell() {
    pkill -f "quickshell.*Main\.qml" 2>/dev/null
    pkill -f "quickshell.*TopBar\.qml" 2>/dev/null
}

start_my_shell() {
    if ! pgrep -f "quickshell.*Main\.qml" >/dev/null 2>&1; then
        quickshell -p "$MY_QML_DIR/Main.qml" >/dev/null 2>&1 &
    fi
    if ! pgrep -f "quickshell.*TopBar\.qml" >/dev/null 2>&1; then
        quickshell -p "$MY_QML_DIR/TopBar.qml" >/dev/null 2>&1 &
    fi
}

stop_waffle() {
    pkill -f "qs -p .*quickshell/ii" 2>/dev/null
    pkill -f "quickshell.*-p .*quickshell/ii" 2>/dev/null
    for _ in $(seq 1 20); do
        waffle_running || break
        sleep 0.1
    done
}

if waffle_running; then
    stop_waffle
    start_my_shell
    notify-send -a Waffle "Windows look OFF" "رجع لشكل النظام العادي"
else
    stop_my_shell
    qs -p "$WAFFLE_DIR" >/tmp/waffle.log 2>&1 &
    sleep 2
    if waffle_running; then
        notify-send -a Waffle "Windows look ON" "Waffle (شكل ويندوز 11)"
    else
        notify-send -a Waffle "Waffle failed" "راجع /tmp/waffle.log — تم إرجاع شكل النظام"
        start_my_shell
    fi
fi
