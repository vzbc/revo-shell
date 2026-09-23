pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Singleton {
    id: root

    property bool isNixOS: false
    property bool usesHjem: false
    property bool scanning: false
    property int pureCount: 0
    property int dirtyCount: 0
    property var dirtyFiles: []
    property var dirtyCounts: ({})
    property var ignoredApps: []

    readonly property string _cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/zesis"
    readonly property string _cachePath: _cacheDir + "/nix-purity-ignore.json"

    readonly property var topOffenders: {
        var entries = Object.entries(dirtyCounts);
        entries.sort((a, b) => b[1] - a[1]);
        return entries.slice(0, 8);
    }

    readonly property real rawPurity: {
        var total = pureCount + dirtyCount;
        return total > 0 ? pureCount / total : 0;
    }

    // Boosted purity: +10% for hjem users. Capped at 1.0 for bar/tier; displayPurity can exceed 1.0.
    readonly property real purity: Math.min(1.0, rawPurity + (usesHjem ? 0.1 : 0))
    readonly property real displayPurity: rawPurity + (usesHjem ? 0.1 : 0)

    readonly property int tierIndex: {
        var p = purity * 100;
        if (p >= 100)
            return 8;
        if (p >= 98)
            return 7;
        if (p >= 92)
            return 6;
        if (p >= 80)
            return 5;
        if (p >= 65)
            return 4;
        if (p >= 45)
            return 3;
        if (p >= 25)
            return 2;
        if (p >= 10)
            return 1;
        return 0;
    }

    readonly property var tiers: [
        {
            greek: "Archikakodaímōn",
            title: I18n.t("nixpurity.tier0Title"),
            taunt: I18n.t("nixpurity.tier0Taunt")
        },
        {
            greek: "Bárbaros",
            title: I18n.t("nixpurity.tier1Title"),
            taunt: I18n.t("nixpurity.tier1Taunt")
        },
        {
            greek: "Neóphytos",
            title: I18n.t("nixpurity.tier2Title"),
            taunt: I18n.t("nixpurity.tier2Taunt")
        },
        {
            greek: "Mathētḗs",
            title: I18n.t("nixpurity.tier3Title"),
            taunt: I18n.t("nixpurity.tier3Taunt")
        },
        {
            greek: "Philósophos",
            title: I18n.t("nixpurity.tier4Title"),
            taunt: I18n.t("nixpurity.tier4Taunt")
        },
        {
            greek: "Sophós",
            title: I18n.t("nixpurity.tier5Title"),
            taunt: I18n.t("nixpurity.tier5Taunt")
        },
        {
            greek: "Mýstēs",
            title: I18n.t("nixpurity.tier6Title"),
            taunt: I18n.t("nixpurity.tier6Taunt")
        },
        {
            greek: "ho Theatḗs",
            title: I18n.t("nixpurity.tier7Title"),
            taunt: I18n.t("nixpurity.tier7Taunt")
        },
        {
            greek: "Hyperoúsios",
            title: I18n.t("nixpurity.tier8Title"),
            taunt: I18n.t("nixpurity.tier8Taunt")
        }
    ]

    readonly property var currentTier: tiers[tierIndex]

    Component.onCompleted: {
        checkNixOSProc.running = true;
    }

    function ignore(app) {
        if (root.ignoredApps.indexOf(app) >= 0)
            return;
        root.ignoredApps = [...root.ignoredApps, app];
        _saveIgnoreList();
        root.scan();
    }

    function unignore(app) {
        root.ignoredApps = root.ignoredApps.filter(a => a !== app);
        _saveIgnoreList();
        root.scan();
    }

    function _saveIgnoreList() {
        var json = JSON.stringify({
            ignored: root.ignoredApps
        });
        var esc = s => s.replace(/'/g, "'\\''");
        saveProc.command = ["sh", "-c", "mkdir -p '" + esc(root._cacheDir) + "'" + " && printf '%s' '" + esc(json) + "' > '" + esc(root._cachePath) + "'"];
        saveProc.running = false;
        saveProc.running = true;
    }

    function scan() {
        root.scanning = true;
        root.pureCount = 0;
        root.dirtyCount = 0;
        root.dirtyFiles = [];
        root.dirtyCounts = ({});

        var builtIn = ["__pycache__", ".git", "WidevineCdm", "sentry", "addons", "scripts", "Proton", "libvirt",
            // Browsers
            "vivaldi", "opera", "firefox", "thorium", "microsoft-edge", "Ladybird", "BraveSoftware", "chromium", "Chromium", "google-chrome", "google-chrome-beta", "extensions",
            // Electron/GUI apps which are awful
            "Electron", "discord", "vesktop", "slack", "obsidian", "spotify", "VSCodium", "node_modules", "Code", "Code - OSS",
            // Gaming
            "unity3d", "godot", "Epic", "lutris", "heroic", "Valve",
            // System/runtime
            "pulse", "pipewire", "dconf", "ibus", "fcitx", "fcitx5", "session", "autostart",
            // JetBrains
            "JetBrains",
            // Creative apps
            "libreoffice", "GIMP", "Inkscape", "Blender",
            // File managers
            "Thunar", "Nautilus", "dolphin",
            // XDG junk
            "menus"];
        var esc = s => s.replace(/'/g, "'\\''");
        var pruneExpr = builtIn.concat(root.ignoredApps).map(n => "-name '" + esc(n) + "' -prune").join(" -o ");

        scanProc.command = ["sh", "-c", "find \"$HOME/.config\" \\( " + pruneExpr + " \\)" + " -o \\( -type f -o -type l \\) -print 2>/dev/null |" + " while IFS= read -r f; do" + "  if [ -L \"$f\" ]; then" + "    t=$(readlink \"$f\" 2>/dev/null);" + "    case \"$t\" in /nix/store/*) echo P ;; *) echo \"D|$f\" ;; esac;" + "  else" + "    b=\"${f##*/}\";" + "    case \"$b\" in" + "      package.json|manifest.json|package-lock.json|installed.json|imgui.ini|*-data.conf) ;;" + "      *.conf|*.toml|*.yaml|*.yml|*.json|*.ini|*.cfg|*.config" + "|*.sh|*.bash|*.zsh|*.fish|*.lua|*.nix|*.css|*.scss" + "|*.rasi|*.theme|*.py|*.env|*.desktop|*.rules|*.service" + "|*.profile|*.rc|*.kdl|*.dhall|*.ron) echo \"D|$f\" ;;" + "    esac;" + "  fi;" + " done;" + " echo DONE"];
        scanProc.running = false;
        scanProc.running = true;
    }

    Process {
        id: checkNixOSProc
        command: ["test", "-f", "/etc/NIXOS"]
        onExited: code => {
            root.isNixOS = (code === 0);
            if (root.isNixOS)
                checkHjemProc.running = true;
        }
    }

    Process {
        id: checkHjemProc
        command: ["test", "-d", "/var/lib/hjem"]
        onExited: code => {
            root.usesHjem = (code === 0);
            loadIgnoreProc.running = true;
        }
    }

    Process {
        id: loadIgnoreProc
        property string _buf: ""
        command: ["sh", "-c", "cat \"$HOME/.cache/zesis/nix-purity-ignore.json\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => loadIgnoreProc._buf += line
        }
        onExited: _ => {
            try {
                var obj = JSON.parse(loadIgnoreProc._buf);
                root.ignoredApps = obj.ignored || [];
            } catch (e) {
                root.ignoredApps = [];
            }
            root.scan();
        }
    }

    Process {
        id: saveProc
    }

    Process {
        id: scanProc
        command: []
        stdout: SplitParser {
            onRead: line => {
                if (line === "DONE") {
                    root.scanning = false;
                    return;
                }
                if (line === "P") {
                    root.pureCount++;
                    return;
                }
                if (line.startsWith("D|")) {
                    root.dirtyCount++;
                    var home = Quickshell.env("HOME");
                    var fullPath = line.substring(2);
                    var rel = fullPath.startsWith(home + "/.config/") ? fullPath.substring(home.length + 9) : fullPath;
                    var app = rel.split("/")[0];
                    var counts = root.dirtyCounts;
                    counts[app] = (counts[app] || 0) + 1;
                    root.dirtyCounts = Object.assign({}, counts);
                    if (root.dirtyFiles.length < 40)
                        root.dirtyFiles = [...root.dirtyFiles, "~/.config/" + rel];
                }
            }
        }
        onExited: _ => root.scanning = false
    }
}
