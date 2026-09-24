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

On a TTY you get a **multi-select shell menu** (same idea as the GUI Stage 3):

```text
select Quickshell shells to install (multi-select)
  [0] all
  [1] ii
  [2] k4
  [3] lucid
  …
Enter numbers (e.g. 1,3,5), names, or "all" [all]:
```

Non-interactive runs (scripts, no TTY) deploy **all** shells unless you pass `--shells`.

What `install.sh` does:

1. Lets you pick which shells to install (menu / `--shells` / all)
2. Detects your package manager (pacman / apt / dnf)
3. Installs **system packages** needed by the installer and shells
4. Installs AUR packages via yay/paru when available (`quickshell-git`, fonts, …)
5. Installs Python deps (`pip --user`)
6. Deploys `hypr/`, selected `quickshell/` shells (+ shared root assets), `rofi/`, `kitty/` → `~/.config/`, `wallpapers/` → `~/Pictures/Wallpapers`
7. Sets the **first selected shell** as the Hyprland default (`# REVO_DEFAULT_SHELL` in autostart)
8. Rewrites hardcoded `/home/revo` → `$HOME`
9. Builds CMake shells (caelestia + Clavis)
10. Enables pipewire / NetworkManager / bluetooth
11. **Verifies every requirement** — prints `[ok]` / `[MISS]` / `[fixed]` for each, **auto-installs any missing package** (pacman / apt / dnf + yay/paru for AUR), and **installs the HyprGlass plugin via hyprpm** if missing/disabled

Flags:

```bash
./install.sh --shells macos,ii,k4   # deploy only these shells (first = default)
./install.sh --shells all           # every shell
./install.sh --help
DRY_RUN=1 ./install.sh              # show what would run, change nothing
DRY_RUN=1 ./install.sh --shells ii  # dry-run selective deploy
DOTFILES_REPO_URL=... ./install.sh  # override clone URL
SHELLS=macos,k4 ./install.sh        # env form of --shells
```

After install, verify again anytime:

```bash
./install.sh   # re-runs verify at the end (non-interactive → all shells already deployed)
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
