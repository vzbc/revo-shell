# Lotus Shell

Lotus Shell is the live Quickshell configuration for the Lotus Hyprland desktop.

It includes three top islands, a native launcher, clipboard manager, system dashboard, audio controls, notification center, system tray and session menu.

## Current state

- The Lotus Paper theme tokens are defined in `Theme.qml`.
- Reusable raised surfaces, text buttons and icon buttons are in `components/`.
- The top-left island opens a native Quickshell application launcher, shows ten live Hyprland workspaces and hosts Quickshell StatusNotifier tray items.
- The launcher indexes real desktop entries, searches names and metadata, supports keyboard selection, handles terminal applications through Ghostty, and keeps the existing Rofi script as a fallback.
- The top-center island selects the active MPRIS player, shows artwork or a drawn fallback, displays real track metadata, and exposes capability-aware previous, play/pause and next controls.
- With no MPRIS player, the media island contracts to a quiet `No media` state instead of leaving a dead control row.
- The top-right island shows live audio, Bluetooth, Wi-Fi, clock and native notification state.
- The audio, Bluetooth and Wi-Fi icons toggle their matching system setting.
- Clicking the notification button opens an in-memory notification center with unread state, Quiet mode, actions and replies.
- Clicking the clock opens a top-right quick panel with CPU and RAM state, connectivity controls, volume and brightness sliders, a calendar, and confirmed session actions.
- The quick panel closes on Escape or an outside click. Its hardware pollers sleep while the panel is closed.
- Brightness uses the existing Hyprland controller, including its `hyprsunset` fallback when no display backlight device exists.
- The launcher closes on Escape or a click into another application. It does no filtering work while closed.
- Alt+F4 opens a native session menu for suspend, logout, reboot and shutdown. Every action requires confirmation, and the menu supports pointer and keyboard navigation.
- `ThemePreview.qml` remains available as the original visual proof.
- The reference screenshots are preserved in `docs/references/`.
- Hyprland starts this config with native notification ownership and binds its launcher, clipboard, dashboard and notification overlays.

## Run the preview

```bash
qmlformat -i Theme.qml UserConfig.qml components/*.qml services/*.qml widgets/*.qml windows/*.qml shell.qml
qmllint Theme.qml UserConfig.qml components/*.qml services/*.qml widgets/*.qml windows/*.qml shell.qml
qs -c lotus-shell -n
```

Use fixture notifications without claiming the DBus notification service:

```bash
LOTUS_NOTIFICATION_FIXTURES=1 LOTUS_NOTIFICATION_SERVER=0 qs -c lotus-shell
```

The live Hyprland autostart sets `LOTUS_NOTIFICATION_SERVER=1`, allowing Quickshell to own `org.freedesktop.Notifications`. Disable any other notification daemon before starting the shell.

Use `qs list --all` to identify its exact instance, and stop only that instance after testing.

## Project guide

- `docs/DESIGN_SYSTEM.md`: visual language and token rules.
- `docs/ARCHITECTURE.md`: code ownership and window plan.
- `docs/WORKFLOW.md`: development phases and quality gates.
- `docs/DEPENDENCIES.md`: runtime services and external commands.
- `AGENTS.md`: implementation and safety contract for coding agents.

Keep recovery archives outside the repository and never commit them.
