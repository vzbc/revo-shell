# Nautilus UI (nautui)

Custom sidebar UI for Nautilus via `LD_PRELOAD`.

## Files

| Path | Purpose |
|------|---------|
| `nautilus-sidebar.patch` | Patch on `src/nautilus-sidebar.c` + `src/nautilus-enums.h` (GNOME Nautilus 50.3.1) |
| `lib/libnautui.so` | Preload library (built from `nautui.c` — source lived in `/tmp/opencode/` and is lost) |
| `share/` | Sidebar/folder icons used by the UI |
| `nautilus-wrapper.sh` | Launches the patched nautilus build with the preload |

## Apply patch

```bash
git clone https://gitlab.gnome.org/GNOME/nautilus.git
cd nautilus
git checkout 435f8d4   # 50.3.1
git apply path/to/nautilus-sidebar.patch
meson setup _build && meson compile -C _build
```

## Run

```bash
# install wrapper to ~/.local/bin/nautilus
install -m 755 nautilus-wrapper.sh ~/.local/bin/nautilus
# point NAUT_BIN at your _build binary, keep libnautui.so path correct
```
