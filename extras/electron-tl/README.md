# electron-tl — macOS traffic lights for Electron apps (optional)

Hyprland draws no frame for Electron apps, so each app draws its own buttons.
This replaces them with macOS 26/27 traffic lights (close / minimize-to-Dock /
zoom) inside the app. Not run by `install.sh`.

```bash
cp -r extras/electron-tl ~/.local/share/electron-tl
```

- **Code-OSS / Obsidian** (system electron, no root): use the launchers in `bin/`
  (copy `/usr/share/applications/<app>.desktop` to `~/.local/share/applications`
  and point `Exec=` at `~/.local/share/electron-tl/bin/<app>`). For Code-OSS also
  set `"window.controlsStyle": "hidden"`.
- **Claude / ChatGPT / T3 Code** (bundled electron): `sudo ~/.local/share/electron-tl/root/install.sh`
  adds a one-line loader to their `app.asar` (original kept as `app.asar.mac-tl-orig`)
  and a pacman hook that re-applies it after updates. Undo: `root/uninstall.sh`.
- Per-app placement lives in `profiles.json` (re-read live).
