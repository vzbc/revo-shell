#!/usr/bin/env bash
# Full CLI installer: packages + clone + deploy + build for ALL Quickshell shells.
# Primary path is still the GUI (qs-gui-installer) — this mirrors it for terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.config/revo-shell-backup-$TS}"
DRY_RUN="${DRY_RUN:-0}"
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/vzbc/revo-shell.git}"
SUDO="${SUDO:-sudo}"

log()  { printf '[install] %s\n' "$*"; }
run()  { if [[ "$DRY_RUN" == "1" ]]; then log "DRY: $*"; else eval "$*"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

copy_tree() {
  local src="$1" dest="$2"
  [[ -d "$src" ]] || { log "skip (missing): $src"; return 0; }
  if [[ -d "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null || true)" ]]; then
    log "backup → $BACKUP_ROOT/$(basename "$dest")"
    run "mkdir -p '$BACKUP_ROOT'"
    run "cp -a '$dest' '$BACKUP_ROOT/$(basename "$dest")'"
  fi
  run "mkdir -p '$dest'"
  log "copy $src → $dest"
  if have rsync; then
    run "rsync -a --exclude '.git' '$src/' '$dest/'"
  else
    run "cp -a '$src/.' '$dest/'"
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
        hyprland xdg-desktop-portal-hyprland hypridle hyprlock hyprpolkitagent hyprsunset polkit
        qt6-base qt6-declarative qt6-5compat qt6-multimedia qt6-multimedia-ffmpeg qt6ct
        qt6-shadertools qt6-wayland qt6-svg qt6-tools qt6-imageformats qt6-location qt6-positioning qt6-lottie
        git curl wget jq python python-pip which libnotify xdg-utils xdg-user-dirs desktop-file-utils
        procps-ng psmisc util-linux coreutils findutils fd gawk sed grep zenity
        pipewire pipewire-pulse wireplumber libpulse playerctl cava mpv-mpris
        networkmanager bluez bluez-utils brightnessctl upower power-profiles-daemon lm_sensors rfkill ddcutil
        grim slurp wf-recorder hyprshot hyprpicker ffmpeg imagemagick wl-clipboard cliphist wtype swappy
        matugen swww hyprpaper swaybg mpvpaper python-pywal swaync swayosd easyeffects
        kitty nautilus thunar rofi-wayland wofi fastfetch starship fish gnome-calculator
        papirus-icon-theme adwaita-cursors xdg-desktop-portal-gtk
        ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common ttf-material-symbols-variable
        noto-fonts noto-fonts-emoji ttf-rubik ttf-iosevka ttf-firacode
        base-devel cmake ninja pkgconf clang gcc
      )
      # shellcheck disable=SC2086
      run "$SUDO pacman -S --noconfirm --needed ${PKGS[*]}"
      AUR_HELPER=""
      have yay && AUR_HELPER=yay
      have paru && AUR_HELPER=paru
      if [[ -n "$AUR_HELPER" ]]; then
        AUR_PKGS=(quickshell-git awww ttf-material-symbols-variable-git ttf-comicshannsmono-nerd ttf-meslo-nerd kde-material-you-colors)
        run "$AUR_HELPER -S --noconfirm --needed ${AUR_PKGS[*]}" || log "AUR partial — some optional packages skipped"
      else
        log "no yay/paru — skipping AUR (install yay for quickshell-git)"
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
  log "pip install (user)…"
  run "python -m pip install --user --upgrade materialyoucolor pillow numpy click loguru tqdm icalendar recurring-ical-events evdev pywal requests distro psutil PySide6 || true"
  if [[ -f "$ROOT/qs-gui-installer/requirements.txt" ]]; then
    run "python -m pip install --user -r '$ROOT/qs-gui-installer/requirements.txt' || true"
  fi
  if [[ -f "$ROOT/quickshell/Q1/scripts/aikira/requirements.txt" ]]; then
    run "python -m pip install --user -r '$ROOT/quickshell/Q1/scripts/aikira/requirements.txt' || true"
  fi
  if [[ -f "$ROOT/quickshell/nibrasshell/scripts/python/requirements-3.13.txt" ]]; then
    run "python -m pip install --user -r '$ROOT/quickshell/nibrasshell/scripts/python/requirements-3.13.txt' || true"
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
}

