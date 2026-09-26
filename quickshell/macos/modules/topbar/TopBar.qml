import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../services"
import "../common"
import qs.core.system
import "./eqsh" as Eq

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
        right: true
    }
    margins { top: 6; left: 10; right: 10 }
    height: Appearance.barHeight
    exclusiveZone: Appearance.barHeight + 4
    color: "transparent"
    WlrLayershell.namespace: "macos:topbar"

    property bool appleOpen: false
    property bool wifiOpen: false
    property bool batteryOpen: false

    readonly property color barFg: "#ffffff"
    readonly property color barFgDim: "#a0a0a8"
    readonly property color barHover: Qt.rgba(1, 1, 1, 0.18)
    readonly property color barSel: "#315bdc"

    readonly property string activeAppId: {
        const id = ToplevelManager.activeToplevel?.appId ?? "";
        if (!id) return "finder";
        return id.toLowerCase();
    }

        readonly property string activeAppName: {
        const id = activeAppId;
        if (!id || id === "finder") return "Finder";
        if (id.includes("afterfx.exe")) return "After Effects"; // الشرط الذكي للأفتر إفكتس
        const seg = id.split(".").pop();
        if (!seg) return "Finder";
        return seg.charAt(0).toUpperCase() + seg.slice(1);
    }


    readonly property var appMenuConfig: ({
        // Finder
        "finder": ["file", "edit", "view", "go", "window", "help"],
        // Browsers
        "firefox": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "chrome": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "chromium": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "brave": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "vivaldi": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "safari": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "epiphany": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        "waterfox": ["file", "edit", "view", "history", "bookmarks", "window", "help"],
        // Terminal
        "kitty": ["shell", "edit", "view", "window", "help"],
        "alacritty": ["shell", "edit", "view", "window", "help"],
        "foot": ["shell", "edit", "view", "window", "help"],
        "wezterm": ["shell", "edit", "view", "window", "help"],
        "ghostty": ["shell", "edit", "view", "window", "help"],
        "konsole": ["shell", "edit", "view", "window", "help"],
        "terminal": ["shell", "edit", "view", "window", "help"],
        // Code editors
        "code": ["file", "edit", "selection", "view", "go", "run", "terminal", "window", "help"],
        "code-oss": ["file", "edit", "selection", "view", "go", "run", "terminal", "window", "help"],
        "vim": ["file", "edit", "view", "window", "help"],
        "emacs": ["file", "edit", "view", "window", "help"],
        "sublime": ["file", "edit", "selection", "view", "goto", "tools", "project", "window", "help"],
        "notepadqq": ["file", "edit", "view", "search", "language", "macros", "run", "window", "help"],
        "gedit": ["file", "edit", "view", "window", "help"],
        "kate": ["file", "edit", "view", "project", "session", "window", "help"],
        // File managers
        "nautilus": ["file", "edit", "view", "go", "window", "help"],
        "thunar": ["file", "edit", "view", "go", "window", "help"],
        "dolphin": ["file", "edit", "view", "go", "tools", "window", "help"],
        "pcmanfm": ["file", "edit", "view", "go", "window", "help"],
        "nemo": ["file", "edit", "view", "go", "window", "help"],
        "files": ["file", "edit", "view", "go", "window", "help"],
        // Media
        "vlc": ["media", "playback", "audio", "video", "subtitle", "tools", "view", "window", "help"],
        "mpv": ["file", "edit", "view", "playback", "window", "help"],
        "celluloid": ["file", "edit", "view", "playback", "window", "help"],
        "totem": ["file", "edit", "view", "window", "help"],
        "rhythmbox": ["file", "edit", "view", "playback", "window", "help"],
        "audacious": ["file", "edit", "view", "playback", "window", "help"],
        "spotify": ["file", "edit", "view", "playback", "window", "help"],
        // Communication
        "discord": ["file", "edit", "view", "window", "help"],
        "telegram": ["file", "edit", "view", "window", "help"],
        "signal": ["file", "edit", "view", "window", "help"],
        "whatsapp": ["file", "edit", "view", "window", "help"],
        "slack": ["file", "edit", "view", "window", "help"],
        "teams": ["file", "edit", "view", "window", "help"],
        "zoom": ["file", "edit", "view", "window", "help"],
        // Office
        "libreoffice": ["file", "edit", "view", "insert", "format", "tools", "window", "help"],
        "libreoffice-writer": ["file", "edit", "view", "insert", "format", "tools", "window", "help"],
        "libreoffice-calc": ["file", "edit", "view", "insert", "format", "tools", "data", "window", "help"],
        "libreoffice-impress": ["file", "edit", "view", "insert", "format", "slideshow", "tools", "window", "help"],
        // Image editors
        "gimp": ["file", "edit", "select", "view", "image", "layer", "colors", "tools", "filters", "windows", "help"],
        "inkscape": ["file", "edit", "view", "layer", "object", "path", "text", "filters", "extensions", "help"],
        "krita": ["file", "edit", "view", "image", "layer", "select", "filter", "tools", "window", "help"],
                // Settings
        "gnome-control-center": ["file", "edit", "view", "help"],
        "systemsettings": ["file", "edit", "view", "help"],
        // Default
        "_default": ["file", "edit", "view", "window", "help"],
        // Adobe After Effects 2022
        "afterfx.exe": ["file", "edit", "composition", "layer", "effect", "animation", "view", "window", "help"]
    })


    readonly property var activeMenus: {
        const al = root.activeAppId;
        // Try exact match
        if (al in root.appMenuConfig) return root.appMenuConfig[al];
        // Try partial match
        for (const key of Object.keys(root.appMenuConfig)) {
            if (key === "_default") continue;
            if (al.includes(key)) return root.appMenuConfig[key];
        }
        return root.appMenuConfig["_default"];
    }

    property string openMenu: ""

    function closeAllMenus() {
        root.appleOpen = false; root.wifiOpen = false; root.batteryOpen = false; root.openMenu = "";
    }
    function openOne(name) {
        root.closeAllMenus();
        ShellController.closeAll();
        if (!name || name === "none") return;
        if (name === "apple") root.appleOpen = true;
        else if (name === "wifi") root.wifiOpen = true;
        else if (name === "battery") root.batteryOpen = true;
        else root.openMenu = name;
    }

    function sendCombo(mods, key) {
        root.closeAllMenus();
        const tl = ToplevelManager.activeToplevel;
        if (tl && typeof tl.activate === "function") tl.activate();
        let cmd = "sleep 0.08; wtype";
        for (const m of mods) cmd += " -M " + m;
        cmd += " -k " + key;
        for (const m of mods) cmd += " -m " + m;
        root.run(cmd);
    }

    function openPath(p) {
        const e = (p || "~").replace(/^~\/?$/, "$HOME").replace(/^~\//, "$HOME/");
        root.run("mkdir -p \"" + e + "\"; xdg-open \"" + e + "\"");
    }

    function menuItems(name) {
        const aid = ToplevelManager.activeToplevel?.appId ?? "";
        const al = aid.toLowerCase();
        const appName = root.activeAppName;
        const tl = ToplevelManager.activeToplevel;

        // Detect app type
        const isFinder = al.includes("finder");
        const isBrowser = al.includes("firefox") || al.includes("chrome") || al.includes("chromium") || al.includes("brave") || al.includes("vivaldi") || al.includes("safari") || al.includes("epiphany") || al.includes("waterfox");
        const isTerminal = al.includes("kitty") || al.includes("alacritty") || al.includes("foot") || al.includes("wezterm") || al.includes("ghostty") || al.includes("terminal") || al.includes("konsole") || al.includes("opencode");
        const isEditor = al.includes("code") || al.includes("vim") || al.includes("emacs") || al.includes("nano") || al.includes("gedit") || al.includes("kate") || al.includes("sublime") || al.includes("notepadqq") || al.includes("opencode");
        const isFiles = al.includes("nautilus") || al.includes("thunar") || al.includes("dolphin") || al.includes("pcmanfm") || al.includes("nemo") || al.includes("files");
        const isMedia = al.includes("vlc") || al.includes("mpv") || al.includes("celluloid") || al.includes("totem") || al.includes("rhythmbox") || al.includes("audacious");
        const isSettings = al.includes("settings") || al.includes("preferences") || al.includes("control");
        const isGeneric = !isFinder && !isBrowser && !isTerminal && !isEditor && !isFiles && !isMedia && !isSettings;

        if (name === "file") {
            if (isFinder || isFiles) {
                return [
                    { label: "New Finder Window", sub: "\u2318N", onClick: () => root.run("xdg-open ~") },
                    { label: "New Folder", sub: "\u21e7\u2318N", onClick: () => root.run("mkdir -p ~/\"New Folder\" && xdg-open ~/\"New Folder\"") },
                    { label: "New Smart Folder", onClick: () => {} },
                    { label: "New Tab", sub: "\u2318T", onClick: () => root.sendCombo(["logo"], "t") },
                    { sep: true },
                    { label: "Open", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                    { label: "Open With\u2026", sub: "", onClick: () => root.sendCombo(["logo", "alt"], "o") },
                    { label: "Close Window", sub: "\u2318W", onClick: () => { if (tl && typeof tl.close === "function") tl.close(); } },
                    { label: "Get Info", sub: "\u2318I", onClick: () => root.sendCombo(["logo"], "i") },
                    { sep: true },
                    { label: "Compress", onClick: () => root.sendCombo(["logo", "alt"], "c") },
                    { sep: true },
                    { label: "Duplicate", sub: "\u2318D", onClick: () => root.sendCombo(["logo"], "d") },
                    { label: "Make Alias", sub: "\u2318M", onClick: () => root.sendCombo(["logo", "m"]) },
                    { label: "Quick Look", sub: "Space", onClick: () => root.sendCombo([], "space") },
                    { label: "Print\u2026", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") },
                    { sep: true },
                    { label: "Move to Trash", sub: "\u2318\u232b", onClick: () => root.sendCombo(["logo"], "Delete") }
                ];
            }
            if (isBrowser) {
                return [
                    { label: "New Window", sub: "\u2318N", onClick: () => root.sendCombo(["logo"], "n") },
                    { label: "New Tab", sub: "\u2318T", onClick: () => root.sendCombo(["logo"], "t") },
                    { label: "New Private Window", sub: "\u21e7\u2318N", onClick: () => root.sendCombo(["logo", "shift"], "n") },
                    { sep: true },
                    { label: "Open File\u2026", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                    { label: "Open Location\u2026", sub: "\u2318L", onClick: () => root.sendCombo(["logo"], "l") },
                    { label: "Open Recent\u2026", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Close Tab", sub: "\u2318W", onClick: () => root.sendCombo(["logo", "shift"], "w") },
                    { label: "Close Window", sub: "\u21e7\u2318W", onClick: () => root.sendCombo(["logo", "shift"], "w") },
                    { sep: true },
                    { label: "Save Page As\u2026", sub: "\u21e7\u2318S", onClick: () => root.sendCombo(["logo", "shift"], "s") },
                    { label: "Share\u2026", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Print\u2026", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") }
                ];
            }
            if (isTerminal) {
                return [
                    { label: "New Window", sub: "\u2318N", onClick: () => root.sendCombo(["logo"], "n") },
                    { label: "New Tab", sub: "\u2318T", onClick: () => root.sendCombo(["logo", "shift"], "t") },
                    { sep: true },
                    { label: "Open\u2026", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                    { label: "Close Window", sub: "\u2318W", onClick: () => { if (tl && typeof tl.close === "function") tl.close(); } },
                    { sep: true },
                    { label: "Save Session\u2026", sub: "\u2318S", onClick: () => root.sendCombo(["logo"], "s") },
                    { label: "Export Session\u2026", sub: "", onClick: () => root.run("sleep 0.05; wtype '/export'; sleep 0.05; wtype -k Return") },
                    { sep: true },
                    { label: "Split Horizontal", sub: "\u2318D", onClick: () => root.sendCombo(["logo", "shift"], "d") },
                    { label: "Split Vertical", sub: "\u2318E", onClick: () => root.sendCombo(["logo", "shift"], "e") },
                    { sep: true },
                    { label: "Select Font\u2026", sub: "", onClick: () => {} }
                ];
            }
            if (isEditor) {
                return [
                    { label: "New File", sub: "\u2318N", onClick: () => root.sendCombo(["logo"], "n") },
                    { label: "New Window", sub: "\u21e7\u2318N", onClick: () => root.sendCombo(["logo", "shift"], "n") },
                    { sep: true },
                    { label: "Open\u2026", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                    { label: "Open Recent\u2026", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Close", sub: "\u2318W", onClick: () => { if (tl && typeof tl.close === "function") tl.close(); } },
                    { sep: true },
                    { label: "Save", sub: "\u2318S", onClick: () => root.sendCombo(["logo"], "s") },
                    { label: "Save As\u2026", sub: "\u21e7\u2318S", onClick: () => root.sendCombo(["logo", "shift"], "s") },
                    { label: "Save All", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Revert File", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Print\u2026", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") }
                ];
            }
            if (isMedia) {
                return [
                    { label: "Open File\u2026", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                    { label: "Open Network Stream\u2026", sub: "\u2318N", onClick: () => root.sendCombo(["logo", "shift"], "n") },
                    { label: "Open Disc\u2026", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Open Recent\u2026", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Save Playlist to File\u2026", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Convert / Stream\u2026", sub: "\u2318R", onClick: () => root.sendCombo(["logo", "shift"], "r") },
                    { sep: true },
                    { label: "Quit " + appName, sub: "\u2318Q", onClick: () => { if (aid) DockApps.quitApp([aid]); } }
                ];
            }
            // Generic / default
            return [
                { label: "New Window", sub: "\u2318N", onClick: () => { if (aid) Apps.launchById(aid); } },
                { sep: true },
                { label: "Open\u2026", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                { label: "Open Recent\u2026", sub: "", onClick: () => {} },
                { sep: true },
                { label: "Close", sub: "\u2318W", onClick: () => { if (tl && typeof tl.close === "function") tl.close(); } },
                { sep: true },
                { label: "Save", sub: "\u2318S", onClick: () => root.sendCombo(["logo"], "s") },
                { label: "Save As\u2026", sub: "\u21e7\u2318S", onClick: () => root.sendCombo(["logo", "shift"], "s") },
                { sep: true },
                { label: "Page Setup\u2026", sub: "", onClick: () => {} },
                { label: "Print\u2026", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") }
            ];
        }

        if (name === "edit") {
            if (isBrowser) {
                return [
                    { label: "Undo", sub: "\u2318Z", onClick: () => root.sendCombo(["logo"], "z") },
                    { label: "Redo", sub: "\u21e7\u2318Z", onClick: () => root.sendCombo(["logo", "shift"], "z") },
                    { sep: true },
                    { label: "Cut", sub: "\u2318X", onClick: () => root.sendCombo(["logo"], "x") },
                    { label: "Copy", sub: "\u2318C", onClick: () => root.sendCombo(["logo"], "c") },
                    { label: "Paste", sub: "\u2318V", onClick: () => root.sendCombo(["logo"], "v") },
                    { label: "Paste and Match Style", sub: "\u21e7\u2318\u2318V", onClick: () => root.sendCombo(["logo", "shift"], "v") },
                    { label: "Delete", onClick: () => root.sendCombo([], "Delete") },
                    { label: "Select All", sub: "\u2318A", onClick: () => root.sendCombo(["logo"], "a") },
                    { sep: true },
                    { label: "Find\u2026", sub: "\u2318F", onClick: () => root.sendCombo(["logo"], "f") },
                    { label: "Find Again", sub: "\u2318G", onClick: () => root.sendCombo(["logo"], "g") },
                    { label: "Find Previous", sub: "\u21e7\u2318G", onClick: () => root.sendCombo(["logo", "shift"], "g") },
                    { sep: true },
                    { label: "Search with Google", sub: "\u2318E", onClick: () => root.sendCombo(["logo"], "e") },
                    { sep: true },
                    { label: "Emoji & Symbols", sub: "\u2303\u2318Space", onClick: () => root.sendCombo(["logo", "ctrl"], "space") }
                ];
            }
            if (isEditor) {
                return [
                    { label: "Undo", sub: "\u2318Z", onClick: () => root.sendCombo(["logo"], "z") },
                    { label: "Redo", sub: "\u21e7\u2318Z", onClick: () => root.sendCombo(["logo", "shift"], "z") },
                    { sep: true },
                    { label: "Cut", sub: "\u2318X", onClick: () => root.sendCombo(["logo"], "x") },
                    { label: "Copy", sub: "\u2318C", onClick: () => root.sendCombo(["logo"], "c") },
                    { label: "Paste", sub: "\u2318V", onClick: () => root.sendCombo(["logo"], "v") },
                    { label: "Delete", onClick: () => root.sendCombo([], "Delete") },
                    { label: "Select All", sub: "\u2318A", onClick: () => root.sendCombo(["logo"], "a") },
                    { sep: true },
                    { label: "Find\u2026", sub: "\u2318F", onClick: () => root.sendCombo(["logo"], "f") },
                    { label: "Find and Replace\u2026", sub: "\u2325\u2318F", onClick: () => root.sendCombo(["logo", "alt"], "f") },
                    { label: "Find Next", sub: "\u2318G", onClick: () => root.sendCombo(["logo"], "g") },
                    { label: "Find Previous", sub: "\u21e7\u2318G", onClick: () => root.sendCombo(["logo", "shift"], "g") },
                    { sep: true },
                    { label: "Indent", sub: "\u2318]", onClick: () => root.sendCombo(["logo"], "bracketright") },
                    { label: "Outdent", sub: "\u2318[", onClick: () => root.sendCombo(["logo"], "bracketleft") },
                    { sep: true },
                    { label: "Toggle Comment", sub: "\u2318/", onClick: () => root.sendCombo(["logo"], "slash") },
                    { label: "Transpose", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Emoji & Symbols", sub: "\u2303\u2318Space", onClick: () => root.sendCombo(["logo", "ctrl"], "space") }
                ];
            }
            // Default (Finder, Files, Generic)
            return [
                { label: "Undo", sub: "\u2318Z", onClick: () => root.sendCombo(["logo"], "z") },
                { label: "Redo", sub: "\u21e7\u2318Z", onClick: () => root.sendCombo(["logo", "shift"], "z") },
                { sep: true },
                { label: "Cut", sub: "\u2318X", onClick: () => root.sendCombo(["logo"], "x") },
                { label: "Copy", sub: "\u2318C", onClick: () => root.sendCombo(["logo"], "c") },
                { label: "Copy as Plain Text", onClick: () => root.sendCombo(["logo", "alt"], "c") },
                { label: "Paste", sub: "\u2318V", onClick: () => root.sendCombo(["logo"], "v") },
                { label: "Paste and Match Style", sub: "\u2325\u21e7\u2318V", onClick: () => root.sendCombo(["logo", "alt", "shift"], "v") },
                { label: "Delete", onClick: () => root.sendCombo([], "Delete") },
                { label: "Select All", sub: "\u2318A", onClick: () => root.sendCombo(["logo"], "a") },
                { sep: true },
                { label: "Show Clipboard", onClick: () => {} },
                { sep: true },
                { label: "Find\u2026", sub: "\u2318F", onClick: () => root.sendCombo(["logo"], "f") },
                { label: "Find and Replace\u2026", sub: "\u2325\u2318F", onClick: () => root.sendCombo(["logo", "alt"], "f") },
                { label: "Find Next", sub: "\u2318G", onClick: () => root.sendCombo(["logo"], "g") },
                { label: "Find Previous", sub: "\u21e7\u2318G", onClick: () => root.sendCombo(["logo", "shift"], "g") },
                { sep: true },
                { label: "Spelling and Grammar", sub: "", onClick: () => {} },
                { label: "Substitutions", sub: "", onClick: () => {} },
                { label: "Speech", sub: "", onClick: () => {} },
                { sep: true },
                { label: "Start Dictation", sub: "\u2318;", onClick: () => root.sendCombo(["logo"], "semicolon") },
                { label: "Emoji & Symbols", sub: "\u2303\u2318Space", onClick: () => root.sendCombo(["logo", "ctrl"], "space") }
            ];
        }

        if (name === "view") {
            if (isFinder || isFiles) {
                return [
                    { label: "as Icons", sub: "\u23181", onClick: () => root.sendCombo(["logo"], "1"), checked: true },
                    { label: "as List", sub: "\u23182", onClick: () => root.sendCombo(["logo"], "2") },
                    { label: "as Columns", sub: "\u23183", onClick: () => root.sendCombo(["logo"], "3") },
                    { label: "as Gallery", sub: "\u23184", onClick: () => root.sendCombo(["logo"], "4") },
                    { sep: true },
                    { label: "Clean Up", sub: "", onClick: () => root.sendCombo(["logo", "alt"], "o") },
                    { label: "Sort By", sub: "", onClick: () => {} },
                    { label: "Reset Column Width", sub: "", onClick: () => {} },
                    { sep: true },
                    { label: "Show Path Bar", sub: "\u2325\u2318P", onClick: () => root.sendCombo(["logo", "alt"], "p") },
                    { label: "Show Status Bar", sub: "\u2318/", onClick: () => root.sendCombo(["logo"], "slash") },
                    { label: "Show Sidebar", sub: "\u2325\u2318S", onClick: () => root.sendCombo(["logo", "alt"], "s") },
                    { label: "Show Preview", sub: "\u21e7\u2318P", onClick: () => root.sendCombo(["logo", "shift"], "p") },
                    { sep: true },
                    { label: "Show Toolbar", sub: "\u2325\u2318T", onClick: () => root.sendCombo(["logo", "alt"], "t") },
                    { label: "Show Tab Bar", sub: "\u21e7\u2318T", onClick: () => root.sendCombo(["logo", "shift"], "t") },
                    { sep: true },
                    { label: "Enter Full Screen", sub: "\u2303\u2318F", onClick: () => { if (tl) tl.fullscreen = true; } }
                ];
            }
            if (isBrowser) {
                return [
                    { label: "Stop", sub: "\u2318.", onClick: () => root.sendCombo(["logo"], "period") },
                    { label: "Reload This Page", sub: "\u2318R", onClick: () => root.sendCombo(["logo"], "r") },
                    { sep: true },
                    { label: "Zoom In", sub: "\u2318+", onClick: () => root.sendCombo(["logo"], "plus") },
                    { label: "Zoom Out", sub: "\u2318-", onClick: () => root.sendCombo(["logo"], "minus") },
                    { label: "Actual Size", sub: "\u23180", onClick: () => root.sendCombo(["logo"], "0") },
                    { sep: true },
                    { label: "Toggle Sidebar", sub: "\u2318S", onClick: () => root.sendCombo(["logo"], "s") },
                    { label: "Toggle Bookmarks Bar", sub: "\u21e7\u2318B", onClick: () => root.sendCombo(["logo", "shift"], "b") },
                    { label: "Toggle Full Screen", sub: "\u21e7\u2318F", onClick: () => { if (tl) tl.fullscreen = !tl.fullscreen; } },
                    { sep: true },
                    { label: "Page Source", sub: "\u2318U", onClick: () => root.sendCombo(["logo"], "u") },
                    { label: "Developer Tools", sub: "\u21e7\u2318I", onClick: () => root.sendCombo(["logo", "shift"], "i") }
                ];
            }
            if (isTerminal) {
                return [
                    { label: "Zoom In", sub: "\u2318+", onClick: () => root.sendCombo(["logo"], "plus") },
                    { label: "Zoom Out", sub: "\u2318-", onClick: () => root.sendCombo(["logo"], "minus") },
                    { label: "Actual Size", sub: "\u23180", onClick: () => root.sendCombo(["logo"], "0") },
                    { sep: true },
                    { label: "Toggle Full Screen", sub: "\u21e7\u2318F", onClick: () => { if (tl) tl.fullscreen = !tl.fullscreen; } }
                ];
            }
            // Default
            return [
                { label: "Show Toolbar", sub: "\u2325\u2318T", onClick: () => root.sendCombo(["logo", "alt"], "t") },
                { label: "Toggle Full Screen", sub: "\u21e7\u2318F", onClick: () => { if (tl) tl.fullscreen = !tl.fullscreen; } }
            ];
        }

        if (name === "go") {
            if (isBrowser) {
                return [
                    { label: "Back", sub: "\u2318[", onClick: () => root.sendCombo(["logo"], "bracketleft") },
                    { label: "Forward", sub: "\u2318]", onClick: () => root.sendCombo(["logo"], "bracketright") },
                    { sep: true },
                    { label: "Home", sub: "\u2318H", onClick: () => root.sendCombo(["logo"], "h") },
                    { sep: true },
                    { label: "Show History", sub: "\u21e7\u2318H", onClick: () => root.sendCombo(["logo", "shift"], "h") },
                    { label: "Show Downloads", sub: "\u21e7\u2318J", onClick: () => root.sendCombo(["logo", "shift"], "j") }
                ];
            }
            // Finder / Files / Generic
            return [
                { label: "Back", sub: "\u2318[", onClick: () => root.sendCombo(["logo"], "bracketleft") },
                { label: "Forward", sub: "\u2318]", onClick: () => root.sendCombo(["logo"], "bracketright") },
                { label: "Enclosing Folder", sub: "\u2318\u2191", onClick: () => root.sendCombo(["logo"], "Up") },
                { sep: true },
                { label: "Recents", onClick: () => root.openPath("~/Recent") },
                { label: "Documents", onClick: () => root.openPath("~/Documents") },
                { label: "Desktop", onClick: () => root.openPath("~/Desktop") },
                { label: "Downloads", onClick: () => root.openPath("~/Downloads") },
                { label: "Home", sub: "\u21e7\u2318H", onClick: () => root.openPath("~") },
                { label: "Computer", sub: "\u21e7\u2318C", onClick: () => root.run("xdg-open /") },
                { label: "AirDrop", sub: "\u21e7\u2318R", onClick: () => root.run("xdg-open network://") },
                { label: "Network", sub: "\u21e7\u2318K", onClick: () => root.run("xdg-open network://") },
                { sep: true },
                { label: "iCloud Drive", onClick: () => root.openPath("~") },
                { label: "Applications", sub: "\u21e7\u2318A", onClick: () => root.openPath("~/Applications") },
                { label: "Utilities", sub: "\u21e7\u2318U", onClick: () => root.openPath("~/Utilities") },
                { sep: true },
                { label: "Go to Folder\u2026", sub: "\u21e7\u2318G", onClick: () => root.run("dir=$(zenity --file-selection --directory --title 'Go to Folder' 2>/dev/null) && xdg-open \"$dir\"") },
                { label: "Connect to Server\u2026", sub: "\u2318K", onClick: () => root.sendCombo(["logo"], "k") }
            ];
        }

        if (name === "window") {
            const items = [];
            items.push({ label: "Minimize", sub: "\u2318M", onClick: () => { if (tl) tl.minimized = true; } });
            items.push({ label: "Zoom", onClick: () => { if (tl) tl.maximized = !tl.maximized; } });
            if (!isTerminal && !isMedia) {
                items.push({ sep: true });
                items.push({ label: "Move Window to Left Side of Screen", onClick: () => {} });
                items.push({ label: "Move Window to Right Side of Screen", onClick: () => {} });
            }
            items.push({ sep: true });
            items.push({ label: "Cycle Through Windows", sub: "\u2318`", onClick: () => root.sendCombo(["logo"], "grave") });
            items.push({ sep: true });
            const tops = ToplevelManager.toplevels?.values ?? [];
            for (const t of tops) {
                const key = (t.title && t.title.length) ? t.title : (t.appId || "Window");
                items.push({ label: key, onClick: () => { if (typeof t.activate === "function") t.activate(); } });
            }
            items.push({ sep: true });
            items.push({ label: "Bring All to Front", onClick: () => { for (const t of tops) if (typeof t.activate === "function") t.activate(); } });
            return items;
        }

        if (name === "help") {
            return [
                { label: appName + " Help", sub: "\u21e7\u2318?", onClick: () => root.sendCombo(["logo", "shift"], "question") },
                { sep: true },
                { label: "Search", onClick: () => { root.closeAllMenus(); ShellController.toggle("spotlight"); } }
            ];
        }

        // Terminal - Shell menu
        if (name === "shell") {
            return [
                { label: "New Window", sub: "\u2318N", onClick: () => root.sendCombo(["logo"], "n") },
                { label: "New Tab", sub: "\u2318T", onClick: () => root.sendCombo(["logo", "shift"], "t") },
                { sep: true },
                { label: "Close Tab", sub: "\u2318W", onClick: () => root.sendCombo(["logo", "shift"], "w") },
                { label: "Close Window", sub: "\u21e7\u2318W", onClick: () => { if (tl && typeof tl.close === "function") tl.close(); } },
                { sep: true },
                { label: "Split Horizontal", sub: "\u2318D", onClick: () => root.sendCombo(["logo", "shift"], "d") },
                { label: "Split Vertical", sub: "\u2318E", onClick: () => root.sendCombo(["logo", "shift"], "e") },
                { sep: true },
                { label: "Clear Scrollback", sub: "\u2318K", onClick: () => root.sendCombo(["logo"], "k") },
                { label: "Reset", onClick: () => {} },
                { sep: true },
                { label: "Export Text As\u2026", onClick: () => {} },
                { label: "Print\u2026", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") }
            ];
        }

        // Browser - History menu
        if (name === "history") {
            return [
                { label: "Back", sub: "\u2318[", onClick: () => root.sendCombo(["logo"], "bracketleft") },
                { label: "Forward", sub: "\u2318]", onClick: () => root.sendCombo(["logo"], "bracketright") },
                { sep: true },
                { label: "Show All History", sub: "\u21e7\u2318H", onClick: () => root.sendCombo(["logo", "shift"], "h") },
                { sep: true },
                { label: "Reopen Last Closed Tab", sub: "\u21e7\u2318T", onClick: () => root.sendCombo(["logo", "shift"], "t") },
                { label: "Reopen Last Closed Window", sub: "\u2325\u21e7\u2318T", onClick: () => root.sendCombo(["logo", "alt", "shift"], "t") },
                { sep: true },
                { label: "Clear History\u2026", onClick: () => {} }
            ];
        }

        // Browser - Bookmarks menu
        if (name === "bookmarks") {
            return [
                { label: "Add Bookmark\u2026", sub: "\u2318D", onClick: () => root.sendCombo(["logo"], "d") },
                { label: "Add to Reading List", sub: "\u21e7\u2318D", onClick: () => root.sendCombo(["logo", "shift"], "d") },
                { sep: true },
                { label: "Show Bookmarks", sub: "\u2325\u2318B", onClick: () => root.sendCombo(["logo", "alt"], "b") },
                { label: "Show Reading List", onClick: () => {} },
                { sep: true },
                { label: "Edit Bookmarks\u2026", onClick: () => {} }
            ];
        }

        // VS Code - Selection menu
        if (name === "selection") {
            return [
                { label: "Select All", sub: "\u2318A", onClick: () => root.sendCombo(["logo"], "a") },
                { label: "Expand Selection", sub: "\u2325\u2190", onClick: () => root.sendCombo(["logo", "alt"], "Left") },
                { label: "Shrink Selection", sub: "\u2325\u2192", onClick: () => root.sendCombo(["logo", "alt"], "Right") },
                { sep: true },
                { label: "Add Cursor Above", sub: "\u2325\u2318\u2191", onClick: () => root.sendCombo(["logo", "alt"], "Up") },
                { label: "Add Cursor Below", sub: "\u2325\u2318\u2193", onClick: () => root.sendCombo(["logo", "alt"], "Down") },
                { label: "Add Cursor to Next Occurrence", sub: "\u2318D", onClick: () => root.sendCombo(["logo"], "d") },
                { sep: true },
                { label: "Select All Occurrences", sub: "\u21e7\u2318L", onClick: () => root.sendCombo(["logo", "shift"], "l") },
                { label: "Column Selection", sub: "\u21e7\u2325\u2318\u2190", onClick: () => {} }
            ];
        }

        // VS Code - Run menu
        if (name === "run") {
            return [
                { label: "Start Debugging", sub: "F5", onClick: () => root.sendCombo([], "F5") },
                { label: "Run Without Debugging", sub: "\u2318F5", onClick: () => root.sendCombo(["logo"], "F5") },
                { label: "Stop Debugging", sub: "\u21e7F5", onClick: () => root.sendCombo(["shift"], "F5") },
                { label: "Restart Debugging", sub: "\u21e7\u2318F5", onClick: () => root.sendCombo(["logo", "shift"], "F5") },
                { sep: true },
                { label: "Open Configurations", onClick: () => {} },
                { sep: true },
                { label: "Toggle Breakpoint", sub: "\u2318B", onClick: () => root.sendCombo(["logo"], "b") },
                { label: "Step Over", sub: "F10", onClick: () => root.sendCombo([], "F10") },
                { label: "Step Into", sub: "F11", onClick: () => root.sendCombo([], "F11") },
                { label: "Step Out", sub: "\u21e7F11", onClick: () => root.sendCombo(["shift"], "F11") }
            ];
        }

        // VS Code - Terminal menu
        if (name === "terminal") {
            return [
                { label: "New Terminal", sub: "\u2303\u21e7`", onClick: () => root.sendCombo(["logo", "shift"], "grave") },
                { label: "Split Terminal", sub: "\u2303\u21e7`", onClick: () => root.sendCombo(["logo", "shift"], "grave") },
                { sep: true },
                { label: "Kill Terminal", onClick: () => {} },
                { sep: true },
                { label: "Run Task\u2026", onClick: () => {} },
                { label: "Run Build Task\u2026", sub: "\u21e7\u2318B", onClick: () => root.sendCombo(["logo", "shift"], "b") },
                { label: "Run Task\u2026", onClick: () => {} }
            ];
        }

        // VLC - Media menu
        if (name === "media") {
            return [
                { label: "Open File\u2026", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                { label: "Open Network Stream\u2026", sub: "\u2318N", onClick: () => root.sendCombo(["logo", "shift"], "n") },
                { label: "Open Disc\u2026", onClick: () => {} },
                { label: "Open Capture Device\u2026", sub: "\u2318C", onClick: () => root.sendCombo(["logo"], "c") },
                { sep: true },
                { label: "Open Recent\u2026", onClick: () => {} },
                { sep: true },
                { label: "Save Playlist to File\u2026", sub: "\u2318Y", onClick: () => root.sendCombo(["logo"], "y") },
                { sep: true },
                { label: "Convert / Stream\u2026", sub: "\u21e7\u2318S", onClick: () => root.sendCombo(["logo", "shift"], "s") },
                { label: "Quit", sub: "\u2318Q", onClick: () => { if (aid) DockApps.quitApp([aid]); } }
            ];
        }

        // Media - Playback menu
        if (name === "playback") {
            return [
                { label: "Play / Pause", sub: "Space", onClick: () => root.sendCombo([], "space") },
                { label: "Stop", sub: "S", onClick: () => root.sendCombo([], "s") },
                { label: "Previous", sub: "P", onClick: () => root.sendCombo([], "p") },
                { label: "Next", sub: "N", onClick: () => root.sendCombo([], "n") },
                { sep: true },
                { label: "Speed \u2190", sub: "\u2318\u2190", onClick: () => root.sendCombo(["logo"], "Left") },
                { label: "Speed \u2192", sub: "\u2318\u2192", onClick: () => root.sendCombo(["logo"], "Right") },
                { label: "Normal Speed", sub: "\u2318=", onClick: () => root.sendCombo(["logo"], "equal") },
                { sep: true },
                { label: "Jump Forward", sub: "\u2318\u2192", onClick: () => root.sendCombo(["logo"], "Right") },
                { label: "Jump Backward", sub: "\u2318\u2190", onClick: () => root.sendCombo(["logo"], "Left") }
            ];
        }

        // VLC - Audio menu
        if (name === "audio") {
            return [
                { label: "Increase Volume", sub: "\u2318\u2191", onClick: () => root.sendCombo(["logo"], "Up") },
                { label: "Decrease Volume", sub: "\u2318\u2193", onClick: () => root.sendCombo(["logo"], "Down") },
                { label: "Mute", sub: "M", onClick: () => root.sendCombo([], "m") },
                { sep: true },
                { label: "Audio Device", onClick: () => {} },
                { label: "Stereo Mode", onClick: () => {} },
                { sep: true },
                { label: "Visualizations", onClick: () => {} }
            ];
        }

        // VLC - Video menu
        if (name === "video") {
            return [
                { label: "Fullscreen", sub: "F", onClick: () => root.sendCombo([], "f") },
                { sep: true },
                { label: "Zoom", onClick: () => {} },
                { label: "Aspect Ratio", onClick: () => {} },
                { label: "Crop", onClick: () => {} },
                { sep: true },
                { label: "Deinterlace", onClick: () => {} },
                { label: "Deinterlace mode", onClick: () => {} }
            ];
        }

        // VLC - Subtitle menu
        if (name === "subtitle") {
            return [
                { label: "Add Subtitle File\u2026", onClick: () => {} },
                { sep: true },
                { label: "Sub Track", onClick: () => {} }
            ];
        }

        // Tools menu (Dolphin, LibreOffice, etc.)
        if (name === "tools") {
            return [
                { label: "Add Account\u2026", onClick: () => {} },
                { sep: true },
                { label: "Start Up Debugging", onClick: () => {} },
                { label: "Settings\u2026", sub: "\u2318,", onClick: () => root.sendCombo(["logo"], "comma") }
            ];
        }

        // Sublime Text - Goto menu
        if (name === "goto") {
            return [
                { label: "Go to Anything\u2026", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") },
                { label: "Go to Line\u2026", sub: "\u2318G", onClick: () => root.sendCombo(["logo"], "g") },
                { label: "Go to Symbol", sub: "\u2318R", onClick: () => root.sendCombo(["logo"], "r") },
                { sep: true },
                { label: "Go to Definition", sub: "F12", onClick: () => root.sendCombo([], "F12") },
                { label: "Go to Reference", sub: "\u2318F12", onClick: () => root.sendCombo(["logo"], "F12") },
                { sep: true },
                { label: "Jump Back", sub: "\u2325\u2190", onClick: () => root.sendCombo(["logo", "alt"], "Left") },
                { label: "Jump Forward", sub: "\u2325\u2192", onClick: () => root.sendCombo(["logo", "alt"], "Right") }
            ];
        }

        // Notepadqq - Search menu
        if (name === "search") {
            return [
                { label: "Find\u2026", sub: "\u2318F", onClick: () => root.sendCombo(["logo"], "f") },
                { label: "Find in Files\u2026", sub: "\u21e7\u2318F", onClick: () => root.sendCombo(["logo", "shift"], "f") },
                { label: "Replace\u2026", sub: "\u2318H", onClick: () => root.sendCombo(["logo"], "h") },
                { sep: true },
                { label: "Find Next", sub: "\u2318G", onClick: () => root.sendCombo(["logo"], "g") },
                { label: "Find Previous", sub: "\u21e7\u2318G", onClick: () => root.sendCombo(["logo", "shift"], "g") },
                { sep: true },
                { label: "Mark All", sub: "\u21e7\u2318A", onClick: () => root.sendCombo(["logo", "shift"], "a") },
                { label: "Unmark All", onClick: () => {} },
                { label: "Go to Next Mark", sub: "\u2318K", onClick: () => root.sendCombo(["logo"], "k") },
                { label: "Go to Previous Mark", sub: "\u21e7\u2318K", onClick: () => root.sendCombo(["logo", "shift"], "k") }
            ];
        }

        // Notepadqq - Language menu
        if (name === "language") {
            return [
                { label: "HTML", onClick: () => {} },
                { label: "CSS", onClick: () => {} },
                { label: "JavaScript", onClick: () => {} },
                { label: "Python", onClick: () => {} },
                { label: "Markdown", onClick: () => {} },
                { sep: true },
                { label: "plain text", onClick: () => {} }
            ];
        }

        // Notepadqq - Macros menu
        if (name === "macros") {
            return [
                { label: "Start recording", sub: "\u2318\u21e7R", onClick: () => root.sendCombo(["logo", "shift"], "r") },
                { label: "Stop recording", sub: "\u21e7\u2318\u21e7R", onClick: () => {} },
                { label: "Playback", sub: "\u2318\u21e7P", onClick: () => root.sendCombo(["logo", "shift"], "p") },
                { sep: true },
                { label: "Save macro\u2026", onClick: () => {} },
                { label: "Load macro\u2026", onClick: () => {} },
                { label: "Macro manager\u2026", onClick: () => {} }
            ];
        }

        // LibreOffice - Insert menu
        if (name === "insert") {
            return [
                { label: "Page Break", sub: "\u21e7\u2318Enter", onClick: () => root.sendCombo(["logo", "shift"], "Return") },
                { label: "More Breaks", onClick: () => {} },
                { sep: true },
                { label: "Image\u2026", sub: "\u2318\u2302", onClick: () => root.sendCombo(["logo"], "i") },
                { label: "Media", onClick: () => {} },
                { label: "Chart\u2026", onClick: () => {} },
                { sep: true },
                { label: "Text Box", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { label: "Shape", onClick: () => {} },
                { label: "Object\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { sep: true },
                { label: "Symbol\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { label: "Special Character\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { sep: true },
                { label: "Header", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { label: "Footer", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { sep: true },
                { label: "Bookmark\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { label: "Cross-reference\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") }
            ];
        }

        // LibreOffice - Format menu
        if (name === "format") {
            return [
                { label: "Text", onClick: () => {} },
                { label: "Spacing", onClick: () => {} },
                { sep: true },
                { label: "Align", onClick: () => {} },
                { label: "Styre", onClick: () => {} },
                { label: "Paragraph\u2026", onClick: () => {} },
                { label: "Bullets and Numbering\u2026", onClick: () => {} },
                { sep: true },
                { label: "Page Style\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { label: "Character\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") },
                { sep: true },
                { label: "Paragraph\u2026", sub: "\u2318F10", onClick: () => root.sendCombo(["logo"], "F10") }
            ];
        }

        // LibreOffice Calc - Data menu
        if (name === "data") {
            return [
                { label: "Define Range\u2026", onClick: () => {} },
                { label: "Select Ranges\u2026", onClick: () => {} },
                { sep: true },
                { label: "Sort", onClick: () => {} },
                { label: "Sort Ascending", onClick: () => {} },
                { label: "Sort Descending", onClick: () => {} },
                { sep: true },
                { label: "AutoFilter", sub: "\u2318\u2325\u2318F", onClick: () => root.sendCombo(["logo", "alt"], "f") },
                { label: "Advanced Filter", onClick: () => {} },
                { sep: true },
                { label: "Validation", onClick: () => {} },
                { label: "Text to Columns", onClick: () => {} },
                { label: "Duplicate Removal", onClick: () => {} },
                { sep: true },
                { label: "Consolidate", onClick: () => {} },
                { label: "Group and Outline", onClick: () => {} },
                { label: "Pivot Table", onClick: () => {} }
            ];
        }

        // GIMP/Krita - Select menu
        if (name === "select") {
            return [
                { label: "All", sub: "\u2318A", onClick: () => root.sendCombo(["logo"], "a") },
                { label: "None", sub: "\u21e7\u2318A", onClick: () => root.sendCombo(["logo", "shift"], "a") },
                { label: "Invert", sub: "\u2318I", onClick: () => root.sendCombo(["logo"], "i") },
                { sep: true },
                { label: "Float", sub: "\u21e7\u2318V", onClick: () => root.sendCombo(["logo", "shift"], "v") },
                { label: "By Color", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") },
                { sep: true },
                { label: "Feather\u2026", sub: "\u2318\u2325F", onClick: () => root.sendCombo(["logo", "alt"], "f") },
                { label: "Grow\u2026", sub: "\u2318\u2325I", onClick: () => root.sendCombo(["logo", "alt"], "i") },
                { label: "Shrink\u2026", sub: "\u2318\u2325S", onClick: () => root.sendCombo(["logo", "alt"], "s") },
                { label: "Border\u2026", sub: "\u2318\u2325B", onClick: () => root.sendCombo(["logo", "alt"], "b") },
                { sep: true },
                { label: "Rounded Rectangle\u2026", onClick: () => {} },
                { label: "Ellipse", onClick: () => {} },
                { label: "Rectangle", onClick: () => {} }
            ];
        }

        // GIMP/Krita - Image menu
        if (name === "image") {
            return [
                { label: "Duplicate", sub: "\u2318D", onClick: () => root.sendCombo(["logo"], "d") },
                { sep: true },
                { label: "Mode", onClick: () => {} },
                { label: "Transform", onClick: () => {} },
                { label: "Canvas Size\u2026", sub: "\u2318\u2325C", onClick: () => root.sendCombo(["logo", "alt"], "c") },
                { label: "Scale Image\u2026", sub: "\u2318\u2325S", onClick: () => root.sendCombo(["logo", "alt"], "s") },
                { sep: true },
                { label: "Crop to Selection", sub: "\u2318\u2325R", onClick: () => root.sendCombo(["logo", "alt"], "r") },
                { label: "Autocrop Image", sub: "\u21e7\u2318\u2325R", onClick: () => root.sendCombo(["logo", "alt", "shift"], "r") },
                { sep: true },
                { label: "Flatten Image", onClick: () => {} },
                { label: "Merge Visible Layers", sub: "\u2318M", onClick: () => root.sendCombo(["logo"], "m") }
            ];
        }

        // GIMP/Krita/Inkscape - Layer menu
        if (name === "layer") {
            return [
                { label: "New Layer", sub: "\u21e7\u2318N", onClick: () => root.sendCombo(["logo", "shift"], "n") },
                { label: "Duplicate Layer", sub: "\u21e7\u2318D", onClick: () => root.sendCombo(["logo", "shift"], "d") },
                { label: "Delete Layer", onClick: () => {} },
                { sep: true },
                { label: "Stack", onClick: () => {} },
                { label: "Transparency", onClick: () => {} },
                { label: "Transform", onClick: () => {} },
                { sep: true },
                { label: "Merge Down", sub: "\u2318M", onClick: () => root.sendCombo(["logo"], "m") },
                { label: "Flatten Image", onClick: () => {} },
                { sep: true },
                { label: "Alpha to Selection", sub: "\u2318O", onClick: () => root.sendCombo(["logo"], "o") }
            ];
        }

        // GIMP - Colors menu
        if (name === "colors") {
            return [
                { label: "Color Balance", sub: "\u2318B", onClick: () => root.sendCombo(["logo"], "b") },
                { label: "Hue-Saturation", sub: "\u2318U", onClick: () => root.sendCombo(["logo"], "u") },
                { label: "Colorize", sub: "\u2318;", onClick: () => root.sendCombo(["logo"], "semicolon") },
                { label: "Brightness-Contrast", sub: "\u2318C", onClick: () => root.sendCombo(["logo"], "c") },
                { sep: true },
                { label: "Levels", sub: "\u2318L", onClick: () => root.sendCombo(["logo"], "l") },
                { label: "Curves", sub: "\u2318M", onClick: () => root.sendCombo(["logo"], "m") },
                { sep: true },
                { label: "Threshold", sub: "\u2318T", onClick: () => root.sendCombo(["logo"], "t") },
                { label: "Posterize", sub: "\u2318P", onClick: () => root.sendCombo(["logo"], "p") },
                { sep: true },
                { label: "Desaturate", sub: "\u21e7\u2318U", onClick: () => root.sendCombo(["logo", "shift"], "u") },
                { label: "Invert", sub: "\u2318I", onClick: () => root.sendCombo(["logo"], "i") }
            ];
        }

        // GIMP/Krita - Filters menu
        if (name === "filters") {
            return [
                { label: "Repeat Last", sub: "\u2318F", onClick: () => root.sendCombo(["logo"], "f") },
                { label: "Re-Show", sub: "\u21e7\u2318F", onClick: () => root.sendCombo(["logo", "shift"], "f") },
                { sep: true },
                { label: "Blur", onClick: () => {} },
                { label: "Enhance", onClick: () => {} },
                { label: "Distorts", onClick: () => {} },
                { label: "Light and Shadow", onClick: () => {} },
                { label: "Noise", onClick: () => {} },
                { label: "Edge-Detect", onClick: () => {} },
                { label: "Generic", onClick: () => {} },
                { label: "Combine", onClick: () => {} },
                { sep: true },
                { label: "Python-Fu", onClick: () => {} },
                { label: "Script-Fu", onClick: () => {} }
            ];
        }

        // GIMP/Inkscape - Extensions menu
        if (name === "extensions") {
            return [
                { label: "Repeat Last Extension", sub: "\u2318F", onClick: () => root.sendCombo(["logo"], "f") },
                { label: "Re-Show Last Extension", sub: "\u21e7\u2318F", onClick: () => root.sendCombo(["logo", "shift"], "f") },
                { sep: true },
                { label: "Extensions Gallery", onClick: () => {} }
            ];
        }

        // LibreOffice Impress - Slideshow menu
        if (name === "slideshow") {
            return [
                { label: "Start from First Slide", sub: "F5", onClick: () => root.sendCombo([], "F5") },
                { label: "Start from Current Slide", sub: "\u21e7F5", onClick: () => root.sendCombo(["shift"], "F5") },
                { sep: true },
                { label: "Pause", sub: "N", onClick: () => root.sendCombo([], "n") },
                { label: "End Show", sub: "Esc", onClick: () => root.sendCombo([], "Escape") },
                { sep: true },
                { label: "Slide Show Settings\u2026", onClick: () => {} },
                { label: "Custom Animation", onClick: () => {} },
                { label: "Slide Transition", onClick: () => {} }
            ];
        }

        // Kate - Project menu
        if (name === "project") {
            return [
                { label: "Open Project\u2026", onClick: () => {} },
                { label: "Recent Projects", onClick: () => {} },
                { sep: true },
                { label: "Project Options\u2026", onClick: () => {} },
                { label: "Close Project", onClick: () => {} }
            ];
        }

        // Kate - Session menu
        if (name === "session") {
            return [
                { label: "New Session", sub: "\u21e7\u2318N", onClick: () => root.sendCombo(["logo", "shift"], "n") },
                { label: "Open Session\u2026", sub: "\u2325\u2318\u21e7O", onClick: () => root.sendCombo(["logo", "alt", "shift"], "o") },
                { label: "Save Session\u2026", sub: "\u2325\u2318\u21e7S", onClick: () => root.sendCombo(["logo", "alt", "shift"], "s") },
                { sep: true },
                { label: "Quick Open Session\u2026", sub: "\u2325\u2318\u21e7Q", onClick: () => root.sendCombo(["logo", "alt", "shift"], "q") },
                { sep: true },
                { label: "Delete Session\u2026", onClick: () => {} }
            ];
        }

        return [];
    }

    function anchor(popup, item) {
        const pos = item.mapToItem(null, item.width / 2, item.height);
        popup.relativeX = Math.max(6, Math.min(root.width - popup.width - 6, pos.x - popup.width / 2));
        popup.relativeY = Appearance.barHeight + 8;
    }

    function run(cmd) {
        _launcher.command = ["bash", "-c", "setsid -f " + cmd + " >/dev/null 2>&1"];
        _launcher.running = true;
    }
    Process {
        id: _launcher; running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() { root.closeAllMenus(); }
    }
    Connections {
        target: ShellController
        function onSpotlightOpenChanged() { if (ShellController.spotlightOpen) root.closeAllMenus(); }
        function onControlCenterOpenChanged() { if (ShellController.controlCenterOpen) root.closeAllMenus(); }
        function onOpenRequested(name) { if (name === "closeall") root.closeAllMenus(); }
    }
    Connections {
        target: root
        function syncGrab() {
            const mine = [appleMenu, wifiPopup, batteryPopup, menuPopup];
            const list = GlobalFocusGrab.dismissable.filter(w => mine.indexOf(w) === -1);
            if (root.appleOpen) list.push(appleMenu);
            if (root.wifiOpen) list.push(wifiPopup);
            if (root.batteryOpen) list.push(batteryPopup);
            if (root.openMenu !== "") list.push(menuPopup);
            GlobalFocusGrab.dismissable = list;
        }
        function onAppleOpenChanged() { syncGrab(); }
        function onWifiOpenChanged() { syncGrab(); }
        function onBatteryOpenChanged() { syncGrab(); }
        function onOpenMenuChanged() { syncGrab(); }
    }

    component PopItem: Rectangle {
        id: pit
        property string label: ""
        property string sub: ""
        property bool checked: false
        property var onClick: null
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 6
        color: "transparent"
        Text {
            anchors.left: parent.left; anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: pit.label
            font { family: Appearance.fontFamily; pixelSize: 13 }
            color: root.barFg
        }
        Text {
            visible: !pit.checked
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: pit.sub
            font { family: Appearance.fontFamily; pixelSize: 12 }
            color: root.barFgDim
        }
        Text {
            visible: pit.checked
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "\u2713"
            font { family: Appearance.fontFamily; pixelSize: 13 }
            color: root.barFg
        }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true
            onEntered: pit.color = Appearance.menuHighlight
            onExited: pit.color = "transparent"
            onClicked: { if (pit.onClick) pit.onClick(); }
        }
    }

    component PopSep: Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 1
        Layout.topMargin: 4; Layout.bottomMargin: 4
        color: Qt.rgba(1, 1, 1, 0.12)
    }

    component PopSlider: Item {
        id: psl
        property real value: 0
        signal moved(real v)
        implicitHeight: 20
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6
            radius: 3; color: Qt.rgba(255, 255, 255, 0.16)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(height, psl.value * (parent.width - h.width)) + h.width
                height: parent.height - 2; radius: height / 2; color: "#315bdc"
            }
            Rectangle {
                id: h
                x: psl.value * (parent.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: psl.value > 0 ? 16 : 6; height: parent.height - 2
                radius: width / 2; color: "#f6f6f6"; border.color: "#bdbebf"; border.width: 1
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }
        MouseArea {
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            function ap(mx) { const f = Math.max(0, Math.min(1, mx / width)); psl.moved(f); }
            onPressed: (m) => ap(m.x)
            onPositionChanged: (m) => { if (pressed) ap(m.x); }
        }
    }

    // Background click to close menus
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeAllMenus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6; anchors.rightMargin: 8
        spacing: 2

        // ---- Apple ----
        Item {
            id: appleButton
            Layout.preferredWidth: 34; Layout.preferredHeight: parent.height
            Rectangle { id: appleButtonBg; anchors.fill: parent; radius: 5; color: "transparent" }
            Text {
                anchors.centerIn: parent; text: "\uF8FF"
                font { family: Appearance.fontFamily; pixelSize: 22 }
                color: root.barFg
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: appleButtonBg.color = root.barHover; onExited: appleButtonBg.color = "transparent"
                onClicked: { if (root.appleOpen) { root.closeAllMenus(); } else { root.openOne("apple"); } }
            }
        }

        Text {
            Layout.leftMargin: 6; Layout.rightMargin: 8
            text: root.activeAppName
            font { family: Appearance.fontFamily; pixelSize: 14; weight: Font.DemiBold }
            color: root.barFg; verticalAlignment: Text.AlignVCenter
        }

        Repeater {
            model: root.activeMenus
            delegate: Item {
                id: mb
                Layout.preferredHeight: parent.height; Layout.preferredWidth: txt.width + 16
                Rectangle { id: mBg; anchors.fill: parent; radius: 5; color: "transparent" }
                Text {
                    id: txt; anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    font { family: Appearance.fontFamily; pixelSize: 14 }
                    color: root.barFg
                }
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: mBg.color = root.barHover; onExited: mBg.color = "transparent"
                    onClicked: {
                        const nm = modelData.toLowerCase();
                        if (root.openMenu === nm) root.closeAllMenus();
                        else { root.anchor(menuPopup, mb); root.openOne(nm); }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }

        // ---- Right side (left->right: Tray -> Recording -> Mic -> Battery -> Keyboard -> WiFi -> Spotlight -> CC -> Clock) ----

        // ---- System Tray (eqsh) ----
        Item {
            id: systemTrayHost
            visible: Appearance.menubarTray
            Layout.leftMargin: 4
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: eqshTray.visible ? eqshTray.implicitWidth : 0
            Eq.SystemTray {
                id: eqshTray
                height: Appearance.barHeight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ---- Screen Recording / Sharing indicator (purple) ----
        Item {
            id: recordItem
            Layout.preferredWidth: 30; Layout.preferredHeight: parent.height
            property bool recording: false

            Timer { interval: 2000; running: true; repeat: true; onTriggered: _recCheckProc.running = true }
            Process {
                id: _recCheckProc; running: false
                command: ["bash", "-c", "hyprctl clients -j 2>/dev/null | python3 -c \"import sys,json\ntry:\n d=json.load(sys.stdin)\n for c in d:\n  t=(c.get('title','')+' '+c.get('class','')).lower()\n  if any(k in t for k in ['obs','screen','record','share','cast','screencode']): print('1'); break\n else: print('0')\nexcept: print('0')\" 2>/dev/null"]
                stdout: StdioCollector {
                    onStreamFinished: recordItem.recording = text.trim() === "1"
                }
            }

            visible: recordItem.recording
            Rectangle {
                anchors.fill: parent; radius: 7
                color: "#bf5af2"
            }
            Canvas {
                anchors.centerIn: parent; width: 16; height: 16
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.fillStyle = "#ffffff"
                    ctx.beginPath()
                    ctx.roundedRect(4, 0.5, 5, 8, 2.5, 2.5)
                    ctx.fill()
                    ctx.fillRect(6, 8.5, 1, 2.5)
                    ctx.fillRect(3, 11, 5, 1)
                    ctx.beginPath()
                    ctx.arc(6.5, 7, 4.5, 0, Math.PI)
                    ctx.strokeStyle = "#ffffff"
                    ctx.lineWidth = 1
                    ctx.stroke()
                }
            }
        }

        // ---- Mic indicator (orange) ----
        Item {
            id: micIndicator
            Layout.preferredWidth: 30; Layout.preferredHeight: parent.height
            property bool micActive: false

            Timer { interval: 2000; running: true; repeat: true; onTriggered: _micStatusProc.running = true }
            Process {
                id: _micStatusProc; running: false
                command: ["bash", "-c", "pactl list sources 2>/dev/null | grep -c 'RUNNING' || echo 0"]
                stdout: StdioCollector { onStreamFinished: micIndicator.micActive = parseInt(text.trim()) > 0 }
            }

            visible: micIndicator.micActive
            Rectangle {
                anchors.fill: parent; radius: 7
                color: "#ff9500"
            }
            Canvas {
                anchors.centerIn: parent; width: 16; height: 16
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.fillStyle = "#ffffff"
                    ctx.beginPath()
                    ctx.roundedRect(4, 0.5, 5, 8, 2.5, 2.5)
                    ctx.fill()
                    ctx.fillRect(6, 8.5, 1, 2.5)
                    ctx.fillRect(3, 11, 5, 1)
                    ctx.beginPath()
                    ctx.arc(6.5, 7, 4.5, 0, Math.PI)
                    ctx.strokeStyle = "#ffffff"
                    ctx.lineWidth = 1
                    ctx.stroke()
                }
            }
        }

        // ---- Battery ----
        Item {
            id: batteryItem
            visible: Battery.available && Appearance.menubarBattery
            Layout.preferredWidth: 50; Layout.preferredHeight: parent.height
            Rectangle { id: batteryBg; anchors.fill: parent; radius: 5; color: "transparent" }
            Image {
                anchors.centerIn: parent; width: 22; height: 22
                source: {
                    var p = Battery.percentage * 100;
                    if (Battery.isCharging) {
                        if (p <= 20) return Qt.resolvedUrl("../../assets/icons/tb-battery-low-charging.svg");
                        return Qt.resolvedUrl("../../assets/icons/tb-battery-charging.svg");
                    }
                    if (Battery.isFull || p > 95) return Qt.resolvedUrl("../../assets/icons/tb-battery-charged.svg");
                    if (p <= 20) return Qt.resolvedUrl("../../assets/icons/tb-battery-low.svg");
                    if (p <= 50) return Qt.resolvedUrl("../../assets/icons/tb-battery-good.svg");
                    return Qt.resolvedUrl("../../assets/icons/tb-battery-full.svg");
                }
                sourceSize: Qt.size(22, 22)
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: batteryBg.color = root.barHover; onExited: batteryBg.color = "transparent"
                onClicked: { root.anchor(batteryPopup, batteryItem); root.openOne(root.batteryOpen ? "none" : "battery"); }
            }
        }

        // ---- Keyboard Language (after battery) ----
        Item {
            id: kbdItem
            visible: true
            Layout.preferredWidth: 32; Layout.preferredHeight: parent.height
            property bool isAr: false
            property bool switching: false

            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: if (!kbdItem.switching) _kbdLayoutProc.running = true
            }
            Process {
                id: _kbdLayoutProc; running: false
                command: ["bash", "-c", "hyprctl devices -j 2>/dev/null | python3 -c \"import sys,json\ntry:\n kb=json.load(sys.stdin).get('keyboards',[])\n km=kb[0].get('active_keymap','') if kb else ''\n print('ar' if 'Arab' in km or 'ar' in km.lower() else 'us')\nexcept: print('us')\""]
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (!kbdItem.switching)
                            kbdItem.isAr = text.trim() === "ar"
                    }
                }
            }

            // EN: exact SVG from input-caps-on.svg (white, no bg)
            Image {
                anchors.centerIn: parent; width: 26; height: 26
                visible: !kbdItem.isAr
                source: Qt.resolvedUrl("../../assets/icons/tb-input-caps-on.svg")
                sourceSize: Qt.size(26, 26)
            }

            // AR: ع text with white bg
            Rectangle {
                anchors.centerIn: parent
                visible: kbdItem.isAr
                width: 28; height: 22; radius: 5
                color: "#ffffff"
            }
            Text {
                anchors.centerIn: parent
                visible: kbdItem.isAr
                text: "\u0639"
                font { family: Appearance.fontFamily; pixelSize: 16; weight: Font.Bold }
                color: "#000000"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    kbdItem.switching = true
                    kbdItem.isAr = !kbdItem.isAr
                    if (kbdItem.isAr) {
                        root.run("setxkbmap -layout ar -option grp:alt_shift_toggle")
                    } else {
                        root.run("setxkbmap -layout us -option grp:alt_shift_toggle")
                    }
                    _resetSwitching.start()
                }
            }
            Timer { id: _resetSwitching; interval: 1000; onTriggered: kbdItem.switching = false }
        }

        // ---- Wi-Fi (eqsh icon) ----
        Item {
            id: wifiItem
            visible: Appearance.menubarWifi
            Layout.preferredWidth: 30; Layout.preferredHeight: parent.height
            readonly property string signalIcon: {
                if (!Network.wifiOn) return "0";
                const s = (typeof NetworkManager !== "undefined" && NetworkManager.active)
                    ? NetworkManager.active.strength : 100;
                return s > 90 ? "100" : s > 66 ? "66" : s > 33 ? "33" : "0";
            }
            Rectangle { id: wifiBg; anchors.fill: parent; radius: 5; color: "transparent" }
            VectorImage {
                anchors.centerIn: parent; width: 24; height: 24
                preferredRendererType: VectorImage.CurveRenderer
                source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/wifi/nm-signal-" + wifiItem.signalIcon + "-symbolic.svg")
                opacity: Network.wifiOn ? 1 : 0.45
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: wifiBg.color = root.barHover; onExited: wifiBg.color = "transparent"
                onClicked: { root.anchor(wifiPopup, wifiItem); root.openOne(root.wifiOpen ? "none" : "wifi"); }
            }
        }

        // ---- Spotlight (eqsh icon) ----
        Item {
            id: spotItem
            visible: Appearance.menubarSpotlight
            Layout.preferredWidth: 30; Layout.preferredHeight: parent.height
            Rectangle { id: spotlightBg; anchors.fill: parent; radius: 5; color: "transparent" }
            VectorImage {
                anchors.centerIn: parent; width: 19; height: 19
                preferredRendererType: VectorImage.CurveRenderer
                source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/search.svg")
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: spotlightBg.color = root.barHover; onExited: spotlightBg.color = "transparent"
                onClicked: ShellController.toggle("spotlight")
            }
        }

        // ---- Control Center (eqsh icon) ----
        Item {
            id: ccItem
            visible: Appearance.menubarControlCenter
            Layout.preferredWidth: 30; Layout.preferredHeight: parent.height
            Rectangle { id: controlBg; anchors.fill: parent; radius: 5; color: "transparent" }
            VectorImage {
                anchors.centerIn: parent; width: 24; height: 24
                preferredRendererType: VectorImage.CurveRenderer
                source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/control-center.svg")
            }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: controlBg.color = root.barHover; onExited: controlBg.color = "transparent"
                onClicked: ShellController.toggle("controlcenter")
            }
        }

        // ---- Clock (rightmost) ----
        Text {
            Layout.preferredWidth: clockMetrics.width + 12; Layout.preferredHeight: parent.height
            horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
            text: Time.full
            font { family: Appearance.fontFamily; pixelSize: 14; weight: Font.DemiBold }
            visible: Appearance.menubarClock
            color: root.barFg
            TextMetrics { id: clockMetrics; text: Time.full; font { family: Appearance.fontFamily; pixelSize: 14; weight: Font.DemiBold } }
            MouseArea {
                anchors.fill: parent; hoverEnabled: true
                onEntered: parent.color = "#315bdc"; onExited: parent.color = root.barFg
                onClicked: ShellController.toggle("notifications")
            }
        }
    }

    // =================== POPOVERS ===================

    PopupWindow {
        id: wifiPopup
        parentWindow: root; screen: Quickshell.screens[0]
        implicitWidth: 280; implicitHeight: 340; visible: root.wifiOpen; color: "transparent"
        Rectangle {
            anchors.fill: parent; radius: 12
            color: Qt.rgba(0.18, 0.18, 0.22, 0.45)
            border.color: Appearance.menuBorder; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 2

                // Header: Wi-Fi + toggle
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Wi\u2011Fi"
                        font { family: Appearance.fontFamily; pixelSize: 15; weight: Font.Bold }
                        color: root.barFg; Layout.fillWidth: true
                    }
                    // Blue toggle switch
                    Rectangle {
                        width: 36; height: 20; radius: 10
                        color: Network.wifiOn ? "#007aff" : Qt.rgba(1, 1, 1, 0.3)
                        Layout.alignment: Qt.AlignVCenter
                        Rectangle {
                            x: Network.wifiOn ? parent.width - 18 : 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16; radius: 8; color: "#ffffff"
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Network.toggleWifi()
                        }
                    }
                }

                PopSep {}

                // Privacy Warning
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 28
                    Text {
                        text: "Privacy Warning\u2026"
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.barFg; Layout.fillWidth: true
                    }
                    Text {
                        text: "\u26A0"
                        font { family: Appearance.fontFamily; pixelSize: 14 }
                        color: "#ff9f0a"
                    }
                }

                PopSep {}

                // Known Network header
                Text {
                    text: "Known Network"
                    font { family: Appearance.fontFamily; pixelSize: 12; weight: Font.DemiBold }
                    color: root.barFgDim; Layout.fillWidth: true; Layout.topMargin: 2
                }

                // Current connected network
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 28
                    spacing: 8
                    // Blue WiFi icon
                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: "#007aff"
                        Layout.alignment: Qt.AlignVCenter
                        Image {
                            anchors.centerIn: parent; width: 14; height: 14
                            source: Qt.resolvedUrl("../../assets/icons/tb_network-wireless-100.svg")
                            sourceSize: Qt.size(14, 14)
                        }
                    }
                    Text {
                        text: Network.wifiSsid || "Unknown"
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.barFg; Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "\uD83D\uDD12"
                        font { pixelSize: 12 }
                        color: root.barFgDim
                    }
                }

                PopSep {}

                // Other Networks
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 28
                    Text {
                        text: "Other Networks"
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.barFg; Layout.fillWidth: true
                    }
                    Text {
                        text: "\u25B6"
                        font { family: Appearance.fontFamily; pixelSize: 10 }
                        color: root.barFgDim
                    }
                }

                PopSep {}

                // Wi-Fi Settings
                PopItem {
                    label: "Wi\u2011Fi Settings\u2026"
                    onClick: () => { root.wifiOpen = false; root.run("nm-connection-editor"); }
                }
            }
        }
    }

    // ---- Battery popup ----
    PopupWindow {
        id: batteryPopup
        parentWindow: root; screen: Quickshell.screens[0]
        implicitWidth: 280; implicitHeight: 360; visible: root.batteryOpen; color: "transparent"
        property real pct: Battery.percentage
        property bool charging: Battery.isCharging
        property bool full: Battery.isFull
        readonly property string pctText: Math.round(pct * 100) + "%"
        readonly property string holdText: {
            if (full) return "Fully Charged";
            if (charging) return "Charging On Hold";
            return "On Battery";
        }
        readonly property string sourceText: {
            if (charging || full) return "Power Adapter";
            return "Battery";
        }
        Rectangle {
            anchors.fill: parent; radius: 12
            color: Qt.rgba(0.18, 0.18, 0.22, 0.45)
            border.color: Appearance.menuBorder; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 2

                // Header: "Battery" + "On Hold: XX%"
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Battery"
                        font { family: Appearance.fontFamily; pixelSize: 15; weight: Font.Bold }
                        color: root.barFg; Layout.fillWidth: true
                    }
                    Text {
                        text: batteryPopup.holdText
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.barFgDim
                    }
                }

                // Power Source: Power Adapter
                Text {
                    text: "Power Source: " + batteryPopup.sourceText
                    font { family: Appearance.fontFamily; pixelSize: 13 }
                    color: root.barFg; Layout.fillWidth: true; Layout.topMargin: 4
                }

                // Charging On Hold / Charging / On Battery
                Text {
                    text: batteryPopup.holdText
                    font { family: Appearance.fontFamily; pixelSize: 13 }
                    color: root.barFg; Layout.fillWidth: true
                }

                PopSep {}

                // Charge to Full Now
                PopItem {
                    label: "Charge to Full Now"
                    onClick: () => root.run("echo force > /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null || true")
                }

                PopSep {}

                // Energy Mode header
                Text {
                    text: "Energy Mode"
                    font { family: Appearance.fontFamily; pixelSize: 13; weight: Font.DemiBold }
                    color: root.barFgDim; Layout.fillWidth: true; Layout.topMargin: 2
                }

                // Low Power toggle (always on - performance mode)
                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: 28
                    Image {
                        width: 16; height: 16
                        source: Qt.resolvedUrl("../../assets/icons/tb-battery-good.svg")
                        sourceSize: Qt.size(16, 16)
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "Low Power"
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.barFg; Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 36; height: 20; radius: 10
                        color: "#30d158"
                        Layout.alignment: Qt.AlignVCenter
                        Rectangle {
                            x: 18; anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16; radius: 8; color: "#ffffff"
                        }
                    }
                }

                PopSep {}

                // No Apps Using Significant Energy
                Text {
                    text: "No Apps Using Significant Energy"
                    font { family: Appearance.fontFamily; pixelSize: 12 }
                    color: root.barFgDim; Layout.fillWidth: true; Layout.topMargin: 2
                }

                PopSep {}

                // Battery Settings
                PopItem {
                    label: "Battery Settings\u2026"
                    onClick: () => { root.batteryOpen = false; Apps.launch("pearos-settings"); }
                }
            }
        }
    }

    // ---- Apple menu (real macOS: only 3 items) ----
    PopupWindow {
        id: appleMenu
        parentWindow: root; screen: Quickshell.screens[0]
        relativeX: 2; relativeY: Appearance.barHeight + 8
        implicitWidth: 232; implicitHeight: 370; visible: root.appleOpen; color: "transparent"
        Rectangle {
            anchors.fill: parent; radius: 12; 
            color: Qt.rgba(0.18, 0.18, 0.22, 0.45) // خلفية شفافة
            border.color: Appearance.menuBorder; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 5; spacing: 1
                // ... بقية المحتوى
                component AMItem: Rectangle {
                    id: ai; property string label: ""; property string sublabel: ""; property url icon: ""; property var onClick: null
                    Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 6; color: "transparent"
                    VectorImage {
                        visible: ai.icon.toString() !== ""
                        width: 16; height: 16
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors.left: parent.left; anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        source: ai.icon
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: ai.icon.toString() !== "" ? 31 : 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: ai.label
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.barFg
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: ai.sublabel
                        font { family: Appearance.fontFamily; pixelSize: 12 }
                        color: root.barFgDim
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: ai.color = Appearance.menuHighlight; onExited: ai.color = "transparent"; onClicked: { root.appleOpen = false; if (ai.onClick) ai.onClick(); } }
                }
                component ASep: Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.topMargin: 4; Layout.bottomMargin: 4; color: Qt.rgba(1, 1, 1, 0.12) }
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/icon.svg"); label: "About This Mac"; onClick: () => ShellController.openAbout() }
                ASep {}
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/settings.svg"); label: "System Settings…"; onClick: () => Apps.launch("pearos-settings") }
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/store.svg"); label: "App Store…"; onClick: () => Apps.launch("pearos-appstore") }
                ASep {}
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/clock.svg"); label: "Recent Items"; sublabel: "▶" }
                ASep {}
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/quit.svg"); label: "Force Quit..."; onClick: () => ShellController.openForceQuit() }
                ASep {}
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/sleep.svg"); label: "Sleep"; onClick: () => ShellController.action("sleep") }
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/arrow-counterclockwise.svg"); label: "Restart..."; onClick: () => ShellController.requestAction("restart") }
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/power.svg"); label: "Shut Down..."; onClick: () => ShellController.requestAction("shutdown") }
                ASep {}
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dropdown/lock.svg"); label: "Lock Screen"; sublabel: "⌃⌘Q"; onClick: () => ShellController.action("lock") }
                AMItem { icon: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/arrow-right.svg"); label: "Log Out Revo..."; sublabel: "⇧⌘Q"; onClick: () => ShellController.requestAction("logout") }
            }
        }
    }

    // ---- Generic menubar dropdowns (File/Edit/View/Go/Window/Help) ----
    PopupWindow {
        id: menuPopup
        parentWindow: root; screen: Quickshell.screens[0]
        implicitWidth: 280; visible: root.openMenu !== ""; color: "transparent"
        implicitHeight: Math.min(600, (root.menuItems(root.openMenu).length * 29) + 24)
        Rectangle {
            anchors.fill: parent; radius: 12; 
            color: Qt.rgba(0.18, 0.18, 0.22, 0.45) // خلفية شفافة
            border.color: Appearance.menuBorder; border.width: 1
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 6; spacing: 1
                // ... بقية المحتوى
                Repeater {
                    model: root.menuItems(root.openMenu)
                    delegate: Item {
                        Layout.fillWidth: true
                        implicitHeight: modelData.sep ? 9 : 28
                        Rectangle {
                            visible: modelData.sep === true
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            height: 1; color: Qt.rgba(1, 1, 1, 0.12)
                        }
                        Rectangle {
                            visible: modelData.sep !== true
                            anchors.fill: parent; radius: 6
                            color: mArea.containsMouse ? Appearance.menuHighlight : "transparent"
                        }
                        Text {
                            visible: modelData.sep !== true
                            anchors.left: parent.left; anchors.leftMargin: 10
                            width: parent.width - 90
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label || ""
                            font { family: Appearance.fontFamily; pixelSize: 13 }
                            color: root.barFg; elide: Text.ElideRight
                        }
                        Text {
                            visible: modelData.sep !== true && !!modelData.sub
                            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.sub || ""
                            font { family: Appearance.fontFamily; pixelSize: 12 }
                            color: root.barFgDim
                        }
                        MouseArea {
                            id: mArea
                            visible: !modelData.sep
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: { if (modelData.onClick) modelData.onClick(); root.closeAllMenus(); }
                        }
                    }
                }
            }
        }
    }
}
