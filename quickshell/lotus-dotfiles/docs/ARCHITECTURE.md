# Shell architecture

## Config boundary

`lotus-shell` is the live and canonical Quickshell configuration.

## Directory responsibilities

- `components/`: visual primitives with no system polling.
- `services/`: shared system data and commands. Keep one instance of expensive services.
- `widgets/`: composed visual modules driven by services.
- `windows/`: Wayland windows, layer selection, focus behavior and screen placement.
- `assets/icons/`: project-owned SVG icon sources.
- `docs/`: design rules, architecture and workflow.

## Planned window map

1. Top-left island: launcher, workspaces and task entry.
2. Top-center island: compact media state and controls.
3. Top-right island: audio, Bluetooth, network, clock and notifications, with a click-open quick panel for hardware state, sliders, calendar and session actions.
4. Optional desktop widgets may use `WlrLayer.Bottom` without blocking desktop input.
5. Dashboard: centered toggleable panel on `WlrLayer.Overlay`.
6. Launcher and notification center: focused overlays with explicit keyboard handling.
7. System tray: a compact top-left cluster with a focused overflow window for additional items.
8. Session menu: a centered Alt+F4 overlay with confirmed suspend, logout, reboot and shutdown actions.

Use separate windows for the three visible top islands. A one-pixel, empty-input `TopReserveWindow` owns the shared top exclusive zone so the three islands align instead of stacking below one another. It has an empty input region and cannot intercept clicks in unused areas.

## Data ownership

- Keep clocks in a shared `SystemClock` source.
- Use Quickshell integrations for desktop entries, media, notifications, system tray and audio where available.
- Use processes only when Quickshell lacks the required API.
- Stop timers and polling while their consumer is hidden.
- Store tasks and user settings in a documented state file under the Quickshell data or cache directory.
- Pass service state into widgets. Widgets must not launch duplicate pollers per monitor.

Current top-right service map:

- `ClockService.qml` owns minute-precision time formatting.
- `AudioService.qml` tracks PipeWire sinks and sources, exposes output and microphone gain/mute state, and changes preferred devices through Quickshell's native PipeWire model.
- `NetworkService.qml` reads and toggles NetworkManager through `Quickshell.Networking`.
- `BluetoothService.qml` reads and toggles the default BlueZ adapter.
- `NotificationService.qml` owns session history, toast queuing, unread state, Quiet mode and the native `NotificationServer`. The server is gated by `LOTUS_NOTIFICATION_SERVER`, which the live Hyprland session enables.
- `PanelController.qml` tracks quick-panel visibility across screens so hidden-only services can sleep.
- `BrightnessService.qml` reads and writes brightness through the controller configured in `UserConfig.qml`, rejects stale poll results while a value is pending, and serializes script calls. The current controller is Hyprland's `brightnesscontrol.sh`, which uses a real backlight device when one exists and otherwise controls a user-managed `hyprsunset` process.
- `SystemStats.qml` samples CPU and memory from `/proc` only while a quick panel is visible, and reads a laptop battery from Quickshell's UPower integration when present.
- `CalendarService.qml` owns the visible month and 42-cell calendar model while reusing the shared clock.
- `SessionService.qml` owns lock, suspend, logout, reboot and power-off commands. Session widgets require an explicit confirmation before invoking an action.
- `AttentionService.qml` owns timed caffeine state. `NotificationService.qml` owns Quiet mode. Each top-right window attaches the shared caffeine state to Quickshell's native Wayland `IdleInhibitor`.

Current dashboard service map:

- `OverlayController.qml` gives the dashboard one owning screen and one open instance across all monitors.
- `SystemHealth.qml` reads storage, lm-sensors data, Arch update counts and `/proc/net/dev` throughput only while the dashboard is visible.
- `DashboardWindow.qml` owns centered overlay placement, on-demand keyboard focus, Escape handling and outside-click dismissal.

Current session-menu service map:

