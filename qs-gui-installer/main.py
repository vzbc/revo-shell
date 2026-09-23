"""
Quickshell GUI Installer - Black/White Design

Single-window QML installer (MainView.qml) with a fixed sidebar and
five stages. English-only UI, SF Pro typography.

Key Features:
- Black (#000000) / white (#FFFFFF) design language
- Five-stage flow with fixed sidebar (Magic UI / shadcn style)
- Pre-flight Safety Checks: Anti-overwrite protection and system validation
- Core Deployment Engine: GitHub & Local sync for Quickshell and Hyprland
"""

import os
import sys
import json
import shutil
import platform
import subprocess
import threading
import time
import datetime
import logging
import distro
import psutil
import traceback
from pathlib import Path
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass
from enum import Enum

# Logging (also write a file so failures are visible after GUI closes)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
log_dir = Path.home() / ".local" / "state" / "qs-gui-installer"
try:
    log_dir.mkdir(parents=True, exist_ok=True)
    _fh = logging.FileHandler(log_dir / "install.log", encoding="utf-8")
    _fh.setFormatter(logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s"))
    logging.getLogger().addHandler(_fh)
except Exception:
    pass
logger = logging.getLogger(__name__)

# Try to import PySide6 modules
TRY_QT = True
if TRY_QT:
    try:
        from PySide6.QtCore import (
            QObject, Signal, QTimer, QThread, QSize, Qt, QRectF, QPoint, QPointF,
            QTimeLine, QEasingCurve, QPropertyAnimation, QSequentialAnimationGroup,
            QParallelAnimationGroup, QUrl
        )
        from PySide6.QtGui import (
            QColor, QPainter, QBrush, QPen, QFont, QLinearGradient, QGradient,
            QMouseEvent, QWheelEvent, QAction, QFontDatabase, QIcon, QFontMetrics,
            QPalette, QWindow
        )
        from PySide6.QtWidgets import (
            QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
            QStackedLayout, QFormLayout, QLabel, QLineEdit, QPushButton,
            QProgressBar, QMessageBox, QTextEdit, QSpinBox, QGroupBox,
            QDial, QSlider, QSplitter, QScrollArea, QStackedWidget,
            QCheckBox, QRadioButton, QListWidget, QListWidgetItem, QTableWidget,
            QTableWidgetItem, QHeaderView, QGraphicsView, QGraphicsScene,
            QFileDialog, QInputDialog, QGridLayout, QFrame, QMenu, QMenuBar,
            QSplashScreen, QSizePolicy, QSystemTrayIcon
        )
        try:
            from PySide6.QtQuickWidgets import QQuickWidget
        except ImportError:
            from PySide6.QtQuick import QQuickWidget
        from PySide6.QtQml import QQmlComponent, QQmlProperty, QQmlApplicationEngine
    except ImportError as e:
        logger.warning(f"PySide6 import failed: {e}")
        TRY_QT = False
else:
    TRY_QT = False

# Installer Configuration
class InstallerConfig:
    # Monorepo (hypr/ + quickshell/ + wallpapers/) — set after you create the GitHub repo
    DOTFILES_REPO_URL = "https://github.com/X3jo/revo-shell.git"
    # Same monorepo paths (kept for tests / older hooks)
    QUIKSHELL_REPO_URL = DOTFILES_REPO_URL
    HYPRLAND_CONFIGS_REPO_URL = DOTFILES_REPO_URL

    # Installation paths
    INSTALL_PREFIX = "/usr/local"
    HOME_QUICKSHELL_PATH = "~/.config/quickshell"
    HOME_HYPR_PATH = "~/.config/hypr"
    HOME_WALLPAPERS_PATH = "~/Pictures/Wallpapers"
    HOME_ROFI_PATH = "~/.config/rofi"
    HOME_KITTY_PATH = "~/.config/kitty"
    BACKUP_DIR = "/tmp/dotfiles_backup"

    # Version
    INSTALLER_VERSION = "1.0.0"
    MIN_SYSTEM_VERSION = "5.4"

    # Safety
    AUTO_BACKUP_ENABLED = True
    REQUIRE_ROOT = False
    # GUI always installs packages/builds even if configs already exist
    FORCE_FULL_INSTALL = True

    # UI
    WINDOW_WIDTH = 1024
    WINDOW_HEIGHT = 768
    ANIMATION_DURATION = 300
    BORDER_RADIUS = 12
    GLASS_EFFECT_ENABLED = True

    # Arch/CachyOS package union — enough for every shell + hypr
    PACMAN_PACKAGES = [
        # compositor + shell runtime
        "hyprland", "xdg-desktop-portal-hyprland", "hypridle", "hyprlock",
        "hyprpolkitagent", "hyprsunset", "polkit",
        "qt6-base", "qt6-declarative", "qt6-5compat", "qt6-multimedia",
        "qt6-multimedia-ffmpeg", "qt6ct", "qt6-shadertools", "qt6-wayland",
        "qt6-svg", "qt6-tools", "qt6-imageformats", "qt6-location",
        "qt6-positioning", "qt6-lottie",
        # tools
        "git", "curl", "wget", "jq", "python", "python-pip", "which",
        "libnotify", "xdg-utils", "xdg-user-dirs", "desktop-file-utils",
        "procps-ng", "psmisc", "util-linux", "coreutils", "findutils",
        "fd", "gawk", "sed", "grep", "zenity",
        # audio
        "pipewire", "pipewire-pulse", "wireplumber", "libpulse",
        "playerctl", "cava", "mpv-mpris",
        # network / bt / power / sensors
        "networkmanager", "bluez", "bluez-utils", "brightnessctl",
        "upower", "power-profiles-daemon", "lm_sensors", "rfkill", "ddcutil",
        # capture / clipboard
        "grim", "slurp", "wf-recorder", "hyprshot", "hyprpicker",
        "ffmpeg", "imagemagick", "wl-clipboard", "cliphist", "wtype", "swappy",
        # theming / wallpaper
        "matugen", "swww", "hyprpaper", "swaybg", "mpvpaper", "python-pywal",
        "swaync", "swayosd", "easyeffects",
        # desktop apps used by shells (install if missing — GUI verifies later)
        "kitty", "nautilus", "thunar", "rofi-wayland", "rofi", "wofi",
        "fastfetch", "starship", "fish", "gnome-calculator",
        "papirus-icon-theme", "adwaita-cursors", "ttf-dejavu",
        "xdg-desktop-portal-gtk", "qt5compat",
        # fonts (UI + icons for shells)
        "ttf-jetbrains-mono-nerd", "ttf-nerd-fonts-symbols-common",
        "ttf-material-symbols-variable", "noto-fonts", "noto-fonts-emoji",
        "ttf-rubik", "ttf-iosevka", "ttf-firacode",
        # build toolchain for C++ shells
        "base-devel", "cmake", "ninja", "pkgconf", "clang", "gcc",
    ]

    AUR_PACKAGES = [
        "quickshell-git",
        "awww",
        "ttf-material-symbols-variable-git",
        "ttf-comicshannsmono-nerd",
        "ttf-meslo-nerd",
        "kde-material-you-colors",
        "hyprpolkitagent",
        "cliphist",
    ]

    PIP_PACKAGES = [
        "materialyoucolor", "pillow", "numpy", "click", "loguru", "tqdm",
        "icalendar", "recurring-ical-events", "evdev", "pywal",
        "requests", "distro", "psutil", "PySide6",
    ]

# Data Models
@dataclass
class SystemInfo:
    distribution: str
    version: str
    architecture: str
    kernel: str
    hostname: str
    memory_gb: float
    cpu_cores: int
    cpu_model: str
    gpu_info: str

@dataclass
class ShellInfo:
    id: str
    name: str
    description: str
    repo_url: str
    icon_path: str
    preview_path: str
    theme_color: QColor
    build_type: str
    dependencies: List[str]

@dataclass
class InstallationResult:
    success: bool
    message: str
    files_installed: int
    backup_created: bool
    errors: List[str]

class InstallationStep(Enum):
    PRE_FLIGHT_CHECK = "pre_flight_check"
    SAFETY_VERIFICATION = "safety_verification"
    BACKUP_CREATION = "backup_creation"
    DOTFILES_INSTALLATION = "dotfiles_installation"
    HYPRLAND_INSTALLATION = "hyprland_installation"
    QUIKSHELL_INSTALLATION = "quickshell_installation"
    CONFIGURATION = "configuration"
    VERIFICATION = "verification"
    COMPLETION = "completion"

# Background Worker for Safe Operations
class InstallationWorker(QObject):
    progress_changed = Signal(int, str)
    installation_result = Signal(InstallationResult)
    system_info_ready = Signal(SystemInfo)

    def __init__(self):
        super().__init__()
        self.config = InstallerConfig()
        self.system_info = None
        self.is_cancelled = False
        self.current_step = InstallationStep.PRE_FLIGHT_CHECK
        self.current_shell = None
        self.sudo_password: str = ""
        self._staged_repo: Optional[Path] = None
        self._staged_is_local: bool = False

    def run_installation(self, shell_id: str = None, password: str = ""):
        """Full install: packages → clone → deploy → build → python → services."""
        try:
            logger.info("Starting full installation process...")
            if password:
                self.sudo_password = password

            self.progress_changed.emit(5, "Getting system information...")
            self.system_info = self._get_system_info()
            self.system_info_ready.emit(self.system_info)

            self.progress_changed.emit(8, "Running pre-flight checks...")
            if not self._pre_flight_check():
                self.installation_result.emit(InstallationResult(
                    success=False,
                    message="Pre-flight checks failed. Installation aborted.",
                    files_installed=0,
                    backup_created=False,
                    errors=["System requirements not met"]
                ))
                return

            # Soft safety: warn only — FORCE_FULL_INSTALL + per-file backup
            self.progress_changed.emit(12, "Safety verification...")
            if not self._safety_verification():
                logger.warning("Configs already present — continuing with backup (force full install)")
                if not self.config.FORCE_FULL_INSTALL:
                    self.installation_result.emit(InstallationResult(
                        success=False,
                        message="Safety verification failed. Installation aborted.",
                        files_installed=0,
                        backup_created=False,
                        errors=["Potential overwrite detected"]
                    ))
                    return

            self.progress_changed.emit(15, "Creating backup...")
            backup_result = self._create_backup()
            if backup_result['success']:
                self.progress_changed.emit(18, f"Backup created at {backup_result['path']}")

            # 1) System packages (all libraries for every shell)
            self.progress_changed.emit(22, "Installing system packages…")
            pkg_ok, pkg_err = self._install_system_packages()
            if not pkg_ok:
                logger.warning(f"Package install issues: {pkg_err}")

            # 2) Clone monorepo once (shared by deploy steps)
            self.progress_changed.emit(40, "Cloning monorepo from GitHub…")
            try:
                self._staged_repo = self._clone_monorepo()
            except Exception as e:
                self._staged_repo = None
                logger.error(f"Clone failed: {e}")
            if self._staged_repo is None:
                self.installation_result.emit(InstallationResult(
                    success=False,
                    message="Failed to clone repository. Check DOTFILES_REPO_URL / network.",
                    files_installed=0,
                    backup_created=backup_result['success'],
                    errors=["git clone failed or URL not configured"]
                ))
                return

            # 3) Deploy trees
            self.progress_changed.emit(55, "Installing wallpapers…")
            dotfiles_result = self._install_dotfiles()

            self.progress_changed.emit(65, "Installing Hyprland configurations…")
            hyprland_result = self._install_hyprland_configs()

            self.progress_changed.emit(72, "Installing Quickshell shells…")
            quickshell_result = self._install_quickshell(shell_id)

            self.progress_changed.emit(76, "Installing rofi & kitty configs…")
            desk_result = self._install_desktop_configs()

            # 4) Rewrite absolute /home/revo paths → current $HOME
            self.progress_changed.emit(80, "Fixing home paths…")
            self._fix_home_paths()

            # 5) Python deps for shells + GUI
            self.progress_changed.emit(85, "Installing Python packages…")
            self._install_python_packages()

            # 6) Build C++ shells (caelestia + clavis) — best effort
            self.progress_changed.emit(90, "Building native shell modules…")
            self._build_native_shells()

            # 7) Services + permissions + verify
            self.progress_changed.emit(95, "Enabling services & permissions…")
            self._enable_services()
            self._finalize_installation()

            total = (
                dotfiles_result.get('files_installed', 0)
                + hyprland_result.get('files_installed', 0)
                + quickshell_result.get('files_installed', 0)
                + desk_result.get('files_installed', 0)
            )
            # Fail loudly if nothing was deployed (typical: clone/preflight issue)
            if total == 0 and not dotfiles_result.get('success'):
                self.installation_result.emit(InstallationResult(
                    success=False,
                    message="Installation failed — no files deployed. Check network / repo URL.",
                    files_installed=0,
                    backup_created=backup_result['success'],
                    errors=[pkg_err or "deploy produced 0 files"]
                ))
                return
            self.progress_changed.emit(100, "Installation complete.")
            self.installation_result.emit(InstallationResult(
                success=True,
                message=f"Installation completed — {total} files installed.",
                files_installed=total,
                backup_created=backup_result['success'],
                errors=[pkg_err] if pkg_err else []
            ))

        except Exception as e:
            logger.error(f"Installation error: {str(e)}")
            logger.error("Stack trace: " + traceback.format_exc())
            self.installation_result.emit(InstallationResult(
                success=False,
                message=f"Installation failed: {str(e)}",
                files_installed=0,
                backup_created=False,
                errors=[str(e)]
            ))
        finally:
            # Never delete a local monorepo checkout
            if (
                self._staged_repo
                and self._staged_repo.exists()
                and not self._staged_is_local
                and self._staged_repo.name == "revo_shell_repo"
            ):
                shutil.rmtree(self._staged_repo, ignore_errors=True)
            if not self._staged_is_local:
                self._staged_repo = None

    def _sudo_run(self, cmd: List[str], timeout: int = 1800) -> subprocess.CompletedProcess:
        """Run command with sudo, feeding OTP password on stdin when needed."""
        password = self.sudo_password or ""
        if password:
            input_text = password + "\n"
        else:
            input_text = None
        env = os.environ.copy()
        env.setdefault("SUDO_ASKPASS", "/bin/false")
        return subprocess.run(
            ["sudo", "-S", "-p", "", *cmd],
            input=input_text,
            text=True,
            capture_output=True,
            timeout=timeout,
            env=env,
        )

    def _install_system_packages(self) -> tuple:
        """Install pacman + AUR + pip packages needed by all shells."""
        errors: List[str] = []
        dist = (self.system_info.distribution if self.system_info else "").lower()

        # Arch family → pacman + yay/paru
        if any(x in dist for x in ("arch", "cachyos", "cachy", "manjaro", "garuda", "endeavour", "artix", "arcolinux")) or shutil.which("pacman"):
            pkgs = list(self.config.PACMAN_PACKAGES)
            # filter already-installed
            try:
                q = subprocess.run(
                    ["pacman", "-Qq"], capture_output=True, text=True, timeout=60
                )
                installed = set(q.stdout.split())
                missing = [p for p in pkgs if p not in installed]
            except Exception:
                missing = pkgs

            if missing:
                self.progress_changed.emit(
                    28, f"pacman -S ({len(missing)} packages)…"
                )
                # install in chunks to keep progress alive
                chunk = 40
                for i in range(0, len(missing), chunk):
                    if self.is_cancelled:
                        return False, "cancelled"
                    part = missing[i:i + chunk]
                    try:
                        r = self._sudo_run(
                            ["pacman", "-S", "--noconfirm", "--needed", *part],
                            timeout=3600,
                        )
                        if r.returncode != 0:
                            # retry package-by-package (some names may not exist)
                            for p in part:
                                r2 = self._sudo_run(
                                    ["pacman", "-S", "--noconfirm", "--needed", p],
                                    timeout=600,
                                )
                                if r2.returncode != 0:
                                    errors.append(p)
                    except Exception as e:
                        errors.append(f"chunk:{e}")

            # AUR via yay/paru if present
            aur_helper = None
            for h in ("yay", "paru"):
                if shutil.which(h):
                    aur_helper = h
                    break
            if aur_helper:
                aur_missing = []
                try:
                    q = subprocess.run(
                        [aur_helper, "-Qq"], capture_output=True, text=True, timeout=120
                    )
                    installed = set(q.stdout.split())
                    aur_missing = [p for p in self.config.AUR_PACKAGES if p not in installed]
                except Exception:
                    aur_missing = list(self.config.AUR_PACKAGES)
                if aur_missing:
                    self.progress_changed.emit(
                        35, f"{aur_helper} AUR ({len(aur_missing)})…"
                    )
                    # AUR helpers cannot use sudo -S the same way; run as user
                    # and let helper call sudo itself if needed
                    try:
                        env = os.environ.copy()
                        if self.sudo_password:
                            # provide askpass helper
                            ask = Path.home() / ".cache" / "revo_sudo_askpass.sh"
                            ask.parent.mkdir(parents=True, exist_ok=True)
                            ask.write_text(
                                "#!/bin/sh\nprintf '%s\\n' "
                                + repr(self.sudo_password)[1:-1].replace("'", "'\\''")
                                + "\n"
                            )
                            # safer: write password without shell injection issues
                            ask.write_text(
                                "#!/bin/sh\n" + "printf '%s\\n' " +
                                "'" + self.sudo_password.replace("'", "'\\''") + "'\n"
                            )
                            ask.chmod(0o700)
                            env["SUDO_ASKPASS"] = str(ask)
                            env["SUDO_ASKPASS_REQUIRE"] = "force"
                        r = subprocess.run(
                            [aur_helper, "-S", "--noconfirm", "--needed", *aur_missing],
                            capture_output=True, text=True, timeout=3600, env=env,
                        )
                        if r.returncode != 0:
                            for p in aur_missing:
                                r2 = subprocess.run(
                                    [aur_helper, "-S", "--noconfirm", "--needed", p],
                                    capture_output=True, text=True, timeout=900, env=env,
                                )
                                if r2.returncode != 0:
                                    errors.append(f"aur:{p}")
                    except Exception as e:
                        errors.append(f"aur:{e}")
            else:
                errors.append("no AUR helper (yay/paru) for quickshell-git")

            # Critical apps even if batch install partially failed
            self.progress_changed.emit(36, "Checking rofi & kitty…")
            self._ensure_desktop_packages()

        elif any(x in dist for x in ("ubuntu", "debian", "pop", "zorin")) or shutil.which("apt-get"):
            try:
                env = os.environ.copy()
                env["DEBIAN_FRONTEND"] = "noninteractive"
                apt_pkgs = [
                    "hyprland", "xdg-desktop-portal-hyprland", "hypridle", "hyprlock",
                    "qt6-base-dev", "qt6-declarative-dev", "cmake", "ninja-build",
                    "pkg-config", "git", "curl", "jq", "python3", "python3-pip",
                    "libnotify-bin", "xdg-utils", "grim", "slurp", "wf-recorder",
                    "ffmpeg", "imagemagick", "wl-clipboard", "playerctl",
                    "pipewire", "wireplumber", "network-manager", "bluez",
                    "brightnessctl", "fonts-jetbrains-mono", "papirus-icon-theme",
                    "rofi", "kitty", "fish", "fastfetch",
                ]
                self._sudo_run(["apt-get", "update", "-y"], timeout=600)
                r = self._sudo_run(
                    ["apt-get", "install", "-y", *apt_pkgs], timeout=3600
                )
                if r.returncode != 0:
                    errors.append("apt partial failure (quickshell may need source build)")
            except Exception as e:
                errors.append(f"apt:{e}")

        elif "fedora" in dist:
            try:
                dnf_pkgs = [
                    "hyprland", "cmake", "ninja-build", "git", "curl", "jq",
                    "python3", "python3-pip", "libnotify", "xdg-utils",
                    "grim", "slurp", "ffmpeg", "wl-clipboard", "playerctl",
                    "pipewire", "wireplumber", "NetworkManager", "bluez",
                    "brightnessctl", "kitty", "fish",
                ]
                r = self._sudo_run(
                    ["dnf", "-y", "install", *dnf_pkgs], timeout=3600
                )
                if r.returncode != 0:
                    errors.append("dnf partial failure")
            except Exception as e:
                errors.append(f"dnf:{e}")

        # Python packages (user site — no root)
        try:
            self.progress_changed.emit(38, "pip install shell Python deps…")
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "--user", "--upgrade",
                 *self.config.PIP_PACKAGES],
                capture_output=True, text=True, timeout=1800,
            )
        except Exception as e:
            errors.append(f"pip:{e}")

        err_str = "; ".join(errors[:12])
        return (len(errors) == 0), err_str

    def _get_system_info(self) -> SystemInfo:
        """Get comprehensive system information"""
        try:
            # Get distribution info
            distro_data = distro.os_release_info()
            distribution = distro_data.get('NAME', 'Unknown')
            version = distro_data.get('VERSION_ID', 'Unknown')
            
            # Get CPU info
            cpu_freq = psutil.cpu_freq().current if psutil.cpu_freq() else 0
            
            # Get memory info
            memory = psutil.virtual_memory()
            
            # Get GPU info (basic)
            gpu_info = "Unknown"
            try:
                if platform.system() == 'Linux':
                    result = subprocess.run(['lspci'], capture_output=True, text=True)
                    if 'VGA' in result.stdout or '3D' in result.stdout:
                        gpu_info = "Integrated/Discrete GPU detected"
            except:
                pass
            
            return SystemInfo(
                distribution=distribution,
                version=version,
                architecture=platform.machine(),
                kernel=platform.release(),
                hostname=platform.node(),
                memory_gb=round(memory.total / (1024 ** 3), 2),
                cpu_cores=psutil.cpu_count(logical=False),
                cpu_model=cpu_freq,
                gpu_info=gpu_info
            )
        except Exception as e:
            logger.error(f"Error getting system info: {e}")
            return SystemInfo(
                distribution="Unknown",
                version="Unknown",
                architecture=platform.machine(),
                kernel=platform.release(),
                hostname=platform.node(),
                memory_gb=0,
                cpu_cores=0,
                cpu_model=0,
                gpu_info="Unknown"
            )

    def _pre_flight_check(self) -> bool:
        """Run pre-flight safety checks (never abort for soft requirements)."""
        checks = [
            ("Check distribution compatibility", self._check_distribution_compatibility),
            ("Check minimum memory", lambda: self.system_info.memory_gb >= 4),
            ("Check minimum CPU cores", lambda: (self.system_info.cpu_cores or 0) >= 2),
            ("Check kernel version", lambda: int(str(self.system_info.kernel).split('.')[0]) >= 5),
        ]

        failed_checks = []
        for check_name, check_func in checks:
            try:
                if not check_func():
                    failed_checks.append(check_name)
            except Exception as e:
                failed_checks.append(f"{check_name} (error: {e})")

        # Soft: log only — FORCE_FULL_INSTALL always continues.
        # Hard fail only if distro is completely unknown (no package manager path).
        if failed_checks:
            logger.warning(f"Pre-flight soft failures (continuing): {failed_checks}")
        return True

    def _safety_verification(self) -> bool:
        """Detect existing installs. With FORCE_FULL_INSTALL, return False
        (warn) so the caller continues with backup instead of aborting."""
        quickshell_path = Path.home() / ".config" / "quickshell"
        hyprland_path = Path.home() / ".config" / "hypr"
        existing = False
        if quickshell_path.exists() and any(quickshell_path.iterdir()):
            logger.warning(f"Quickshell already installed at {quickshell_path}")
            existing = True
        if hyprland_path.exists() and any(hyprland_path.iterdir()):
            logger.warning(f"Hyprland configs already installed at {hyprland_path}")
            existing = True
        return not existing

    def _create_backup(self) -> Dict:
        """Create a backup of existing configuration files"""
        try:
            backup_dir = Path(self.config.BACKUP_DIR)
            backup_dir.mkdir(parents=True, exist_ok=True)
            
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = backup_dir / f"dotfiles_backup_{timestamp}"
            backup_path.mkdir(parents=True, exist_ok=True)
            
            # Copy existing configs if they exist
            config_dirs = [
                Path.home() / ".config" / "quickshell",
                Path.home() / ".config" / "hypr",
                Path.home() / ".config" / "rofi",
                Path.home() / ".config" / "kitty",
            ]
            
            files_backed_up = 0
            for config_dir in config_dirs:
                if config_dir.exists():
                    dest_dir = backup_path / config_dir.relative_to(Path.home())
                    dest_dir.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copytree(config_dir, dest_dir, dirs_exist_ok=True)
                    files_backed_up += len(list(dest_dir.rglob("*")))
            
            return {
                'success': True,
                'path': str(backup_path),
                'files_backed_up': files_backed_up
            }
        except Exception as e:
            logger.error(f"Backup creation failed: {e}")
            return {
                'success': False,
                'path': '',
                'files_backed_up': 0
            }

    def _check_distribution_compatibility(self) -> bool:
        """Match NAME / pretty NAME / ID / ID_LIKE — not exact full name only."""
        if not self.system_info:
            return True
        fields = [
            self.system_info.distribution or "",
            distro.os_release_info().get("pretty_name", ""),
            distro.os_release_info().get("name", ""),
            distro.id() or "",
            distro.id_like() or "",
        ]
        blob = " ".join(fields).lower()
        needles = (
            "ubuntu", "debian", "fedora", "arch", "cachy", "manjaro",
            "pop", "zorin", "garuda", "endeavour", "artix", "arcolinux",
            "nixos", "unknown", "raspbian", "linuxmint", "elementary",
        )
        if any(n in blob for n in needles):
            return True
        # Unknown distro: still allow — install.sh / pacman path may fail later with logs
        logger.warning(f"Unknown distro fields={fields!r} — continuing anyway")
        return True

    def _clone_monorepo(self) -> Optional[Path]:
        """Clone monorepo into a staged dir. Reuses self._staged_repo if set.
        Offline fallback: monorepo sitting next to qs-gui-installer/ (local checkout)."""
        if self._staged_repo and self._staged_repo.is_dir() and (self._staged_repo / "hypr").is_dir():
            return self._staged_repo

        # Local monorepo checkout (this installer lives inside revo-shell/)
        local_root = Path(__file__).resolve().parent.parent
        if (local_root / "hypr").is_dir() and (local_root / "quickshell").is_dir():
            logger.info(f"Using local monorepo at {local_root}")
            self._staged_repo = local_root
            self._staged_is_local = True
            return local_root

        repo_dir = Path.home() / "revo_shell_repo"
        if repo_dir.exists():
            shutil.rmtree(repo_dir, ignore_errors=True)
        url = self.config.DOTFILES_REPO_URL
        if "USERNAME" in url or "yourusername" in url.lower():
            logger.error(f"DOTFILES_REPO_URL not configured: {url}")
            return None
        logger.info(f"Cloning monorepo from {url}")
        r = subprocess.run(
            ["git", "clone", "--depth", "1", url, str(repo_dir)],
            capture_output=True,
            text=True,
            timeout=600,
        )
        if r.returncode != 0 or not (repo_dir / "hypr").is_dir():
            logger.error(f"git clone failed rc={r.returncode}: {(r.stderr or r.stdout)[-500:]}")
            shutil.rmtree(repo_dir, ignore_errors=True)
            return None
        self._staged_repo = repo_dir
        self._staged_is_local = False
        return repo_dir

    @staticmethod
    def _copy_tree(src: Path, dest: Path) -> int:
        """Merge-copy directory tree. Never deletes files already in dest that are not in src."""
        if not src.is_dir():
            return 0
        dest.mkdir(parents=True, exist_ok=True)
        count = 0
        for item in src.rglob("*"):
            rel = item.relative_to(src)
            target = dest / rel
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            elif item.is_file():
                if target.exists() and target.is_dir():
                    continue
                # Do not overwrite: if destination file exists, keep user copy
                if target.exists():
                    backup = target.with_name(
                        target.name + ".backup." + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                    )
                    try:
                        shutil.move(str(target), str(backup))
                    except OSError:
                        pass
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(str(item), str(target))
                count += 1
                if target.suffix == ".sh":
                    try:
                        os.chmod(str(target), 0o755)
                    except OSError:
                        pass
        return count

    def _install_dotfiles(self) -> Dict:
        """Install wallpapers + monorepo root assets from staged monorepo."""
        try:
            repo_dir = self._staged_repo or self._clone_monorepo()
            if repo_dir is None:
                return {'success': False, 'files_installed': 0}

            files_installed = 0
            wp_src = repo_dir / "wallpapers"
            wp_dest = Path.home() / "Pictures" / "Wallpapers"
            files_installed += self._copy_tree(wp_src, wp_dest)

            for item in repo_dir.iterdir():
                if item.is_file() and item.suffix not in {'.md'} and not (Path.home() / item.name).exists():
                    try:
                        shutil.copy2(str(item), str(Path.home() / item.name))
                        files_installed += 1
                    except OSError:
                        pass

            return {'success': True, 'files_installed': files_installed}
        except Exception as e:
            logger.error(f"Dotfiles installation failed: {e}")
            return {'success': False, 'files_installed': 0}

    def _install_hyprland_configs(self) -> Dict:
        """Install full hypr/ tree from staged monorepo → ~/.config/hypr."""
        try:
            repo_dir = self._staged_repo or self._clone_monorepo()
            if repo_dir is None:
                return {'success': False, 'files_installed': 0}

            hypr_src = repo_dir / "hypr"
            if not hypr_src.is_dir():
                logger.error("monorepo has no hypr/ directory")
                return {'success': False, 'files_installed': 0}

            hyprland_dest = Path.home() / ".config" / "hypr"
            files_installed = self._copy_tree(hypr_src, hyprland_dest)
            return {'success': True, 'files_installed': files_installed}
        except Exception as e:
            logger.error(f"Hyprland configs installation failed: {e}")
            return {'success': False, 'files_installed': 0}

    def _install_quickshell(self, shell_id: str = None) -> Dict:
        """Install quickshell/ tree (or one shell folder) from staged monorepo."""
        try:
            repo_dir = self._staged_repo or self._clone_monorepo()
            if repo_dir is None:
                return {'success': False, 'files_installed': 0}

            qs_src_root = repo_dir / "quickshell"
            if not qs_src_root.is_dir():
                logger.error("monorepo has no quickshell/ directory")
                return {'success': False, 'files_installed': 0}

            quickshell_dest = Path.home() / ".config" / "quickshell"
            if shell_id:
                one = qs_src_root / shell_id
                if one.is_dir():
                    files_installed = self._copy_tree(one, quickshell_dest / shell_id)
                else:
                    files_installed = self._copy_tree(qs_src_root, quickshell_dest)
            else:
                files_installed = self._copy_tree(qs_src_root, quickshell_dest)

            for script_path in quickshell_dest.rglob("*"):
                if script_path.is_file() and script_path.suffix in {".sh", ".fish"} or script_path.name in {"instalar", "install.sh"}:
                    try:
                        os.chmod(str(script_path), 0o755)
                    except OSError:
                        pass

            # Repair absolute guide symlink → current home
            guide = quickshell_dest / "guide"
            target = Path.home() / ".config" / "hypr" / "scripts" / "quickshell" / "guide"
            try:
                if guide.is_symlink() or not guide.exists():
                    if guide.is_symlink():
                        guide.unlink()
                    if target.exists():
                        guide.symlink_to(target)
            except OSError as e:
                logger.warning(f"guide symlink repair: {e}")

            return {'success': True, 'files_installed': files_installed}
        except Exception as e:
            logger.error(f"Quickshell installation failed: {e}")
            return {'success': False, 'files_installed': 0}

    def _install_desktop_configs(self) -> Dict:
        """Deploy monorepo rofi/ and kitty/ → ~/.config/{rofi,kitty}.
        Also ensure the packages themselves are present (install if missing)."""
        try:
            repo_dir = self._staged_repo or self._clone_monorepo()
            if repo_dir is None:
                return {'success': False, 'files_installed': 0}

            files_installed = 0
            pairs = [
                (repo_dir / "rofi", Path.home() / ".config" / "rofi"),
                (repo_dir / "kitty", Path.home() / ".config" / "kitty"),
            ]
            for src, dest in pairs:
                if src.is_dir():
                    files_installed += self._copy_tree(src, dest)
                    logger.info(f"Deployed {src.name} → {dest} ({files_installed} total)")

            self._ensure_desktop_packages()
            return {'success': True, 'files_installed': files_installed}
        except Exception as e:
            logger.error(f"Desktop configs (rofi/kitty) install failed: {e}")
            return {'success': False, 'files_installed': 0}

    def _ensure_desktop_packages(self) -> None:
        """Install rofi + kitty if the user does not already have them."""
        need_rofi = shutil.which("rofi") is None
        need_kitty = shutil.which("kitty") is None
        if not need_rofi and not need_kitty:
            logger.info("rofi + kitty already present — skip package install")
            return

        dist = (self.system_info.distribution if self.system_info else "").lower()
        self.progress_changed.emit(77, "Ensuring rofi & kitty packages…")
        try:
            if any(x in dist for x in ("arch", "cachy", "manjaro", "garuda", "endeavour", "artix")) or shutil.which("pacman"):
                want = []
                if need_rofi:
                    # prefer rofi-wayland on Arch, fall back to rofi
                    want.append("rofi-wayland")
                if need_kitty:
                    want.append("kitty")
                if want:
                    r = self._sudo_run(
                        ["pacman", "-S", "--noconfirm", "--needed", *want],
                        timeout=900,
                    )
                    if r.returncode != 0 and need_rofi:
                        self._sudo_run(
                            ["pacman", "-S", "--noconfirm", "--needed", "rofi"],
                            timeout=600,
                        )
            elif shutil.which("apt-get"):
                want = []
                if need_rofi:
                    want.append("rofi")
                if need_kitty:
                    want.append("kitty")
                if want:
                    self._sudo_run(
                        ["apt-get", "install", "-y", *want],
                        timeout=900,
                    )
            elif shutil.which("dnf"):
                want = []
                if need_kitty:
                    want.append("kitty")
                if want:
                    self._sudo_run(["dnf", "-y", "install", *want], timeout=900)
                if need_rofi:
                    logger.warning("rofi not always in dnf repos — install manually if missing")
        except Exception as e:
            logger.warning(f"ensure rofi/kitty packages: {e}")

        logger.info(
            f"after ensure: rofi={'yes' if shutil.which('rofi') else 'NO'} "
            f"kitty={'yes' if shutil.which('kitty') else 'NO'}"
        )

    def _fix_home_paths(self) -> None:
        """Rewrite hardcoded /home/revo → current $HOME in deployed configs."""
        home = str(Path.home())
        roots = [
            Path.home() / ".config" / "hypr",
            Path.home() / ".config" / "quickshell",
            Path.home() / ".config" / "rofi",
            Path.home() / ".config" / "kitty",
        ]
        text_exts = {".conf", ".lua", ".json", ".sh", ".qml", ".py", ".js", ".ts", ".md", ".ini"}
        changed = 0
        for root in roots:
            if not root.is_dir():
                continue
            for p in root.rglob("*"):
                if not p.is_file() or p.suffix.lower() not in text_exts:
                    continue
                if p.is_symlink():
                    continue
                try:
                    data = p.read_text(errors="ignore")
                except Exception:
                    continue
                if "/home/revo/" not in data:
                    continue
                new = data.replace("/home/revo/", home + "/")
                if new != data:
                    try:
                        p.write_text(new)
                        changed += 1
                    except OSError:
                        pass
        logger.info(f"Rewrote /home/revo paths in {changed} files")

    def _install_python_packages(self) -> None:
        """pip --user for shell extras + any requirements.txt in monorepo."""
        reqs = []
        if self._staged_repo:
            for req in [
                self._staged_repo / "qs-gui-installer" / "requirements.txt",
                self._staged_repo / "quickshell" / "Q1" / "scripts" / "aikira" / "requirements.txt",
            ]:
                if req.is_file():
                    reqs.append(str(req))
        for req in reqs:
            try:
                subprocess.run(
                    [sys.executable, "-m", "pip", "install", "--user", "-r", req],
                    capture_output=True, text=True, timeout=1800,
                )
            except Exception as e:
                logger.warning(f"pip -r {req}: {e}")
        # nibrasshell optional (heavy) — best effort
        nib = None
        if self._staged_repo:
            nib = self._staged_repo / "quickshell" / "nibrasshell" / "scripts" / "python" / "requirements-3.13.txt"
        if nib and nib.is_file():
            try:
                subprocess.run(
                    [sys.executable, "-m", "pip", "install", "--user", "-r", str(nib)],
                    capture_output=True, text=True, timeout=1800,
                )
            except Exception as e:
                logger.warning(f"nibrasshell pip: {e}")

    def _build_native_shells(self) -> None:
        """Configure+build CMake shells (caelestia + Clavis). Best effort."""
        qs = Path.home() / ".config" / "quickshell"
        builds = [
            # (src, extra cmake args)
            (qs / "shell", ["-DVERSION=1.0.0", "-DGIT_REVISION=local",
                            "-DENABLE_MODULES=extras;plugin;shell"]),
            (qs / "imported-1789667132", []),
        ]
        for src, extra in builds:
            if self.is_cancelled:
                return
            if not (src / "CMakeLists.txt").is_file():
                continue
            build = src / "build"
            try:
                self.progress_changed.emit(
                    91, f"Building {src.name}…"
                )
                conf = ["cmake", "-S", str(src), "-B", str(build),
                        "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release", *extra]
                r = subprocess.run(conf, capture_output=True, text=True, timeout=600)
                if r.returncode != 0:
                    logger.warning(f"cmake configure {src.name}: {r.stderr[-400:]}")
                    continue
                r = subprocess.run(
                    ["cmake", "--build", str(build), "-j", str(os.cpu_count() or 4)],
                    capture_output=True, text=True, timeout=3600,
                )
                if r.returncode != 0:
                    logger.warning(f"cmake build {src.name}: {r.stderr[-400:]}")
                else:
                    # install if root possible
                    try:
                        self._sudo_run(
                            ["cmake", "--install", str(build)], timeout=600
                        )
                    except Exception:
                        pass
            except Exception as e:
                logger.warning(f"build {src.name}: {e}")

    def _enable_services(self) -> None:
        """Enable user + system services shells depend on."""
        user_units = [
            "pipewire.service", "pipewire-pulse.service", "wireplumber.service",
            "playerctld.service",
        ]
        for u in user_units:
            try:
                subprocess.run(
                    ["systemctl", "--user", "enable", "--now", u],
                    capture_output=True, text=True, timeout=30,
                )
            except Exception:
                pass
        system_units = ["NetworkManager.service", "bluetooth.service", "upower.service"]
        for u in system_units:
            try:
                self._sudo_run(["systemctl", "enable", "--now", u], timeout=60)
            except Exception as e:
                logger.warning(f"systemctl {u}: {e}")

    def _get_available_shells(self) -> List[ShellInfo]:
        """Get available shell builds (mock implementation)"""
        return [
            ShellInfo(
                id="quickshell-default",
                name="Quickshell Default",
                description="Clean, minimal Quickshell implementation",
                repo_url="https://github.com/yourusername/quickshell-default",
                icon_path="qrc:/icons/quickshell-default.png",
                preview_path="qrc:/previews/quickshell-default.png",
                theme_color=QColor(59, 130, 246),
                build_type="stable",
                dependencies=[]
            ),
            ShellInfo(
                id="quickshell-minimal",
                name="Quickshell Minimal",
                description="Ultra-minimal Quickshell build",
                repo_url="https://github.com/yourusername/quickshell-minimal",
                icon_path="qrc:/icons/quickshell-minimal.png",
                preview_path="qrc:/previews/quickshell-minimal.png",
                theme_color=QColor(153, 153, 153),
                build_type="experimental",
                dependencies=[]
            ),
            ShellInfo(
                id="quickshell-dark",
                name="Quickshell Dark",
                description="Dark theme Quickshell",
                repo_url="https://github.com/yourusername/quickshell-dark",
                icon_path="qrc:/icons/quickshell-dark.png",
                preview_path="qrc:/previews/quickshell-dark.png",
                theme_color=QColor(34, 34, 34),
                build_type="stable",
                dependencies=[]
            )
        ]

    def _finalize_installation(self):
        """Final cleanup and setup after installation"""
        # Remove backup if auto-backup is enabled
        if self.config.AUTO_BACKUP_ENABLED:
            backup_dir = Path(self.config.BACKUP_DIR)
            if backup_dir.exists():
                shutil.rmtree(backup_dir)
        
        # Set permissions on installed files
        config_dirs = [Path.home() / ".config" / "quickshell", Path.home() / ".config" / "hypr"]
        for config_dir in config_dirs:
            if config_dir.exists():
                for file_path in config_dir.rglob("*"):
                    if file_path.is_file() and file_path.suffix in ['.conf', '.lua', '.sh']:
                        file_path.chmod(0o644 if file_path.suffix in ['.conf', '.lua'] else 0o755)

    def cancel(self):
        """Cancel the installation process"""
        self.is_cancelled = True


