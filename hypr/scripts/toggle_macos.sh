#!/usr/bin/env bash

MY_QML_DIR="$HOME/.config/hypr/scripts/quickshell"
MACOS_QML="$HOME/.config/quickshell/macos/shell.qml"

macos_running() {
    pgrep -f "quickshell.*-p .*quickshell/macos" >/dev/null 2>&1 || pgrep -f "quickshell.*macos/shell\.qml" >/dev/null 2>&1
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

stop_macos() {
    pkill -f "quickshell.*-p .*quickshell/macos" 2>/dev/null
    pkill -f "quickshell.*macos/shell\.qml" 2>/dev/null
    for _ in $(seq 1 20); do
        macos_running || break
        sleep 0.1
    done
}

start_macos() {
    if ! pgrep -f "quickshell.*macos/shell\.qml" >/dev/null 2>&1; then
        quickshell -p "$MACOS_QML" >"$HOME/macos.log" 2>&1 &
    fi
    sleep 2
    if macos_running; then
        notify-send -a macOS "macOS look ON" "شكل الماك"
    else
        notify-send -a macOS "macOS failed" "راجع $HOME/macos.log — تم إرجاع شكل النظام"
        start_my_shell
    fi
}

if macos_running; then
    stop_macos
    start_my_shell
    notify-send -a macOS "macOS OFF" "رجع لشكل النظام العادي"
else
    stop_my_shell
    start_macos
fi
