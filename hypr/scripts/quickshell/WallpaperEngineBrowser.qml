import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "WEModel.js" as Model

PanelWindow {
    id: panel

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wallpaper-engine-browser"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Keys.onReturnPressed: function(event) {
        if (panel.ready && panel.filtered.length > 0) panel.applySelected()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        if (panel.ready && panel.filtered.length > 0) panel.applySelected()
        event.accepted = true
    }

    readonly property bool ready: loaded && layoutSettled

    property bool loaded:        false
    property bool layoutSettled: false
    property bool closing:       false
    property int  thumbEpoch:    0
    property var  imageArray:    []
    property int  selFilt:       0
    property string filterText:  ""
    property string wallpiperctlPath: ""

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
                    if (c.base)   panel.paper   = c.base
                    if (c.text)   panel.ink     = c.text
                    if (c.blue)   panel.seal    = c.blue
                    if (c.surface2) panel.sep   = c.surface2
                    if (c.surface0) panel.frameBg = c.surface0
                    if (c.subtext0) panel.sumiHi = c.subtext0
                } catch(e) {}
            }
        }
    }

    property real reveal: 0
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onReadyChanged: reveal = ready ? 1 : 0

    readonly property var filtered: {
        var out = []
        for (var i = 0; i < imageArray.length; i++) {
            if (!Model.itemMatches(imageArray, i, filterText)) continue
            out.push({
                idx:      i,
                filePath: imageArray[i].filePath,
                thumbnailPath: imageArray[i].thumbnailPath,
                thumb:    imageArray[i].thumbnailPath ? ("file://" + imageArray[i].thumbnailPath) : "",
                label:    imageArray[i].title || Model.nameForPath(imageArray[i].filePath),
                workshopId: imageArray[i].filePath.split("/").slice(-2, -1)[0] || ""
            })
        }
        return out
    }
    onFilteredChanged: if (selFilt >= filtered.length) selFilt = Math.max(0, filtered.length - 1)

    readonly property string currentLabel:
        (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
            ? filtered[selFilt].label
            : (filterText ? "No matches" : "")

    function releaseClosedState() {
        panel.closing = true
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
        colorReader.running = true
        findWallpiperctl.running = true
        panel.runScan()
    }

    Process {
        id: findWallpiperctl
        command: ["bash", "-c", "P=$HOME/.local/bin/wallpiperctl; [ -x \"$P\" ] && echo \"$P\" || which wallpiperctl 2>/dev/null || echo wallpiperctl"]
        stdout: StdioCollector { onStreamFinished: panel.wallpiperctlPath = this.text.trim() }
    }

    function buildScanCmd() {
        return ["bash", "-c",
            "WE_DIR=/mnt/games/steamapps/workshop/content/431960; " +
            "CACHE_DIR=$HOME/.cache/wallpiper-we-thumbs; mkdir -p \"$CACHE_DIR\"; " +
            "for dir in \"$WE_DIR\"/*/; do " +
            "  [ -d \"$dir\" ] || continue; " +
            "  ID=$(basename \"$dir\"); " +
            "  [ \"$ID\" = \"wallpaper.jpg\" ] && continue; " +
            "  PREVIEW=$(find \"$dir\" -maxdepth 1 -name 'preview.*' -print -quit 2>/dev/null); " +
            "  [ -z \"$PREVIEW\" ] && continue; " +
            "  TITLE=$(python3 -c \"import json,sys; d=json.load(open('$dir/project.json')); print(d.get('title','Unknown'))\" 2>/dev/null || echo Unknown); " +
            "  CACHED=$CACHE_DIR/${ID}.jpg; " +
            "  [ ! -f \"$CACHED\" ] || [ \"$PREVIEW\" -nt \"$CACHED\" ] && cp \"$PREVIEW\" \"$CACHED\" 2>/dev/null; " +
            "  printf '%s\\t%s\\t%s\\n' \"$PREVIEW\" \"$CACHED\" \"$TITLE\"; " +
            "done"]
    }

    readonly property string scanCachePath: Quickshell.env("HOME") + "/.cache/quickshell-scan-we-wallpapers"
    property string _lastScan: ""
    function liveScanCmd() { var c = panel.buildScanCmd(); return c }
    function runScan() {
        scanProc.command = panel.liveScanCmd(); scanProc.running = false; scanProc.running = true
    }
    Process {
        id: scanProc
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: panel.applyScan(text, false)
        }
    }

    function applyScan(text, fromCache) {
        var t = String(text || "")
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
            if (panel.imageArray.length > 0) stage.forceActiveFocus()
            if (!fromCache) warmTimer.restart()
            panel.layoutSettled = true
        })
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
        warmProc.command = ["bash", "-c",
            "D=$HOME/.cache/wallpiper-we-thumbs; mkdir -p \"$D\"; " +
            "command -v magick >/dev/null 2>&1 || exit 0; " +
            "tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
            "for s in \"$@\"; do k=$(printf '%s' \"$s\" | md5sum | cut -d' ' -f1); " +
            "o=\"$D/$k.jpg\"; [ -s \"$o\" ] && continue; " +
            "printf '%s\\n%s\\n' \"$s\" >> \"$tmp\"; done; " +
            "if [ -s \"$tmp\" ]; then xargs -r -d '\\n' -P 3 -n 2 sh -c " +
            "'magick \"$0\" -auto-orient -strip -thumbnail 480x270^ -quality 82 \"$1\" >/dev/null 2>&1' < \"$tmp\"; " +
            "echo changed; fi"].concat(srcs)
        warmProc.running = false; warmProc.running = true
    }

    function applySelected() {
        if (!loaded || filtered.length === 0) return
        if (selFilt < 0 || selFilt >= filtered.length) return
        var item = filtered[selFilt]
        var wsId = item.workshopId; if (!wsId) return
        var preview = item.filePath || ""
        var env = "export WALLPIPER_PORTAL=hyprland; " +
            "export WALLPIPER_STEAM_ROOT=/mnt/games; " +
            "export WALLPIPER_PROTON_BIN=$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-1/proton; " +
            "export WALLPIPER_WINE_BIN=$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-1/files/bin/wine; "
        var cmd = env +
            panel.shq(panel.wallpiperctlPath) + " set " + panel.shq(wsId) + " && " +
            "notify-send 'Wallpiper' 'Wallpaper set: " + item.title.replace(/'/g, "'\\''") + "' -i preferences-desktop-wallpaper" +
            " || notify-send -u critical 'Wallpiper' 'wallpiperctl set failed for " + wsId + "'"
        if (preview) {
            cmd += "; matugen image " + panel.shq(preview) +
                " && bash ~/.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh"
        }
        Quickshell.execDetached(["bash", "-c", cmd])
        panel.close()
    }

    function moveSel(delta) {
        if (filtered.length === 0) return
        selFilt = Math.max(0, Math.min(filtered.length - 1, selFilt + delta))
    }

    function stopWallpapers() {
        Quickshell.execDetached(["bash", "-c",
            "pkill -9 -f wallpiperd; pkill -9 -f wallpiper-portal-hyprland; " +
            "pkill -9 -f wallpiperctl; pkill -9 -f wallpaper64; pkill -9 -f 'start.exe'; " +
            "rm -rf /tmp/wallpiper; rm -f /tmp/wallpiperd-renderer.log; " +
            "notify-send 'Wallpiper' 'All stopped' -i preferences-desktop-wallpaper"])
        panel.close()
    }

    readonly property var sel: (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
                               ? filtered[selFilt] : null

    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    // ── geometry ──
    readonly property int  focusedW:   460
    readonly property int  focusedH:   259
    readonly property int  peekW:      104
    readonly property int  stripW:     24
    readonly property int  gap:        8
    readonly property int  maxVisible: 5

    function stripWidthFor(d) {
        if (d <= 0) return focusedW
        if (d === 1) return peekW
        return stripW
    }

    readonly property color scrim:   Qt.rgba(panel.paper.r, panel.paper.g, panel.paper.b, 0.8)
    readonly property color uiDim:   Qt.rgba(panel.ink.r, panel.ink.g, panel.ink.b, 0.45)

    Rectangle {
        anchors.fill: parent
        color: panel.scrim
        opacity: panel.reveal
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

    Text {
        visible: panel.ready
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: stage.top
        anchors.bottomMargin: 22
        opacity: panel.reveal
        text: "WALLPAPER ENGINE"
        color: panel.sumiHi
        font.family: panel.mono; font.pixelSize: 12; font.letterSpacing: 3; font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        id: stage
        visible: panel.ready && panel.filtered.length > 0
        focus: panel.ready && panel.filtered.length > 0
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
                if (panel.filterText) panel.filterText = ""
                else panel.close()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                panel.applySelected(); event.accepted = true
            } else if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                panel.stopWallpapers(); event.accepted = true
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
                if (event.text !== " " || (panel.filterText.length > 0 && !panel.filterText.endsWith(" "))) panel.filterText += event.text;
                event.accepted = true
            }
        }

        Repeater {
            model: panel.filtered.length

            delegate: Item {
                id: item
                required property int index
                readonly property var  entry:   panel.filtered[index] || null
                readonly property int  relIdx:  index - panel.selFilt
                readonly property bool focused: relIdx === 0
                readonly property bool near:    Math.abs(relIdx) <= panel.maxVisible

                readonly property bool wantThumb: panel.ready && near && entry

                width:  panel.stripWidthFor(Math.abs(relIdx))
                height: panel.focusedH
                y: 0
                x: stage.xForRel(relIdx)
                z: focused ? 100 : 50 - Math.abs(relIdx)
                visible: near
                opacity: near ? 1 : 0

                Behavior on x       { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on width   { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                readonly property string thumbPath: {
                    if (!entry) return ""
                    var fp = entry.thumbnailPath || ""
                    if (!fp) fp = entry.filePath
                    return fp ? "file://" + fp : ""
                }

                Rectangle {
                    id: frame
                    anchors.fill: parent
                    radius: 8
                    color: panel.frameBg
                    border.width: 1
                    border.color: item.focused ? panel.seal : panel.sep
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 3
                        clip: true

                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            readonly property string wantedSource: (panel.ready && item.near && item.entry && item.thumbPath) ? item.thumbPath : ""
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
                            sourceSize.width:  panel.focusedW
                            sourceSize.height: panel.focusedH
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: panel.paper
                            opacity: item.focused ? 0 : (Math.abs(item.relIdx) === 1 ? 0.28 : 0.5)
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.focused ? panel.applySelected() : (panel.selFilt = index)
                }
            }
        }
    }

    Column {
        visible: panel.ready && panel.filtered.length > 0
        opacity: panel.reveal
        anchors.top: stage.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: stage.horizontalCenter
        spacing: 12

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: panel.focusedW * 0.42
            height: 3; radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.5;  color: panel.seal }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: panel.focusedW + 160
            text: "Wallpaper Engine · " + panel.currentLabel
            color: panel.ink
            font.family: panel.mono; font.pixelSize: 22; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        Text {
            visible: panel.filterText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: panel.filterText
            color: panel.seal; opacity: 0.95
            font.family: panel.mono; font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            visible: true
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← →  scroll     Enter apply     Home/End stop all     Esc close     Type to filter"
            color: panel.uiDim
            font.family: panel.mono; font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
