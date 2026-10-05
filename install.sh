#!/usr/bin/env bash
# Full CLI installer: packages + clone + deploy + build for Quickshell shells.
# Primary path is still the GUI (qs-gui-installer) — this mirrors it for terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.config/revo-shell-backup-$TS}"
DRY_RUN="${DRY_RUN:-0}"
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/vzbc/revo-shell.git}"
SUDO="${SUDO:-sudo}"
SHELLS_FLAG="${SHELLS_FLAG:-}"
CHECK_ONLY="${CHECK_ONLY:-0}"
SELECTED_SHELLS=()
QS_SKIP_NAMES=(previews guide modules config settings build dist node_modules)

log()  { printf '[install] %s\n' "$*"; }
run()  { if [[ "$DRY_RUN" == "1" ]]; then log "DRY: $*"; else eval "$*"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --shells LIST     Comma-separated shell ids to deploy (e.g. macos,ii,k4)
                    Use "all" to deploy every shell (default when non-interactive).
  --check           Read-only health check: hyprpm/repos, default shell, running
                    shell, QML errors in its log, leftover /home/revo paths.
                    Exit code 1 if anything is broken.
  -h, --help        Show this help

Environment:
  DRY_RUN=1         Print commands without changing the system
  DOTFILES_REPO_URL Override clone URL
  SHELLS=LIST       Same as --shells (env form)

Interactive mode (TTY): a numbered multi-select menu is shown for shells.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shells)
      SHELLS_FLAG="${2:-}"
      shift 2
      ;;
    --shells=*)
      SHELLS_FLAG="${1#*=}"
      shift
      ;;
    --check|check)
      CHECK_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done
if [[ -z "$SHELLS_FLAG" && -n "${SHELLS:-}" ]]; then
  SHELLS_FLAG="$SHELLS"
fi

copy_tree() {
  local src="$1" dest="$2"
  [[ -d "$src" ]] || { log "skip (missing): $src"; return 0; }
  if [[ -d "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null || true)" ]]; then
    log "backup → $BACKUP_ROOT/$(basename "$dest")"
    run "mkdir -p '$BACKUP_ROOT'" || true
    run "cp -a '$dest' '$BACKUP_ROOT/$(basename "$dest")'" \
      || log "backup failed (continuing): $dest"
  fi
  run "mkdir -p '$dest'" || { log "cannot create $dest"; return 1; }
  log "copy $src → $dest"
  # a copy error must not abort the install before fix_paths()/verify() run
  if have rsync; then
    run "rsync -a --exclude '.git' '$src/' '$dest/'" \
      || log "rsync failed (continuing): $src → $dest"
  else
    run "cp -a '$src/.' '$dest/'" \
      || log "copy failed (continuing): $src → $dest"
  fi
}

# ── Shell selection (CLI multi-select like Stage3) ──────────
is_skip_shell_dir() {
  local name="$1" n
  for n in "${QS_SKIP_NAMES[@]}"; do
    [[ "$name" == "$n" ]] && return 0
  done
  [[ "$name" == .* ]] && return 0
  return 1
}

