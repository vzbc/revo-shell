#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  toggle_qs_dots.sh — Switch Quickshell Dots via Rofi / Cycle
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QS_BASE="$HOME/.config/quickshell"
HYPR_QS="$HOME/.config/hypr/scripts/quickshell"

# ─── 1. Detect Currently Active Dot ───────────────────────
get_active_dot() {
    if pgrep -f "ryoku/shell/ipc/ryoku-shell" >/dev/null 2>&1; then
        echo "ryoku"
    elif pgrep -f "quickshell.*macos" >/dev/null 2>&1 || pgrep -f "qs.*macos" >/dev/null 2>&1; then
        echo "macos"
    elif pgrep -f "quickshell.*ii" >/dev/null 2>&1 || pgrep -f "qs.*ii" >/dev/null 2>&1; then
        echo "ii"
    elif pgrep -f "quickshell.*k4" >/dev/null 2>&1 || pgrep -f "qs.*k4" >/dev/null 2>&1; then
        echo "k4"
    else
        for dir in "$QS_BASE"/*/; do
            [[ -d "$dir" && -f "$dir/shell.qml" ]] || continue
            local dot_name
            dot_name=$(basename "$dir")
            if pgrep -f "quickshell.*$dot_name" >/dev/null 2>&1 || pgrep -f "qs.*$dot_name" >/dev/null 2>&1; then
                echo "$dot_name"
                return
            fi
        done
        if pgrep -f "Main\.qml" >/dev/null 2>&1 || pgrep -f "TopBar\.qml" >/dev/null 2>&1; then
            echo "default"
        else
            echo "none"
        fi
    fi
}

# ─── 2. Stop All Quickshell Instances ─────────────────────
stop_all_quickshell() {
    pkill -9 -f "ryoku/shell/ipc/ryoku-shell" 2>/dev/null || true
    pkill -9 -f "quickshell -p" 2>/dev/null || true
    pkill -9 -f "quickshell -c" 2>/dev/null || true
    pkill -9 -f "qs -p" 2>/dev/null || true
    pkill -9 -f "qs -c" 2>/dev/null || true
    pkill -9 -x "quickshell" 2>/dev/null || true

    for _ in $(seq 1 10); do
        pgrep -x "quickshell" >/dev/null 2>&1 || break
        sleep 0.1
    done
}

# ─── 3. Start Specific Dot ────────────────────────────────
start_dot() {
    local target="$1"
    stop_all_quickshell

    if [[ "$target" == "default" ]]; then
        if [[ -f "$HYPR_QS/Main.qml" ]]; then
            setsid -f quickshell -p "$HYPR_QS/Main.qml" >/dev/null 2>&1
        fi
        if [[ -f "$HYPR_QS/TopBar.qml" ]]; then
            setsid -f quickshell -p "$HYPR_QS/TopBar.qml" >/dev/null 2>&1
        fi
    elif [[ "$target" == "macos" ]]; then
        setsid -f quickshell -p "$QS_BASE/macos/shell.qml" >"$HOME/macos.log" 2>&1
        setsid -f "$QS_BASE/k4/arrancar" >/tmp/k4.log 2>&1
    elif [[ "$target" == "ii" ]]; then
        setsid -f qs -p "$QS_BASE/ii" >/tmp/ii.log 2>&1
    elif [[ "$target" == "k4" ]]; then
        setsid -f "$QS_BASE/k4/arrancar" >/tmp/k4.log 2>&1
    elif [[ "$target" == "ryoku" ]]; then
        setsid -f bash -c "$QS_BASE/ryoku/launch.sh" >/dev/null 2>&1
    elif [[ -d "$QS_BASE/$target" ]]; then
        if [[ -f "$QS_BASE/$target/shell.qml" ]]; then
            local env_prefix=""
            if [[ -d "$QS_BASE/$target/build/qml" ]]; then
                env_prefix="QML2_IMPORT_PATH=$QS_BASE/$target/build/qml "
            elif [[ -d "$QS_BASE/$target/api" ]]; then
                env_prefix="QML2_IMPORT_PATH=$QS_BASE/$target/api "
            fi
            setsid -f bash -c "${env_prefix}quickshell -p $QS_BASE/$target/shell.qml" >"$HOME/${target}.log" 2>&1
        fi
    fi
}

# ─── 4. List All Available Dots ───────────────────────────
get_available_dots() {
    local dots=("default")
    for d in "$QS_BASE"/*/; do
        if [[ -d "$d" && -f "$d/shell.qml" ]]; then
            dots+=("$(basename "$d")")
        fi
    done
    echo "${dots[@]}"
}

# ─── 5. Cycle Mode (--next) ───────────────────────────────
cycle_next() {
    local active
    active=$(get_active_dot)
    read -ra dots_list <<< "$(get_available_dots)"

    local current_idx=-1
    for i in "${!dots_list[@]}"; do
        if [[ "${dots_list[$i]}" == "$active" ]]; then
            current_idx=$i
            break
        fi
    done

    local next_idx=$(( (current_idx + 1) % ${#dots_list[@]} ))
    local next_dot="${dots_list[$next_idx]}"
    start_dot "$next_dot"
}

# ─── 6. Rofi Selector Mode ────────────────────────────────
show_rofi_menu() {
    if pgrep -x "rofi" > /dev/null; then
        pkill rofi
        exit 0
    fi

    local active
    active=$(get_active_dot)
    read -ra dots_list <<< "$(get_available_dots)"

    local options=""
    for dot in "${dots_list[@]}"; do
        local label=""
        case "$dot" in
            default) label="default  │ ⚙️ Default (System Shell)" ;;
            macos)   label="macos    │ 🍎 macOS + 🏝️ k4 Dynamic Island" ;;
            ii)      label="ii       │ 🪟 ii (Windows 11 Waffle)" ;;
            k4)      label="k4       │ 🏝️ k4 (Dynamic Island الكاملة)" ;;
            shell)   label="shell    │ 🌌 Caelestia Shell" ;;
            ryoku)   label="ryoku    │ 🎴 Ryoku Shell (力と美)" ;;
            *)       label="$dot    │ 🎨 $dot" ;;
        esac

        if [[ "$dot" == "$active" ]]; then
            options+="$label  ✔ [نشط]\n"
        else
            options+="$label\n"
        fi
    done
    options+="stop     │ ❌ Stop Quickshell"

    local selected
    selected=$(echo -e "$options" | rofi -dmenu \
        -p "Quickshell Dots" \
        -config "$HOME/.config/rofi/config.rasi" \
        -theme-str 'listview { columns: 1; lines: 8; spacing: 4px; }' \
        -theme-str 'element { orientation: horizontal; padding: 8px 12px; }' \
        -theme-str 'element-text { enabled: true; vertical-align: 0.5; font: "Inter DemiBold 12"; }' \
        -theme-str 'element-icon { enabled: false; }' \
        || true)

    if [[ -z "$selected" ]]; then
        exit 0
    fi

    local chosen_key
    chosen_key=$(echo "$selected" | awk '{print $1}')

    if [[ "$chosen_key" == "stop" ]]; then
        stop_all_quickshell
        exit 0
    fi

    if [[ -n "$chosen_key" ]]; then
        start_dot "$chosen_key"
    fi
}

# ─── Main Switcher ────────────────────────────────────────
case "${1:-menu}" in
    --next|-n) cycle_next ;;
    --menu|-m|menu) show_rofi_menu ;;
    *) start_dot "$1" ;;
esac