- `OverlayController.qml` gives the session menu one owning screen and one open instance across all monitors.
- `SessionMenu.qml` owns four-action navigation, confirmation state and keyboard handling without running commands directly.
- `SessionMenuWindow.qml` centers the menu, closes it on Escape or an outside click and passes confirmed actions to the shared session service.
- The Quickshell global shortcut is named `sessionMenuToggle` and Hyprland binds it to `ALT+F4`.

Current clipboard service map:

- `ClipboardService.qml` owns the two `wl-paste` watchers, a 100-item local `cliphist` history, search data and copy/delete/wipe actions. Clipboard previews exist only in the focused clipboard overlay; they are never written to shell logs.
- `ClipboardWindow.qml` owns the focused overlay and uses the same single-screen controller pattern as the dashboard and launcher.
- The Quickshell global shortcut is named `clipboardToggle` and Hyprland binds it to `SUPER+V`.
- The dashboard exposes `dashboardToggle` on `SUPER+W`; its top-left Info button remains another entry point.

Current top-left service map:

- `WorkspaceService.qml` reads monitors, workspaces and toplevel counts through `Quickshell.Hyprland`. Raw Hyprland events trigger refreshes, so it does not poll.
- `LauncherService.qml` indexes visible applications through Quickshell's `DesktopEntries` model. It owns search ranking, normal application execution, explicit Ghostty handling for terminal entries, and validation of the Rofi fallback.
- `LauncherController.qml` keeps one launcher open across all screens and records which screen owns it.
- `ApplicationLauncherWindow.qml` owns the centered layer-shell overlay, delayed keyboard focus and outside-click dismissal. Its search and result model only refresh while the window is visible.
- `TopLeftIsland.qml`, `TopCenterIsland.qml` and `TopRightIsland.qml` stay separate so the space between them never intercepts pointer input.
- `SystemTrayService.qml` ranks Quickshell StatusNotifier items by attention state. The top-left cluster shows four items inline and sends additional items to a focused overflow window.

Current top-center service map:

- `MediaService.qml` selects a playing MPRIS client first, then a paused client, then the first available client. It uses Quickshell's MPRIS objects directly and does not poll.
- `MediaIsland.qml` owns active, paused, stopped, no-player, artwork-loading and artwork-error presentations.
- Playback buttons follow each player's reported capabilities. Clicking unavailable previous or next actions is impossible because those controls are disabled.

Current desktop-widget service map:


## Wayland behavior

- Top islands use `WlrLayer.Top`, ignore one another's exclusion geometry and rely on the empty-input top reservation window to keep application windows below them.
- The quick panel is a separate non-exclusive `PanelWindow` on `WlrLayer.Overlay`; `HyprlandFocusGrab` supplies outside-click dismissal.
- The application launcher is a separate `WlrLayer.Overlay` window. It requests keyboard focus on demand while visible, closes on Escape, and uses `HyprlandFocusGrab` to close when another application receives an outside click.
- The audio studio is a focused top-right popover. It is mutually exclusive with the quick panel and changes devices without invoking external mixers.
- The session menu is a centered focused overlay. It closes conflicting overlays before opening and confirms every system action.
- Notification toasts are non-focusable overlay windows on the active monitor. The notification center is focused, opens below the top-right island and keeps session history in memory only.
- Dashboard, launcher, clipboard, tray overflow and notification controls close conflicting overlays before opening, preventing competing focus grabs.
- Non-interactive desktop decoration uses an empty input region.
- Interactive desktop widgets expose only their visible bounds to pointer input.
- Focused overlays request layer-shell keyboard focus on demand and pair it with `HyprlandFocusGrab`. They keep keyboard input while in use, close when an outside click clears the grab, and release focus before the click reaches another window.
- Every overlay closes on Escape and outside click.

## Portability

- Never hardcode a specific user's home directory; use `Quickshell.env("HOME")` or shell home expansion.
- Use `Quickshell.shellDir` for config assets and `Quickshell.env("HOME")` for user-owned paths.
- Keep monitor names and primary-monitor policy in one config source.
- Document every external command and package dependency.