# QML-only window (black/white installer)
if TRY_QT:
    class MainWindow(QMainWindow):
        def __init__(self):
            super().__init__()
            self.config = InstallerConfig()
            self.installation_worker = InstallationWorker()
            self.current_shell_id = None
            self.installation_thread = None

            self.setWindowTitle("Revo Shell Installer")
            self.resize(1280, 800)
            self.setStyleSheet("QMainWindow { background-color: #000000; }")

            self.design_view = QQuickWidget()
            self.design_view.setResizeMode(QQuickWidget.SizeRootObjectToView)
            qml_path = Path(__file__).resolve().parent / "qml" / "MainView.qml"
            self.design_view.setSource(QUrl.fromLocalFile(str(qml_path)))
            if self.design_view.status() == QQuickWidget.Error:
                for err in self.design_view.errors():
                    logger.warning(f"QML error: {err.toString()}")

            self.setCentralWidget(self.design_view)
            self._wire_qml_hooks()

            self.installation_worker.progress_changed.connect(self._on_progress_changed)
            self.installation_worker.installation_result.connect(self._on_installation_result)
            self.installation_worker.system_info_ready.connect(self._on_system_info_ready)

        def _scan_local_shells(self) -> List[Dict]:
            """Scan ~/.config/quickshell for ready shell folders"""
            qs_path = Path.home() / ".config" / "quickshell"
            shells: List[Dict] = []
            if not qs_path.is_dir():
                return shells
            for entry in sorted(qs_path.iterdir(), key=lambda p: p.name.lower()):
                if not entry.is_dir() or entry.name.startswith("."):
                    continue
                if entry.name in ("previews", "guide", "modules"):
                    continue
                display = entry.name.replace("-", " ").replace("_", " ").title()
                shells.append({
                    "id": entry.name,
                    "name": display,
                    "path": str(entry),
                    "icon": entry.name[:2].upper(),
                    "available": True,
                })
            return shells

        def _wire_qml_hooks(self):
            """Push shells + backend hooks into MainView.qml"""
            view = getattr(self, "design_view", None)
            if view is None or view.status() == QQuickWidget.Error:
                return
            root = view.rootObject()
            if root is None:
                return
            try:
                shells = self._scan_local_shells()
                root.setShells(shells)
                logger.info(f"QML setShells: {len(shells)} shells")
            except Exception as e:
                logger.warning(f"setShells failed: {e}")
            try:
                root.setProperty("installBackend", self._on_qml_install_requested)
                root.setProperty("rebootHost", self._on_qml_reboot_requested)
                root.setProperty("shellScanner", self._on_qml_rescan_shells)
                root.setProperty("filesChecker", self._check_local_files)
                root.setProperty("installProgress", 0)
                root.setProperty("installStatus", "")
                root.setProperty("installRunning", False)
                root.setProperty("installCompleted", False)
                root.setProperty("installFailed", False)
                root.setProperty("installLogLine", "")
            except Exception as e:
                logger.warning(f"Could not set QML hooks: {e}")

        def _check_local_files(self) -> Dict:
            """Local config files present → skip download (anti-overwrite).
            Missing → download/load from GitHub."""
            qs = Path.home() / ".config" / "quickshell"
            hy = Path.home() / ".config" / "hypr"
            paths = []
            if qs.is_dir() and any(qs.iterdir()):
                paths.append(str(qs))
            if hy.is_dir() and any(hy.iterdir()):
                paths.append(str(hy))
            exists = len(paths) > 0
            logger.info(f"Local files check: exists={exists} paths={paths}")
            return {"exists": exists, "found": exists, "paths": paths, "count": len(paths)}

        def _on_qml_install_requested(self, password: str):
            logger.info(f"QML install requested (password length={len(password or '')})")
            # Always run full install from GUI (packages + build + deploy).
            # Existing configs are backed up per-file; no skip.
            if self.installation_thread and self.installation_thread.isRunning():
                return
            self.installation_worker.sudo_password = password or ""
            self.installation_thread = QThread()
            self.installation_worker.moveToThread(self.installation_thread)
            shell_id = self.current_shell_id
            self.installation_thread.started.connect(
                lambda: self.installation_worker.run_installation(shell_id, password or "")
            )
            self.installation_thread.finished.connect(self.installation_thread.deleteLater)
            self.installation_thread.start()

        def _on_qml_reboot_requested(self):
            logger.info("QML reboot requested")
            try:
                subprocess.Popen(
                    ["sudo", "reboot"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except Exception as e:
                logger.warning(f"Reboot failed: {e}")

        def _on_qml_rescan_shells(self):
            try:
                root = self.design_view.rootObject() if hasattr(self, "design_view") else None
                if root is not None:
                    root.setShells(self._scan_local_shells())
            except Exception as e:
                logger.warning(f"Rescan shells failed: {e}")

        def _push_install_progress(self, value: int, message: str):
            """Push real backend progress into Stage4 via MainView properties."""
            try:
                root = self.design_view.rootObject() if hasattr(self, "design_view") else None
                if root is None:
                    return
                root.setProperty("installProgress", value)
                root.setProperty("installStatus", message)
                root.setProperty("installRunning", True)
            except Exception as e:
                logger.debug(f"progress push: {e}")

        def _on_progress_changed(self, value: int, message: str):
            logger.info(f"Install progress {value}%: {message}")
            self._push_install_progress(value, message)

        def _on_installation_result(self, result: InstallationResult):
            try:
                root = self.design_view.rootObject() if hasattr(self, "design_view") else None
                if root is not None:
                    root.setProperty("installRunning", False)
                    root.setProperty("installCompleted", bool(result.success))
                    root.setProperty("installFailed", not result.success)
                    if result.success:
                        root.setProperty("installProgress", 100)
                        root.setProperty(
                            "installStatus",
                            f"Done — {result.files_installed} files installed"
                        )
                    else:
                        root.setProperty(
                            "installStatus",
                            result.message or "Installation failed"
                        )
                        for err in result.errors[:5]:
                            try:
                                root.setProperty("installLogLine", "$ error: " + str(err))
                            except Exception:
                                pass
            except Exception as e:
                logger.debug(f"result push: {e}")

            if result.success:
                logger.info(
                    f"Installation OK: {result.files_installed} files, backup={result.backup_created}"
                )
            else:
                logger.error(f"Installation failed: {result.message} | {result.errors}")

        def _on_system_info_ready(self, system_info: SystemInfo):
            logger.info(
                f"System: {system_info.distribution} {system_info.version} "
                f"({system_info.architecture})"
            )

        def closeEvent(self, event):
            if self.installation_thread and self.installation_thread.isRunning():
                self.installation_worker.cancel()
                self.installation_thread.quit()
                self.installation_thread.wait(2000)
            event.accept()

# Main Application Entry Point
if __name__ == "__main__":
    # Create application
    app = None
    if TRY_QT:
        app = QApplication(sys.argv)
        
        # Set application properties
        app.setApplicationName("Revo Shell Installer")
        app.setApplicationVersion(InstallerConfig.INSTALLER_VERSION)
        app.setOrganizationName("Revo")
    else:
        # Mock application for demo
        class MockApp:
            def exec(self):
                return 0
        app = MockApp()
    
    # Initialize demo installation worker
    worker = InstallationWorker()
    
    # Demo mode: run installation synchronously if no Qt available
    if not TRY_QT:
        result = worker.run_installation()
        if hasattr(result, 'wait'):
            result.wait()
        sys.exit(0)
    
    # Create and show main window (fullscreen)
    window = MainWindow()
    window.showFullScreen()

    # Start event loop
    sys.exit(app.exec())