list_available_shells() {
  local d
  [[ -d "$ROOT/quickshell" ]] || return 0
  for d in "$ROOT/quickshell"/*/; do
    [[ -d "$d" ]] || continue
    local base
    base="$(basename "$d")"
    is_skip_shell_dir "$base" && continue
    # shell must look like a quickshell root (shell.qml or any root *.qml)
    if [[ -f "$d/shell.qml" ]] || compgen -G "$d/*.qml" >/dev/null 2>&1; then
      printf '%s\n' "$base"
    fi
  done | sort -f
}

parse_shell_list() {
  local raw="$1" item
  SELECTED_SHELLS=()
  raw="${raw// /}"
  [[ -z "$raw" ]] && return 0
  if [[ "$raw" == "all" || "$raw" == "*" ]]; then
    SELECTED_SHELLS=()
    SELECTED_SHELLS_ALL=1
    return 0
  fi
  SELECTED_SHELLS_ALL=0
  IFS=',' read -r -a _items <<<"$raw"
  for item in "${_items[@]}"; do
    [[ -z "$item" ]] && continue
    SELECTED_SHELLS+=("$item")
  done
}

prompt_shell_selection() {
  local -a avail=()
  local line i=0
  while IFS= read -r line; do
    [[ -n "$line" ]] && avail+=("$line")
  done < <(list_available_shells)

  if [[ ${#avail[@]} -eq 0 ]]; then
    log "no shells found under $ROOT/quickshell — full tree deploy"
    SELECTED_SHELLS_ALL=1
    SELECTED_SHELLS=()
    return 0
  fi

  # Non-interactive / explicit "all" / empty flag → full deploy
  if [[ ! -t 0 ]] || [[ -n "${NO_SHELL_PROMPT:-}" ]]; then
    SELECTED_SHELLS_ALL=1
    SELECTED_SHELLS=()
    return 0
  fi

  log "select Quickshell shells to install (multi-select)"
  printf '  [0] all\n'
  for i in "${!avail[@]}"; do
    printf '  [%d] %s\n' "$((i + 1))" "${avail[$i]}"
  done
  printf 'Enter numbers (e.g. 1,3,5), names, or "all" [%s]: ' "${SHELLS_FLAG:-all}"
  local answer=""
  read -r answer || answer=""
  answer="${answer:-${SHELLS_FLAG:-all}}"
  log "selection: $answer"

  if [[ "$answer" == "all" || "$answer" == "*" || "$answer" == "0" ]]; then
    SELECTED_SHELLS_ALL=1
    SELECTED_SHELLS=()
    return 0
  fi

  SELECTED_SHELLS_ALL=0
  SELECTED_SHELLS=()
  local token
  local IFS_save=$IFS
  answer="${answer// /}"
  IFS=',' read -r -a tokens <<<"$answer"
  IFS=$IFS_save
  for token in "${tokens[@]}"; do
    [[ -z "$token" ]] && continue
    if [[ "$token" =~ ^[0-9]+$ ]]; then
      if [[ "$token" -eq 0 ]]; then
        SELECTED_SHELLS_ALL=1
        SELECTED_SHELLS=()
        return 0
      fi
      local idx=$((token - 1))
      if [[ $idx -ge 0 && $idx -lt ${#avail[@]} ]]; then
        SELECTED_SHELLS+=("${avail[$idx]}")
      else
        log "ignore out-of-range index: $token"
      fi
    else
      SELECTED_SHELLS+=("$token")
    fi
  done

  # de-dupe
  if [[ ${#SELECTED_SHELLS[@]} -gt 0 ]]; then
    local -A seen=()
    local -a uniq=()
    local s
    for s in "${SELECTED_SHELLS[@]}"; do
      [[ -n "${seen[$s]:-}" ]] && continue
      seen[$s]=1
      uniq+=("$s")
    done
    SELECTED_SHELLS=("${uniq[@]}")
  fi

  if [[ ${#SELECTED_SHELLS[@]} -eq 0 ]]; then
    log "empty selection — deploying all shells"
    SELECTED_SHELLS_ALL=1
  fi
}

deploy_quickshell() {
  local src="$ROOT/quickshell"
  local dest="$HOME/.config/quickshell"
  [[ -d "$src" ]] || { log "skip (missing): $src"; return 0; }

  if [[ "$SELECTED_SHELLS_ALL" == "1" ]] || [[ ${#SELECTED_SHELLS[@]} -eq 0 ]]; then
    copy_tree "$src" "$dest"
    return 0
  fi

  if [[ -d "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null || true)" ]]; then
    log "backup → $BACKUP_ROOT/quickshell"
    run "mkdir -p '$BACKUP_ROOT'"
    run "cp -a '$dest' '$BACKUP_ROOT/quickshell'"
  fi
  run "mkdir -p '$dest'"
  log "copy shared quickshell root → $dest"
  # root files only (shell.qml, assets, tools, …)
  local item base
  for item in "$src"/*; do
    [[ -e "$item" ]] || continue
    base="$(basename "$item")"
    is_skip_shell_dir "$base" && continue
    if [[ -d "$item" ]]; then
      continue
    fi
    run "cp -a '$item' '$dest/$base'"
  done
  # shared non-shell dirs (settings, previews excluded by skip list)
  if [[ -d "$src/settings" ]]; then
    run "mkdir -p '$dest/settings'"
    run "cp -a '$src/settings/.' '$dest/settings/'"
  fi
  # selected shells only
  local sid
  for sid in "${SELECTED_SHELLS[@]}"; do
    if [[ -d "$src/$sid" ]]; then
      log "copy shell: $sid"
      run "mkdir -p '$dest/$sid'"
      if have rsync; then
        run "rsync -a --exclude '.git' '$src/$sid/' '$dest/$sid/'"
      else
        run "cp -a '$src/$sid/.' '$dest/$sid/'"
      fi
    else
      log "MISS shell (not in repo): $sid"
    fi
  done
}

set_default_shell() {
  local shell_id="$1"
  shell_id="${shell_id// /}"
  [[ -z "$shell_id" || "$shell_id" == "default" ]] && return 0
  local qs_dir="$HOME/.config/quickshell/$shell_id"
  [[ -d "$qs_dir" ]] || { log "default shell missing on disk: $qs_dir — skip"; return 0; }

  local launch=""
  local toggle="$HOME/.config/hypr/scripts/toggle_qs_dots.sh"
  if [[ -f "$toggle" ]]; then
    run "chmod +x '$toggle' || true"
    launch="exec-once = ~/.config/hypr/scripts/toggle_qs_dots.sh $shell_id"
  elif [[ -f "$qs_dir/shell.qml" ]]; then
    launch="exec-once = quickshell -p ~/.config/quickshell/$shell_id/shell.qml"
  else
    log "no shell.qml under $qs_dir — skip default rewrite"
    return 0
  fi

  local marker="# REVO_DEFAULT_SHELL"
  local conf
  for conf in \
    "$HOME/.config/hypr/configs/autostart.conf" \
    "$HOME/.config/hypr/config/autostart.conf"; do
    [[ -f "$conf" ]] || continue
    local tmp
    tmp="$(mktemp)"
    # drop old markers + previous toggle launches; comment stock Main/TopBar/Floating
    awk -v marker="$marker" '
      index($0, marker) { next }
      /^[ \t]*#/ { print; next }
      /^[ \t]*exec-once/ && /toggle_qs_dots\.sh/ { next }
      /^[ \t]*exec-once/ && /quickshell/ && (/Main\.qml/ || /TopBar\.qml/ || /Floating\.qml/) {
        print "# " $0
        next
      }
      { print }
    ' "$conf" >"$tmp"
    printf '%s\n%s\n' "$marker" "$launch" >>"$tmp"
    if [[ "$DRY_RUN" == "1" ]]; then
      log "DRY: set default shell $shell_id in $conf"
      rm -f "$tmp"
    else
      # backup once per conf basename into session backup root
      run "mkdir -p '$BACKUP_ROOT'"
      run "cp -a '$conf' '$BACKUP_ROOT/$(basename "$conf").autostart'"
      run "mv '$tmp' '$conf'"
      log "default shell → $shell_id in $conf"
    fi
  done

  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: write ~/.config/hypr/.revo_default_shell = $shell_id"
  else
    run "mkdir -p '$HOME/.config/hypr'"
    run "printf '%s\\n' '$shell_id' > '$HOME/.config/hypr/.revo_default_shell'"
  fi

  if have hyprctl && [[ "${HYPRLAND_INSTANCE_SIGNATURE:-}" != "" ]]; then
    run "hyprctl reload || true" || true
    run "bash '$toggle' '$shell_id' >/dev/null 2>&1 || true" || true
  fi
}

# ── 1) Detect distro ─────────────────────────────────────────
detect_pm() {
  if have pacman; then echo arch
  elif have apt-get; then echo debian
  elif have dnf; then echo fedora
  else echo unknown
  fi
}
PM="$(detect_pm)"
log "package manager: $PM"

# ── 2) System packages (union for every shell) ───────────────
install_packages() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: would install packages for $PM"
    return 0
  fi
  case "$PM" in
    arch)
      PKGS=(
        hyprland hyprpm xdg-desktop-portal-hyprland hypridle hyprlock hyprpolkitagent hyprsunset polkit
        qt6-base qt6-declarative qt6-5compat qt6-multimedia qt6-multimedia-ffmpeg qt6ct
        qt6-shadertools qt6-wayland qt6-svg qt6-tools qt6-imageformats qt6-location qt6-positioning qt6-lottie
        git curl wget jq python python-pip which libnotify xdg-utils xdg-user-dirs desktop-file-utils
        procps-ng psmisc util-linux coreutils findutils fd gawk sed grep zenity
        pipewire pipewire-pulse wireplumber libpulse playerctl cava mpv-mpris
        networkmanager bluez bluez-utils brightnessctl upower power-profiles-daemon lm_sensors rfkill ddcutil
        grim slurp wf-recorder hyprshot hyprpicker ffmpeg imagemagick wl-clipboard cliphist wtype swappy
        matugen swww hyprpaper swaybg mpvpaper python-pywal swaync swayosd easyeffects
        quickshell
        kitty nautilus thunar rofi-wayland wofi fastfetch starship fish gnome-calculator
        papirus-icon-theme adwaita-cursors xdg-desktop-portal-gtk
        ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common ttf-material-symbols-variable
        noto-fonts noto-fonts-emoji ttf-rubik ttf-iosevka ttf-firacode
        base-devel cmake ninja pkgconf clang gcc
      )
      # shellcheck disable=SC2086
      run "$SUDO pacman -S --noconfirm --needed ${PKGS[*]}" || log "pacman reported errors — continuing"
      AUR_HELPER=""
      have yay && AUR_HELPER=yay
      have paru && AUR_HELPER=paru
      if [[ -n "$AUR_HELPER" ]]; then
        AUR_PKGS=(awww ttf-material-symbols-variable-git ttf-comicshannsmono-nerd ttf-meslo-nerd kde-material-you-colors)
        # official `quickshell` covers qs/quickshell; only fall back to the AUR build
        have qs || have quickshell || AUR_PKGS+=(quickshell-git)
        run "$AUR_HELPER -S --noconfirm --needed ${AUR_PKGS[*]}" || log "AUR partial — some optional packages skipped"
      else
        log "no yay/paru — skipping AUR extras (official quickshell/hyprpm come from the repos)"
      fi
      ;;
    debian)
      run "$SUDO apt-get update -y"
      run "$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y hyprland cmake ninja-build pkg-config git curl jq python3 python3-pip libnotify-bin xdg-utils grim slurp ffmpeg imagemagick wl-clipboard playerctl pipewire wireplumber network-manager bluez brightnessctl fonts-jetbrains-mono papirus-icon-theme rofi kitty fish"
      log "quickshell not in apt — build from https://git.outfoxxed.me/quickshell/quickshell"
      ;;
    fedora)
      run "$SUDO dnf -y install hyprland cmake ninja-build git curl jq python3 python3-pip libnotify xdg-utils grim slurp ffmpeg wl-clipboard playerctl pipewire wireplumber NetworkManager bluez brightnessctl kitty fish"
      ;;
    *)
      log "unknown PM — install packages manually"
      ;;
  esac
}

# ── 3) Python packages ───────────────────────────────────────
install_python() {
  # PEP 668 (Arch, Debian 12+, …) marks the system python "externally managed"
  # and rejects pip installs — even with --user. Bypass it: we only touch the
  # user site-packages, never the distro's files.
  local -a pip_flags=(--user --upgrade)
  if python -m pip install --help 2>/dev/null | grep -q -- '--break-system-packages' &&
     { compgen -G '/usr/lib/python3*/EXTERNALLY-MANAGED' >/dev/null 2>&1 ||
       compgen -G '/usr/lib/python3.*/EXTERNALLY-MANAGED' >/dev/null 2>&1; }; then
    pip_flags+=(--break-system-packages)
    log "python is externally managed (PEP 668) — using --break-system-packages (user site only)"
  fi
  log "pip install (user)…"
  run "python -m pip install ${pip_flags[*]} materialyoucolor pillow numpy click loguru tqdm icalendar recurring-ical-events evdev pywal requests distro psutil PySide6 || true"
  if [[ -f "$ROOT/qs-gui-installer/requirements.txt" ]]; then
    run "python -m pip install ${pip_flags[*]} -r '$ROOT/qs-gui-installer/requirements.txt' || true"
  fi
  if [[ -f "$ROOT/quickshell/Q1/scripts/aikira/requirements.txt" ]]; then
    run "python -m pip install ${pip_flags[*]} -r '$ROOT/quickshell/Q1/scripts/aikira/requirements.txt' || true"
  fi
  if [[ -f "$ROOT/quickshell/nibrasshell/scripts/python/requirements-3.13.txt" ]]; then
    run "python -m pip install ${pip_flags[*]} -r '$ROOT/quickshell/nibrasshell/scripts/python/requirements-3.13.txt' || true"
  fi
}

