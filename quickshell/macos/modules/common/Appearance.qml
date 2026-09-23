pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---- live user preferences (read from userconfig.json; shell reloads on change) ----
    property var userCfg: ({})
    FileView {
        id: cfgFile
        path: Qt.resolvedUrl("../../userconfig.json")
        onLoaded: (file) => { try { userCfg = JSON.parse(file.text) } catch (e) { userCfg = {} } }
    }
    function cfgGet(k, d) {
        if (!userCfg || typeof userCfg[k] === "undefined") return d
        return userCfg[k]
    }
    Process { id: cfgWriter; running: false }
    function set(k, v) {
        cfgWriter.command = ["python3", "/home/revo/.config/quickshell/macos/scripts/setcfg.py", k, JSON.stringify(v)]
        cfgWriter.running = true
    }

    readonly property color accent: (userCfg && userCfg.accentColor) ? userCfg.accentColor : "#315bdc"
    readonly property color accentPressed: "#2647ad"
    readonly property color green: "#30d158"
    readonly property color red: "#ff453a"
    readonly property color yellow: "#ffd60a"
    readonly property color orange: "#ff9f0a"

    readonly property color bg: "#1b1b1e"
    readonly property color panelBg: Qt.rgba(0.11, 0.11, 0.13, 0.25)
    readonly property color panelBgGlass: Qt.rgba(0.10, 0.10, 0.12, 0.45)
    readonly property color barGlass: Qt.rgba(0.15, 0.15, 0.18, 0.42)
    readonly property color barHover: Qt.rgba(1, 1, 1, 0.18)
    readonly property color dockGlass: Qt.rgba(0.055, 0.055, 0.065, 0.52)
    readonly property color fieldBg: Qt.rgba(255, 255, 255, 0.08)
    readonly property color fieldHover: Qt.rgba(255, 255, 255, 0.12)
    readonly property color border: Qt.rgba(255, 255, 255, 0.10)

    // ---- macOS Liquid Glass material tokens (faithful to Tahoe) ----
    readonly property color menuBg: Qt.rgba(0.10, 0.10, 0.12, 0.95)
    readonly property color menuBorder: Qt.rgba(255, 255, 255, 0.14)
    readonly property color menuHighlight: "#315bdc"
    readonly property color popoverBg: Qt.rgba(0.10, 0.10, 0.12, 0.92)
    readonly property color ccBg: Qt.rgba(0.10, 0.10, 0.12, 0.38)
    readonly property color ccBorder: Qt.rgba(255, 255, 255, 0.16)
    readonly property int ccRadius: 28
    readonly property color glassSheen: Qt.rgba(255, 255, 255, 0.14)
    readonly property color glassSheenEdge: Qt.rgba(255, 255, 255, 0.0)

    readonly property color fg: "#f5f5f7"
    readonly property color fgDim: "#b8b8bd"
    readonly property color fgFaint: "#7d7d85"

    readonly property string fontFamily: "SF Pro Display"
    readonly property string fontFamilyHeavy: "SF Pro Display"

    readonly property int barHeight: 24
    readonly property int barRadius: 10
    readonly property int cornerRadius: 18

    // user-controllable shell prefs (consumed by Dock / TopBar / elsewhere)
    property int dockIconSize: cfgGet("dockIconSize", 52)
    property bool dockMagnification: cfgGet("dockMagnification", true)
    property bool dockAutohide: cfgGet("dockAutohide", false)
    property bool menubarWifi: cfgGet("menubarWifi", true)
    property bool menubarBluetooth: cfgGet("menubarBluetooth", true)
    property bool menubarBattery: cfgGet("menubarBattery", true)
    property bool menubarSound: cfgGet("menubarSound", true)
    property bool menubarControlCenter: cfgGet("menubarControlCenter", true)
    property bool menubarSpotlight: cfgGet("menubarSpotlight", true)
    property bool menubarClock: cfgGet("menubarClock", true)
    property bool menubarTray: cfgGet("menubarTray", true)
    property bool darkMode: cfgGet("darkMode", false)

    readonly property url iconsDir: Qt.resolvedUrl("../../assets/icons/")
}
