pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// General-purpose org.freedesktop.secrets (Secret Service) state: which CLI
// tool is available, whether the default collection is locked, and whether
// an unlock attempt can actually succeed. Any widget that stores credentials
// in the keyring (Network today, others later) should read this instead of
// probing the keyring itself.
Singleton {
    id: root

    // "" | "secret-tool" | "oo7-cli"
    property string tool: ""
    property bool available: false

    property bool checked: false
    property bool locked: true
    property bool unlocking: false

    // Only meaningful when tool === "oo7-cli": oo7-daemon delegates prompting
    // to an external D-Bus service (org.gnome.keyring.internal.Prompter,
    // implemented by gcr-prompter) and just hangs until timeout if none is
    // registered. gnome-keyring-daemon (secret-tool's usual backend) has no
    // such dependency - confirmed via `strings` on the actual binary, it
    // implements org.freedesktop.Secret.Prompt itself in-process (see
    // gkd-secret-prompt.c) and draws its own dialog directly, so there's no
    // "missing prompter" failure mode possible for that backend at all.
    property bool promptAvailable: true
    property bool promptChecked: false

    property string _collectionPath: ""

    function refresh() {
        root.checked = false;
        root.promptChecked = false;
        _detectToolProc.running = false;
        _detectToolProc.running = true;
    }

    function checkLocked() {
        _resolveCollectionProc.running = false;
        _resolveCollectionProc.running = true;
    }

    function unlock() {
        if (root.tool === "" || root.unlocking)
            return;
        root.unlocking = true;
        _unlockProc.command = root.tool === "oo7-cli" ? ["sh", "-c", "timeout 60 oo7-cli unlock -c login"] : ["sh", "-c", "timeout 60 secret-tool search protocol zesis-keychain-unlock-probe id none 2>/dev/null"];
        _unlockProc.running = false;
        _unlockProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: _detectToolProc
        command: ["sh", "-c", "command -v oo7-cli 2>/dev/null || command -v secret-tool 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var path = data.trim();
                if (path.length > 0)
                    root.tool = path.split("/").pop();
            }
        }
        onExited: code => {
            root.available = (code === 0);
            if (code !== 0)
                return;
            root.checkLocked();
            if (root.tool === "oo7-cli") {
                _promptCheckProc.running = false;
                _promptCheckProc.running = true;
            } else {
                root.promptAvailable = true;
                root.promptChecked = true;
            }
        }
    }

    // Resolve the "default" collection alias to its real object path via the
    // standard Secret Service API, rather than assuming a fixed path, the
    // default collection is named "Login" under oo7-daemon but "login"
    // (lowercase) under classic gnome-keyring, so hardcoding either breaks
    // the other backend.
    Process {
        id: _resolveCollectionProc
        command: ["sh", "-c", "busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service ReadAlias s default 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var m = data.trim().match(/^o\s+"(.+)"$/);
                if (m)
                    root._collectionPath = m[1];
            }
        }
        onExited: code => {
            if (code !== 0 || root._collectionPath === "")
                return;
            _lockCheckProc.command = ["sh", "-c", "busctl --user get-property org.freedesktop.secrets '" + root._collectionPath + "' org.freedesktop.Secret.Collection Locked 2>/dev/null"];
            _lockCheckProc.running = false;
            _lockCheckProc.running = true;
        }
    }

    Process {
        id: _lockCheckProc
        stdout: SplitParser {
            onRead: data => {
                root.locked = data.trim().indexOf("true") >= 0;
                root.checked = true;
            }
        }
    }

    // oo7-daemon actually supports two prompter protocols: this one
    // (org.gnome.keyring.SystemPrompter, via gcr-prompter) and a KDE one
    // (org.kde.secretprompter, via ksecretd), confirmed via `strings` on
    // oo7-daemon's binary. We only ever check for the GNOME one: oo7 gates
    // the KDE path behind an XDG_CURRENT_DESKTOP check (in_plasma_environment())
    // that never passes under Hyprland, so ksecretd being present or absent
    // makes no difference here, oo7 would never call it on this system
    // regardless. If this shell is ever ported to a real Plasma session,
    // this check would need to branch on the desktop environment too.
    Process {
        id: _promptCheckProc
        command: ["sh", "-c", "busctl --user list --activatable 2>/dev/null | grep -q org.gnome.keyring.SystemPrompter && echo yes || echo no"]
        stdout: SplitParser {
            onRead: data => {
                root.promptAvailable = data.trim() === "yes";
                root.promptChecked = true;
            }
        }
    }

    Process {
        id: _unlockProc
        onExited: code => {
            root.unlocking = false;
            root.checkLocked();
        }
    }
}
