# 🎨 Cartoon Shell - QuickShell Panel for Hyprland

<div align="center">

[Cartoon Shell Screenshot](https://github.com/user-attachments/assets/315049eb-89f6-47e3-8890-e7c2b4364025)

*A modern, feature-rich Wayland panel built with QuickShell for Hyprland*

[![Hyprland](https://img.shields.io/badge/Hyprland-Compatible-blue)](https://hyprland.org/)
[![QuickShell](https://img.shields.io/badge/QuickShell-Wayland-green)](https://github.com/outfoxxed/quickshell)

</div>

---

## 🎯 Introduction

**Cartoon Shell** is a modern Wayland panel built entirely with **QuickShell** (QML) specifically for **Hyprland window manager**. The panel provides a smooth user experience with highly customizable interface, multi-language support, and multi-resolution display compatibility.


## 💻 System Requirements

### Operating System
- **Linux** (developed on Arch Linux)
- **Wayland** compositor (X11 not supported)
- **Hyprland(Lua)** window manager (required)

## 🔧 Installation

### 1. Install dependencies (Arch Linux)

#### Full setup with dotfiles
```bash
cd ~
git clone https://github.com/mailong2401/dotfiles-hyprland
cd dotfiles-hyprland
chmod +x setup.sh
./setup.sh
```

#### Or manual installation
```bash
# Install main packages (Arch Linux)
sudo pacman -S hyprland networkmanager brightnessctl \
               bluez bluez-utils pipewire wireplumber curl python \
               jq ffmpeg qt6-multimedia bc 

# Install AUR packages
yay -S quickshell-git cava sysstat qt6-5compat ttf-comicshannsmono-nerd ttf-material-symbols-variable-git
```

### 2. Clone Cartoon Shell
```bash
# Clone to QuickShell config directory
git clone https://github.com/mailong2401/cartoon-shell.git \
    ~/.config/quickshell/cartoon-shell

cd ~/.config/quickshell/cartoon-shell
```

### 3. Run QuickShell
```bash
# Run directly
quickshell --path ~/.config/quickshell/cartoon-shell

# Or add to Hyprland config
echo "quickshell --path ~/.config/quickshell/cartoon-shell" \
    >> ~/.config/hypr/hyprland.conf
```


---
## Contributors

<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="25%"><a href="https://github.com/crystalforceix"><img src="https://avatars.githubusercontent.com/u/171352546?v=4?s=100" width="100px;" alt="Anh Ba Phu"/><br /><sub><b>Anh Ba Phu</b></sub></a><br /></td>
    </tr>
  </tbody>
</table>

## Star History

<a href="https://www.star-history.com/?repos=mailong2401%2Fcartoon-shell&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=mailong2401/cartoon-shell&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=mailong2401/cartoon-shell&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=mailong2401/cartoon-shell&type=date&legend=top-left" />
 </picture>
</a>