# ── 4) Build CMake shells ────────────────────────────────────
build_native() {
  local qs="$HOME/.config/quickshell"
  # caelestia shell
  if [[ -f "$qs/shell/CMakeLists.txt" ]]; then
    log "building caelestia shell…"
    run "cmake -S '$qs/shell' -B '$qs/shell/build' -G Ninja -DCMAKE_BUILD_TYPE=Release -DVERSION=1.0.0 -DGIT_REVISION=local -DENABLE_MODULES='extras;plugin;shell' || true"
    run "cmake --build '$qs/shell/build' -j$(nproc) || true"
    run "$SUDO cmake --install '$qs/shell/build' || true"
  fi
  # Clavis shell
  if [[ -f "$qs/imported-1789667132/CMakeLists.txt" ]]; then
    log "building Clavis shell…"
    run "cmake -S '$qs/imported-1789667132' -B '$qs/imported-1789667132/build' -G Ninja -DCMAKE_BUILD_TYPE=Release || true"
    run "cmake --build '$qs/imported-1789667132/build' -j$(nproc) || true"
    run "$SUDO cmake --install '$qs/imported-1789667132/build' || true"
  fi
  build_systemsettings
}

# SystemSettings app (Qt6) → ~/.local/bin/systemsettings
build_systemsettings() {
  local src="$ROOT/SystemSettings" bin="$HOME/.local/bin/systemsettings"
  [[ -f "$src/CMakeLists.txt" ]] || return 0
  log "building SystemSettings…"
  run "cmake -S '$src' -B '$src/build' -G Ninja -DCMAKE_BUILD_TYPE=Release || true"
  run "cmake --build '$src/build' -j$(nproc) || true"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: install -m755 '$src/build/systemsettings' '$bin'"
    return 0
  fi
  if [[ -x "$src/build/systemsettings" ]]; then
    mkdir -p "$HOME/.local/bin"
    if install -m755 "$src/build/systemsettings" "$bin" 2>/dev/null; then
      printf '  [fixed] systemsettings → %s\n' "$bin"
    else
      printf '  [MISS] systemsettings (install failed)\n'
      return 1
    fi
    install_desktop_entry "$bin"
  else
    printf '  [MISS] systemsettings (build produced no binary)\n'
    return 1
  fi
}

