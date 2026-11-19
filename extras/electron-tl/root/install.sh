#!/usr/bin/bash
# Run once with sudo:  sudo ~/.local/share/electron-tl/root/install.sh
# Adds the macOS traffic-light loader to Claude, ChatGPT and T3 Code, and a
# pacman hook that re-adds it after each update of those packages.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
U="${SUDO_USER:?run via sudo from your user}"
SRC="$(dirname "$(readlink -f "$0")")"
install -d -m 755 /usr/local/lib/electron-tl
install -m 644 "$SRC/../patch-asar.py" /usr/local/lib/electron-tl/patch-asar.py
cat > /usr/local/lib/electron-tl/apply.sh <<APPLY
#!/bin/sh
# re-run by /etc/pacman.d/hooks/90-electron-traffic-lights.hook
for a in /usr/lib/claude-desktop/resources/app.asar /usr/lib/chatgpt/resources/app.asar /opt/t3code-bin/resources/app.asar; do
  [ -f "\$a" ] && MAC_TL_USER=$U /usr/bin/python3 -I /usr/local/lib/electron-tl/patch-asar.py "\$a" || true
done
APPLY
chmod 755 /usr/local/lib/electron-tl/apply.sh
install -d -m 755 /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/90-electron-traffic-lights.hook <<'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = claude-desktop
Target = chatgpt-desktop-bin
Target = t3code-bin

[Action]
Description = Adding macOS traffic lights to Electron apps...
When = PostTransaction
Exec = /usr/local/lib/electron-tl/apply.sh
HOOK
/usr/local/lib/electron-tl/apply.sh
echo "done. Restart Claude / ChatGPT / T3 Code to see the traffic lights."
