#!/usr/bin/env python3
"""Build the macOS-shell Dock from the apps installed on THIS machine.

Writes ~/.config/revo-shell/dock.json, which services/DockApps.qml reads
(and rewrites when you pin / unpin / reorder in the Dock).

  dock_setup.py --auto          pick sensible apps automatically (no prompt)
  dock_setup.py --choose        interactive picker (fzf if installed, else a numbered list)
  dock_setup.py --list          print the installed apps that can go in the Dock
  dock_setup.py --keep          do nothing if a dock.json already exists (used by the installers)

Finder (your file manager), Launchpad, Terminal and System Settings are
always added when available; the rest is up to you.
"""
import argparse
import configparser
import glob
import json
import os
import re
import shlex
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
OUT = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.join(HOME, ".config")), "revo-shell", "dock.json")
HERE = os.path.dirname(os.path.abspath(__file__))
ICON_SCRIPT = os.path.join(HERE, "dock_icon.sh")
ICON_BASE = os.path.realpath(os.path.join(HERE, "..", "assets", "icons"))
QS_DIR = os.path.realpath(os.path.join(HERE, ".."))

# auto mode: first installed match of each group, in this order (desktop ids /
# binaries, lowercase). Keeps the Dock short, like a fresh Mac.
AUTO_GROUPS = [
    ["zen", "io.github.zen_browser.zen", "firefox", "librewolf", "brave-browser", "brave",
     "google-chrome", "chromium", "vivaldi-stable", "org.gnome.epiphany", "pafari", "org.gnome.pafari"],
    ["org.mozilla.thunderbird", "thunderbird", "org.gnome.geary", "geary", "evolution"],
    ["org.telegram.desktop", "telegram-desktop", "telegramdesktop"],
    ["dev.vencord.vesktop", "vesktop", "discord", "com.discordapp.discord", "webcord"],
    ["com.github.eneshecan.whatsie", "whatsie", "signal-desktop", "org.signal.signal"],
    ["spotify", "com.spotify.client", "org.gnome.rhythmbox3", "rhythmbox", "elisa", "org.kde.elisa"],
    ["org.gnome.loupe", "loupe", "org.kde.gwenview", "gwenview", "eog", "org.gnome.eog"],
    ["org.gnome.calendar", "gnome-calendar"],
    ["steam", "com.valvesoftware.steam"],
    ["code-oss", "code", "com.visualstudio.code", "codium", "com.vscodium.codium", "dev.zed.zed", "zed"],
]
FILE_MANAGERS = ["org.gnome.nautilus", "nautilus", "org.kde.dolphin", "dolphin", "thunar",
                 "nemo", "pcmanfm", "pcmanfm-qt", "org.gnome.files"]
TERMINALS = ["kitty", "org.wezfurlong.wezterm", "alacritty", "foot", "org.kde.konsole", "konsole",
             "org.gnome.console", "org.gnome.terminal", "com.mitchellh.ghostty", "ghostty", "xfce4-terminal"]
# never offered: the shell's own surfaces and helper entries
HIDDEN = {"macos-launcher", "systemsettings", "atoll"}


def desktop_dirs():
    data_home = os.environ.get("XDG_DATA_HOME", os.path.join(HOME, ".local", "share"))
    dirs = [data_home] + os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    dirs += [os.path.join(data_home, "flatpak", "exports", "share"), "/var/lib/flatpak/exports/share"]
    seen, out = set(), []
    for d in dirs:
        a = os.path.join(d, "applications")
        if a not in seen and os.path.isdir(a):
            seen.add(a)
            out.append(a)
    return out


def clean_exec(cmd):
    # strip desktop-entry field codes (%f %U ...) and quote-safe join
    try:
        parts = shlex.split(cmd)
    except ValueError:
        parts = cmd.split()
    out = []
    for p in parts:
        q = re.sub(r"%[fFuUdDnNickvm]", "", p).replace("%%", "%")
        if q and not q.endswith("="):
            out.append(q)
    parts = out
    return " ".join(shlex.quote(p) if any(c in p for c in " \"'$`\\") else p for p in parts)


def scan_apps():
    apps, seen = [], set()
    for d in desktop_dirs():                       # earlier dirs win (user overrides)
        for path in sorted(glob.glob(os.path.join(d, "**", "*.desktop"), recursive=True)):
            did = os.path.relpath(path, d)[:-8].replace("/", "-")
            if did in seen:
                continue
            seen.add(did)
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(path, encoding="utf-8")
            except Exception:
                continue
            if "Desktop Entry" not in cp:
                continue
            e = cp["Desktop Entry"]
            if e.get("Type", "Application") != "Application" or not e.get("Exec"):
                continue
            if e.get("NoDisplay", "false").lower() == "true" or e.get("Hidden", "false").lower() == "true":
                continue
            desk = os.environ.get("XDG_CURRENT_DESKTOP", "Hyprland")
            only = e.get("OnlyShowIn", "")
            if only and not any(x in only.split(";") for x in desk.split(":")):
                continue
            tryexec = e.get("TryExec")
            if tryexec and not (shutil.which(tryexec) or os.path.exists(os.path.expanduser(tryexec))):
                continue
            if did.lower() in HIDDEN:
                continue
            exe = clean_exec(e["Exec"])
            binary = os.path.basename(shlex.split(exe)[0]) if exe else ""
            ids = [did]
            wm = e.get("StartupWMClass")
            for x in (wm, binary, did.split(".")[-1]):
                if x and x not in ids:
                    ids.append(x)
            apps.append({"name": e.get("Name", did), "desktop": did, "exec": exe,
                         "appIds": ids, "themeIcon": e.get("Icon", ""),
                         "categories": e.get("Categories", "")})
    apps.sort(key=lambda a: a["name"].lower())
    return apps