# Minimal .desktop launcher so dock/menu entries resolve systemsettings
install_desktop_entry() {
  local bin="$1" apps="$HOME/.local/share/applications"
  local icon="$ROOT/SystemSettings/icons/dt_about.png"
  [[ -f "$apps/systemsettings.desktop" ]] && return 0
  mkdir -p "$apps"
  {
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Name=System Settings\n'
    printf 'Comment=Configure your system\n'
    printf 'Exec=%s\n' "$bin"
    printf 'Terminal=false\n'
    printf 'Categories=Settings;System;\n'
    printf 'StartupWMClass=systemsettings\n'
    [[ -f "$icon" ]] && printf 'Icon=%s\n' "$icon"
  } >"$apps/systemsettings.desktop"
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$apps" >/dev/null 2>&1 || true
  printf '  [fixed] systemsettings.desktop\n'
}

# ── 5) Fix /home/revo paths + guide symlink ──────────────────
# Everything we deploy is written for the dev user (/home/revo). Rewrite it to
# the installing user. Text files are found by content (grep -I), never by a
# fixed extension list, so a new file type can never slip through unnoticed.
FIX_PATHS_DIRS=("$HOME/.config/hypr" "$HOME/.config/quickshell" "$HOME/.config/rofi" "$HOME/.config/kitty")
GREP_SKIP=(--exclude-dir=node_modules --exclude-dir=build --exclude-dir=.git
           --exclude-dir=__pycache__ --exclude-dir=.next --exclude-dir=.cache
           --exclude-dir=dist --exclude-dir=.git)

# list deployed text files that still contain the dev home
list_dev_path_files() {
  # on the dev machine itself /home/revo IS $HOME — nothing to rewrite
  if [[ "$HOME" == "/home/revo" ]]; then
    return 0
  fi
  local dir
  for dir in "${FIX_PATHS_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    grep -rIlZ '/home/revo/' "$dir" "${GREP_SKIP[@]}" 2>/dev/null || true
  done
}

count_dev_paths() {
  [[ "$HOME" == "/home/revo" ]] && { printf '0'; return 0; }
  # list is NUL-separated (-Z) — count NULs
  list_dev_path_files | tr -cd '\0' | wc -c | tr -d ' ' || printf '0'
}

