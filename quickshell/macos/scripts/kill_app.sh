#!/usr/bin/env bash
# Force-kill all windows of the given app ids (matches hyprland class / initialClass)
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    sig=$(ls "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" 2>/dev/null | head -1)
    [ -n "$sig" ] && export HYPRLAND_INSTANCE_SIGNATURE="$sig"
fi
ids=$(printf '%s;' "$@")
hyprctl -j clients 2>/dev/null | python3 -c '
import sys, json, os, signal
ids = {x.lower() for x in sys.argv[1].split(";") if x}
data = sys.stdin.read().strip()
if not data:
    sys.exit(0)
try:
    clients = json.loads(data)
except Exception:
    sys.exit(0)
for c in clients:
    cls = str(c.get("class", "")).lower()
    icls = str(c.get("initialClass", "")).lower()
    if cls in ids or icls in ids:
        try:
            os.kill(int(c.get("pid", 0)), signal.SIGKILL)
        except Exception:
            pass
' "$ids"
