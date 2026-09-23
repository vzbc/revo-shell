# Quickshell GUI Installer

Black/white, English-only GUI installer for Quickshell shells and Hyprland
configs. Single QML window with a fixed sidebar and five stages.

## Overview

- **Design**: `#000000` background, `#FFFFFF` text, SF Pro typography
- **Layout**: Fixed sidebar (Magic UI / shadcn style) + five-stage flow
- **Stages**: Welcome → Repo → Shells → Install (full) → Done / Reboot
- **Backend**: Python + PySide6 (`InstallationWorker`)
- **Language**: UI strings are English only
- **Source**: monorepo `https://github.com/X3jo/revo-shell.git` (`hypr/` + `quickshell/` + `wallpapers/`)

## Structure

```
main.py                 # Backend + single QML window
qml/MainView.qml        # Root: stages + live install progress
qml/theme/              # Theme singleton
qml/components/         # Shared UI components
qml/stages/Stage*.qml   # Stage 1–5
requirements.txt        # Python deps
```

## What Stage 4 installs

Same work as root `./install.sh` (parallel implementations, neither calls the other):

1. System packages (pacman/apt/dnf) for every shell  
2. AUR (`quickshell-git`, fonts, …) when available  
3. Python deps (`pip --user`, Q1 / nibrasshell requirements)  
4. `git clone` monorepo → deploy `hypr/`, `quickshell/`, `wallpapers/`  
5. Rewrite `/home/revo` → `$HOME`  
6. Build CMake shells (`shell` + `imported-1789667132`)  
7. Enable pipewire / NetworkManager / bluetooth  
8. Per-file backup — never blindly deletes existing configs  

Repo URL (already set):

```python
DOTFILES_REPO_URL = "https://github.com/X3jo/revo-shell.git"
```

## Install & Run

```bash
pip install -r requirements.txt
python main.py
```

Or:

```bash
./run_installer.sh
```

## Safety

- Force full install with backup if configs already exist (`FORCE_FULL_INSTALL`)
- Validates distro (Ubuntu, Debian, Fedora, Arch, Manjaro, Pop!, Zorin, CachyOS, …)
- Minimum: 4GB RAM, 2+ CPU cores, kernel >= 5.4
- Secrets (`.env`, API keys) stay gitignored

## Testing

```bash
python test_installer.py
```

## License

Personal use / demonstration project.