fix_paths() {
  local home_esc f n=0
  home_esc="$(printf '%s' "$HOME" | sed 's/[\/&]/\\&/g')"
  while IFS= read -r -d '' f; do
    [[ -L "$f" ]] && continue
    if [[ "$DRY_RUN" == "1" ]]; then
      n=$((n + 1))
      continue
    fi
    if sed -i "s|/home/revo/|${home_esc}/|g" "$f" 2>/dev/null; then
      n=$((n + 1))
    else
      log "rewrite failed: $f"
    fi
  done < <(list_dev_path_files)
  if [[ "$n" -gt 0 ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      log "DRY: rewrite /home/revo → $HOME in $n file(s)"
    else
      log "rewrote /home/revo → $HOME in $n file(s)"
    fi
  fi

  # guide symlink
  local guide="$HOME/.config/quickshell/guide"
  local target="$HOME/.config/hypr/scripts/quickshell/guide"
  if [[ "$DRY_RUN" == "1" ]]; then
    if [[ -L "$guide" || ! -e "$guide" ]]; then
      log "DRY: rm -f '$guide'; ln -s '$target' '$guide'"
    fi
    return 0
  fi
  if [[ -L "$guide" || ! -e "$guide" ]]; then
    rm -f "$guide"
    [[ -d "$target" ]] && ln -s "$target" "$guide" || true
  fi
}

# ── 6) Services ──────────────────────────────────────────────
enable_services() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: enable pipewire/NetworkManager/bluetooth"
    return 0
  fi
  systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true
  $SUDO systemctl enable --now NetworkManager.service bluetooth.service upower.service 2>/dev/null || true
}

# ── Health check (read-only) ──────────────────────────────────
# Proves the install actually *works*, not just that files landed:
# hyprpm + its repos, the default-shell marker, the shell process,
# QML errors in its log and leftover /home/revo paths.
# Runs at the end of every install, and standalone via ./install.sh --check
health_check() {
  local pass=0 fail=0 warn=0
  local -a fixes=()
  local sid="" shell_dir="" shell_log="" marker lua conf dev_left live=0
  local hyprpm_out repos

  log "── health check ──────────────────────────────"

  if have hyprpm; then
    printf '  [ok]   hyprpm\n'; pass=$((pass + 1))
  else
    printf '  [FAIL] hyprpm (not installed) — no plugins/repos can work\n'
    fail=$((fail + 1))
    fixes+=("sudo pacman -S hyprpm        # Arch/CachyOS: hyprland ships without it")
  fi

  if have hyprctl; then
    printf '  [ok]   hyprctl\n'; pass=$((pass + 1))
  else
    printf '  [FAIL] hyprctl missing — is Hyprland installed?\n'
    fail=$((fail + 1))
    fixes+=("sudo pacman -S hyprland")
  fi

  if have qs || have quickshell; then
    printf '  [ok]   quickshell (qs)\n'; pass=$((pass + 1))
  else
    printf '  [FAIL] quickshell missing — no shell can start\n'
    fail=$((fail + 1))
    fixes+=("sudo pacman -S quickshell    # official Extra pkg (AUR: quickshell-git)")
  fi

  # hyprpm repositories — the "hyprpm repos are missing" report
  if have hyprpm; then
    hyprpm_out="$(hyprpm list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || true)"
    repos="$(printf '%s' "$hyprpm_out" | grep -c 'Repository ' || true)"
    if [[ "${repos:-0}" -gt 0 ]]; then
      printf '  [ok]   hyprpm repos: %s\n' "$repos"
      pass=$((pass + 1))
    else
      printf '  [FAIL] hyprpm repos: none — plugins will not load\n'
      fail=$((fail + 1))
      fixes+=("re-run ./install.sh          # adds the hyprpm repos (or ./update)")
    fi
  fi

  # deployed shells
  local shell_count
  shell_count="$(find "$HOME/.config/quickshell" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ' || true)"
  if [[ "${shell_count:-0}" -gt 0 ]]; then
    printf '  [ok]   %s quickshell shell(s) deployed\n' "$shell_count"
    pass=$((pass + 1))
  else
    printf '  [FAIL] no quickshell shells under ~/.config/quickshell\n'
    fail=$((fail + 1))
    fixes+=("./install.sh --shells macos  # deploy a shell")
  fi

  # default shell marker + the deployed autostart that must read it
  marker="$HOME/.config/hypr/.revo_default_shell"
  [[ -f "$marker" ]] && sid="$(tr -d ' \n' < "$marker")"
  if [[ -n "$sid" && "$sid" != "default" ]]; then
    shell_dir="$HOME/.config/quickshell/$sid"
    if [[ -d "$shell_dir" ]]; then
      printf '  [ok]   default shell: %s\n' "$sid"
      pass=$((pass + 1))
    else
      printf '  [FAIL] default shell "%s" is not deployed (%s)\n' "$sid" "$shell_dir"
      fail=$((fail + 1))
      fixes+=("./install.sh --shells $sid")
    fi
  else
    printf '  [warn] no default shell — login falls back to the legacy Main/TopBar shells\n'
    warn=$((warn + 1))
    fixes+=("./install.sh --shells macos  # set what starts at login")
  fi

  lua="$HOME/.config/hypr/configs/autostart.lua"
  conf="$HOME/.config/hypr/configs/autostart.conf"
  if [[ -f "$lua" ]]; then
    if grep -q 'revo_default_shell' "$lua" 2>/dev/null; then
      printf '  [ok]   autostart.lua launches the selected shell\n'
      pass=$((pass + 1))
    else
      printf '  [FAIL] autostart.lua is an old build — the selected shell never starts\n'
      fail=$((fail + 1))
      fixes+=("re-run ./install.sh          # deploys the fixed autostart.lua")
    fi
    if grep -qE '(^|[^[:alnum:]_])h\.' "$lua" 2>/dev/null; then
      printf '  [FAIL] autostart.lua still calls the undefined "h" (config dies at login)\n'
      fail=$((fail + 1))
      fixes+=("re-run ./install.sh          # deploys the fixed autostart.lua")
    fi
  elif [[ -f "$conf" ]] && grep -q 'REVO_DEFAULT_SHELL' "$conf" 2>/dev/null; then
    printf '  [ok]   autostart.conf carries the default shell\n'
    pass=$((pass + 1))
  else
    printf '  [warn] no deployed autostart that knows about the default shell\n'
    warn=$((warn + 1))
    fixes+=("re-run ./install.sh")
  fi

  # is the selected shell actually running? (only meaningful in a live session)
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || hyprctl version >/dev/null 2>&1; then
    live=1
  fi
  if [[ -n "$sid" && -d "$shell_dir" ]]; then
    if [[ "$live" == "1" ]]; then
      if pgrep -f "quickshell/$sid" >/dev/null 2>&1 || pgrep -f "quickshell .*${sid}" >/dev/null 2>&1; then
        printf '  [ok]   shell "%s" is running\n' "$sid"
        pass=$((pass + 1))
      else
        printf '  [FAIL] shell "%s" is NOT running — the screen will look empty\n' "$sid"
        fail=$((fail + 1))
        fixes+=("bash ~/.config/hypr/scripts/toggle_qs_dots.sh $sid")
      fi
    else
      printf '  [ok]   shell "%s" starts at the next Hyprland login\n' "$sid"
      pass=$((pass + 1))
    fi
  fi

  # QML errors in the shell log (toggle_qs_dots.sh writes these)
  case "$sid" in
    macos) shell_log="$HOME/macos.log" ;;
    k4)    shell_log="/tmp/k4.log" ;;
    ii)    shell_log="/tmp/ii.log" ;;
    *)     shell_log="" ;;
  esac
  if [[ -n "$shell_log" && -f "$shell_log" ]]; then
    if tail -200 "$shell_log" 2>/dev/null \
        | grep -E '(^|[[:space:]])ERROR|Failed to load|Type .* unavailable|No PanelWindow backend' \
          >/dev/null 2>&1; then
      printf '  [FAIL] %s reports QML errors:\n' "$shell_log"
      fail=$((fail + 1))
      tail -200 "$shell_log" 2>/dev/null \
        | grep -E '(^|[[:space:]])ERROR|Failed to load|Type .* unavailable|No PanelWindow backend' \
        | tail -3 | sed 's/^/         /'
      fixes+=("tail -40 $shell_log           # send us this output")
    else
      printf '  [ok]   %s: no QML errors\n' "$(basename "$shell_log")"
      pass=$((pass + 1))
    fi
  fi

  # no deployed config may still point at the dev machine
  dev_left="$(count_dev_paths)"
  if [[ "${dev_left:-0}" -eq 0 ]]; then
    printf '  [ok]   no /home/revo paths in deployed configs\n'
    pass=$((pass + 1))
  else
    printf '  [FAIL] %s file(s) still contain /home/revo\n' "$dev_left"
    fail=$((fail + 1))
    fixes+=("re-run ./install.sh          # fix_paths rewrites them")
  fi

  # python deps used by the shells' scripts
  if python3 -c 'import requests, psutil' >/dev/null 2>&1; then
    printf '  [ok]   python deps (requests, psutil)\n'
    pass=$((pass + 1))
  else
    printf '  [warn] python deps missing — some shell scripts will fail\n'
    warn=$((warn + 1))
    fixes+=("re-run ./install.sh          # installs the pip requirements")
  fi

  log "health check: $pass ok, $fail failed, $warn warning(s)"
  if [[ ${#fixes[@]} -gt 0 ]]; then
    log "how to fix:"
    local f
    for f in "${fixes[@]}"; do
      printf '  → %s\n' "$f"
    done
  fi
  [[ $fail -eq 0 ]] && return 0 || return 1
}

# standalone mode: ./install.sh --check — diagnose only, change nothing
if [[ "$CHECK_ONLY" == "1" ]]; then
  if health_check; then exit 0; else exit 1; fi
fi

# ── Main ─────────────────────────────────────────────────────
log "root: $ROOT"
log "repo: $REPO_URL"

# ── Shell multi-select (before deploy) ──────────────────────
SELECTED_SHELLS_ALL=0
if [[ -n "$SHELLS_FLAG" ]]; then
  parse_shell_list "$SHELLS_FLAG"
  if [[ "$SELECTED_SHELLS_ALL" == "1" ]]; then
    log "shells: all"
  else
    log "shells: ${SELECTED_SHELLS[*]}"
  fi
else
  prompt_shell_selection
  if [[ "$SELECTED_SHELLS_ALL" == "1" ]]; then
    log "shells: all"
  else
    log "shells: ${SELECTED_SHELLS[*]:-all}"
  fi
fi

# ── Deploy FIRST (files must land even if package install fails) ──
copy_tree "$ROOT/hypr" "$HOME/.config/hypr"
deploy_quickshell
copy_tree "$ROOT/wallpapers" "$HOME/Pictures/Wallpapers"
copy_tree "$ROOT/rofi" "$HOME/.config/rofi"
copy_tree "$ROOT/kitty" "$HOME/.config/kitty"

if [[ "$DRY_RUN" != "1" ]]; then
  find "$HOME/.config/hypr" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  find "$HOME/.config/quickshell" -type f \( -name '*.sh' -o -name '*.fish' -o -name 'instalar' -o -name 'install.sh' \) -exec chmod +x {} + 2>/dev/null || true
  chmod +x "$ROOT/install.sh" 2>/dev/null || true
  chmod +x "$ROOT/update.sh" "$ROOT/update" 2>/dev/null || true
fi

fix_paths

# Default shell = first selected (same marker as GUI _set_default_shell)
if [[ "$SELECTED_SHELLS_ALL" != "1" ]] && [[ ${#SELECTED_SHELLS[@]} -gt 0 ]]; then
  set_default_shell "${SELECTED_SHELLS[0]}"
else
  # full deploy overwrote autostart.conf — re-apply the persisted default shell
  if [[ -f "$HOME/.config/hypr/.revo_default_shell" ]]; then
    set_default_shell "$(tr -d ' \n' < "$HOME/.config/hypr/.revo_default_shell")"
  fi
fi

# ── Packages (non-fatal: one failed package must not abort) ──
install_packages || log "package install had errors — continuing (configs already deployed)"
install_python || log "python deps had errors — continuing"

# Ensure rofi + kitty packages (install if user does not have them)
ensure_term_apps() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: would ensure rofi + kitty if missing"
    return 0
  fi
  local need_rofi=0 need_kitty=0
  command -v rofi >/dev/null 2>&1 || need_rofi=1
  command -v kitty >/dev/null 2>&1 || need_kitty=1
  if [[ $need_rofi -eq 0 && $need_kitty -eq 0 ]]; then
    log "rofi + kitty already present"
    return 0
  fi
  case "$PM" in
    arch)
      if [[ $need_rofi -eq 1 ]]; then
        run "$SUDO pacman -S --noconfirm --needed rofi-wayland" \
          || run "$SUDO pacman -S --noconfirm --needed rofi" || true
      fi
      if [[ $need_kitty -eq 1 ]]; then
        run "$SUDO pacman -S --noconfirm --needed kitty" || true
      fi
      ;;
    debian)
      [[ $need_rofi -eq 1 ]] && run "$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y rofi" || true
      [[ $need_kitty -eq 1 ]] && run "$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y kitty" || true
      ;;
    fedora)
      [[ $need_kitty -eq 1 ]] && run "$SUDO dnf -y install kitty" || true
      ;;
  esac
}
ensure_term_apps || true

build_native || log "native shell build had errors — continuing"
enable_services || true

# ── 7) Verify + auto-install missing requirements ───────────
REQUIRED_CMDS=(
  hyprland Hyprland hyprctl hyprpm
  qs quickshell
  kitty rofi
  python python3 pip pip3
  git curl jq cmake ninja
  playerctl grim slurp wl-copy wl-paste
  swww matugen swaync
  pipewire wireplumber
  systemctl
)
CMD_PKGS=(
  "hyprland:hyprland:hyprland:hyprland"
  "hyprctl:hyprland:hyprland:hyprland"
  "hyprpm:hyprpm:hyprland:hyprland"
  "qs:quickshell:quickshell:quickshell"
  "quickshell:quickshell:quickshell:quickshell"
  "kitty:kitty:kitty:kitty"
  "rofi:rofi-wayland:rofi:rofi"
  "python:python:python3:python3"
  "python3:python:python3:python3"
  "pip:python-pip:python3-pip:python3-pip"
  "pip3:python-pip:python3-pip:python3-pip"
  "git:git:git:git"
  "curl:curl:curl:curl"
  "jq:jq:jq:jq"
  "cmake:cmake:cmake:cmake"
  "ninja:ninja:ninja-build:ninja-build"
  "playerctl:playerctl:playerctl:playerctl"
  "grim:grim:grim:grim"
  "slurp:slurp:slurp:slurp"
  "wl-copy:wl-clipboard:wl-clipboard:wl-clipboard"
  "wl-paste:wl-clipboard:wl-clipboard:wl-clipboard"
  "swww:swww:swww:swww"
  "matugen:matugen:matugen:matugen"
  "swaync:swaync:swaync:swaync"
  "pipewire:pipewire:pipewire:pipewire"
  "wireplumber:wireplumber:wireplumber:wireplumber"
  "systemctl:systemd:systemd:systemd"
)
REQUIRED_DIRS=(
  "$HOME/.config/hypr"
  "$HOME/.config/quickshell"
  "$HOME/.config/rofi"
  "$HOME/.config/kitty"
  "$HOME/Pictures/Wallpapers"
)

# Look up package names for a missing cmd on current PM
lookup_pkg() {
  local cmd="$1" entry c a d f
  for entry in "${CMD_PKGS[@]}"; do
    IFS=: read -r c a d f <<<"$entry"
    if [[ "$c" == "$cmd" ]]; then
      case "$PM" in
        arch) echo "$a" ;;
        debian) echo "$d" ;;
        fedora) echo "$f" ;;
        *) echo "" ;;
      esac
      return 0
    fi
  done
  echo ""
}