# ── 5) Fix /home/revo paths + guide symlink ──────────────────
fix_paths() {
  local home_esc
  home_esc="$(printf '%s' "$HOME" | sed 's/[\/&]/\\&/g')"
  for dir in "$HOME/.config/hypr" "$HOME/.config/quickshell" "$HOME/.config/rofi" "$HOME/.config/kitty"; do
    [[ -d "$dir" ]] || continue
    find "$dir" -type f \( -name '*.conf' -o -name '*.lua' -o -name '*.json' -o -name '*.sh' -o -name '*.qml' -o -name '*.py' -o -name '*.rasi' \) -print0 2>/dev/null \
      | while IFS= read -r -d '' f; do
          if grep -q '/home/revo/' "$f" 2>/dev/null; then
            sed -i "s|/home/revo/|${home_esc}/|g" "$f" 2>/dev/null || true
          fi
        done
  done
  # guide symlink
  local guide="$HOME/.config/quickshell/guide"
  local target="$HOME/.config/hypr/scripts/quickshell/guide"
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

# ── Main ─────────────────────────────────────────────────────
log "root: $ROOT"
log "repo: $REPO_URL"

# ── Deploy FIRST (files must land even if package install fails) ──
copy_tree "$ROOT/hypr" "$HOME/.config/hypr"
copy_tree "$ROOT/quickshell" "$HOME/.config/quickshell"
copy_tree "$ROOT/wallpapers" "$HOME/Pictures/Wallpapers"
copy_tree "$ROOT/rofi" "$HOME/.config/rofi"
copy_tree "$ROOT/kitty" "$HOME/.config/kitty"

if [[ "$DRY_RUN" != "1" ]]; then
  find "$HOME/.config/hypr" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  find "$HOME/.config/quickshell" -type f \( -name '*.sh' -o -name '*.fish' -o -name 'instalar' -o -name 'install.sh' \) -exec chmod +x {} + 2>/dev/null || true
  chmod +x "$ROOT/install.sh" 2>/dev/null || true
fi

fix_paths

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
  hyprland Hyprland hyprctl
  qs quickshell
  kitty rofi
  python python3 pip pip3
  git curl jq cmake ninja
  playerctl grim slurp wl-copy wl-paste
  swww matugen swaync
  pipewire wireplumber
  systemctl
)
# Map each binary → package name per PM (cmd:arch:debian:fedora)
CMD_PKGS=(
  "hyprland:hyprland:hyprland:hyprland"
  "hyprctl:hyprland:hyprland:hyprland"
  "qs:quickshell-git:quickshell:quickshell"
  "quickshell:quickshell-git:quickshell:quickshell"
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
  # hyprpm + HyprGlass plugin
  HYPRGLASS_URL="https://github.com/hyprnux/hyprglass"
  if have hyprpm; then
    printf '  [ok]   hyprpm\n'
    pass=$((pass + 1))
    # check if hyprglass is installed + enabled
    if hyprpm list 2>/dev/null | grep -qi 'HyprGlass'; then
      if hyprpm list 2>/dev/null | grep -A2 -i 'HyprGlass' | grep -q 'enabled.*true'; then
        printf '  [ok]   hyprglass (enabled)\n'
        pass=$((pass + 1))
      else
        printf '  [MISS] hyprglass installed but disabled — enabling\n'
        run "hyprpm enable hyprglass" || true
        if hyprpm list 2>/dev/null | grep -A2 -i 'HyprGlass' | grep -q 'enabled.*true'; then
          printf '  [fixed] hyprglass\n'
          pass=$((pass + 1))
        else
          fail=$((fail + 1))
        fi
      fi
    else
      printf '  [MISS] hyprglass — installing via hyprpm\n'
      if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY: hyprpm add $HYPRGLASS_URL && hyprpm enable hyprglass"
      else
        hyprpm add "$HYPRGLASS_URL" || true
        hyprpm enable hyprglass || true
      fi
      if hyprpm list 2>/dev/null | grep -qi 'HyprGlass'; then
        printf '  [fixed] hyprglass\n'
        pass=$((pass + 1))
      else
        printf '  [MISS] hyprglass (install failed)\n'
        fail=$((fail + 1))
      fi
    fi
  else
    printf '  [MISS] hyprpm\n'
    fail=$((fail + 1))
    # hyprpm ships with hyprland — try install
    install_missing_pkgs "hyprland"
    if have hyprpm; then
      printf '  [fixed] hyprpm\n'
      pass=$((pass + 1))
      # now try hyprglass
      if ! hyprpm list 2>/dev/null | grep -qi 'HyprGlass'; then
        if [[ "$DRY_RUN" == "1" ]]; then
          log "DRY: hyprpm add $HYPRGLASS_URL && hyprpm enable hyprglass"
        else
          hyprpm add "$HYPRGLASS_URL" || true
          hyprpm enable hyprglass || true
        fi
      fi
      if hyprpm list 2>/dev/null | grep -qi 'HyprGlass'; then
        printf '  [fixed] hyprglass\n'
        pass=$((pass + 1))
      else
        printf '  [MISS] hyprglass\n'
        fail=$((fail + 1))
      fi
    else
      fail=$((fail + 1))
    fi
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
log "deployed: hypr quickshell wallpapers rofi kitty"
if [[ -d "$BACKUP_ROOT" ]]; then
  log "previous configs: $BACKUP_ROOT"
fi
log "launch a shell: qs -p ~/.config/quickshell/<name>"
verify || true
