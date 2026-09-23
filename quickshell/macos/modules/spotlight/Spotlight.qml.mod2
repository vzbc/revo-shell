import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: root._shown
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:spotlight"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root._shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool _shown: false
    property string query: ""
    property int selectedIndex: 0
    property var items: []
    property var results: []
    property var fileItems: []
    property string mode: "search"
    property var recentItems: []
    property var clipItems: []
    property bool _opened: false
    property bool hasBody: root.mode !== "search" || root.query.length > 0 || root.items.length > 0

    // ── Liquid Glass Color Palette (Translucent Liquid Glass) ──
    readonly property color dimColor: Qt.rgba(0, 0, 0, 0.20)
    readonly property color glassBg: Qt.rgba(255, 255, 255, 0.12)
    readonly property color glassBorder: Qt.rgba(255, 255, 255, 0.35)
    readonly property color glassHighlight: Qt.rgba(255, 255, 255, 0.65)
    readonly property color selectionBg: Qt.rgba(255, 255, 255, 0.22)
    readonly property color hoverBg: Qt.rgba(255, 255, 255, 0.15)
    readonly property color divider: Qt.rgba(255, 255, 255, 0.18)
    readonly property color headerFg: Qt.rgba(255, 255, 255, 0.65)
    readonly property color sFg: "#ffffff"
    readonly property color sFgDim: Qt.rgba(255, 255, 255, 0.85)
    readonly property color placeholderFg: Qt.rgba(255, 255, 255, 0.55)
    readonly property color accent: "#0c84ff"
    readonly property color circleBg: Qt.rgba(255, 255, 255, 0.18)
    readonly property color circleBorder: Qt.rgba(255, 255, 255, 0.30)
    readonly property color circleActive: "#0c84ff"

    // ── Glass Shader Parameters ──
    readonly property real glassRadius: 60.0
    readonly property real glassThickness: 38.0
    readonly property real glassBezel: 60.0
    readonly property real glassIOR: 3.00
    readonly property real glassBlur: 1.5
    readonly property real glassSpecular: 0.55
    readonly property real glassTint: 0.08
    readonly property real glassShadow: 0.55

    // ── Dimensions ──
    readonly property real panelWidth: 320
    readonly property real panelRadius: 15
    readonly property real searchH: 30
    readonly property real searchPadH: 0
    readonly property real rowH: 38
    readonly property real headerH: 22
    readonly property real iconSize: 22
    readonly property real footerH: 28
    readonly property real stripH: 58
    readonly property real circleSize: 48
    readonly property real circlesGap: 4

    property real panelOpacity: 0.0
    property real panelScale: 0.94
    property real panelYOffset: 15
    property real dimOpacity: 0.0
    property bool circlesVisible: false
    property bool circlesLocked: false
    property string placeholderText: "Spotlight Search"

    function computeHeight() {
        const maxH = Math.round(root.screen.height * 0.70);
        const pad = root.searchPadH * 2;
        if (root.mode === "search" && root.query.length === 0 && root.items.length === 0) {
            return root.searchH + pad + 4;
        }
        if (root.mode === "apps") {
            const cols = 2;
            const rows = Math.max(1, Math.ceil(root.items.length / cols));
            let h = root.searchH + pad + Math.min(8, rows) * root.rowH + 8;
            return Math.min(maxH, h);
        }
        let h = root.searchH + pad + 2;
        for (const r of root.results) h += r.isHeader ? root.headerH : root.rowH;
        if (root.items.length === 0 && root.query.length > 0) h += 56;
        if (root.selectedItem !== null && root.mode !== "apps") h += root.stripH + 1;
        return Math.min(maxH, Math.max(root.searchH + pad + 36, h));
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function openPath(p) {
        const e = (p || "~").replace(/^~\/?$/, "$HOME").replace(/^~\//, "$HOME/");
        ShellController.run("mkdir -p " + root.shellQuote(e) + "; xdg-open " + root.shellQuote(e));
    }

    function evalMath(q) {
        if (!/^[0-9+\-*/%.()\s]+$/.test(q)) return null;
        try {
            const r = Function('"use strict";return (' + q + ')')();
            if (typeof r !== "number" || !isFinite(r)) return null;
            return r;
        } catch (e) { return null; }
    }

    function buildResults() {
        const q = root.query.trim();
        const ql = q.toLowerCase();
        const items = [];
        const disp = [];
        const addItems = (arr, title) => {
            if (!arr.length) return;
            if (title) disp.push({ isHeader: true, title: title });
            for (const it of arr) { it._idx = items.length; items.push(it); disp.push(it); }
        };
        const m = root.mode;

        if (m === "apps") {
            const list = ql ? Apps.search(q) : Apps.apps;
            addItems(list.slice(0, 60).map(a => ({ kind: "app", name: a.name, icon: a.icon, exec: a.exec, category: a.category || "Application" })), ql ? "APPLICATIONS" : "");
            root.items = items; root.results = disp; root.selectedIndex = 0; return;
        }
        if (m === "files") {
            addItems(root.recentItems.map(f => ({ kind: "file", name: f.name, path: f.path, category: f.dir })), ql ? "FILES" : "RECENT FILES");
            root.items = items; root.results = disp; root.selectedIndex = 0; return;
        }
        if (m === "clipboard") {
            addItems(root.clipItems.map(c => ({ kind: "clip", name: c.text, text: c.text, category: "Clipboard" })), "CLIPBOARD");
            root.items = items; root.results = disp; root.selectedIndex = 0; return;
        }
        if (m === "actions") {
            const acts = [];
            const A = (name, act, key, cat) => acts.push({ kind: "action", name: name, action: act, iconKey: key, category: cat || "Actions" });
            A("Send Message", "action:msg", "message", "Actions");
            A("Create Note", "action:note", "note", "Actions");
            A("Start Timer", "action:timer", "timer", "Actions");
            A("Run Shortcut", "action:shortcut", "shortcut", "Actions");
            A("Lock Screen", "lock", "lock", "System");
            A("Sleep", "sleep", "moon", "System");
            A("Restart\u2026", "restart", "restart", "System");
            A("Shut Down\u2026", "shutdown", "power", "System");
            A("Log Out", "logout", "logout", "System");
            addItems(acts, "ACTIONS");
            root.items = items; root.results = disp; root.selectedIndex = 0; return;
        }

        if (ql) {
            const apps = Apps.search(q);
            addItems(apps.map(a => ({ kind: "app", name: a.name, icon: a.icon, exec: a.exec, category: a.category || "Application" })), "APPLICATIONS");
        }
        if (ql && root.fileItems.length) addItems(root.fileItems.map(f => ({ kind: "file", name: f.name, path: f.path, category: f.dir })), "FILES");
        const sys = [];
        const S = (name, act, key) => sys.push({ kind: "action", name: name, action: act, iconKey: key, category: "System" });
        if (ql && "lock screen sleep restart shut down log out".includes(ql)) {
            S("Lock Screen", "lock", "lock"); S("Sleep", "sleep", "moon"); S("Restart\u2026", "restart", "restart"); S("Shut Down\u2026", "shutdown", "power"); S("Log Out", "logout", "logout");
        }
        addItems(sys, "SYSTEM");
        if (ql) {
            const mm = root.evalMath(q);
            if (mm !== null) addItems([{ kind: "calc", name: "= " + mm, raw: q, category: "Calculator", iconKey: "calc" }], "CALCULATOR");
            addItems([
                { kind: "action", name: "Search the Web for \u201c" + q + "\u201d", action: "web:" + q, iconKey: "web", category: "Search" },
                { kind: "action", name: "Search in Files", action: "filesearch:" + q, iconKey: "finder", category: "Search" }
            ], "SEARCH");
        }
        root.items = items; root.results = disp; root.selectedIndex = 0;
    }

    function setMode(m) {
        root.mode = m;
        root.selectedIndex = 0;
        if (m === "files" && root.recentItems.length === 0) runRecents();
        if (m === "clipboard" && root.clipItems.length === 0) runClip();
        root.buildResults();
    }

    function runRecents() { _recents.running = true; }
    function runClip() { _clip.running = true; }

    function moveSelection(delta) {
        if (root.items.length === 0) return;
        root.selectedIndex = (root.selectedIndex + delta + root.items.length) % root.items.length;
    }

    function openSelected() {
        const e = root.items[root.selectedIndex];
        if (!e) return;
        if (e.kind === "app") Apps.launch(e.exec);
        else if (e.kind === "file") ShellController.run("xdg-open " + root.shellQuote(e.path));
        else if (e.kind === "clip") ShellController.run("echo -n " + root.shellQuote(e.text) + " | wl-copy 2>/dev/null || true");
        else if (e.kind === "calc") ShellController.run("echo -n " + root.shellQuote(e.raw) + " | wl-copy 2>/dev/null || true");
        else if (e.kind === "action") {
            if (e.action.startsWith("web:")) ShellController.run("xdg-open 'https://www.google.com/search?q=" + encodeURIComponent(e.action.slice(4)) + "'");
            else if (e.action.startsWith("filesearch:")) root.openPath("~");
            else if (e.action.startsWith("action:")) {
                const sub = e.action.slice(7);
                if (sub === "msg") ShellController.run("xdg-open 'https://messages.google.com/web' 2>/dev/null || true");
                else if (sub === "note") ShellController.run("xdg-open 'obsidian://new' 2>/dev/null || true");
                else if (sub === "timer") ShellController.run("notify-send 'Timer' '5 minutes' 2>/dev/null || true");
                else if (sub === "shortcut") ShellController.run("xdg-open 'shortcuts://' 2>/dev/null || true");
                else ShellController.requestAction(e.action);
            }
            else ShellController.requestAction(e.action);
        }
        ShellController.spotlightOpen = false;
    }

    property var selectedItem: (root.items.length ? root.items[root.selectedIndex] : null)

    Connections {
        target: ShellController
        function onSpotlightOpenChanged() {
            if (ShellController.spotlightOpen) {
                root._opened = true;
                root._shown = true;
                root.query = "";
                root.mode = "search";
                root.selectedIndex = 0;
                searchField.text = "";
                root.circlesVisible = false;
                root.buildResults();
                openAnim.start();
                Qt.callLater(() => searchField.forceActiveFocus());
            } else {
                root._opened = false;
                closeAnim.start();
            }
        }
    }

    Connections {
        target: Apps
        function onReadyChanged() {
            if (ShellController.spotlightOpen) root.buildResults();
        }
    }

    SequentialAnimation {
        id: openAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "panelScale"; to: 1.0; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            NumberAnimation { target: root; property: "panelYOffset"; to: 0; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "panelOpacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "dimOpacity"; to: 1.0; duration: 240; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "panelScale"; to: 0.95; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "panelYOffset"; to: 10; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "panelOpacity"; to: 0.0; duration: 140; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "dimOpacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
        }
        ScriptAction { script: { root._shown = false; root.circlesVisible = false; } }
    }

    Rectangle {
        anchors.fill: parent
        color: root.dimColor
        opacity: root.dimOpacity
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            onClicked: ShellController.spotlightOpen = false
        }
    }

    Item {
        id: outerWrap
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.panelYOffset
        height: root.computeHeight()
        width: root.circlesVisible ? root.panelWidth + root.circleSize * 4 + root.circlesGap * 4 : root.panelWidth

        Behavior on width {
            NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
        }

        MouseArea {
            id: hoverZone
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 60
            height: root.searchH + 40
            hoverEnabled: true
            z: 10
            onEntered: { if (!root.circlesLocked) root.circlesVisible = true }
            onExited: { if (!root.circlesLocked && !searchField.activeFocus) root.circlesVisible = false }
        }

        // ── 4 CIRCLES CONTAINER WITH ENHANCED ANIMATION ──
        Row {
            id: circlesRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: panel.right
            anchors.leftMargin: root.circlesVisible ? root.circlesGap : 0
            spacing: root.circlesGap
            width: root.circlesVisible ? (root.circleSize * 4 + root.circlesGap * 3) : 0
            clip: false
            opacity: root.circlesVisible ? 1.0 : 0.0
            z: 100

            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Repeater {
                model: [
                    { m: "apps",      tip: "Apps" },
                    { m: "files",     tip: "Files" },
                    { m: "actions",   tip: "Actions" },
                    { m: "clipboard", tip: "Clipboard" }
                ]

                delegate: Item {
                    id: circleBtn
                    width: root.circleSize; height: root.circleSize
                    property bool isActive: root.mode === modelData.m
                    property bool isHover: circleMA.containsMouse

                    opacity: root.circlesVisible ? 1.0 : 0.0
                    scale: root.circlesVisible ? (circleBtn.isHover ? 1.15 : 1.0) : 0.3

                    Behavior on opacity {
                        SequentialAnimation {
                            PauseAnimation { duration: index * 45 }
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                    }
                    Behavior on scale {
                        SequentialAnimation {
                            PauseAnimation { duration: root.circlesVisible ? index * 45 : 0 }
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: circleBtn.isActive ? root.accent
                             : circleBtn.isHover ? Qt.rgba(255, 255, 255, 0.35)
                             : root.circleBg
                        border.color: circleBtn.isActive ? Qt.rgba(12, 132, 255, 0.8)
                                    : circleBtn.isHover ? Qt.rgba(255, 255, 255, 0.5)
                                    : root.circleBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on border.color { ColorAnimation { duration: 160 } }
                    }

                    Canvas {
                        anchors.centerIn: parent
                        width: 20; height: 20
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset()
                            var c = "#ffffff"
                            ctx.strokeStyle = c; ctx.fillStyle = c
                            ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"

                            if (modelData.m === "apps") {
                                ctx.beginPath()
                                ctx.moveTo(10, 2); ctx.lineTo(2, 17); ctx.lineTo(5.5, 17)
                                ctx.lineTo(7.5, 12); ctx.lineTo(12.5, 12); ctx.lineTo(14.5, 17); ctx.lineTo(18, 17)
                                ctx.closePath(); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(8.5, 9.5); ctx.lineTo(11.5, 9.5); ctx.stroke()
                            } else if (modelData.m === "files") {
                                ctx.beginPath()
                                ctx.moveTo(2, 4.5); ctx.lineTo(2, 15.5); ctx.lineTo(18, 15.5)
                                ctx.lineTo(18, 4.5); ctx.lineTo(10, 4.5); ctx.lineTo(8, 2); ctx.lineTo(2, 2)
                                ctx.closePath(); ctx.stroke()
                            } else if (modelData.m === "actions") {
                                ctx.beginPath(); ctx.moveTo(10, 2); ctx.lineTo(17, 5.5); ctx.lineTo(10, 9); ctx.lineTo(3, 5.5); ctx.closePath(); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(3, 8.5); ctx.lineTo(10, 12); ctx.lineTo(17, 8.5); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(3, 11.5); ctx.lineTo(10, 15); ctx.lineTo(17, 11.5); ctx.stroke()
                            } else if (modelData.m === "clipboard") {
                                ctx.beginPath(); ctx.roundedRect(5, 1, 11, 14, 1.5); ctx.stroke()
                                ctx.beginPath(); ctx.roundedRect(3, 4.5, 11, 14, 1.5); ctx.stroke()
                                ctx.beginPath(); ctx.moveTo(5.5, 8.5); ctx.lineTo(9.5, 8.5); ctx.moveTo(5.5, 11.5); ctx.lineTo(9.5, 11.5); ctx.stroke()
                            }
                        }
                    }

                    Rectangle {
                        anchors.top: parent.bottom; anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: tipText.width + 12; height: 20; radius: 6
                        color: Qt.rgba(20, 20, 25, 0.75)
                        border.color: Qt.rgba(255, 255, 255, 0.3)
                        border.width: 1
                        visible: circleBtn.isHover
                        opacity: circleBtn.isHover ? 1.0 : 0.0
                        scale: circleBtn.isHover ? 1.0 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Text {
                            id: tipText
                            anchors.centerIn: parent
                            text: modelData.tip
                            font { family: "SF Pro Display"; pixelSize: 10; weight: Font.Medium }
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: circleMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (modelData.m === "apps") root.placeholderText = "Applications"
                            else if (modelData.m === "files") root.placeholderText = "Files"
                            else if (modelData.m === "actions") root.placeholderText = "Actions"
                            else if (modelData.m === "clipboard") root.placeholderText = "Clipboard"
                        }
                        onExited: root.placeholderText = "Spotlight Search"
                        onClicked: {
                            root.circlesLocked = true
                            if (root.mode === modelData.m) root.setMode("search")
                            else root.setMode(modelData.m)
                        }
                    }
                }
            }
        }

        Item {
            id: panel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: root.circlesVisible ? root.panelWidth - (root.circleSize * 4 + root.circlesGap * 4) : root.panelWidth
            height: root.computeHeight()
            scale: root.panelScale
            opacity: root.panelOpacity

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

            // ── Liquid Glass Frame Container ──
            Item {
                id: glassBase
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    radius: root.panelRadius
                    color: root.glassBg
                    border.color: root.glassBorder
                    border.width: 1

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: root.panelRadius - 1
                        color: "transparent"
                        border.color: root.glassHighlight
                        border.width: 1
                        opacity: root.glassSpecular
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── Direct Search Input Container ──
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.searchH + root.searchPadH * 2
                    Layout.topMargin: root.searchPadH

                    Item {
                        id: searchContainer
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        height: root.searchH

                        Item {
                            anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18
                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = root.sFgDim; ctx.lineWidth = 1.6; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                    ctx.beginPath(); ctx.arc(7.5, 7.5, 5.5, 0, Math.PI * 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(11.5, 11.5); ctx.lineTo(15.5, 15.5); ctx.stroke()
                                }
                            }
                        }

                        TextInput {
                            id: searchField
                            anchors.left: parent.left; anchors.leftMargin: 38
                            anchors.right: parent.right; anchors.rightMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            height: root.searchH
                            color: root.sFg
                            font { family: "SF Pro Display"; pixelSize: 15; weight: Font.Normal }
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true; clip: true; cursorVisible: root._opened
                            focus: true
                            onActiveFocusChanged: {
                                if (activeFocus) root.circlesLocked = false
                            }
                            Keys.onUpPressed: (event) => { root.moveSelection(-1); event.accepted = true }
                            Keys.onDownPressed: (event) => { root.moveSelection(1); event.accepted = true }
                            Keys.onReturnPressed: (event) => { root.openSelected(); event.accepted = true }
                            Keys.onEscapePressed: (event) => { ShellController.spotlightOpen = false; event.accepted = true }
                            Keys.onPressed: (event) => {
                                if (event.modifiers & Qt.ControlModifier) {
                                    if (event.key === Qt.Key_1) { root.setMode("apps"); event.accepted = true; }
                                    else if (event.key === Qt.Key_2) { root.setMode("files"); event.accepted = true; }
                                    else if (event.key === Qt.Key_3) { root.setMode("actions"); event.accepted = true; }
                                    else if (event.key === Qt.Key_4) { root.setMode("clipboard"); event.accepted = true; }
                                }
                            }
                            onTextChanged: { root.query = text; root.buildResults(); _fdDeb.restart(); if (text.length > 0) root.circlesVisible = false }
                        }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 38; anchors.verticalCenter: parent.verticalCenter
                            text: root.placeholderText
                            font { family: "SF Pro Display"; pixelSize: 15; weight: Font.Normal }
                            color: root.placeholderFg
                            visible: searchField.text.length === 0
                        }

                        Rectangle {
                            id: clearBtn
                            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20; radius: 10
                            color: clearMA.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : "transparent"
                            visible: root.query.length > 0
                            Canvas {
                                anchors.centerIn: parent; width: 14; height: 14
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.85); ctx.lineWidth = 1.4
                                    ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 1, 0, Math.PI * 2); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(width*0.35, height*0.35); ctx.lineTo(width*0.65, height*0.65)
                                    ctx.moveTo(width*0.65, height*0.35); ctx.lineTo(width*0.35, height*0.65); ctx.stroke()
                                }
                            }
                            MouseArea { id: clearMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { searchField.text = ""; root.query = ""; root.buildResults(); searchField.forceActiveFocus() }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: searchContainer
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: { if (!root.circlesLocked) root.circlesVisible = true }
                        onExited: { if (!root.circlesLocked && !searchField.activeFocus) root.circlesVisible = false }
                        onPressed: (mouse) => { mouse.accepted = false }
                        onReleased: (mouse) => { mouse.accepted = false }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.leftMargin: 12; Layout.rightMargin: 12; color: root.divider; visible: root.hasBody }

                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    ListView {
                        id: resultList
                        visible: root.mode !== "apps"
                        anchors.fill: parent; anchors.topMargin: 4; anchors.bottomMargin: 4; anchors.leftMargin: 8; anchors.rightMargin: 8
                        model: root.results; spacing: 2; boundsBehavior: Flickable.StopAtBounds; clip: true

                        delegate: Item {
                            required property var modelData
                            width: resultList.width
                            height: modelData.isHeader === true ? root.headerH : root.rowH

                            Text {
                                visible: modelData.isHeader === true
                                anchors.left: parent.left; anchors.leftMargin: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                                text: modelData.title || ""
                                font { family: "SF Pro Display"; pixelSize: 10; weight: Font.DemiBold }
                                color: root.headerFg
                            }

                            Rectangle {
                                visible: modelData.isHeader !== true
                                anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                                radius: 8
                                color: {
                                    if (root.selectedIndex === modelData._idx) return root.selectionBg;
                                    if (rowHover.containsMouse) return root.hoverBg;
                                    return "transparent";
                                }
                                border.color: root.selectedIndex === modelData._idx ? Qt.rgba(255, 255, 255, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            RowLayout {
                                visible: modelData.isHeader !== true
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 10

                                Image {
                                    visible: modelData.kind === "app"
                                    Layout.preferredWidth: root.iconSize; Layout.preferredHeight: root.iconSize; Layout.alignment: Qt.AlignVCenter
                                    source: modelData.icon || ""
                                    sourceSize { width: root.iconSize * 2; height: root.iconSize * 2 }
                                    asynchronous: true; smooth: true
                                }

                                Item {
                                    visible: modelData.kind !== "app"
                                    Layout.preferredWidth: root.iconSize; Layout.preferredHeight: root.iconSize; Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        Layout.fillWidth: true; text: modelData.name || ""
                                        font { family: "SF Pro Display"; pixelSize: 13; weight: Font.Normal }
                                        color: root.sFg
                                        elide: Text.ElideRight; maximumLineCount: 1
                                    }
                                    Text {
                                        Layout.fillWidth: true; visible: !!modelData.category && modelData.category.length > 0
                                        text: modelData.category || ""
                                        font { family: "SF Pro Text"; pixelSize: 11; weight: Font.Normal }
                                        color: root.sFgDim
                                        elide: Text.ElideRight; maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                visible: modelData.isHeader !== true; id: rowHover
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = modelData._idx
                                onClicked: { root.selectedIndex = modelData._idx; root.openSelected() }
                            }
                        }
                        onCountChanged: { if (root.selectedIndex >= root.items.length) root.selectedIndex = 0 }
                    }

                    GridView {
                        id: resultGrid
                        visible: root.mode === "apps"
                        anchors.fill: parent; anchors.margins: 6
                        cellWidth: Math.floor(width / 2); cellHeight: 46
                        model: root.items; clip: true

                        delegate: Item {
                            required property var modelData
                            width: resultGrid.cellWidth; height: resultGrid.cellHeight

                            Rectangle {
                                anchors.fill: parent; anchors.margins: 3; radius: 8
                                color: {
                                    if (root.selectedIndex === modelData._idx) return root.selectionBg;
                                    if (gridHover.containsMouse) return root.hoverBg;
                                    return "transparent";
                                }
                                border.color: root.selectedIndex === modelData._idx ? Qt.rgba(255, 255, 255, 0.4) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 8
                                Image {
                                    Layout.preferredWidth: 26; Layout.preferredHeight: 26; Layout.alignment: Qt.AlignVCenter
                                    source: modelData.icon || ""; sourceSize { width: 52; height: 52 }
                                    asynchronous: true; smooth: true
                                }
                                Text {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                                    text: modelData.name || ""
                                    font { family: "SF Pro Display"; pixelSize: 13; weight: Font.Normal }
                                    color: root.sFg
                                    elide: Text.ElideRight; maximumLineCount: 1
                                }
                            }

                            MouseArea { id: gridHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = modelData._idx
                                onClicked: { root.selectedIndex = modelData._idx; root.openSelected() }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent; text: "No Results Found"
                        font { family: "SF Pro Display"; pixelSize: 14; weight: Font.Normal }
                        color: root.sFgDim
                        visible: root.query.length > 0 && root.items.length === 0
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.leftMargin: 12; Layout.rightMargin: 12; color: root.divider; visible: root.selectedItem !== null && root.mode !== "apps" }

                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: root.stripH; Layout.leftMargin: 14; Layout.rightMargin: 14
                    visible: root.selectedItem !== null && root.mode !== "apps"; spacing: 12

                    Item {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36; Layout.alignment: Qt.AlignVCenter
                        Image {
                            visible: root.selectedItem && root.selectedItem.kind === "app"
                            anchors.fill: parent
                            source: root.selectedItem ? root.selectedItem.icon || "" : ""
                            sourceSize { width: 72; height: 72 }
                            asynchronous: true; smooth: true
                        }
                    }

                    ColumnLayout { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 1
                        Text { Layout.fillWidth: true; text: root.selectedItem ? root.selectedItem.name || "" : ""
                            font { family: "SF Pro Display"; pixelSize: 13; weight: Font.Medium }
                            color: root.sFg; elide: Text.ElideRight; maximumLineCount: 1 }
                        Text { Layout.fillWidth: true; visible: root.selectedItem && !!root.selectedItem.category
                            text: root.selectedItem ? root.selectedItem.category || "" : ""
                            font { family: "SF Pro Text"; pixelSize: 11; weight: Font.Normal }
                            color: root.sFgDim; elide: Text.ElideRight; maximumLineCount: 1 }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 68; Layout.preferredHeight: 26; Layout.alignment: Qt.AlignVCenter; radius: 8
                        color: openBtnMA.containsMouse ? "#0062cc" : root.accent
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Open"
                            font { family: "SF Pro Display"; pixelSize: 12; weight: Font.DemiBold }
                            color: "#ffffff" }
                        MouseArea { id: openBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openSelected() }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: root.footerH; Layout.leftMargin: 14; Layout.rightMargin: 14
                    color: "transparent"; visible: root.hasBody
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 16
                        Row { spacing: 4
                            Rectangle { width: 18; height: 16; radius: 4; color: Qt.rgba(255,255,255,0.15); border.color: Qt.rgba(255,255,255,0.25); border.width: 1
                                Text { anchors.centerIn: parent; text: "\u2191"; font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Medium } color: root.sFgDim } }
                            Rectangle { width: 18; height: 16; radius: 4; color: Qt.rgba(255,255,255,0.15); border.color: Qt.rgba(255,255,255,0.25); border.width: 1
                                Text { anchors.centerIn: parent; text: "\u2193"; font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Medium } color: root.sFgDim } }
                            Text { text: "Navigate"; font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Normal } color: root.sFgDim; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Row { spacing: 4
                            Rectangle { width: 22; height: 16; radius: 4; color: Qt.rgba(255,255,255,0.15); border.color: Qt.rgba(255,255,255,0.25); border.width: 1
                                Text { anchors.centerIn: parent; text: "\u21a9"; font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Medium } color: root.sFgDim } }
                            Text { text: "Open"; font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Normal } color: root.sFgDim; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Row { spacing: 4
                            Rectangle { width: 28; height: 16; radius: 4; color: Qt.rgba(255,255,255,0.15); border.color: Qt.rgba(255,255,255,0.25); border.width: 1
                                Text { anchors.centerIn: parent; text: "esc"; font { family: "SF Pro Text"; pixelSize: 9; weight: Font.Medium } color: root.sFgDim } }
                            Text { text: "Close"; font { family: "SF Pro Text"; pixelSize: 10; weight: Font.Normal } color: root.sFgDim; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }
    }

    Timer { id: _fdDeb; interval: 140; repeat: false; onTriggered: root.runFd() }

    Process {
        id: _fd; running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(s => s.trim()).filter(Boolean).slice(0, 8);
                const out = [];
                for (const p of lines) {
                    const base = p.split("/").pop();
                    let dir = p.replace(new RegExp("/" + base.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$"), "");
                    out.push({ name: base, path: p, dir: dir || "~" });
                }
                root.fileItems = out; root.buildResults();
            }
        }
    }

    Process {
        id: _recents; running: false
        command: ["bash", "-c", "fd -t f -H --changed-within 60d -E .git -d 6 ~ 2>/dev/null | head -40"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(s => s.trim()).filter(Boolean);
                const out = [];
                for (const p of lines) {
                    const base = p.split("/").pop();
                    let dir = p.replace(new RegExp("/" + base.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$"), "");
                    out.push({ name: base, path: p, dir: dir || "~" });
                }
                root.recentItems = out; if (root.mode === "files") root.buildResults();
            }
        }
    }

    Process {
        id: _clip; running: false
        command: ["bash", "-c", "cliphist list 2>/dev/null | tail -n 30"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").map(s => s.trim()).filter(Boolean);
                const out = [];
                for (const l of lines) {
                    const t = l.replace(/^\d+\t/, "");
                    if (t) out.push({ text: t.length > 120 ? t.slice(0, 120) + "\u2026" : t });
                }
                root.clipItems = out; if (root.mode === "clipboard") root.buildResults();
            }
        }
    }

    Component.onCompleted: root.buildResults()
}