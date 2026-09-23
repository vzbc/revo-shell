#!/bin/sh
while ! pgrep Hyprland >/dev/null; do sleep 1; done
sleep 2  # extra buffer
/usr/bin/ags run $HOME/.config/ags/yuu/app.ts

# ags doesnt work with exec-once in hyprland so just make a service
