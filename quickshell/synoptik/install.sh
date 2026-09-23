#!/usr/bin/env bash

# Prevent running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Don't run this as root — run it as your normal user."
    exit 1
fi

# Ensure pacman exists (Arch Linux check)
if ! command -v pacman >/dev/null 2>&1; then
    echo "pacman not found. Synoptik requires Arch Linux. Aborting."
    exit 1
fi

# 1. Install fish if missing
if ! command -v fish >/dev/null 2>&1; then
    echo "==> Installing fish shell via pacman..."
    sudo pacman -S --needed --noconfirm fish || exit 1
fi

# 2. Hand execution off to fish
exec fish -c '
# Ensure terminal scroll region is restored on exit or error
function cleanup
    # Reset scrolling region to full screen
    tput csr 0 (tput lines)
    # Move cursor to bottom
    tput cup (tput lines) 0
end
trap cleanup EXIT INT TERM

# Clear screen completely
clear

# Print fixed ASCII Art at the top (Lines 1–8)
set_color -o cyan
echo "███████╗██╗   ██╗███╗   ██╗ ██████╗ ██████╗ ████████╗██╗██╗  ██╗"
echo "██╔════╝╚██╗ ██╔╝████╗  ██║██╔═══██╗██╔═══██╗╚══██╔══╝██║██║ ██╔╝"
echo "███████╗ ╚████╔╝ ██╔██╗ ██║██║   ██║██████╔╝   ██║   ██║█████╔╝ "
echo "╚════██║  ╚██╔╝  ██║╚██╗██║██║   ██║██╔═══╝    ██║   ██║██╔═██╗ "
echo "███████║   ██║   ██║ ╚████║╚██████╔╝██║        ██║   ██║██║  ██╗"
echo "╚══════╝   ╚═╝   ╚═╝  ╚═══╝ ╚═════╝ ╚═╝        ╚═╝   ╚═╝╚═╝  ╚═╝"
set_color normal
echo "-----------------------------------------------------------------"

# Lock lines 1–9 at the top and set scroll region from line 10 to screen bottom
set lines (tput lines)
tput csr 9 $lines
# Position cursor at line 10 to begin execution output
tput cup 9 0

function say
    set_color -o cyan
    printf "==> "
    set_color normal
    echo $argv
end

# Check for or bootstrap an AUR helper (paru or yay)
set AUR_HELPER ""
if command -v paru >/dev/null
    set AUR_HELPER paru
else if command -v yay >/dev/null
    set AUR_HELPER yay
else
    say "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    or exit 1
    set tmpdir (mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    or exit 1
    set orig_dir (pwd)
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    or exit 1
    cd "$orig_dir"
    rm -rf "$tmpdir"
    set AUR_HELPER yay
end

# Official Arch packages
set PACMAN_PKGS \
    hyprland \
    base-devel \
    git \
    qt6-base \
    qt6-declarative \
    qt6-5compat \
    qt6-multimedia \
    qt6-multimedia-ffmpeg \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugin-pipewire \
    v4l-utils \
    fish \
    python \
    python-gobject \
    curl \
    jq \
    wireplumber \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    pipewire-alsa \
    cava \
    networkmanager \
    bluez \
    bluez-utils \
    brightnessctl \
    playerctl \
    wl-clipboard \
    grim \
    slurp \
    satty \
    showmethekey \
    wf-recorder \
    hypridle \
    libnotify \
    ffmpeg \
    procps-ng \
    psmisc \
    xdg-utils \
    gawk \
    sed \
    coreutils \
    util-linux \
    power-profiles-daemon \
    libcanberra \
    qt6-webview \
    qt6-imageformats

say "Installing pacman packages..."
sudo pacman -S --needed --noconfirm $PACMAN_PKGS
or exit 1

# Explicit AUR packages
set AUR_PKGS \
    quickshell-git \
    awww \
    mpvpaper \
    cliphist \
    ttf-material-symbols-variable-git \
    iris-colors

# Check both exact package names and provided capabilities via pacman -T / pacman -Qs
set MISSING_AUR_PKGS
for pkg in $AUR_PKGS
    # Strip -git suffix for local capability comparison
    set base_pkg (string replace -r "-git\$" "" $pkg)
    
    # Test if package, base package, or capability is satisfied
    if pacman -T $pkg >/dev/null 2>&1
        continue
    else if pacman -T $base_pkg >/dev/null 2>&1
        continue
    else if pacman -Qs "^$base_pkg" >/dev/null 2>&1
        continue
    else
        set -a MISSING_AUR_PKGS $pkg
    end
end

if test -n "$MISSING_AUR_PKGS"
    say "Installing missing AUR packages: $MISSING_AUR_PKGS..."
    $AUR_HELPER -S --needed $MISSING_AUR_PKGS
    or exit 1
else
    say "All AUR packages are already installed, skipping."
end

say "Enabling systemd services..."
sudo systemctl enable --now power-profiles-daemon.service
or exit 1

set TARGET_DIR "$HOME/.config/quickshell/Synoptik"
say "Deploying Synoptik Shell files..."

mkdir -p "$HOME/.config/quickshell"

# CD out of target directory to ensure working directory stays valid during clone/removal
cd "$HOME"

# Clone or pull latest repository state
if test -d "$TARGET_DIR/.git"
    say "Existing git installation detected at $TARGET_DIR. Syncing with remote..."
    cd "$TARGET_DIR"
    git fetch origin main >/dev/null 2>&1
    and git reset --hard origin/main >/dev/null 2>&1
    or begin
        echo "Failed to sync repo at $TARGET_DIR"
        exit 1
    end
else
    say "Cloning repository to $TARGET_DIR..."
    if test -d "$TARGET_DIR"
        rm -rf "$TARGET_DIR"
    end
    git clone -b main https://github.com/natepayn3/Synoptik.git "$TARGET_DIR"
    or begin
        echo "Failed to clone repository."
        exit 1
    end
end

# Make all backend helper scripts executable
if test -d "$TARGET_DIR/scripts"
    say "Setting executable permissions on backend scripts..."
    chmod +x "$TARGET_DIR"/scripts/*
end

set HYPR_LUA "$HOME/.config/hypr/hyprland.lua"
set LUA_DIRECTIVE "-- Load custom isolated dynamic border style configuration\nrequire(\"hypr_style\")"

say "Updating Hyprland Lua configuration..."
mkdir -p "$HOME/.config/hypr"
touch "$HYPR_LUA"

# Append the directive only if it does not already exist in the file
if not grep -q "require(\"hypr_style\")" "$HYPR_LUA"
    # Ensure file ends with a newline before appending logic
    test -s "$HYPR_LUA"; and test (tail -c 1 "$HYPR_LUA" | wc -l) -eq 0; and echo "" >> "$HYPR_LUA"
    echo -e "\n$LUA_DIRECTIVE" >> "$HYPR_LUA"
    say "Appended hypr_style require directive to $HYPR_LUA"
else
    say "Directive already present in $HYPR_LUA, skipping."
end

say "Restarting quickshell..."
# Suppress error outputs if no instances were running
killall quickshell >/dev/null 2>&1
killall qs >/dev/null 2>&1

# Launch new instance and disown job
qs -c Synoptik >/dev/null 2>&1 &
disown

echo ""
say "Done! Synoptik Shell is ready and running."
'