# Install a list of packages on current PM
install_missing_pkgs() {
  local -a pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  [[ "$DRY_RUN" == "1" ]] && { log "DRY: would install ${pkgs[*]}"; return 0; }
  log "installing missing: ${pkgs[*]}"
  case "$PM" in
    arch)
      run "$SUDO pacman -S --noconfirm --needed ${pkgs[*]}" || true
      # quickshell-git etc. live on AUR
      local -a aur=()
      local p
      for p in "${pkgs[@]}"; do
        [[ "$p" == *-git || "$p" == "awww" || "$p" == "kde-material-you-colors" ]] && aur+=("$p")
      done
      # official `quickshell` missing (old mirror / no repo) → AUR git build
      if ! have qs && ! have quickshell; then
        for p in "${pkgs[@]}"; do
          [[ "$p" == "quickshell" ]] && aur+=(quickshell-git) && break
        done
      fi
      if [[ ${#aur[@]} -gt 0 ]]; then
        local helper=""
        have yay && helper=yay
        have paru && helper=paru
        if [[ -n "$helper" ]]; then
          run "$helper -S --noconfirm --needed ${aur[*]}" || true
        fi
      fi
      ;;
    debian)
      run "$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkgs[*]}" || true
      ;;
    fedora)
      run "$SUDO dnf -y install ${pkgs[*]}" || true
      ;;
  esac
}

