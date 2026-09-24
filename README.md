# Revo Shell Dotfiles

Revo Shell its place to Add all ypur quickShells in one place

if you share any video to this dot files in tik tok or insta pleas mention me : @_flz4

## Showcase

https://github.com/user-attachments/assets/42df3de9-9fab-4843-9afc-35f82d5852f7

## Layout

| Path | Deploy target |
|------|----------------|
| `hypr/` | `~/.config/hypr` |
| `quickshell/` | `~/.config/quickshell` |
| `wallpapers/` | `~/Pictures/Wallpapers` |
| `rofi/` | `~/.config/rofi` |
| `kitty/` | `~/.config/kitty` |
| `qs-gui-installer/` | **run this (GUI)** |

## Install (CLI — recommended)

One-time clone, then run the installer:

```bash
git clone https://github.com/vzbc/revo-shell.git revo-shell
cd revo-shell
./install.sh
```

What `install.sh` does:

1. Detects your package manager (pacman / apt / dnf)
2. Installs **all system packages** needed by every shell
3. Installs AUR packages via yay/paru when available (`quickshell-git`, fonts, …)
4. Installs Python deps (`pip --user`)
5. Deploys `hypr/`, `quickshell/`, `rofi/`, `kitty/` → `~/.config/`, `wallpapers/` → `~/Pictures/Wallpapers`
6. Rewrites hardcoded `/home/revo` → `$HOME`
7. Builds CMake shells (caelestia + Clavis)
8. Enables pipewire / NetworkManager / bluetooth
9. **Verifies every requirement** — prints `[ok]` / `[MISS]` / `[fixed]` for each, and **auto-installs any missing package** (pacman / apt / dnf + yay/paru for AUR)

Flags:

```bash
DRY_RUN=1 ./install.sh          # show what would run, change nothing
DOTFILES_REPO_URL=... ./install.sh   # override clone URL
```

After install, verify again anytime:

```bash
./install.sh   # re-runs verify at the end
```

Launch a shell:

```bash
qs -p ~/.config/quickshell/lucid
qs -p ~/.config/quickshell/brain_shell
```

## Install (GUI)

```bash
git clone https://github.com/vzbc/revo-shell.git revo-shell
cd revo-shell/qs-gui-installer
pip install -r requirements.txt
python main.py
```

The GUI **full install** does everything:

1. System packages (pacman/apt/dnf) for **every** shell  
2. **rofi + kitty** installed if missing (`--needed`)  
3. AUR (`quickshell-git`, `awww`, fonts, …) when available  
4. Python deps (`pip --user`, Q1/nibrasshell requirements)  
5. `git clone` monorepo → deploy `hypr/`, `quickshell/`, `wallpapers/`, **`rofi/`, `kitty/`**  
6. Rewrite hardcoded `/home/revo` → `$HOME`  
7. **Build** CMake shells (`shell` caelestia + `imported-1789667132` Clavis)  
8. Enable pipewire / NetworkManager / bluetooth  
9. Per-file backup — existing configs are never blindly deleted  

Logs: `~/.local/state/qs-gui-installer/install.log`

Enter your sudo password in Stage 4 → **Install Now**.

## After clone — repo URL

Already set in `qs-gui-installer/main.py`:

```python
DOTFILES_REPO_URL = "https://github.com/vzbc/revo-shell.git"
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
