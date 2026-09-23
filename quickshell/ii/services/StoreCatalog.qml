pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Data layer for the Windows-11 style Store.
 *
 * Loads the JSON catalogs produced by scripts/store/store_catalog.py,
 * provides local + AUR search, and runs package installations
 * (flatpak / pacman via pkexec, AUR via pkexec + runuser to paru).
 */
Singleton {
    id: root

    readonly property string catalogScript: FileUtils.trimFileProtocol(`${Directories.scriptPath}/store/store_catalog.py`)
    readonly property string aurInstallScript: FileUtils.trimFileProtocol(`${Directories.scriptPath}/store/aur_install.sh`)
    readonly property string cachePath: FileUtils.trimFileProtocol(`${Directories.cache}/waffle-store`)

    property var flathub: []
    property var arch: []
    property var library: []
    property bool ready: false
    property bool generating: false
    property string lastError: ""

    // AUR live search
    property var aurResults: []
    property bool aurBusy: false

    // install state
    property bool installBusy: false
    property string installingId: ""
    property string installLog: ""

    // currently open product page app
    property var currentApp: null

    // browse page preselected source: "all", "flathub", "arch", "aur"
    property string browseSource: "all"

    // active global search query
    property string activeQuery: ""

    signal refreshed()

    // ----------------------------------------------------------- generation
    function ensureCatalog() {
        root.generating = true
        catalogProc.running = true
    }

    Process {
        id: catalogProc
        command: ["python3", root.catalogScript, "catalog", "--cache-dir", root.cachePath]
        stdout: StdioCollector { }
        onExited: (code, status) => {
            root.generating = false
            root.load()
        }
    }

    // --------------------------------------------------------------- loading
    function load() {
        root.ready = false
        root._loaded = 0
        flathubView.reload()
        archView.reload()
        libraryView.reload()
    }

    property int _loaded: 0
    function _markLoaded() {
        root._loaded += 1
        if (root._loaded >= 3) {
            root.ready = true
            root.refreshed()
        }
    }

    FileView {
        id: flathubView
        path: Qt.resolvedUrl(`${root.cachePath}/flathub.json`)
        onLoaded: {
            try {
                root.flathub = JSON.parse(flathubView.text())
            } catch (e) {
                root.lastError = "flathub: " + e
            }
            root._markLoaded()
        }
    }

    FileView {
        id: archView
        path: Qt.resolvedUrl(`${root.cachePath}/arch.json`)
        onLoaded: {
            try {
                root.arch = JSON.parse(archView.text())
            } catch (e) {
                root.lastError = "arch: " + e
            }
            root._markLoaded()
        }
    }

    FileView {
        id: libraryView
        path: Qt.resolvedUrl(`${root.cachePath}/library.json`)
        onLoaded: {
            try {
                root.library = JSON.parse(libraryView.text())
            } catch (e) {
                root.lastError = "library: " + e
            }
            root._markLoaded()
        }
    }

    // ------------------------------------------------------------ local search
    function localSearch(query, limit) {
        const q = (query || "").trim().toLowerCase()
        const max = limit || 60
        const out = []
        if (q.length === 0)
            return out
        const matches = (app) =>
            (app.name && app.name.toLowerCase().includes(q)) ||
            (app.summary && app.summary.toLowerCase().includes(q))
        for (const app of root.flathub) {
            if (out.length >= max)
                return out
            if (matches(app))
                out.push(app)
        }
        for (const app of root.arch) {
            if (out.length >= max)
                return out
            if (matches(app))
                out.push(app)
        }
        return out
    }

    // ------------------------------------------------------------------ AUR
    function aurSearch(query) {
        if (!query || query.trim().length < 2) {
            root.aurResults = []
            root.aurBusy = false
            return
        }
        root.aurBusy = true
        aurSearchProc.command = ["python3", root.catalogScript, "search-aur", query.trim()]
        aurSearchProc.running = true
    }

    Process {
        id: aurSearchProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.aurResults = JSON.parse(aurSearchCollector.text.trim() || "[]")
                } catch (e) {
                    root.aurResults = []
                }
                root.aurBusy = false
            }
        }
        onExited: root.aurBusy = false
    }

    // --------------------------------------------------------------- install
    function install(app) {
        if (!app || root.installBusy)
            return false
        root.installingId = app.id
        root.installBusy = true
        root.installLog = ""

        if (app.source === "flathub") {
            installProc.command = ["pkexec", "flatpak", "install", "-y", "flathub", app.id]
        } else if (app.source === "arch") {
            installProc.command = ["pkexec", "pacman", "-S", "--noconfirm", app.id]
        } else if (app.source === "aur") {
            installProc.command = [
                "pkexec", "bash", root.aurInstallScript, app.id, SystemInfo.username
            ]
        } else {
            root.installBusy = false
            return false
        }
        installProc.running = true
        return true
    }

    function isInstalling(app) {
        return root.installBusy && root.installingId === (app ? app.id : "")
    }

    Process {
        id: installProc
        stdout: StdioCollector {
            onStreamFinished: root.installLog += installCollector.text + "\n"
        }
        onExited: (code, status) => {
            root.installBusy = false
            root.installingId = ""
            if (code === 0)
                root.ensureCatalog()
        }
    }
}
