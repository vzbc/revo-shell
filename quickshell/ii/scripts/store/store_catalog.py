#!/usr/bin/env python3
"""
Waffle Store catalog generator.

Builds local app catalogs for the Windows-11 style store:
  - Flathub (parsed from the local appstream database)
  - Arch repositories (parsed with expac from the pacman sync db)
  - AUR (queried on demand from the AUR RPC)

Usage:
  store_catalog.py catalog --cache-dir DIR     # writes flathub.json, arch.json, library.json
  store_catalog.py search-aur "query"          # prints JSON search results to stdout
  store_catalog.py aur-info "name"             # prints JSON detail for one AUR package
"""

import argparse
import gzip
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

APPSTREAM = "/var/lib/flatpak/appstream/flathub/x86_64/active/appstream.xml.gz"
FLATPAK_APPS_DIR = "/var/lib/flatpak/app"
DESKTOP_DIR = "/usr/share/applications"

ICON_BASES = [
    "/usr/share/icons/hicolor/256x256/apps",
    "/usr/share/icons/hicolor/128x128/apps",
    "/usr/share/icons/hicolor/64x64/apps",
    "/usr/share/icons/hicolor/48x48/apps",
    "/usr/share/icons/hicolor/scalable/apps",
    "/usr/share/icons/Adwaita/256x256/apps",
    "/usr/share/icons/Adwaita/512x512/apps",
    "/usr/share/icons/breeze/apps/48",
    "/usr/share/icons/Papirus/64x64/apps",
    "/usr/share/icons/gnome/256x256/apps",
    "/usr/share/icons/MacTahoe/apps/scalable",
    "/usr/share/icons/MacTahoe/apps/48",
    "/usr/share/icons/MacTahoe/apps/24",
    "/usr/share/icons/Tela-dark/scalable/apps",
]

AUR_RPC = "https://aur.archlinux.org/rpc"


def resolve_icon(name):
    """Resolve a bare icon name to an absolute path (or return as-is)."""
    if not name:
        return ""
    if os.path.sep in name or name.startswith("/"):
        return name
    for base in ICON_BASES:
        for ext in ("png", "svg", "svgz"):
            path = os.path.join(base, name + "." + ext)
            if os.path.isfile(path):
                return path
    return name


def run(cmd, timeout=120):
    """Run a command, return (exit_code, stdout_text)."""
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return proc.returncode, proc.stdout
    except Exception as e:  # noqa: BLE001
        return 1, str(e)


# ---------------------------------------------------------------- flathub --
def parse_flathub():
    apps = []
    installed = set()
    try:
        for entry in os.listdir(FLATPAK_APPS_DIR):
            if os.path.isdir(os.path.join(FLATPAK_APPS_DIR, entry, "active")):
                installed.add(entry)
    except OSError:
        pass

    icons_dir = os.path.join(os.path.dirname(APPSTREAM), "icons", "128x128")
    try:
        with gzip.open(APPSTREAM, "rt", encoding="utf-8") as fh:
            data = fh.read()
    except OSError:
        return apps

    root = ET.fromstring(data)
    for comp in root.findall("component"):
        if comp.get("type") not in ("desktop-application", "console-application"):
            continue
        cid = comp.findtext("id") or ""
        if not cid:
            continue

        name = comp.findtext("name") or cid
        summary = comp.findtext("summary") or ""
        project_license = comp.findtext("project_license") or ""

        desc_parts = []
        for p in comp.findall("description/p") or []:
            desc_parts.append(p.text or "")
        desc = "\n".join(desc_parts).strip()
        if not desc and comp.find("description") is not None:
            desc = (comp.find("description").text or "").strip()

        icon = ""
        icon_file = os.path.join(icons_dir, f"{cid}.png")
        if os.path.isfile(icon_file):
            icon = icon_file

        screenshots = []
        for img in comp.findall("screenshots/screenshot/image"):
            if img.get("type") == "source":
                screenshots.append(img.text or "")
        screenshots = screenshots[:5]

        categories = [c.text for c in comp.findall("categories/category") if c.text]
        developer = comp.findtext("developer_name") or ""
        last_release = ""
        release = comp.find("releases/release")
        if release is not None and release.get("date"):
            last_release = release.get("date")

        is_free = not (project_license or "").startswith("LicenseRef")

        apps.append({
            "source": "flathub",
            "id": cid,
            "name": name,
            "summary": summary,
            "description": desc,
            "icon": icon,
            "screenshots": screenshots,
            "categories": categories[:4],
            "developer": developer,
            "license": project_license,
            "last_release": last_release,
            "installed": cid in installed,
        })
    return apps


