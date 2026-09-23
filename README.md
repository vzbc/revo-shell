# Revo Shell Dotfiles

Hyprland configs, Quickshell shells, wallpapers, and the **GUI installer** (primary path).

## Layout

| Path | Deploy target |
|------|----------------|
| `hypr/` | `~/.config/hypr` |
| `quickshell/` | `~/.config/quickshell` |
| `wallpapers/` | `~/Pictures/Wallpapers` |
| `qs-gui-installer/` | **run this (GUI)** |

## Install (GUI — recommended)

```bash
git clone https://github.com/X3jo/revo-shell.git revo-shell
cd revo-shell/qs-gui-installer
pip install -r requirements.txt
python main.py
```

The GUI **full install** does everything:

1. System packages (pacman/apt/dnf) for **every** shell  
2. AUR (`quickshell-git`, `awww`, fonts, …) when available  
3. Python deps (`pip --user`, Q1/nibrasshell requirements)  
4. `git clone` monorepo → deploy `hypr/`, `quickshell/`, `wallpapers/`  
5. Rewrite hardcoded `/home/revo` → `$HOME`  
6. **Build** CMake shells (`shell` caelestia + `imported-1789667132` Clavis)  
7. Enable pipewire / NetworkManager / bluetooth  
8. Per-file backup — existing configs are never blindly deleted  

Enter your sudo password in Stage 4 → **Install Now**.

## Install (CLI)

```bash
./install.sh
```

Same steps as the GUI (packages → deploy → build → services).

## After clone — repo URL

Already set in `qs-gui-installer/main.py`:

```python
DOTFILES_REPO_URL = "https://github.com/X3jo/revo-shell.git"
```

## Safety

- `.env` and API keys are **gitignored** (never commit secrets)  
- Existing user files: backed up before merge  
- Backups: `~/.config/revo-shell-backup-*` and `/tmp/dotfiles_backup`  

## Shells

Launch after install:

```bash
qs -p ~/.config/quickshell/lucid
qs -p ~/.config/quickshell/brain_shell
# …or pick any folder under ~/.config/quickshell
```

C++ shells (`shell`, `imported-1789667132`) are built during install.
