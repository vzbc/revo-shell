pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Hyprland

Singleton {
    id: root

    // ── signals (same as before for backward compat) ──────────────
    signal notify(var notification)
    signal discard(int id)

    // ── K4-style state ────────────────────────────────────────────
    property var list: []
    property var latest: null
    property int count: 0
    property bool toastOpen: false

    // recent = reversed tracked list (newest first)
    readonly property var recent: {
        const copy = list.slice()
        copy.reverse()
        return copy
    }

    // ── toast management (from K4 Notifs) ─────────────────────────
    function dismissToast() {
        _toastTimer.stop()
        toastOpen = false
    }

    function holdToast() { _toastTimer.stop() }

    function resumeToast() {
        if (toastOpen) _toastTimer.restart()
    }

    // ── core actions ──────────────────────────────────────────────
    function dismiss(notification) {
        server.closeNotification(notification.id);
        const idx = root.list.indexOf(notification);
        if (idx >= 0) root.list.splice(idx, 1);
        if (root.latest === notification) {
            dismissToast()
            root.latest = null
        }
        root.count = Math.max(0, root.count - 1)
        root.discard(notification.id);
    }

    function clearAll() {
        for (const n of root.list) server.closeNotification(n.id);
        root.list = [];
        dismissToast()
        root.latest = null
        root.count = 0
    }

    function markRead() { count = 0 }

    // ── utility (from K4 Notifs) ──────────────────────────────────
    function iconFor(notification) {
        if (!notification) return "";
        if (notification.image && notification.image.length > 0)
            return notification.image
        const icon = notification.appIcon || "";
        if (icon.length === 0) return ""
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("http")) return icon;
        return Quickshell.iconPath(icon, "image-missing");
    }

    function defaultAction(n) {
        if (!n || !n.actions) return null
        for (let i = 0; i < n.actions.length; ++i) {
            if (n.actions[i].identifier === "default")
                return n.actions[i]
        }
        return null
    }

    function buttons(n) {
        if (!n || !n.actions) return []
        return n.actions.filter(function (a) { return a.identifier !== "default" })
    }

    function activate(n) {
        if (!n) return
        const action = defaultAction(n)
        if (action) {
            action.invoke()
            if (!n.resident) n.dismiss()
            return
        }
        focusApp(n)
    }

    function invokeAction(n, action) {
        if (!action) return
        action.invoke()
        if (n && !n.resident) n.dismiss()
    }

    // ── window matching (from K4 Notifs) ──────────────────────────
    property var pendingMatch: []
    property string pendingPid: ""
    property var pendingNotification: null
    property var destinos: ({})

    readonly property string terminal: "kitty"

    readonly property var aliases: ({
        "claude code": terminal,
        "claude": terminal,
        "codex": terminal
    })

    function _clave(app, cuerpo) {
        return String(app || "").toLowerCase() + "\n" + String(cuerpo || "")
    }

    function apuntarDestino(app, cuerpo, pid) {
        const p = String(pid || "")
        if (p.length === 0) return
        const d = Object.assign({}, destinos)
        d[_clave(app, cuerpo)] = p
        destinos = d
    }

    function olvidarDestino(app, cuerpo) {
        const k = _clave(app, cuerpo)
        if (destinos[k] === undefined) return
        const d = Object.assign({}, destinos)
        delete d[k]
        destinos = d
    }

    function destinoDe(n) {
        if (!n) return ""
        const p = destinos[_clave(n.appName, n.body)]
        return p === undefined ? "" : p
    }

    function clasesDe(n) {
        const raw = (n && n.desktopEntry && n.desktopEntry.length > 0
                     ? n.desktopEntry : (n ? n.appName : "")) || ""
        if (raw.length === 0) return []
        const bajo = raw.toLowerCase()
        if (aliases[bajo] !== undefined)
            return [String(aliases[bajo]).toLowerCase()]
        const salida = [bajo]
        const anotar = function (v) {
            const s = String(v || "").toLowerCase().replace(/\.desktop$/, "")
            if (s.length > 0 && salida.indexOf(s) < 0) salida.push(s)
        }
        const pelado = bajo.replace(/\.desktop$/, "")
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; ++i) {
            const a = apps[i]
            const id = String(a.id || "").toLowerCase().replace(/\.desktop$/, "")
            if (id !== pelado && String(a.name || "").toLowerCase() !== bajo) continue
            anotar(a.startupClass)
            anotar(id)
        }
        return salida
    }

    function focusApp(n) {
        const clases = clasesDe(n)
        if (clases.length === 0) return
        pendingMatch = clases
        pendingPid = destinoDe(n)
        pendingNotification = n
        clientQuery.running = true
    }

    function casa(clases, cls, initial) {
        for (let i = 0; i < clases.length; ++i)
            if (clases[i] === cls || clases[i] === initial) return true
        return false
    }

    function matchAndFocus(json) {
        const clases = pendingMatch
        const n = pendingNotification
        const pid = pendingPid
        pendingMatch = []
        pendingPid = ""
        pendingNotification = null
        if (!clases || clases.length === 0) return
        let list
        try { list = JSON.parse(json) } catch (e) { return }

        const colas = []
        for (let i = 0; i < clases.length; ++i) {
            const k = clases[i]
            const cola = k.indexOf(".") !== -1 ? k.substring(k.lastIndexOf(".") + 1) : k
            if (cola.length > 3 && colas.indexOf(cola) < 0) colas.push(cola)
        }

        let exact = null
        let partial = null
        let porPid = null
        for (let i = 0; i < list.length; ++i) {
            const c = list[i]
            const cls = String(c.class || "").toLowerCase()
            const initial = String(c.initialClass || "").toLowerCase()
            const title = String(c.title || "").toLowerCase()
            const initialTitle = String(c.initialTitle || "").toLowerCase()
            if (pid.length > 0 && String(c.pid) === pid) { porPid = c; break }
            if (casa(clases, cls, initial)) { exact = c; break }
            if (partial === null)
                for (let j = 0; j < colas.length; ++j)
                    if (cls.indexOf(colas[j]) !== -1 || initial.indexOf(colas[j]) !== -1
                        || initialTitle.indexOf(colas[j]) !== -1
                        || title.indexOf(colas[j]) !== -1) { partial = c; break }
        }

        const found = porPid || exact || partial
        if (found) {
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + found.address + '" })')
            if (n && !n.resident) n.dismiss()
            return
        }
        if (n && launchEntry(n)) n.dismiss()
    }

    function launchEntry(n) {
        const id = (n.desktopEntry || "").toLowerCase()
        if (id.length === 0) return false
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; ++i) {
            const app = apps[i]
            const appId = String(app.id || "").toLowerCase()
            if (appId === id || appId === id + ".desktop"
                || appId.replace(/\.desktop$/, "") === id) {
                app.execute()
                return true
            }
        }
        return false
    }

    function descartarDeVentana(t) {
        const d = t && t.lastIpcObject ? t.lastIpcObject : null
        if (!d) return
        const cls = String(d.class || "").toLowerCase()
        const initial = String(d.initialClass || "").toLowerCase()
        if (cls.length === 0 && initial.length === 0) return
        const listCopy = root.list.slice()
        let idas = 0
        for (let i = 0; i < listCopy.length; ++i) {
            if (!casa(clasesDe(listCopy[i]), cls, initial)) continue
            if (latest === listCopy[i]) dismissToast()
            listCopy[i].dismiss()
            ++idas
        }
        if (idas > 0) count = Math.max(0, count - idas)
    }

    function descartarDeApp(app, cuerpo) {
        const quien = String(app || "").toLowerCase()
        if (quien.length === 0) return
        const texto = cuerpo === undefined ? null : String(cuerpo)
        const listCopy = root.list.slice()
        let idas = 0
        for (let i = 0; i < listCopy.length; ++i) {
            const n = listCopy[i]
            if (String(n.appName || "").toLowerCase() !== quien) continue
            if (texto !== null && String(n.body || "") !== texto) continue
            if (latest === n) dismissToast()
            n.dismiss()
            ++idas
        }
        if (idas > 0) count = Math.max(0, count - idas)
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            root.descartarDeVentana(Hyprland.activeToplevel)
        }
    }

    Process {
        id: clientQuery
        command: ["hyprctl", "-j", "clients"]
        stderr: SplitParser {
            onRead: function (l) {
                if (String(l).trim().length > 0)
                    console.warn("notifications:", l)
            }
        }
        stdout: StdioCollector {
            onStreamFinished: root.matchAndFocus(this.text)
        }
    }

    // ── notification server ───────────────────────────────────────
    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true

        onNotification: function (notification) {
            notification.tracked = true;
            root.list.unshift(notification);
            if (root.list.length > 80) root.list.pop();
            root.latest = notification
            root.count += 1
            root.toastOpen = true
            _toastTimer.restart()
            root.notify(notification);
        }
    }

    Timer {
        id: _toastTimer
        interval: 5000
        onTriggered: root.dismissToast()
    }
}
