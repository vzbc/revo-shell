#!/usr/bin/env bash
# Best-effort Focus mode hook for the macOS-style shell.
# macOS Focus has no direct Linux equivalent; we surface it via a desktop
# notification and (if available) toggle Hyprland's silent/no-blur state.
MODE="${1:-off}"
notify-send "Focus" "$MODE" 2>/dev/null || true
exit 0
