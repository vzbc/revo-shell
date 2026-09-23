pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tells non-git-savvy users when zesis itself has upstream changes waiting,
// and offers a one-click fast-forward pull when it's safe to do so
// (working tree clean). If local files were edited, we never touch them
// automatically, that's a go ask someone situation. Let's raise hell for that
// guy haha...
//
// Checks/pulls over the repo's anonymous HTTPS URL (derived from `origin`)
// We don't even bother with an SHH remote. At that point, it's probably
// better for the person to act themselves anyway.
Singleton {
    id: root

    readonly property string repoPath: Quickshell.shellDir

    // "unknown" | "checking" | "upToDate" | "updatable" | "blocked" | "offline" | "noGit" | "noOrigin" | "notGitRepo" | "pulling" | "pullFailed"
    property string status: "unknown"
    property int dirtyCount: 0
    property var lastCheckedAt: null

    // Some deployments (a Nix store path, an Arch/AUR (RIP) package, a plain
    // tarball extract) run zesis from somewhere that was never git cloned
    // at all. There's nothing to check or pull, so we shouldn't do shit.
    property bool _repoChecked: false
    property bool _repoIsGit: false

    signal pullSucceeded

    readonly property bool showBadge: status === "updatable" || status === "blocked" || status === "pulling" || status === "pullFailed"

    readonly property var _env: ({
            "GIT_TERMINAL_PROMPT": "0"
        })

    // Claude Code wrote this bash line, see that sed hell?
    readonly property string _httpsUrlExpr: `HTTPS_URL=$(git -C "$REPO" remote get-url origin 2>/dev/null | sed -E 's#^git@([^:]+):#https://\\1/#; s#^ssh://git@#https://#')`

    readonly property string _checkScript: `
        REPO="$1"
        command -v git >/dev/null 2>&1 || { echo "ERR|nogit"; exit 0; }
        ` + _httpsUrlExpr + `
        if [ -z "$HTTPS_URL" ]; then echo "ERR|noorigin"; exit 0; fi
        BRANCH=$(git -C "$REPO" rev-parse --abbrev-ref HEAD)
        LOCAL_SHA=$(git -C "$REPO" rev-parse HEAD)
        REMOTE_SHA=$(git ls-remote --heads "$HTTPS_URL" "$BRANCH" 2>/dev/null | cut -f1)
        if [ -z "$REMOTE_SHA" ]; then echo "ERR|offline"; exit 0; fi
        DIRTY=$(git -C "$REPO" status --porcelain | wc -l)
        if [ "$LOCAL_SHA" = "$REMOTE_SHA" ]; then
        echo "OK|0|$DIRTY"
        else
        echo "OK|1|$DIRTY"
        fi
    `

    readonly property string _pullScript: `
        REPO="$1"
    ` + _httpsUrlExpr + `
        if [ -z "$HTTPS_URL" ]; then exit 1; fi
        BRANCH=$(git -C "$REPO" rev-parse --abbrev-ref HEAD)
        git -c pull.rebase=false -C "$REPO" pull --ff-only --quiet "$HTTPS_URL" "$BRANCH"
    `

    function checkNow() {
        if (root._repoChecked && !root._repoIsGit)
            return;
        if (root.status === "checking" || root.status === "pulling")
            return;
        root.status = "checking";
        checkProc.running = false;
        checkProc.running = true;
    }

    function updateNow() {
        if (root.status !== "updatable")
            return;
        root.status = "pulling";
        pullProc.running = false;
        pullProc.running = true;
    }

    Component.onCompleted: repoDetectProc.running = true

    // One-shot. Is repoPath even a git working tree? Only once this
    // comes back true do we arm the startup/periodic timers.
    Process {
        id: repoDetectProc
        command: ["sh", "-c", `command -v git >/dev/null 2>&1 || exit 2; git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1`, "sh", root.repoPath]
        onExited: exitCode => {
            root._repoChecked = true;
            if (exitCode === 2) {
                root._repoIsGit = false;
                root.status = "noGit";
                return;
            }
            root._repoIsGit = exitCode === 0;
            if (root._repoIsGit)
                startupTimer.start();
            else
                root.status = "notGitRepo";
        }
    }

    Timer {
        id: startupTimer
        interval: 15000
        onTriggered: root.checkNow()
    }

    Timer {
        interval: 30 * 60 * 1000
        running: root._repoIsGit
        repeat: true
        onTriggered: root.checkNow()
    }

    Process {
        id: checkProc
        command: ["sh", "-c", root._checkScript, "sh", root.repoPath]
        environment: root._env
        stdout: SplitParser {
            onRead: line => {
                root.lastCheckedAt = new Date();
                var parts = line.trim().split("|");
                if (parts[0] !== "OK") {
                    root.status = parts[1] === "nogit" ? "noGit" : (parts[1] === "noorigin" ? "noOrigin" : "offline");
                    return;
                }
                var behind = parseInt(parts[1]) || 0;
                var dirty = parseInt(parts[2]) || 0;
                root.dirtyCount = dirty;
                if (behind === 0)
                    root.status = "upToDate";
                else if (dirty === 0)
                    root.status = "updatable";
                else
                    root.status = "blocked";
            }
        }
        // If the process never produces a recognized line at all (`sh`
        // itself is maybe missing so nothing could even run the `git` check),
        // don't leave status stuck on "checking" forever.
        onExited: exitCode => {
            if (root.status === "checking")
                root.status = "offline";
        }
    }

    Process {
        id: pullProc
        command: ["sh", "-c", root._pullScript, "sh", root.repoPath]
        environment: root._env
        onExited: exitCode => {
            if (exitCode === 0) {
                root.status = "upToDate";
                root.dirtyCount = 0;
                root.pullSucceeded();
            } else {
                root.status = "pullFailed";
            }
        }
    }
}
