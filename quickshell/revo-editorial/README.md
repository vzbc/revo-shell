# revo-editorial

Quickshell desktop component merging **Motion Frames** and **Editorial Collage**.

## Run

```bash
qs -c revo-editorial
# or
qs -p ~/.config/quickshell/revo-editorial
```

## Architecture

| File | Role |
|------|------|
| `shell.qml` | `ShellRoot` + per-screen `PanelWindow`, editorial layout, state flags |
| `components/TypographyRing.qml` | Rotating type ring, pulse tick, sweep hand |
| `components/TickerStrip.qml` | Seamless marquee loop |
| `components/CollageTile.qml` | Overlapping tile + hard offset shadow |
| `components/OptionalPhase2.qml` | Collapsible secondary Phase 2 + **opt-in** `qs-install` |

## Optional behaviors

- **Phase 2** — `phase2Enabled` (toggle on the right badge). Secondary; off by default.
- **qs-install** — `runQsInstall` (chip on the black strip). Off by default; never auto-executed. Flip on to *queue* intent only; wire your own runner if you want execution.

## Design tokens

Paper `#F4F1EA` · Ink `#0E0E0C` · Accent `#E23D28` · SF Pro display / mono ticks
