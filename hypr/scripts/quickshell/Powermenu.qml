import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: panel

    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "powermenu"

    visible: true

    property bool closed: true
    property string currentGif: "file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/kurukuru.gif"
    property int activeWindows: 1

    // ── restrict input to right edge only (empty when windows are open) ──
    mask: Region {
        Region {
            x: panel.activeWindows === 0 ? (panel.width - (panel.closed ? 12 : 132)) : panel.width
            y: 0
            width: panel.activeWindows === 0 ? (panel.closed ? 12 : 132) : 0
            height: panel.height
        }
    }

    MatugenColors { id: theme }

    // ── check active windows ──
    Process {
        id: winChecker
        command: ["sh", "-c", "hyprctl activeworkspace -j | jq '.windows' 2>/dev/null || echo 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var n = parseInt(this.text.trim())
                panel.activeWindows = isNaN(n) ? 1 : n
            }
        }
    }
    Timer {
        interval: 600
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: winChecker.running = true
    }

    // ── read GIF list from iop directory ──
    property var gifList: []
    property real wallpaperCheck: 0
    property string lastWallpaperSig: ""
    Process {
        id: gifReader
        command: ["sh", "-c", "ls " + Quickshell.env("HOME") + "/Downloads/iop/*.gif 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = this.text.trim()
                if (txt) {
                    var files = txt.split("\n")
                    panel.gifList = files.map(f => "file://" + f.trim())
                }
            }
        }
    }
    onWallpaperCheckChanged: {
        if (theme.rawJson !== panel.lastWallpaperSig) {
            panel.lastWallpaperSig = theme.rawJson
            panel.pickGifForWallpaper()
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gifReader.running = true
            panel.wallpaperCheck++
        }
    }

    function pickGifForWallpaper() {
        var all = ["file://" + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/kurukuru.gif"]
        if (panel.gifList.length > 0) all = all.concat(panel.gifList)
        var c = theme.mauve
        if (typeof c !== "object" || c === undefined) c = Qt.rgba(0.67, 0.42, 0.93, 1)
        var r = c.r, g = c.g, b = c.b
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var h = 0
        if (max !== min) {
            var d = max - min
            if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6
            else if (max === g) h = ((b - r) / d + 2) / 6
            else h = ((r - g) / d + 4) / 6
        }
        var idx = Math.floor(h * all.length)
        if (idx >= all.length) idx = all.length - 1
        if (idx < 0) idx = 0
        panel.currentGif = all[idx]
    }

    // ── activation zone: right edge strip ──
    MouseArea {
        id: activationZone
        x: panel.width - (panel.closed ? 12 : 132)
        y: 0
        width: panel.closed ? 12 : 132
        height: parent.height
        hoverEnabled: true
        onEntered: {
            hideTimer.stop()
            if (panel.closed && panel.activeWindows === 0) {
                panel.pickGifForWallpaper()
                panel.closed = false
            }
        }
        onExited: hideTimer.restart()
    }

    // ── menu content ──
    Item {
        id: menuContent
        x: panel.width - 132
        y: 0
        width: 132
        height: parent.height
        opacity: panel.closed ? 0 : 1
        enabled: !panel.closed
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
            anchors.centerIn: parent
            spacing: 16

            // Logout
            Item {
                width: 80; height: 80
                Rectangle {
                    id: bgLogout
                    anchors.fill: parent
                    radius: 20
                    color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: theme.text
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 32
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: bgLogout.color = Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.3)
                    onExited: bgLogout.color = Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    onClicked: { hideTimer.stop(); Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")]) }
                }
            }

            // Shutdown
            Item {
                width: 80; height: 80
                Rectangle {
                    id: bgShutdown
                    anchors.fill: parent
                    radius: 20
                    color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: theme.text
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 32
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: bgShutdown.color = Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.3)
                    onExited: bgShutdown.color = Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    onClicked: { hideTimer.stop(); Quickshell.execDetached(["systemctl", "poweroff", "-i"]) }
                }
            }

            // GIF
            AnimatedImage {
                width: 80; height: 80
                source: panel.currentGif
                playing: visible
                asynchronous: true
                speed: 0.7
                fillMode: AnimatedImage.PreserveAspectFit
            }

            // Hibernate
            Item {
                width: 80; height: 80
                Rectangle {
                    id: bgHibernate
                    anchors.fill: parent
                    radius: 20
                    color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "ᶻ𝗓𐰁"
                        color: theme.text
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 32
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: bgHibernate.color = Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.3)
                    onExited: bgHibernate.color = Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    onClicked: { hideTimer.stop(); Quickshell.execDetached(["systemctl", "hibernate"]) }
                }
            }

            // Reboot
            Item {
                width: 80; height: 80
                Rectangle {
                    id: bgReboot
                    anchors.fill: parent
                    radius: 20
                    color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    Text {
                        anchors.centerIn: parent
                        text: "󰑓"
                        color: theme.text
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: 32
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: bgReboot.color = Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.3)
                    onExited: bgReboot.color = Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.5)
                    onClicked: { hideTimer.stop(); Quickshell.execDetached(["systemctl", "reboot"]) }
                }
            }
        }
    }

    // ── hide timer ──
    Timer {
        id: hideTimer
        interval: 500
        onTriggered: { if (!activationZone.containsMouse) panel.closed = true }
    }
}
