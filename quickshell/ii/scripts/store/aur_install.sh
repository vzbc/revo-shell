#!/usr/bin/env bash
# Install an AUR package as the logged-in user (dropping root privileges).
# Invoked as: pkexec bash aur_install.sh <package> <username>
set -euo pipefail

pkg="$1"
user="$2"

if [ -z "$pkg" ] || [ -z "$user" ]; then
    echo "usage: aur_install.sh <package> <username>" >&2
    exit 2
fi

if command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
elif command -v yay >/dev/null 2>&1; then
    aur_helper="yay"
else
    echo "No AUR helper (paru/yay) found." >&2
    exit 3
fi

exec runuser -u "$user" -- "$aur_helper" -S --noconfirm --noprogressbar "$pkg"
