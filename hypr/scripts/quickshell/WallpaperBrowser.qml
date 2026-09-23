import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "ImagePickerModel.js" as Model

PanelWindow {
    id: panel

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wallpaper-browser"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool ready: loaded && layoutSettled

    property bool loaded:        false
    property bool layoutSettled: false
    property bool closing:       false
    property int  thumbEpoch:    0
    property var  imageArray:    []
    property int  selFilt:       0
    property string filterText:  ""

    // ── reveal ──
    property real reveal: 0
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onReadyChanged: reveal = ready ? 1 : 0

    // ── filtered list ──
    readonly property var filtered: {
        var out = []
        for (var i = 0; i < imageArray.length; i++) {
            if (!Model.itemMatches(imageArray, i, filterText)) continue
            out.push({
                idx:      i,
                filePath: imageArray[i].filePath,
                thumbnailPath: imageArray[i].thumbnailPath,
                thumb:    imageArray[i].thumbnailPath ? ("file://" + imageArray[i].thumbnailPath) : "",
                label:    panel.mediaLabel(imageArray[i].filePath),
                isVideo:  false
            })
        }
        return out
    }
    onFilteredChanged: if (selFilt >= filtered.length) selFilt = Math.max(0, filtered.length - 1)

    readonly property string currentLabel:
        (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
            ? filtered[selFilt].label
            : (filterText ? "No matches" : "")

    // ── open / close ──
    function releaseClosedState() {
        panel.closing = true
        cacheProc.running = false
        scanProc.running = false
        warmTimer.stop()
        warmProc.running = false
        panel.loaded        = false
        panel.layoutSettled = false
        panel.filterText    = ""
        panel.imageArray    = []
        panel.selFilt       = 0
        panel.reveal        = 0
    }

    function close() {
        panel.releaseClosedState()
        Qt.callLater(Qt.quit)
    }

    Component.onCompleted: {
        panel.runScan()
    }

    function buildScanCmd() {
        return ["bash", "-c",
            "D=\"${XDG_CONFIG_HOME:-$HOME/.config}/wallpapers\"; " +
            "find \"$D\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) " +
            "-printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -200 | cut -f2- | " +
            "while IFS= read -r f; do k=$(printf '%s' \"$f\" | md5sum | cut -d' ' -f1); m=$(stat -c %Y \"$f\" 2>/dev/null); printf '%s\\t%s/%s-%s.jpg\\n' \"$f\" \"$HOME/.cache/quickshell-img-thumbs\" \"$k\" \"$m\"; done"]
    }

    readonly property string scanCachePath: Quickshell.env("HOME") + "/.cache/quickshell-scan-wallpapers"
    property string _lastScan: ""
    function liveScanCmd() { var c = panel.buildScanCmd(); c[2] = c[2] + " | tee " + panel.shq(panel.scanCachePath); return c }
    function runScan() {
        cacheProc.running = false; cacheProc.running = true
        scanProc.command = panel.liveScanCmd(); scanProc.running = false; scanProc.running = true
    }
    Process {
        id: cacheProc
        command: ["cat", panel.scanCachePath]
        stdout: StdioCollector { onStreamFinished: panel.applyScan(this.text, true) }
    }
    function applyScan(text, fromCache) {
        var t = String(text || "")
        if (fromCache && (!t.trim() || loaded)) return
        if (!fromCache && t.trim() === _lastScan.trim() && loaded) {
            warmTimer.restart()
            return
        }
        _lastScan = t
        var rows = Model.loadRows(t)
        panel.imageArray = rows
        panel.selFilt    = 0
        panel.loaded     = rows.length > 0
        Qt.callLater(function() {
            if (panel.imageArray.length > 0) hand.forceActiveFocus()
            if (!fromCache) warmTimer.restart()
            panel.layoutSettled = true
        })
    }
    Process {
        id: scanProc
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: panel.applyScan(text, false)
        }
    }

    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function cancellableCommand(body, argv0, args) {
        return ["bash", "-c",
            "body=$1; shift; setsid bash -c \"$body\" worker \"$@\" & worker=$!; " +
            "cleanup() { pkill -TERM -s \"$worker\" 2>/dev/null || true; sleep 0.2; pkill -KILL -s \"$worker\" 2>/dev/null || true; }; " +
            "trap 'cleanup; exit 143' TERM INT; wait \"$worker\"",
            argv0 || "manager", body].concat(args || [])
    }

    Process {
        id: warmProc
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (this.text.trim())
                panel.thumbEpoch++
        }
    }
    Timer { id: warmTimer; interval: 450; onTriggered: panel.warmAll() }
    function warmAll() {
        var srcs = []
        for (var i = 0; i < imageArray.length; i++)
            if (imageArray[i].filePath) srcs.push(imageArray[i].filePath)
        if (srcs.length === 0) return
        warmProc.command = panel.cancellableCommand(
            "D=$HOME/.cache/quickshell-img-thumbs; mkdir -p \"$D\"; command -v magick >/dev/null 2>&1 || exit 0; " +
            "tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
            "for s in \"$@\"; do k=$(printf '%s' \"$s\" | md5sum | cut -d' ' -f1); m=$(stat -c %Y \"$s\" 2>/dev/null); " +
            "o=\"$D/$k-$m.jpg\"; [ -s \"$o\" ] && continue; printf '%s\\n%s\\n' \"$s\" \"$o\" >> \"$tmp\"; done; " +
            "if [ -s \"$tmp\" ]; then nice -n 19 xargs -r -d '\\n' -P 3 -n 2 sh -c 'magick \"$0\" -auto-orient -strip -thumbnail 480x270^ -quality 82 \"$1\" >/dev/null 2>&1' < \"$tmp\"; made=0; while IFS= read -r _src && IFS= read -r out; do [ -s \"$out\" ] && { made=1; break; }; done < \"$tmp\"; [ \"$made\" -eq 1 ] && echo changed; fi",
            "warm", srcs)
        warmProc.running = false; warmProc.running = true
    }

    function applySelected() {
        if (!loaded || filtered.length === 0) return
        if (selFilt < 0 || selFilt >= filtered.length) return
        var path = filtered[selFilt].filePath; if (!path) return
        Quickshell.execDetached(["bash", "-c",
            "W=" + shq(path) + "; " +
            "awww img --transition-type center --transition-step 90 \"$W\" && " +
            "matugen image \"$W\" --source-color-index 0 && " +
            "bash ~/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"])
        panel.close()
    }

    function moveSel(delta) {
        if (filtered.length === 0) return
        selFilt = Math.max(0, Math.min(filtered.length - 1, selFilt + delta))
    }

    readonly property var sel: (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
                               ? filtered[selFilt] : null

    function mediaLabel(path) {
        var n = String(path || "").split("/").pop().replace(/\.[^.]+$/, "")
        return n.replace(/[-_]+/g, " ").replace(/\b\w/g, function(m) { return m.toUpperCase() })
    }

    // ── geometry (qsbar hearthstone match) ──
    readonly property int  cardW:      232
    readonly property int  cardH:      330
    readonly property real focusScale: 1.24
    readonly property real spreadDeg:  6.0
    readonly property real stepX:      128
    readonly property real focusLift:  54
    readonly property int  maxVisible: 5

    readonly property int  focusedW:   cardW
    readonly property int  focusedH:   cardH

    // ── felt look (qsbar original) ──
    readonly property color feltColor: Qt.rgba(0.035, 0.035, 0.05, 0.975)
    readonly property color frameDark: "#16161c"
    readonly property color textLight: "#ECECEE"
    readonly property color textDim:   Qt.rgba(0.92, 0.92, 0.94, 0.55)

    // ── legacy aliases (used by filter text etc) ──
    readonly property color paper:   panel.feltColor
    readonly property color ink:     panel.textLight
    readonly property color seal:    panel.textLight
    readonly property color sep:     "#2a2a30"
    readonly property color frameBg: panel.frameDark
    readonly property color sumiHi:  panel.textDim
    readonly property string mono:   "monospace"

    Rectangle {
        anchors.fill: parent
        color: panel.feltColor
        opacity: panel.reveal
    }

    function stripWidthFor(d) {
        if (d <= 0) return focusedW
        if (d === 1) return peekW
        return stripW
    }

    readonly property color scrim:   Qt.rgba(panel.paper.r, panel.paper.g, panel.paper.b, 0.8)
    readonly property color uiDim:   Qt.rgba(panel.ink.r, panel.ink.g, panel.ink.b, 0.45)

    // ── hearthstone table (qsbar-matched, wallpaper-driven) ──
    readonly property color feltHi:  Qt.rgba(panel.paper.r, panel.paper.g, panel.paper.b, 0.15)
    readonly property color feltLo:  Qt.rgba(panel.paper.r * 0.5, panel.paper.g * 0.5, panel.paper.b * 0.5, 1.0)
    readonly property color accent:  panel.seal
    readonly property color accentDim: Qt.rgba(panel.seal.r, panel.seal.g, panel.seal.b, 0.45)
    readonly property color cardHi:  Qt.rgba(panel.frameBg.r, panel.frameBg.g, panel.frameBg.b, 1.0)
    readonly property color cardLo:  Qt.rgba(panel.paper.r * 0.8, panel.paper.g * 0.8, panel.paper.b * 0.8, 1.0)
    readonly property int  peekStep: 84

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: panel.feltHi }
            GradientStop { position: 1.0; color: panel.feltLo }
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

    Item {
        anchors.fill: parent
        focus: panel.visible && !(panel.ready && panel.filtered.length > 0)
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (panel.filterText) panel.filterText = ""
                else panel.close()
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                if (panel.filterText.length > 0) panel.filterText = panel.filterText.slice(0, -1)
                event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                       && event.text.charCodeAt(0) !== 127
                       && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                if (event.text !== " " || (panel.filterText.length > 0 && !panel.filterText.endsWith(" "))) panel.filterText += event.text;
                event.accepted = true
            }
        }
    }
    Text {
        visible: panel.ready && panel.filtered.length === 0
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: "No matches: " + panel.filterText + "\n\nBackspace to edit, or Esc to clear"
        color: panel.ink
        font.family: panel.mono; font.pixelSize: 16; font.letterSpacing: 1
    }
    Text {
        visible: !panel.ready
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: panel.layoutSettled && !panel.loaded
              ? "No wallpapers found\n\nEsc or click to close"
              : "Loading…"
        color: panel.ink
        font.family: panel.mono; font.pixelSize: 16; font.letterSpacing: 1
    }

    // ── position indicator (top) ──
    Text {
        visible: panel.ready && panel.filtered.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: 40
        opacity: panel.reveal
        text: "WALLPAPER      " + (panel.selFilt + 1) + " / " + panel.filtered.length
        color: panel.textDim
        font.family: panel.mono; font.pixelSize: 12; font.letterSpacing: 2
    }

    // ── the hand ──
    Item {
        id: hand
        visible: panel.ready && panel.filtered.length > 0
        focus: panel.ready && panel.filtered.length > 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -16
        width: parent.width
        height: panel.cardH + panel.focusLift + 40

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (panel.filterText) panel.filterText = ""
                else panel.close()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                panel.applySelected(); event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                if (panel.filterText.length > 0) panel.filterText = panel.filterText.slice(0, -1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab
                       || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                panel.moveSel(-1); event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                panel.moveSel(1); event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                       && event.text.charCodeAt(0) !== 127
                       && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                if (event.text !== " " || (panel.filterText.length > 0 && !panel.filterText.endsWith(" "))) panel.filterText += event.text; event.accepted = true
            }
        }

        Repeater {
            model: panel.filtered.length

            delegate: Item {
                id: card
                required property int index
                readonly property var  entry:   panel.filtered[index] || null
                readonly property int  relIdx:  index - panel.selFilt
                readonly property bool focused: relIdx === 0
                readonly property bool nearby:  Math.abs(relIdx) <= panel.maxVisible
                readonly property real dim: focused ? 0.0 : Math.min(0.62, 0.30 + Math.abs(relIdx) * 0.05)
                property bool hovered: false

                readonly property string thumbPath: {
                    if (!entry) return ""
                    var fp = entry.thumbnailPath || ""
                    if (!fp) fp = entry.filePath
                    return fp ? "file://" + fp : ""
                }

                width: panel.cardW; height: panel.cardH
                visible: nearby
                transformOrigin: Item.Bottom

                x: (hand.width  - panel.cardW) / 2 + relIdx * panel.stepX
                y: (hand.height - panel.cardH)     - (focused ? panel.focusLift : 0)
                rotation: relIdx * panel.spreadDeg
                scale: focused ? (hovered ? panel.focusScale * 1.03 : panel.focusScale) : 1
                z: focused ? 1000 : 500 - Math.min(Math.abs(relIdx), 40)
                opacity: 1

                Behavior on x        { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y        { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale    { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // photo
                Item {
                    anchors.fill: parent
                    anchors.margins: 6
                    clip: true

                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        readonly property string wantedSource: (panel.ready && card.nearby && card.thumbPath) ? card.thumbPath : ""
                        source: wantedSource
                        onWantedSourceChanged: source = wantedSource
                        Connections {
                            target: panel
                            function onThumbEpochChanged() {
                                if (thumbImage.wantedSource && (thumbImage.status === Image.Error || thumbImage.status === Image.Null)) {
                                    var s = thumbImage.wantedSource
                                    thumbImage.source = ""
                                    thumbImage.source = s
                                }
                            }
                        }
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; smooth: true
                        sourceSize.width:  panel.cardW * 2
                        sourceSize.height: panel.cardH * 2
                    }
                    // bottom gradient shadow
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 70
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                        }
                    }
                    // dim overlay for non-focused
                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: card.dim
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                }

                // frame border (qsbar hearthstone style)
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: focused ? 2 : 1
                    border.color: focused ? Qt.rgba(0.85, 0.85, 0.88, 0.6) : Qt.rgba(0.85, 0.85, 0.88, 0.18)
                    radius: 14
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onContainsMouseChanged: card.hovered = containsMouse
                    onClicked: card.focused ? panel.applySelected() : (panel.selFilt = index)
                }
            }
        }
    }

    // ── footer ──
    Column {
        visible: panel.ready && panel.filtered.length > 0
        opacity: panel.reveal
        anchors.top: hand.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: hand.horizontalCenter
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            text: panel.currentLabel
            color: panel.textLight
            font.family: panel.mono; font.pixelSize: 20; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        Text {
            visible: panel.filterText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: panel.filterText
            color: panel.textLight; opacity: 0.85
            font.family: panel.mono; font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            visible: true
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← →  scroll     Enter apply     Esc close     Type to filter"
            color: panel.textDim
            font.family: panel.mono; font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
