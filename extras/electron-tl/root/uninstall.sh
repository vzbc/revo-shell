#!/usr/bin/bash
# sudo ~/.local/share/electron-tl/root/uninstall.sh  -> restore the original app.asar files
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
rm -f /etc/pacman.d/hooks/90-electron-traffic-lights.hook
for a in /usr/lib/claude-desktop/resources/app.asar /usr/lib/chatgpt/resources/app.asar /opt/t3code-bin/resources/app.asar; do
  [ -f "$a.mac-tl-orig" ] && mv -f "$a.mac-tl-orig" "$a" && echo "restored $a"
done
rm -rf /usr/local/lib/electron-tl