# ------------------------------------------------------------------- arch --
def parse_desktop_icons():
    """Map package name -> (icon, category, has_desktop) for installed .desktop entries."""
    mapping = {}
    if not os.path.isdir(DESKTOP_DIR):
        return mapping
    try:
        for fname in os.listdir(DESKTOP_DIR):
            if not fname.endswith(".desktop"):
                continue
            pkg = fname[:-len(".desktop")]
            icon = ""
            category = ""
            try:
                with open(os.path.join(DESKTOP_DIR, fname), encoding="utf-8", errors="replace") as fh:
                    for line in fh:
                        line = line.strip()
                        if line.startswith("Icon="):
                            icon = line[5:].strip()
                        elif line.startswith("Categories="):
                            category = line[11:].strip().split(";")[0] if line[11:].strip() else ""
            except OSError:
                continue
            mapping[pkg] = {"icon": icon, "category": category, "desktop": True}
    except OSError:
        pass
    return mapping


def parse_arch():
    _, out = run(["expac", "-S", "%n|%v|%d|%r"])
    installed = set()
    _, qout = run(["pacman", "-Qq"])
    for line in qout.splitlines():
        installed.add(line.strip())

    desktop_map = parse_desktop_icons()

    apps = []
    for line in out.splitlines():
        parts = line.split("|", 3)
        if len(parts) < 4:
            continue
        name, version, desc, repo = parts
        meta = desktop_map.get(name, {})
        apps.append({
            "source": "arch",
            "id": name,
            "name": name,
            "summary": desc,
            "description": "",
            "icon": resolve_icon(meta.get("icon", "")),
            "category": meta.get("category", ""),
            "desktop": meta.get("desktop", False),
            "version": version,
            "repo": repo,
            "installed": name in installed,
        })
    return apps


# ------------------------------------------------------------------- AUR --
def _aur_rpc(params):
    url = f"{AUR_RPC}/?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:  # noqa: BLE001
        return None


def search_aur(query):
    installed = set()
    _, qout = run(["pacman", "-Qq"])
    for line in qout.splitlines():
        installed.add(line.strip())

    data = _aur_rpc({"v": "5", "type": "search", "arg": query, "by": "name-desc"})
    if not data or not data.get("results"):
        return []

    results = []
    for item in data["results"][:60]:
        results.append({
            "source": "aur",
            "id": item.get("Name", ""),
            "name": item.get("Name", ""),
            "summary": item.get("Description", ""),
            "version": item.get("Version", ""),
            "votes": item.get("NumVotes", 0),
            "popularity": item.get("Popularity", 0.0),
            "maintainer": item.get("Maintainer", ""),
            "license": item.get("License", [""])[0] if isinstance(item.get("License"), list) else "",
            "out_of_date": item.get("OutOfDate") is not None,
            "installed": item.get("Name") in installed,
        })
    return results


def aur_info(name):
    data = _aur_rpc({"v": "5", "type": "info", "arg[]": name})
    if not data or not data.get("results"):
        return None
    item = data["results"][0]
    return {
        "source": "aur",
        "id": item.get("Name", ""),
        "name": item.get("Name", ""),
        "summary": item.get("Description", ""),
        "version": item.get("Version", ""),
        "votes": item.get("NumVotes", 0),
        "popularity": item.get("Popularity", 0.0),
        "maintainer": item.get("Maintainer", ""),
        "license": item.get("License", [""])[0] if isinstance(item.get("License"), list) else "",
        "url": item.get("URL", ""),
        "url_path": item.get("URLPath", ""),
        "out_of_date": item.get("OutOfDate") is not None,
    }


# ---------------------------------------------------------------- library --
def build_library(flathub, arch):
    library = []
    for app in flathub:
        if app["installed"]:
            library.append(app)
    for app in arch:
        if app["installed"] and app["desktop"]:
            library.append(app)
    return library


# ------------------------------------------------------------------- main --
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["catalog", "search-aur", "aur-info"])
    parser.add_argument("query", nargs="?")
    parser.add_argument("--cache-dir", default=os.path.expanduser("~/.cache/waffle-store"))
    args = parser.parse_args()

    if args.command == "search-aur":
        out = search_aur(args.query or "")
        print(json.dumps(out, ensure_ascii=False))
        return

    if args.command == "aur-info":
        info = aur_info(args.query or "")
        print(json.dumps(info or {}, ensure_ascii=False))
        return

    os.makedirs(args.cache_dir, exist_ok=True)
    flathub = parse_flathub()
    arch = parse_arch()
    library = build_library(flathub, arch)

    def write(name, data):
        with open(os.path.join(args.cache_dir, name), "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False)

    write("flathub.json", flathub)
    write("arch.json", arch)
    write("library.json", library)
    print(f"flathub={len(flathub)} arch={len(arch)} library={len(library)}")


if __name__ == "__main__":
    main()
