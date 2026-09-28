# GNOME Console (kgx) UI

Custom window chrome for GNOME Console via `LD_PRELOAD`.

## Files

| Path | Purpose |
|------|---------|
| `share/kgx-window.ui` | Replaced/merged window UI definition |
| `share/title_icon*.png` | Window title icons |
| `lib/libkgxui.so` | Preload library (built from `kgxui.c` — source lived in `/tmp/opencode/` and is lost) |
| `kgx-wrapper.sh` | Launches `/usr/bin/kgx` with the preload |

## Run

```bash
install -m 755 kgx-wrapper.sh ~/.local/bin/kgx
# fix paths inside the wrapper if needed:
#   LD_PRELOAD=~/.local/lib/libkgxui.so
#   share/ → ~/.local/share/kgx-patch/
```
