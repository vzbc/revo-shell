# Runtime dependencies

The control-center slices use software already installed on this machine. A restore should install every required item below before enabling `lotus-shell`.

## Required now

- Quickshell 0.3 or newer, including its PipeWire, Networking, Bluetooth and Wayland modules.
- Quickshell's `DesktopEntries` model for discovering application names, icons, metadata and launch commands.
- Quickshell's MPRIS integration for media discovery, metadata, artwork URLs and playback commands.
- Quickshell's Hyprland integration for workspace state, workspace activation and outside-click focus grabs.
- NetworkManager for Wi-Fi state and toggling through `Quickshell.Networking`.
- PipeWire and Quickshell's PipeWire node model for output/input discovery, preferred-device routing, mute and gain.
- BlueZ for Bluetooth adapter state and toggling.
- Quickshell's Notifications service for native DBus notification ownership, session history, actions, images and inline replies.
- UPower through Quickshell for an optional laptop-battery stat.
- The existing `~/.config/hypr/scripts/brightnesscontrol.sh` controller for brightness reads and writes. It uses `brightnessctl` for a real `/sys/class/backlight` device and falls back to a transient user-managed `hyprsunset` service for software brightness. `systemd-run` keeps that helper alive after a Quickshell command exits. The script's `get` command lets Quickshell read the same state changed by the Hyprland brightness keys.
- Linux `/proc/stat` and `/proc/meminfo`, read with coreutils `cat`, for CPU and memory percentages while the quick panel is open.
- `hyprlock` for the lock action, systemd `systemctl` for suspend, reboot and power-off actions, and `hyprctl dispatch exit` for logout.
- Ghostty for desktop entries marked `Terminal=true`. The command prefix lives in `UserConfig.qml`.
- Bash and the existing Rofi installation for the application-launcher fallback at `~/.config/rofi/rofi.sh`.
- Maple Mono for interface text.
- Quickshell's Wayland idle inhibitor for timed caffeine mode; no synthetic input tool is used.
- `lm_sensors` (`sensors`), coreutils `df`, `/proc/net/dev`, and Arch's `checkupdates` for the on-demand system-health dashboard.
- `cliphist` plus `wl-clipboard` (`wl-paste` and `wl-copy`) for the local clipboard manager. The shell keeps at most 100 entries and starts its watchers only when clipboard capture is enabled in `UserConfig.qml`.
- Bash for the small clipboard decode/delete adapter in `scripts/clipboard-action.sh`.

## Live shell bindings

The live Hyprland config uses:

```ini
bind = SUPER, SPACE, global, quickshell:launcherToggle
bind = SUPER, S, global, quickshell:launcherToggle
bind = SUPER, A, global, quickshell:launcherToggle
bind = SUPER, V, global, quickshell:clipboardToggle
bind = SUPER, N, global, quickshell:notificationToggle
bind = SUPER, W, global, quickshell:dashboardToggle
bind = ALT, F4, global, quickshell:sessionMenuToggle
```

## Ownership note

Quickshell owns `org.freedesktop.Notifications`. `NotificationService.qml` loads its `NotificationServer` when Hyprland sets `LOTUS_NOTIFICATION_SERVER=1`. Do not run another notification daemon in the same session.