def icon_for(app):
    """Mac-style icon from the shell's icon set, else the app's theme icon."""
    path = ""
    for cand in [app["desktop"]] + app["appIds"][1:] + ([app["themeIcon"]] if app["themeIcon"] else []):
        try:
            path = subprocess.run(["bash", ICON_SCRIPT, cand], capture_output=True, text=True,
                                  timeout=5).stdout.strip().splitlines()[0]
        except Exception:
            path = ""
        if path and os.path.isfile(path):
            break
        path = ""
    if not path and app["themeIcon"].startswith("/") and os.path.isfile(app["themeIcon"]):
        path = app["themeIcon"]
    if not path:
        return "Placeholder.png"
    real = os.path.realpath(path)
    if real.startswith(ICON_BASE + os.sep):
        return os.path.relpath(real, ICON_BASE)       # resolved against the shell's icons dir
    return "file://" + real


def find(apps, keys):
    # desktop ids first, then window classes / binaries (so a game whose
    # launcher runs `steam` is never mistaken for Steam itself)
    by_id, by_alias = {}, {}
    for a in apps:
        by_id.setdefault(a["desktop"].lower(), a)
        for k in a["appIds"][1:]:
            by_alias.setdefault(k.lower(), a)
    for k in keys:
        if k in by_id:
            return by_id[k]
    for k in keys:
        if k in by_alias:
            return by_alias[k]
    return None


def entry(app):
    return {"name": app["name"], "icon": icon_for(app), "desktop": app["desktop"],
            "exec": app["exec"], "appIds": app["appIds"]}


def system_items(apps):
    """Finder, Launchpad first; Terminal and System Settings last (macOS order)."""
    head, tail = [], []
    fm = find(apps, FILE_MANAGERS)
    if fm:
        e = entry(fm); e["name"] = "Finder"; e["icon"] = "Finder.png"
        head.append(e)
    head.append({"name": "Launchpad", "icon": "Apps.png", "desktop": "macos-launcher",
                 "exec": "qs ipc -p " + shlex.quote(QS_DIR) + " call launchpad toggle",
                 "appIds": ["macos-launcher", "Launcher"]})
    term = find(apps, TERMINALS)
    if term:
        e = entry(term); e["name"] = "Terminal"; e["icon"] = "Terminal.png"
        tail.append(e)
    if os.path.exists(os.path.join(HOME, ".local", "bin", "systemsettings")) or shutil.which("systemsettings"):
        tail.append({"name": "System Settings", "icon": "System Settings.png", "desktop": "systemsettings",
                     "exec": "$HOME/.local/bin/systemsettings",
                     "appIds": ["systemsettings", "macos-settings", "pearos-settings", "pearos-settings-app"]})
    used = {fm["desktop"] if fm else None, term["desktop"] if term else None}
    return head, tail, used


def auto_pick(apps, used):
    out = []
    for group in AUTO_GROUPS:
        a = find(apps, group)
        if a and a["desktop"] not in used:
            used.add(a["desktop"])
            out.append(a)
    return out


def choose(apps, preselected):
    pre = {a["desktop"] for a in preselected}
    if shutil.which("fzf") and sys.stdin.isatty():
        lines = [f"{a['name']}\t{a['desktop']}" for a in apps]
        hdr = ("Pick the apps for your Dock (TAB = select, ENTER = done). "
               "Empty selection keeps the suggested apps.")
        r = subprocess.run(["fzf", "--multi", "--with-nth=1", "--delimiter=\t", "--header", hdr,
                            "--prompt", "Dock apps> ", "--height", "70%", "--reverse"],
                           input="\n".join(lines), capture_output=True, text=True)
        picked = [l.split("\t")[1] for l in r.stdout.splitlines() if "\t" in l]
        if not picked:
            return preselected
        return [a for a in apps if a["desktop"] in picked]
    print("\nApps installed on this computer (* = suggested):\n")
    for i, a in enumerate(apps, 1):
        print(f"  {'*' if a['desktop'] in pre else ' '} {i:3}. {a['name']}")
    print("\nType the numbers of the apps you want in the Dock (e.g. 3,7,12),")
    ans = input("or press ENTER to keep the suggested (*) apps: ").strip()
    if not ans:
        return preselected
    picked = []
    for tok in ans.replace(" ", ",").split(","):
        if tok.isdigit() and 1 <= int(tok) <= len(apps):
            a = apps[int(tok) - 1]
            if a not in picked:
                picked.append(a)
    return picked or preselected


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--auto", action="store_true")
    g.add_argument("--choose", action="store_true")
    g.add_argument("--list", action="store_true")
    ap.add_argument("--keep", action="store_true", help="leave an existing dock.json alone")
    a = ap.parse_args()

    if a.keep and os.path.exists(OUT):
        print(f"dock: keeping {OUT}")
        return
    apps = scan_apps()
    if a.list:
        for x in apps:
            print(f"{x['name']}\t{x['desktop']}")
        return
    head, tail, used = system_items(apps)
    suggested = auto_pick(apps, used)
    if a.choose:
        pool = [x for x in apps if x["desktop"] not in used]
        middle = choose(pool, suggested)
    else:
        middle = suggested
    pinned = head + [entry(x) for x in middle] + tail
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        json.dump({"version": 1, "pinned": pinned}, f, indent=2)
    os.replace(tmp, OUT)
    print(f"dock: {len(pinned)} apps → {OUT}")
    for p in pinned:
        print("  -", p["name"])


if __name__ == "__main__":
    main()
