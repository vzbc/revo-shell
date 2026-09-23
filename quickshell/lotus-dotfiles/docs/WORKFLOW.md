# Build workflow

## Phase 0: protect the baseline

Keep a verified, timestamped backup outside the repository. Never modify files inside that recovery archive.

Gate: the archive passes its checksum and decompression tests.

## Phase 1: validate the visual language

Use `ThemePreview.qml` to test palette, typography, borders, shadows, spacing and control states. Change tokens in `Theme.qml`, not in the preview.

Gate: one representative surface and button work at the actual monitor scale, with readable text and keyboard focus.

## Phase 2: build primitives

Add only the primitives required by the next vertical slice. Likely additions are icon buttons, chips, dividers, progress bars and text fields.

Gate: each primitive has hover, press, focus and disabled behavior, and does not start processes.

## Phase 3: top islands

Build the left, center and right islands as separate windows. Start with static data, then connect services.

Gate: islands align on every target monitor, do not block unused pointer space and survive Quickshell reloads.

## Phase 4: launcher and core services

Implement the application launcher with `DesktopEntries`, keyboard navigation and a Rofi fallback. Add shared media, audio, network and notification services.

Gate: all normal applications launch, terminal entries have a handler, Escape always closes overlays and hidden windows stop unnecessary work.

## Phase 5: desktop widgets and dashboard

Build dashboard features from reusable services and primitives.

Current completed slices: system-health dashboard, audio studio, timed caffeine, local clipboard overlay, native notification server, Quickshell system tray and native session menu. Tasks, Pomodoro, weather and synced agenda events remain separate future slices.

Gate: loading, empty and error states exist. Persistent data survives a Quickshell restart.

## Phase 6: deployment

Hyprland starts `lotus-shell`, Quickshell owns notifications, and every global shortcut is validated.

Gate: one full session runs without QML errors, broken shortcuts, notification ownership conflicts or blocked input regions.

## Per-change loop

1. Read `AGENTS.md` and the relevant project documents.
2. Inspect the live implementation and service call sites.
3. State the single vertical slice being changed.
4. Reuse theme tokens and existing primitives.
5. Run QML checks and launch the development config.
6. Inspect Quickshell logs and capture the affected window.
7. Run the repository doctor and inspect the affected window in a live session.
8. Update documentation when a token, dependency or architectural decision changes.