# ── hyprpm plugins (HyprGlass, hyprliquid, Hypr3D) ───────────
HYPRGLASS_URL="https://github.com/hyprnux/hyprglass"
HYPRLIQUID_URL="https://github.com/zaregototsukai/hyprliquid"
HYPR3D_URL="https://github.com/samine825/Hypr3D"

hyprpm_list_clean() { hyprpm list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'; }
hyprpm_has() { hyprpm_list_clean | grep -qi "$1"; }
hyprpm_enabled() { hyprpm_list_clean | grep -A2 -i "$1" | grep -q 'enabled.*true'; }

hyprpm_add_repo() {
  local url="$1" name="$2"
  if hyprpm_has "$name"; then
    printf '  [ok]   hyprpm repo %s\n' "$name"
    return 0
  fi
  printf '  [MISS] hyprpm repo %s — adding\n' "$name"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: hyprpm add $url"
    return 0
  fi
  log "hyprpm add $name: clones Hyprland headers and builds the plugin — this first run can take a few minutes"
  local errf
  errf="$(mktemp)"
  # stream the build log (redirecting to a file made this look frozen)
  if timeout 1800 hyprpm add "$url" 2>&1 | tee "$errf"; then
    printf '  [fixed] hyprpm repo %s\n' "$name"
  else
    printf '  [MISS] hyprpm repo %s (add failed)\n' "$name"
    sed 's/^/         /' "$errf" | tail -15
    printf '         → check network/git, then run: hyprpm add %s\n' "$url"
  fi
  rm -f "$errf"
}

ensure_hyprpm_plugins() {
  log "── hyprpm plugins ──────────────────────────────"
  # 1) hyprpm itself (a separate package on Arch/CachyOS, bundled elsewhere)
  if have hyprpm; then
    printf '  [ok]   hyprpm\n'
  else
    printf '  [MISS] hyprpm — installing\n'
    install_missing_pkgs "hyprpm"
    have hyprpm || install_missing_pkgs "hyprland"
    if have hyprpm; then
      printf '  [fixed] hyprpm\n'
    else
      printf '  [MISS] hyprpm (not available)\n'
      printf '         → pacman -S hyprpm   (Arch/CachyOS) / see https://wiki.hypr.land\n'
      return 1
    fi
  fi

  # 2) my plugin repos
  hyprpm_add_repo "$HYPRGLASS_URL"  "HyprGlass"
  hyprpm_add_repo "$HYPRLIQUID_URL" "hyprliquid"
  hyprpm_add_repo "$HYPR3D_URL"     "Hypr3D"

  # 3) liquid glass: prefer hyprliquid, fall back to hyprglass
  local liquid=""
  if hyprpm_has "hyprliquid"; then
    liquid="hyprliquid"
  elif hyprpm_has "HyprGlass"; then
    liquid="hyprglass"
  fi
  if [[ -n "$liquid" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      log "DRY: hyprpm enable $liquid"
    elif hyprpm_enabled "$liquid"; then
      printf '  [ok]   liquid plugin %s (enabled)\n' "$liquid"
    else
      printf '  [MISS] liquid plugin %s — enabling\n' "$liquid"
      if hyprpm enable "$liquid" >/dev/null 2>&1 && hyprpm_enabled "$liquid"; then
        printf '  [fixed] liquid plugin %s\n' "$liquid"
      else
        printf '  [MISS] liquid plugin %s (enable failed)\n' "$liquid"
      fi
    fi
    # keep only one glass engine active
    local other=""
    if [[ "$liquid" == "hyprliquid" ]]; then other="hyprglass"; else other="hyprliquid"; fi
    if hyprpm_has "$other" && hyprpm_enabled "$other"; then
      hyprpm disable "$other" >/dev/null 2>&1 || true
      printf '  [fixed] disabled %s (conflicts with %s)\n' "$other" "$liquid"
    fi
  else
    printf '  [MISS] no liquid plugin repo available\n'
  fi

  # 4) Hypr3D
  if hyprpm_has "Hypr3D"; then
    if [[ "$DRY_RUN" == "1" ]]; then
      log "DRY: hyprpm enable hypr3d"
    elif hyprpm_enabled "hypr3d"; then
      printf '  [ok]   hypr3d (enabled)\n'
    else
      printf '  [MISS] hypr3d — enabling\n'
      if hyprpm enable hypr3d >/dev/null 2>&1 && hyprpm_enabled "hypr3d"; then
        printf '  [fixed] hypr3d\n'
      else
        printf '  [MISS] hypr3d (enable failed)\n'
      fi
    fi
  else
    printf '  [MISS] hypr3d repo not added\n'
  fi

  # 5) load into the running session
  if have hyprpm && [[ "${HYPRLAND_INSTANCE_SIGNATURE:-}" != "" ]] && [[ "$DRY_RUN" != "1" ]]; then
    hyprpm reload >/dev/null 2>&1 || true
  fi
  return 0
}

# Point config plugin loads at the hyprpm-built .so files (per-user cache)
fix_plugin_paths() {
  local user cache conf lua liquid="" hy3d=""
  user="$(id -un)"
  cache="/var/cache/hyprpm/$user"
  conf="$HOME/.config/hypr/hyprland.conf"
  lua="$HOME/.config/hypr/hyprland.lua"

  if [[ -f "$cache/hyprliquid/hyprliquid.so" ]]; then
    liquid="$cache/hyprliquid/hyprliquid.so"
  elif [[ -f "$cache/HyprGlass/hyprglass.so" ]]; then
    liquid="$cache/HyprGlass/hyprglass.so"
  elif [[ -f "$HOME/.local/lib/hyprliquid.so" ]]; then
    liquid="$HOME/.local/lib/hyprliquid.so"
  fi
  if [[ -f "$cache/Hypr3D/hypr3d.so" ]]; then
    hy3d="$cache/Hypr3D/hypr3d.so"
  elif [[ -f "$HOME/Hypr3D/build/hypr3d.so" ]]; then
    hy3d="$HOME/Hypr3D/build/hypr3d.so"
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY: plugin paths → liquid=${liquid:-<none>} hypr3d=${hy3d:-<none>}"
    return 0
  fi
  if [[ -f "$conf" ]]; then
    if [[ -n "$liquid" ]]; then
      sed -i -E "s|^plugin = .+|plugin = $liquid|" "$conf"
    else
      sed -i -E "s|^plugin = (.+)|# plugin = (missing: \1)|" "$conf"
    fi
  fi
  if [[ -n "$liquid" && -f "$lua" ]]; then
    sed -i -E "s#pcall\(hl\.plugin\.load, \"[^\"]*(hyprliquid|hyprglass)\.so\"\)#pcall(hl.plugin.load, \"$liquid\")#" "$lua"
  fi
  if [[ -n "$hy3d" && -f "$lua" ]]; then
    sed -i -E "s|pcall\(hl\.plugin\.load, \"[^\"]*hypr3d\.so\"\)|pcall(hl.plugin.load, \"$hy3d\")|" "$lua"
  fi
}

verify() {
  local pass=0 fail=0
  local -a missing_cmds=() missing_pkgs=()
  log "── verify requirements ──────────────────────────"
  for c in "${REQUIRED_CMDS[@]}"; do
    if have "$c"; then
      printf '  [ok]   %s\n' "$c"
      pass=$((pass + 1))
    else
      printf '  [MISS] %s\n' "$c"
      missing_cmds+=("$c")
      local pkg
      pkg="$(lookup_pkg "$c")"
      if [[ -n "$pkg" ]]; then
        missing_pkgs+=("$pkg")
      else
        log "  no package mapping for: $c"
      fi
      fail=$((fail + 1))
    fi
  done
  # dedupe package list
  if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
    local -A seen=()
    local -a uniq=()
    local p
    for p in "${missing_pkgs[@]}"; do
      [[ -n "${seen[$p]:-}" ]] && continue
      seen[$p]=1
      uniq+=("$p")
    done
    missing_pkgs=("${uniq[@]}")
    # auto-install missing packages
    install_missing_pkgs "${missing_pkgs[@]}"
    # re-check commands after install
    local -a still=()
    for c in "${missing_cmds[@]}"; do
      if have "$c"; then
        printf '  [fixed] %s\n' "$c"
        pass=$((pass + 1))
        fail=$((fail - 1))
      else
        still+=("$c")
      fi
    done
    if [[ ${#still[@]} -gt 0 ]]; then
      missing_cmds=("${still[@]}")
    else
      missing_cmds=()
    fi
  fi
  for d in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$d" ]]; then
      printf '  [ok]   %s\n' "$d"
      pass=$((pass + 1))
    else
      printf '  [MISS] %s\n' "$d"
      fail=$((fail + 1))
    fi
  done
  # quickshell shells present?
  local shell_count
  shell_count=$(find "$HOME/.config/quickshell" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$shell_count" -gt 0 ]]; then
    printf '  [ok]   %s quickshell shell(s)\n' "$shell_count"
    pass=$((pass + 1))
  else
    printf '  [MISS] no quickshell shells deployed\n'
    fail=$((fail + 1))
  fi
  # hyprpm plugins (managed by ensure_hyprpm_plugins)
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '  [ok]   hyprpm plugins (dry-run)\n'
    pass=$((pass + 1))
  elif ! have hyprpm; then
    printf '  [MISS] hyprpm — run ./update.sh\n'
    fail=$((fail + 1))
  elif hyprpm_has "hyprliquid" || hyprpm_has "HyprGlass"; then
    if hyprpm_enabled "hyprliquid" || hyprpm_enabled "hyprglass"; then
      printf '  [ok]   liquid glass plugin (enabled)\n'
      pass=$((pass + 1))
    else
      printf '  [MISS] liquid glass plugin disabled — run ./update.sh\n'
      fail=$((fail + 1))
    fi
  else
    printf '  [MISS] hyprpm repos not added — run ./update.sh\n'
    fail=$((fail + 1))
  fi
  # SystemSettings app
  if [[ -x "$HOME/.local/bin/systemsettings" ]]; then
    printf '  [ok]   systemsettings\n'
    pass=$((pass + 1))
  elif [[ "$DRY_RUN" == "1" && -f "$ROOT/SystemSettings/CMakeLists.txt" ]]; then
    printf '  [ok]   systemsettings (dry-run)\n'
    pass=$((pass + 1))
  else
    printf '  [MISS] systemsettings — run ./update.sh\n'
    fail=$((fail + 1))
  fi
  # no deployed config may still point at the dev machine
  local dev_left
  dev_left="$(count_dev_paths)"
  if [[ "$dev_left" -gt 0 && "$DRY_RUN" != "1" ]]; then
    printf '  [MISS] %s file(s) still contain /home/revo — rewriting\n' "$dev_left"
    fix_paths >/dev/null 2>&1 || true
    dev_left="$(count_dev_paths)"
  fi
  if [[ "$dev_left" -eq 0 ]]; then
    printf '  [ok]   no /home/revo paths in deployed configs\n'
    pass=$((pass + 1))
  elif [[ "$DRY_RUN" == "1" ]]; then
    printf '  [ok]   %s file(s) would be rewritten from /home/revo (dry-run)\n' "$dev_left"
    pass=$((pass + 1))
  else
    printf '  [MISS] %s file(s) still contain /home/revo\n' "$dev_left"
    fail=$((fail + 1))
  fi
  log "verify: $pass ok, $fail missing"
  if [[ $fail -gt 0 ]]; then
    [[ ${#missing_cmds[@]} -gt 0 ]] && log "still missing: ${missing_cmds[*]}"
    log "hint: re-run ./install.sh, or install missing packages manually"
    return 1
  fi
  log "all requirements present ✓"
  return 0
}

log "done — packages, rofi/kitty configs, shells built"
if [[ "$SELECTED_SHELLS_ALL" == "1" ]]; then
  log "deployed: hypr quickshell wallpapers rofi kitty (all shells)"
else
  log "deployed: hypr quickshell wallpapers rofi kitty (shells: ${SELECTED_SHELLS[*]:-all})"
  log "default shell: ${SELECTED_SHELLS[0]:-unchanged}"
fi
if [[ -d "$BACKUP_ROOT" ]]; then
  log "previous configs: $BACKUP_ROOT"
fi
log "launch a shell: qs -p ~/.config/quickshell/<name>"

# safety net: nothing may keep the dev user's paths — rewrite one last time
# after every step that wrote configs (deploy, default-shell marker, builds)
fix_paths || true

# hyprpm plugins + point configs at the hyprpm-built .so files (runs after deploy/fix_paths)
ensure_hyprpm_plugins || log "hyprpm plugin setup had errors — continuing"
fix_plugin_paths || true

verify || true

# did all of that actually produce a working desktop?
if [[ "$DRY_RUN" == "1" ]]; then
  log "DRY: would run the health check (./install.sh --check)"
else
  health_check || log "health check failed — re-run ./install.sh --check to list the fixes"
fi
