import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: panel

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dots-browser"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool ready: loaded && layoutSettled

    property bool loaded:        false
    property bool layoutSettled: false
    property var  dotsArray:     []
    property int  selFilt:       0

    // ── colors (read from qs_colors.json) ──
    property color paper:   "#0d0f09"
    property color ink:     "#e2e3d8"
    property color seal:    "#b4d088"
    property color sep:     "#33362e"
    property color frameBg: "#1e2019"
    property color sumiHi:  "#c5c8b9"
    property string mono:   "monospace"

    Process {
        id: colorReader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/qs_colors.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var c = JSON.parse(this.text.trim())
                    if (c.base)     panel.paper   = c.base
                    if (c.text)     panel.ink     = c.text
                    if (c.blue)     panel.seal    = c.blue
                    if (c.surface2) panel.sep     = c.surface2
                    if (c.surface0) panel.frameBg = c.surface0
                    if (c.subtext0) panel.sumiHi  = c.subtext0
                } catch(e) {}
            }
        }
    }

    // ── reveal animation ──
    property real reveal: 0
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onReadyChanged: reveal = ready ? 1 : 0

    // ── open / close ──
    function close() {
        panel.loaded        = false
        panel.layoutSettled = false
        panel.reveal        = 0
        Qt.callLater(Qt.quit)
    }

    Component.onCompleted: {
        colorReader.running = true
        scannerProc.running = true
    }

    // ── scan script ──
    Process {
        id: scannerProc
        command: ["bash", "-c",
            "HOME_DIR=\"$HOME\"; " +
            "QS_BASE=\"$HOME_DIR/.config/quickshell\"; " +
            "ACTIVE=\"none\"; " +
            "if pgrep -f 'ryoku/shell/ipc/ryoku-shell' >/dev/null 2>&1; then ACTIVE='ryoku'; " +
            "elif pgrep -f 'quickshell.*macos' >/dev/null 2>&1 || pgrep -f 'qs.*macos' >/dev/null 2>&1; then ACTIVE='macos'; " +
            "elif pgrep -f 'quickshell.*ii' >/dev/null 2>&1 || pgrep -f 'qs.*ii' >/dev/null 2>&1; then ACTIVE='ii'; " +
            "elif pgrep -f 'Main\\.qml' >/dev/null 2>&1 || pgrep -f 'TopBar\\.qml' >/dev/null 2>&1; then ACTIVE='default'; fi; " +
            "echo \"ACTIVE:$ACTIVE\"; " +
            "echo \"default|System Default|Base Hyprland Quickshell|⚙️\"; " +
            "for d in \"$QS_BASE\"/*/; do " +
            "  [ -f \"${d}shell.qml\" ] || continue; " +
            "  name=$(basename \"$d\"); " +
            "  title=\"$name\"; " +
            "  icon=\"🎨\"; " +
            "  desc=\"Custom Quickshell Dot\"; " +
            "  if [ \"$name\" = \"macos\" ]; then title=\"macOS Tahoe\"; icon=\"🍎\"; desc=\"macOS Style MenuBar, Dock & Control Center\"; fi; " +
            "  if [ \"$name\" = \"ii\" ]; then title=\"Windows 11 (Waffle)\"; icon=\"🪟\"; desc=\"Illogical Impulse Waffle Shell\"; fi; " +
            "  if [ \"$name\" = \"k4\" ]; then title=\"K4 Theme\"; icon=\"✨\"; desc=\"K4 Cyberpunk Quickshell Theme\"; fi; " +
            "  if [ \"$name\" = \"shell\" ]; then title=\"Caelestia Shell\"; icon=\"🌌\"; desc=\"Caelestia Desktop Quickshell Shell\"; fi; " +
            "  if [ \"$name\" = \"ryoku\" ]; then title=\"Ryoku Shell\"; icon=\"🎴\"; desc=\"Ryoku Frame Bars & Wallpaper Clock (力と美)\"; fi; " +
            "  echo \"$name|$title|$desc|$icon\"; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var activeName = "none"
                var list = []
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (!line) continue
                    if (line.startsWith("ACTIVE:")) {
                        activeName = line.substring(7)
                        continue
                    }
                    var parts = line.split("|")
                    if (parts.length >= 4) {
                        list.push({
                            name: parts[0],
                            title: parts[1],
                            desc: parts[2],
                            icon: parts[3],
                            isActive: (parts[0] === activeName)
                        })
                    }
                }
                panel.dotsArray = list
                panel.selFilt = 0
                panel.loaded = list.length > 0
                Qt.callLater(function() {
                    panel.layoutSettled = true
                    if (list.length > 0) stage.forceActiveFocus()
                })
            }
        }
    }

    function applySelected() {
        if (!loaded || dotsArray.length === 0) return
        if (selFilt < 0 || selFilt >= dotsArray.length) return
        var item = dotsArray[selFilt]
        if (!item || !item.name) return
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/toggle_qs_dots.sh", item.name])
        panel.close()
    }

    function moveSel(delta) {
        if (dotsArray.length === 0) return
        selFilt = Math.max(0, Math.min(dotsArray.length - 1, selFilt + delta))
    }

    readonly property var sel: (dotsArray.length > 0 && selFilt >= 0 && selFilt < dotsArray.length)
                               ? dotsArray[selFilt] : null

    // ── geometry ──
    readonly property int  focusedW:   460
    readonly property int  focusedH:   260
    readonly property int  peekW:      110
    readonly property int  stripW:     28
    readonly property int  gap:        10
    readonly property int  maxVisible: 5

    function stripWidthFor(d) {
        if (d <= 0) return focusedW
        if (d === 1) return peekW
        return stripW
    }

    readonly property color scrim:   Qt.rgba(panel.paper.r, panel.paper.g, panel.paper.b, 0.82)
    readonly property color uiDim:   Qt.rgba(panel.ink.r, panel.ink.g, panel.ink.b, 0.45)

    // ── hearthstone table (wallpaper-driven) ──
    readonly property color feltHi:  Qt.rgba(panel.paper.r, panel.paper.g, panel.paper.b, 0.15)
    readonly property color feltLo:  Qt.rgba(panel.paper.r * 0.5, panel.paper.g * 0.5, panel.paper.b * 0.5, 1.0)
    readonly property color accent:  panel.seal
    readonly property color accentDim: Qt.rgba(panel.seal.r, panel.seal.g, panel.seal.b, 0.45)
    readonly property color cardHi:  Qt.rgba(panel.frameBg.r, panel.frameBg.g, panel.frameBg.b, 1.0)
    readonly property color cardLo:  Qt.rgba(panel.paper.r * 0.8, panel.paper.g * 0.8, panel.paper.b * 0.8, 1.0)
    readonly property int  peekStep: 84

    // Backdrop
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(panel.feltHi.r, panel.feltHi.g, panel.feltHi.b, 0.90) }
            GradientStop { position: 1.0; color: Qt.rgba(panel.feltLo.r, panel.feltLo.g, panel.feltLo.b, 0.95) }
        }
        opacity: panel.reveal
    }

    // ornate table trim
    Rectangle {
        anchors.fill: parent
        anchors.margins: 16
        radius: 24
        color: "transparent"
        border.width: 1
        border.color: panel.accentDim
        opacity: 0.55 * panel.reveal
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 22
        radius: 18
        color: "transparent"
        border.width: 1
        border.color: panel.accent
        opacity: 0.20 * panel.reveal
    }

    MouseArea {
        anchors.fill: parent
        enabled: panel.visible
        onClicked: panel.close()
        onWheel: function(wheel) {
            if (!panel.ready) return
            panel.moveSel(wheel.angleDelta.y < 0 ? 1 : -1)
        }
    }

    // Key handler fallback
    Item {
        anchors.fill: parent
        focus: panel.visible && !panel.ready
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                panel.close()
                event.accepted = true
            }
        }
    }

    Text {
        visible: !panel.ready
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: panel.layoutSettled && !panel.loaded
              ? "No Quickshell dots found\n\nEsc or click to close"
              : "Loading Quickshell Dots…"
        color: panel.ink
        font.family: panel.mono; font.pixelSize: 16; font.letterSpacing: 1
    }

    // Top Header
    Text {
        visible: panel.ready
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: stage.top
        anchors.bottomMargin: 22
        opacity: panel.reveal
        text: "QUICKSHELL DOTS"
        color: panel.accent
        font.family: panel.mono; font.pixelSize: 12; font.letterSpacing: 4; font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
    }

    // Stage (Card Carousel)
    Item {
        id: stage
        visible: panel.ready && panel.dotsArray.length > 0
        focus: panel.ready && panel.dotsArray.length > 0
        opacity: panel.reveal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10 + (1 - panel.reveal) * 14
        width: parent.width
        height: panel.focusedH

        readonly property real cx:     width / 2
        readonly property real fLeft:  cx - panel.focusedW / 2
        readonly property real fRight: cx + panel.focusedW / 2

        function xForRel(r) {
            if (r === 0) return fLeft
            var x
            if (r < 0) {
                x = fLeft
                for (var k = -1; k >= r; k--) x = x - panel.gap - panel.stripWidthFor(-k)
                return x
            }
            x = fRight + panel.gap
            for (var j = 1; j < r; j++) x = x + panel.stripWidthFor(j) + panel.gap
            return x
        }

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                panel.close(); event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                panel.applySelected(); event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab
                       || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                panel.moveSel(-1); event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                panel.moveSel(1); event.accepted = true
            }
        }

        Repeater {
            model: panel.dotsArray.length

            delegate: Item {
                id: item
                required property int index
                readonly property var  entry:   panel.dotsArray[index] || null
                readonly property int  relIdx:  index - panel.selFilt
                readonly property bool focused: relIdx === 0
                readonly property bool near:    Math.abs(relIdx) <= panel.maxVisible
                readonly property int  effRel:  Math.max(-6, Math.min(6, relIdx))
                property bool hovered: false

                width:  panel.focusedW
                height: panel.focusedH
                x: stage.cx - panel.focusedW / 2
                y: Math.abs(effRel) * 7 + (focused ? -14 : 0)
                scale: focused ? (hovered ? 1.045 : 1.0) : 0.97
                z: focused ? 100 : 50 - Math.abs(relIdx)
                visible: near
                opacity: near ? (focused ? 1 : 0.88) : 0

                transform: Rotation {
                    origin.x: panel.focusedW / 2
                    origin.y: panel.focusedH + 1600
                    angle: item.effRel * -4.2
                    Behavior on angle { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                }

                Behavior on y       { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // ── hearthstone minion card ──
                Rectangle {
                    id: frame
                    anchors.fill: parent
                    radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: panel.cardHi }
                        GradientStop { position: 1.0; color: panel.cardLo }
                    }
                    border.width: item.focused ? 2 : 1
                    border.color: item.focused ? panel.accent : panel.sep
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    // gold pinline
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 8
                        color: "transparent"
                        border.width: 1
                        border.color: panel.accentDim
                        opacity: 0.45
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 10
                        radius: 6
                        color: Qt.rgba(panel.paper.r, panel.paper.g, panel.paper.b, 0.55)
                        clip: true

                        // icon art
                        Text {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: item.focused ? -24 : 0
                            text: item.entry ? item.entry.icon : "🎨"
                            font.pixelSize: item.focused ? 72 : (Math.abs(item.relIdx) === 1 ? 34 : 18)
                            opacity: item.focused ? 1.0 : 0.5
                            Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
                            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        // ACTIVE badge — gold gem
                        Rectangle {
                            visible: item.entry && item.entry.isActive
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 10
                            width: activeText.implicitWidth + 16
                            height: 24
                            radius: 12
                            color: Qt.rgba(panel.accent.r, panel.accent.g, panel.accent.b, 0.22)
                            border.color: panel.accent
                            border.width: 1

                            Text {
                                id: activeText
                                anchors.centerIn: parent
                                text: "✔ ACTIVE"
                                color: panel.accent
                                font.family: panel.mono; font.pixelSize: 10; font.weight: Font.Bold
                            }
                        }

                        // title banner (always visible when focused)
                        Column {
                            visible: item.focused
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 14
                            spacing: 5

                            // gold divider
                            Rectangle {
                                width: parent.width; height: 2; radius: 1
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.5; color: panel.accent }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                                opacity: 0.55
                            }

                            Text {
                                width: parent.width
                                text: item.entry ? item.entry.title : ""
                                color: panel.ink
                                font.family: panel.mono; font.pixelSize: 20; font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: item.entry ? item.entry.desc : ""
                                color: panel.accent
                                font.family: panel.mono; font.pixelSize: 11
                                opacity: 0.85
                                elide: Text.ElideRight
                            }
                        }

                        // dim overlay for non-focused
                        Rectangle {
                            anchors.fill: parent
                            color: panel.paper
                            opacity: item.focused ? 0 : (Math.abs(item.relIdx) === 1 ? 0.36 : 0.62)
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // inner hairline
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: 1
                            border.color: panel.accentDim
                            opacity: 0.35
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onContainsMouseChanged: item.hovered = containsMouse
                    onClicked: item.focused ? panel.applySelected() : (panel.selFilt = index)
                }
            }
        }
    }

    // Bottom Details & Hints Footer
    Column {
        visible: panel.ready && panel.dotsArray.length > 0
        opacity: panel.reveal
        anchors.top: stage.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: stage.horizontalCenter
        spacing: 12

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: panel.focusedW * 0.45
            height: 3; radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: panel.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: panel.focusedW + 160
            text: "Quickshell Theme · " + (panel.sel ? panel.sel.title : "")
            color: panel.ink
            font.family: panel.mono; font.pixelSize: 22; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← →  scroll navigate     Enter apply     Esc close"
            color: panel.uiDim
            font.family: panel.mono; font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
