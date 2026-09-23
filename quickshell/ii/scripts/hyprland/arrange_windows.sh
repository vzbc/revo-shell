#!/usr/bin/env bash
# Windows-style window arrangement helpers for the Waffle context menus.
#
# Usage:
#   arrange_windows.sh cascade                 Tile every non-floating window on the active workspace in a cascade
#   arrange_windows.sh sidebyside              Tile every non-floating window on the active workspace side by side
#   arrange_windows.sh stacked                 Tile every non-floating window on the active workspace in a stacked layout
#   arrange_windows.sh showdesktop             Minimize every non-floating window on the active workspace
#   arrange_windows.sh undo                    Undo the last arrangement (cascade/sidebyside/stacked/showdesktop)
#
# The last operation is remembered in /tmp so it can be undone.
set -euo pipefail

mode="${1:-cascade}"
state_file="${QS_ARRANGE_STATE_FILE:-/tmp/quickshell_arrange_state.json}"

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "arrange_windows: hyprctl not found" >&2
    exit 1
fi

python3 - "$mode" "$state_file" <<'PY'
import json
import subprocess
import sys

mode = sys.argv[1]
state_file = sys.argv[2]

FLOATABLE = ("0", "0", "0", "0")

def hyprctl(*args, check=True):
    result = subprocess.run(["hyprctl", *args], capture_output=True, text=True)
    if check and result.returncode != 0:
        raise SystemExit(f"hyprctl {' '.join(args)} failed: {result.stderr.strip()}")
    return result

def dispatch(*args, check=True):
    return hyprctl("dispatch", *args, check=check)

def active_monitor():
    active = json.loads(hyprctl("activeworkspace", "-j").stdout)
    for monitor in json.loads(hyprctl("monitors", "-j").stdout):
        if monitor["id"] == active["monitorID"]:
            return monitor
    raise SystemExit("arrange_windows: active monitor not found")

def workspace_windows():
    active = json.loads(hyprctl("activeworkspace", "-j").stdout)
    clients = json.loads(hyprctl("clients", "-j").stdout)
    windows = []
    for client in clients:
        if client["workspace"]["id"] != active["id"]:
            continue
        if not client.get("mapped", False):
            continue
        if client.get("floating", False):
            continue
        if client.get("minimized", False):
            continue
        windows.append(client)
    return windows

def save(state):
    with open(state_file, "w") as handle:
        json.dump(state, handle)

def load():
    try:
        with open(state_file) as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError):
        return {}

def move_window(window, x, y):
    dispatch("movewindowpixel", f"exact {x} {y},address:{window['address']}", check=False)

def resize_window(window, width, height):
    dispatch("resizewindowpixel", f"exact {width} {height},address:{window['address']}", check=False)

def undo():
    state = load()
    if not state or state.get("windows") is None:
        return
    if state.get("type") == "showdesktop":
        already_minimized = set(state.get("minimized_already", []))
        for address in state.get("minimized_now", []):
            if address not in already_minimized:
                dispatch("minimize", f"address:{address}", check=False)
    else:
        for window in state.get("windows", []):
            move_window({"address": window["address"]}, window["x"], window["y"])

if mode == "undo":
    undo()
    sys.exit(0)

if mode == "showdesktop":
    windows = workspace_windows()
    minimized_now = []
    for window in windows:
        dispatch("minimize", f"address:{window['address']}", check=False)
        minimized_now.append(window["address"])
    save({"type": "showdesktop", "windows": [], "minimized_now": minimized_now})
    sys.exit(0)

if mode not in ("cascade", "sidebyside", "stacked"):
    raise SystemExit(f"arrange_windows: unknown mode '{mode}'")

windows = workspace_windows()
if not windows:
    sys.exit(0)

monitor = active_monitor()
gap = 8
saved = []
for window in windows:
    saved.append({"address": window["address"], "x": window["at"][0], "y": window["at"][1]})
    save({"type": mode, "windows": saved})

if mode == "cascade":
    margin = 24
    step = 40
    for index, window in enumerate(windows):
        move_window(window, monitor["x"] + margin + step * index, monitor["y"] + margin + step * index)
else:
    count = len(windows)
    for index, window in enumerate(windows):
        if mode == "sidebyside":
            width = (monitor["width"] - gap * (count + 1)) // count
            height = monitor["height"] - gap * 2
            x = monitor["x"] + gap + index * (width + gap)
            y = monitor["y"] + gap
        else:  # stacked
            width = monitor["width"] - gap * 2
            height = (monitor["height"] - gap * (count + 1)) // count
            x = monitor["x"] + gap
            y = monitor["y"] + gap + index * (height + gap)
        move_window(window, x, y)
        resize_window(window, width, height)
PY
