import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../../services"
import "../common"

PanelWindow {
        id: root

    // ── 1. الخصائص العادية والمخصصة (يجب أن تكون في البداية معاً) ──
    screen: Quickshell.screens[0]
    anchors {
        bottom: true
        left: true
        right: true
    }
    
    height: root.capsuleHeight + root.iconZoomFactor + root.revealStrip
    property bool isTrashFull: false

    // ── 2. العناصر المستقلة (تأتي بعد الخصائص مباشرة) ──
    Process {
        id: trashChecker
        command: ["sh", "-c", "ls -A ~/.local/share/Trash/files"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: { root.isTrashFull = text.trim().length > 0; }
        }
    }

    Process {
        id: trashOpener
        command: ["/home/revo/.local/bin/nautilus", "trash:///"]
        running: false
    }

    Timer {
        id: trashTimer
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!trashChecker.running) trashChecker.running = true; }
    }

    // ── Downloads stack + screenshot items ──
    property bool downloadsOpen: false
    property bool fanSuppressNextClick: false
    property var dlItems: []
    property var shotItems: []
    property var seenShots: ({})
    property bool shotsSeeded: false
    property real shotSeedMax: 0
    property bool shotDragging: false
    property bool shotOverTrash: false

    property real fanRowH: 66
    property real fanListH: 220
    property real fanPadX: 14

    readonly property var fanModel: root.dlItems.slice(0, 60).map(p => ({ path: p }))

    function refreshDownloads() {
        if (!dlScan.running) dlScan.running = true;
    }

    function isThumb(p) {
        return /\.(png|jpe?g|webp|gif|bmp|svg|avif)$/i.test(p);
    }

    function dlIconFor(p) {
        const e = (p.split(".").pop() || "").toLowerCase();
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(e)) return "video-player.png";
        if (["mp3", "flac", "wav", "ogg", "m4a"].includes(e)) return "elisa.png";
        if (["deb", "rpm", "appimage"].includes(e)) return "app-store.png";
        return "file-doc.svg";
    }

    // ── هندسة قائمة الـDownloads: عمود مستقيم فوق أيقونة الدوك مع تمرير ──
    // ملاحظة: pos بإحداثيات نافذة الدوك (النافذة نفسها أسفل الشاشة)،
    // و anchor.rect يُRelativeTo نفس النافذة، فالقائمة تمتد للأساسب (y سالب).
    function layoutDownloads() {
        const screen = Quickshell.screens[0];
        const pos = dlSlot.mapToItem(null, dlSlot.width / 2, 14);
        const n = Math.max(1, root.fanModel.length);
        const w = 400;
        const headH = 72;   // زر Open in Finder (12 + 46 + 14)
        const padB = 14;
        const listNeed = n * root.fanRowH;
        const visibleRows = 7;   // سبعة ملفات فقط ظاهرة (والباقي بالتمرير)
        const maxH = Math.min(screen.height - 12, headH + visibleRows * root.fanRowH + padB);
        const h = Math.min(headH + listNeed + padB, maxH);
        const winTop = screen.height - root.height - 12;   // أعلى النافذة على الشاشة
        const x = Math.max(6, Math.min(screen.width - w - 6, Math.round(pos.x - w / 2)));
        const y = Math.max(6 - winTop, Math.round(pos.y + 6 - h));
        downloadsFan.implicitWidth = w;
        downloadsFan.implicitHeight = h;
        downloadsFan.anchor.rect.x = x;
        downloadsFan.anchor.rect.y = y;
        root.fanListH = Math.max(72, h - headH - padB);
        return { n: n, w: w, h: h, x: x, y: y };
    }

    // ميلان القائمة: أعلى العرض لليمين وأسفله لليسار (زي فن الستاك بالماك)
    function fanRowX(yInView) {
        return -yInView * 0.25;
    }

    function openDownloads() {
        ShellController.closeAll();
        const g = root.layoutDownloads();
        root.downloadsOpen = true;
        root.refreshDownloads();
        DockApps.stackState = "n=" + g.n
            + " panel=" + g.w + "x" + Math.round(g.h)
            + " listH=" + Math.round(root.fanListH)
            + " contentH=" + (g.n * root.fanRowH)
            + " scroll=" + (g.n * root.fanRowH > root.fanListH)
            + " slant=" + Math.round(0.25 * root.fanListH) + "px"
            + " pos=" + g.x + "," + g.y;
        console.log("[DownloadsStack]", DockApps.stackState);
    }

    onDlItemsChanged: {
        if (root.downloadsOpen) root.layoutDownloads();
    }

    onDownloadsOpenChanged: {
        DockApps.downloadsOpen = root.downloadsOpen;
        if (root.downloadsOpen) {
            GlobalFocusGrab.addDismissable(downloadsFan);
        } else {
            GlobalFocusGrab.removeDismissable(downloadsFan);
        }
    }

    onFanSuppressNextClickChanged: {
        if (root.fanSuppressNextClick) suppressTimer.restart();
    }

    Timer {
        id: suppressTimer
        interval: 400
        onTriggered: root.fanSuppressNextClick = false
    }

    Component.onCompleted: {
        dlScan.running = true;
        DockApps.stackOpen = function() {
            if (root.downloadsOpen) root.downloadsOpen = false;
            else root.openDownloads();
        };
        DockApps.iconLocalPos = root.iconLocalPos;
    }

    // local centre "x,y" of the Dock icon for a window class (genie target)
    function iconLocalPos(cls) {
        var q = (cls || "").toLowerCase().trim();
        if (!q || !dockRow) return "";
        var kids = dockRow.children;
        for (var i = 0; i < kids.length; i++) {
            var c = kids[i];
            var app = c.app;
            if (!app) continue;
            var pos = (c.x + c.width / 2) + "," + (c.y + c.height - 14 - root.iconBase / 2);
            var ids = app.appIds || [];
            for (var j = 0; j < ids.length; j++) {
                var id = (ids[j] || "").toLowerCase();
                if (id && (id === q || id.indexOf(q) !== -1 || q.indexOf(id) !== -1))
                    return pos;
            }
            var nm = (app.name || "").toLowerCase();
            var ex = (app.exec || "").toLowerCase();
            if ((nm && (q.indexOf(nm) !== -1 || nm.indexOf(q) !== -1)) ||
                (ex && q.indexOf(ex) !== -1))
                return pos;
        }
        return "";
    }

    Process {
        id: dlScan
        running: false
        command: ["sh", "-c", "find \"$HOME/Downloads\" -mindepth 1 -maxdepth 1 -printf '%T@|%p\\n' 2>/dev/null | sort -rn | head -60"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("|");
                    if (i > 0) out.push(line.slice(i + 1));
                }
                // ما نعيد الإنشاء إذا المحتوى ما تغيّر (حتى ما ينحفظ الانميشن)
                const cur = root.dlItems;
                let same = cur.length === out.length;
                if (same) {
                    for (let i = 0; i < out.length; i++) {
                        if (cur[i] !== out[i]) { same = false; break; }
                    }
                }
                if (same) return;
                root.dlItems = out;
            }
        }
    }

    Timer {
        interval: 2500
        running: root.downloadsOpen
        repeat: true
        onTriggered: root.refreshDownloads()
    }

    Process {
        id: shotScan
        running: false
        command: ["sh", "-c", "find \"$HOME/Pictures\" -maxdepth 1 -type f \\( -iname '*hyprshot*' -o -iname 'screenshot*' \\) -printf '%T@|%p\\n' 2>/dev/null | sort -rn | head -15"]
        stdout: StdioCollector {
            onStreamFinished: {
                const entries = [];
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("|");
                    if (i > 0) entries.push({ t: parseFloat(line.slice(0, i)), p: line.slice(i + 1) });
                }
                if (!root.shotsSeeded) {
                    const seen = {};
                    for (const e of entries) seen[e.p] = true;
                    root.seenShots = seen;
                    root.shotSeedMax = entries.length > 0 ? entries[0].t : 0;
                    root.shotsSeeded = true;
                    return;
                }
                const fresh = [];
                for (const e of entries) {
                    if (!root.seenShots[e.p] && e.t > root.shotSeedMax) {
                        fresh.push(e.p);
                        root.seenShots[e.p] = true;
                    }
                }
                if (fresh.length === 0) return;
                let items = root.shotItems.slice();
                for (const p of fresh) {
                    items = items.filter(x => x.path !== p);
                    items.unshift({ path: p, name: p.split("/").pop() });
                }
                root.shotItems = items.slice(0, 5);
            }
        }
    }

    Timer {
        id: shotTimer
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!shotScan.running) shotScan.running = true; }
    }

    Process {
        id: dlOpener
        running: false
        stdout: StdioCollector {}
    }

    Process {
        id: shotTrash
        running: false
        stdout: StdioCollector {}
        onExited: { if (!trashChecker.running) trashChecker.running = true; }
    }


    // ── الألوان وتصميم الزجاج ──
    readonly property color glassBorder: Qt.rgba(255, 255, 255, 0.25)
    readonly property color glassHighlight: Qt.rgba(255, 255, 255, 0.45)
    readonly property color selectionBg: Qt.rgba(255, 255, 255, 0.22)
    readonly property color hoverBg: Qt.rgba(255, 255, 255, 0.15)
    readonly property color divider: Qt.rgba(255, 255, 255, 0.18)
    readonly property color headerFg: Qt.rgba(255, 255, 255, 0.65)
    readonly property color sFg: "#ffffff"
    readonly property color sFgDim: Qt.rgba(255, 255, 255, 0.85)
    readonly property color accent: "#0c84ff"

    readonly property int slotWidth: Appearance.dockIconSize + 12
    readonly property int capsuleHeight: 80
    readonly property int totalSlots: DockApps.dockItems.length + root.shotItems.length + 2
    readonly property int sepCount: DockApps.runningApps.length > 0 ? 1 : 0
    readonly property int capsuleWidth: root.totalSlots * root.slotWidth + root.sepCount * 9 + 20
    
    margins {
        bottom: Math.round(8 + root.hideOffset)
        left: Math.max(0, (Quickshell.screens[0].width - root.capsuleWidth) / 2)
        right: Math.max(0, (Quickshell.screens[0].width - root.capsuleWidth) / 2)
    }
   color: "transparent"
    WlrLayershell.namespace: "macos:dock"

    readonly property int iconZoomFactor: Appearance.dockMagnification ? Math.round(Appearance.dockZoom) : 0
    readonly property int revealStrip: 6
    property real hideOffset: Appearance.dockAutohide && !rootReveal.hovered
        ? -(root.height - root.revealStrip) - 8 : 0
    Behavior on hideOffset {
        enabled: Appearance.dockAnimateHide
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }
    HoverHandler { id: rootReveal }
    readonly property int iconBase: Appearance.dockIconSize
    property int instantHoveredIndex: -1
    property real instantHoveredFraction: 0.5
    property bool menuOpen: false
    property int menuSlotIndex: -1
    property var menuTarget: null
    readonly property var menuSlot: root.menuSlotIndex >= 0 && root.menuSlotIndex < DockApps.dockItems.length
        ? DockApps.dockItems[root.menuSlotIndex] : null

    property int dragSourceIndex: -1
    property int dragTargetIndex: -1

    readonly property string activeAppId: ToplevelManager.activeToplevel?.appId ?? ""
    function isActiveApp(slot) {
        return root.activeAppId !== "" && slot.app.appIds.includes(root.activeAppId);
    }

    function openSlotMenu(slot) {
        if (!DockApps.isRunning(slot.app.appIds)) return;
        const pos = slot.mapToItem(null, slot.width / 2, 0);
        root.menuSlotIndex = slot.index;
        root.menuTarget = slot.app;
        slotMenu.relativeX = Math.max(6, Math.min(root.width - slotMenu.width - 6, pos.x - slotMenu.width / 2));
        slotMenu.relativeY = -(slotMenu.height + 12);
        ShellController.closeAll();
        root.downloadsOpen = false;
        root.menuOpen = true;
    }

    onMenuOpenChanged: {
        if (root.menuOpen) {
            GlobalFocusGrab.addDismissable(slotMenu);
        } else {
            GlobalFocusGrab.removeDismissable(slotMenu);
            root.menuSlotIndex = -1;
        }
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.menuOpen = false;
            if (root.downloadsOpen) {
                root.fanSuppressNextClick = true;
                root.downloadsOpen = false;
            }
        }
    }

    // ── مكون الزجاج المعدل ليتناسب مع Quickshell ──
    component ShaderLiquidGlass: Item {
        id: glass

        property real radius: 26
        property real roundness: 7.5
        property color tint: "#1e1e24" // لون داكن شفاف افتراضي متناسق
        property real tintAlpha: 0.65
        property bool solidMode: false
        // true => follow the Appearance "Liquid Glass" setting (Clear / Tinted + intensity)
        property bool followSetting: true
        property real alphaBoost: 0

        readonly property color effTint: followSetting ? Appearance.liquidGlassTint : tint
        readonly property real effAlpha: followSetting
            ? Math.min(0.95, Appearance.liquidGlassAlpha + alphaBoost)
            : tintAlpha

        property real _mouseU: -1
        property real _mouseV: -1
        property real _mouseFade: 0

        Behavior on _mouseFade {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        readonly property var wallpaperItem: null
        readonly property bool active: false

      Rectangle {
            id: capsuleBg
            anchors.fill: parent
            radius: glass.radius
            color: Qt.rgba(glass.effTint.r, glass.effTint.g, glass.effTint.b, glass.effAlpha)
            border.color: root.glassBorder
            border.width: 1
        }
    }

    PopupWindow {
        id: slotMenu
        parentWindow: root
        screen: Quickshell.screens[0]
        width: 220
        height: menuCol.implicitHeight + 12
        visible: root.menuOpen
        color: "transparent"

        ShaderLiquidGlass {
            id: popupGlass
            anchors.fill: parent
            radius: 14
            alphaBoost: 0.45

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onPositionChanged: (mouse) => {
                    popupGlass._mouseU = mouse.x / Math.max(1, popupGlass.width)
                    popupGlass._mouseV = mouse.y / Math.max(1, popupGlass.height)
                    popupGlass._mouseFade = 1
                }
                onEntered: popupGlass._mouseFade = 1
                onExited: { popupGlass._mouseFade = 0; popupGlass._mouseU = -1; popupGlass._mouseV = -1; }
            }

            ColumnLayout {
                id: menuCol
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                component MenuLabel: Rectangle {
                    id: label
                    property string text: ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 6
                    color: "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: label.text
                        font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.DemiBold }
                        color: root.headerFg
                        elide: Text.ElideRight
                        width: parent.width - 20
                    }
                }

                component MenuItem: Rectangle {
                    id: item
                    property string label: ""
                    property var onClick: null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 6
                    color: "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: item.label
                        font { family: Appearance.fontFamily; pixelSize: 13 }
                        color: root.sFg
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: item.color = root.hoverBg
                        onExited: item.color = "transparent"
                        onClicked: {
                            root.menuOpen = false;
                            if (item.onClick) item.onClick();
                        }
                    }
                }

                component MenuSeparator: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 3
                    Layout.bottomMargin: 3
                    color: root.divider
                }

                MenuLabel { text: root.menuSlot ? root.menuSlot.name : "" }
                MenuSeparator {}

                MenuItem {
                    label: "Open"
                    visible: !root.menuTarget || !DockApps.isRunning(root.menuTarget.appIds)
                    onClick: () => {
                        if (root.menuTarget) {
                            if (typeof root.menuTarget.launch === "function") root.menuTarget.launch();
                            else if (root.menuTarget.exec) Apps.launch(root.menuTarget.exec);
                        }
                    }
                }
                MenuItem {
                    label: "Quit"
                    visible: root.menuTarget && DockApps.isRunning(root.menuTarget.appIds)
                    onClick: () => { if (root.menuTarget) DockApps.quitApp(root.menuTarget.appIds); }
                }
                MenuItem {
                    label: "Force Quit…"
                    visible: root.menuTarget && DockApps.isRunning(root.menuTarget.appIds)
                    onClick: () => { if (root.menuTarget) DockApps.forceKillApp(root.menuTarget.appIds); }
                }

                MenuSeparator {}

                MenuItem {
                    readonly property bool pinned: root.menuTarget ? DockApps.isPinned(root.menuTarget.appIds[0]) : false
                    label: pinned ? "✓ Keep in Dock" : "Keep in Dock"
                    onClick: () => {
                        if (!root.menuTarget) return;
                        if (pinned) {
                            DockApps.unpinApp(root.menuTarget);
                        } else {
                            DockApps.pinApp(root.menuTarget);
                        }
                    }
                }
                MenuItem { label: "Open at Login"; onClick: () => {} }
                MenuItem { label: "Show in Finder"; onClick: () => {} }
            }
        }
    }

  Item {
    id: capsule
    anchors.fill: parent

    PopupWindow {
        id: downloadsFan
        anchor.window: root
        implicitWidth: 360
        implicitHeight: 300
        visible: root.downloadsOpen || fanStage.t > 0.01
        color: "transparent"

        Item {
            id: fanStage
            anchors.fill: parent
            property real t: root.downloadsOpen ? 1 : 0
            opacity: t
            scale: 0.9 + 0.1 * t
            transformOrigin: Item.Bottom
            Behavior on t {
                NumberAnimation { duration: root.downloadsOpen ? 260 : 420; easing.type: Easing.OutCubic }
            }

            // ── زر Open in Finder الدائري (سهم داخل مربع) ──
            Rectangle {
                id: fanFinderBtn
                anchors.top: parent.top
                anchors.topMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 14
                width: 46
                height: 46
                radius: 23
                color: fanFinderHover.hovered ? "#ffffff" : Qt.rgba(0.93, 0.93, 0.95, 0.95)
                border.color: Qt.rgba(0, 0, 0, 0.14)
                border.width: 1

                HoverHandler { id: fanFinderHover }

                Canvas {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    onPaint: {
                        const c = getContext("2d");
                        c.reset();
                        c.strokeStyle = "#1a1a1a";
                        c.lineWidth = 2.2;
                        c.lineCap = "round";
                        c.lineJoin = "round";
                        c.beginPath();
                        c.moveTo(12.5, 3);
                        c.lineTo(5.5, 3);
                        c.quadraticCurveTo(3, 3, 3, 5.5);
                        c.lineTo(3, 13.5);
                        c.quadraticCurveTo(3, 16, 5.5, 16);
                        c.lineTo(13.5, 16);
                        c.quadraticCurveTo(16, 16, 16, 13.5);
                        c.lineTo(16, 7);
                        c.moveTo(6, 13);
                        c.lineTo(13.5, 5.5);
                        c.moveTo(8.5, 5.5);
                        c.lineTo(13.5, 5.5);
                        c.lineTo(13.5, 10.5);
                        c.stroke();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        dlOpener.command = ["/home/revo/.local/bin/nautilus", "--new-window", "file:///home/revo/Downloads"];
                        dlOpener.running = true;
                        root.downloadsOpen = false;
                    }
                }
            }

            Rectangle {
                id: fanFinderTip
                anchors.right: fanFinderBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: fanFinderBtn.verticalCenter
                visible: fanFinderHover.hovered
                width: fanFinderTipText.implicitWidth + 20
                height: 24
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.9)
                border.color: Qt.rgba(255, 255, 255, 0.15)
                border.width: 1

                Text {
                    id: fanFinderTipText
                    anchors.centerIn: parent
                    text: "Open in Finder"
                    font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.Medium }
                    color: "#ffffff"
                }
            }

            Flickable {
                id: fanFlick
                anchors.top: fanFinderBtn.bottom
                anchors.topMargin: 14
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.left: parent.left
                anchors.leftMargin: root.fanPadX
                anchors.right: parent.right
                anchors.rightMargin: root.fanPadX
                contentWidth: width
                contentHeight: fanCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                HoverHandler { id: fanFlickHover }

                Column {
                    id: fanCol
                    width: fanFlick.width

                    Repeater {
                        model: root.fanModel
                        delegate: Item {
                            id: fanItem
                            required property int index
                            required property var modelData
                            width: fanCol.width
                            height: root.fanRowH
                            x: root.fanRowX(fanItem.y - fanFlick.contentY)

                            // ── انميشن الظهور: يطلع من الدوك بالتتابع (الأسفل أولاً) ──
                            property real appearT: root.downloadsOpen ? 1 : 0
                            opacity: Math.min(1, fanItem.appearT * 2.5)
                            transform: [
                                Translate {
                                    x: (1 - fanItem.appearT) * 30
                                    y: (1 - fanItem.appearT) * 80
                                },
                                Scale {
                                    origin.x: fanItem.width / 2
                                    origin.y: fanItem.height
                                    xScale: 0.6 + 0.4 * fanItem.appearT
                                    yScale: 0.6 + 0.4 * fanItem.appearT
                                }
                            ]
                            Behavior on appearT {
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: root.downloadsOpen
                                            ? 40 + Math.max(0, 6 - Math.min(fanItem.index, 6)) * 48
                                            : 0
                                    }
                                    NumberAnimation { duration: 420; easing.type: Easing.OutQuint }
                                }
                            }

                            HoverHandler { id: rowHover }

                            Rectangle {
                                id: fanIcon
                                readonly property bool thumbBg: root.isThumb(fanItem.modelData.path)
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 46
                                height: 46
                                radius: 10
                                color: fanIcon.thumbBg ? "#1c1c1e" : "transparent"
                                border.color: Qt.rgba(0, 0, 0, 0.18)
                                border.width: fanIcon.thumbBg ? 1 : 0
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: fanIcon.thumbBg ? 2 : 4
                                    source: fanIcon.thumbBg
                                        ? "file://" + encodeURI(fanItem.modelData.path)
                                        : DockApps.iconSource(root.dlIconFor(fanItem.modelData.path))
                                    fillMode: fanIcon.thumbBg ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                    asynchronous: true
                                    mipmap: true
                                }
                            }

                            Rectangle {
                                id: fanPill
                                anchors.right: fanIcon.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 26
                                width: Math.min(fanPillText.implicitWidth + 20, fanCol.width - 160)
                                radius: 13
                                color: rowHover.hovered ? "#ffffff" : Qt.rgba(0.93, 0.93, 0.95, 0.95)
                                border.color: Qt.rgba(0, 0, 0, 0.12)
                                border.width: 1

                                Text {
                                    id: fanPillText
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: fanItem.modelData.path.split("/").pop()
                                    font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.Medium }
                                    color: "#1a1a1a"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    dlOpener.command = ["/usr/bin/xdg-open", fanItem.modelData.path];
                                    dlOpener.running = true;
                                    root.downloadsOpen = false;
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: fanScrollBar
                visible: fanCol.implicitHeight > fanFlick.height + 4
                x: fanFlick.x + fanFlick.width + 6
                y: fanFlick.y + (fanFlick.height - height)
                   * (fanFlick.contentY / Math.max(1, fanCol.implicitHeight - fanFlick.height))
                width: 3
                height: Math.max(28, fanFlick.height * fanFlick.height / fanCol.implicitHeight)
                radius: 1.5
                color: Qt.rgba(0, 0, 0, 0.4)
                opacity: (fanFlick.moving || fanFlickHover.hovered) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    ShaderLiquidGlass {
        id: capsuleBg
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.capsuleHeight
        radius: 26
        tint: "#121217"
        tintAlpha: 0.30
    }


        MouseArea {
            id: capsuleMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
        }

        RowLayout {
            id: dockRow
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0
            z: 2

                        component DockSeparator: Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.capsuleHeight - 30
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 15
                color: root.divider
                radius: 0.5
            }


            component DockSlot: Item {
                id: slot
                required property var modelData
                required property int index
                Layout.preferredWidth: root.slotWidth
                Layout.preferredHeight: parent.height

                property real dragXOffset: 0
                property real shiftOffset: {
                    if (root.dragSourceIndex === -1 || root.dragTargetIndex === -1) return 0;
                    if (slot.index === root.dragSourceIndex) return 0;
                    if (root.dragSourceIndex < root.dragTargetIndex) {
                        if (slot.index > root.dragSourceIndex && slot.index <= root.dragTargetIndex) {
                            return -root.slotWidth;
                        }
                    } else if (root.dragSourceIndex > root.dragTargetIndex) {
                        if (slot.index >= root.dragTargetIndex && slot.index < root.dragSourceIndex) {
                            return root.slotWidth;
                        }
                    }
                    return 0;
                }

                Behavior on shiftOffset {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                transform: Translate {
                    x: slot.index === root.dragSourceIndex ? slot.dragXOffset : slot.shiftOffset
                }

                z: slot.index === root.dragSourceIndex ? 100 : (slot.growSize > 0 ? 10 : 0)

                readonly property var app: slot.modelData

                readonly property real virtualCursorIndex: root.instantHoveredIndex !== -1
                    ? root.instantHoveredIndex + root.instantHoveredFraction - 0.5 : -1
                readonly property real distanceToCursor: slot.virtualCursorIndex !== -1
                    ? Math.abs(slot.index - slot.virtualCursorIndex) : -1
                readonly property real zoomMultiplier: {
                    const d = slot.distanceToCursor;
                    if (d === -1) return 0.0;
                    if (d <= 0.5) return 1.0 - d;
                    else if (d < 1.5) return 0.5 * (1.5 - d);
                    return 0.0;
                }
                property int growSize: Math.round(slot.zoomMultiplier * root.iconZoomFactor)
                readonly property real magScale: 1.0 + slot.growSize / root.iconBase
                property real bounceScale: 1.0
                property real bounceLift: 0.0
                property bool launching: false

                Behavior on growSize {
                    NumberAnimation { duration: 30; easing.type: Easing.InOutQuad }
                }

                onLaunchingChanged: {
                    if (launching) {
                        launchBounce.start();
                    } else {
                        launchBounce.stop();
                        bounceScale = 1.0;
                        bounceLift = 0.0;
                    }
                }

                onIsRunningChanged: {
                    if (slot.launching && DockApps.isRunning(slot.app.appIds)) {
                        slot.launching = false;
                    }
                }

                property bool isRunning: DockApps.isRunning(slot.app.appIds)

                ParallelAnimation {
                    id: launchBounce
                    loops: Animation.Infinite
                    running: false
                    SequentialAnimation {
                        NumberAnimation {
                            target: slot; property: "bounceScale"
                            to: 1.22; duration: 90; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: slot; property: "bounceScale"
                            to: 1.0; duration: 340; easing.type: Easing.OutBounce
                        }
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: slot; property: "bounceLift"
                            to: 12; duration: 90; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: slot; property: "bounceLift"
                            to: 0; duration: 340; easing.type: Easing.OutBounce
                        }
                    }
                }

                function bounce() {
                    bounceAnim.restart();
                }

                ParallelAnimation {
                    id: bounceAnim
                    running: false
                    onFinished: { slot.bounceScale = 1.0; slot.bounceLift = 0.0; }
                    SequentialAnimation {
                        NumberAnimation {
                            target: slot; property: "bounceScale"
                            to: 1.22; duration: 90; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: slot; property: "bounceScale"
                            to: 1.0; duration: 340; easing.type: Easing.OutBounce
                        }
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: slot; property: "bounceLift"
                            to: 12; duration: 90; easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: slot; property: "bounceLift"
                            to: 0; duration: 340; easing.type: Easing.OutBounce
                        }
                    }
                }

                Rectangle {
                    id: activeGlow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: icon.top
                    anchors.bottom: icon.bottom
                    anchors.topMargin: -7
                    anchors.bottomMargin: -3
                    width: 52 + 16
                    radius: 13
                    color: root.selectionBg
                    visible: opacity > 0
                    opacity: root.isActiveApp(slot) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Image {
                    id: icon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14 + slot.bounceLift
                    width: root.iconBase * slot.magScale
                    height: root.iconBase * slot.magScale
                    scale: slot.bounceScale
                    transformOrigin: Item.Bottom
                    source: DockApps.iconSource(DockApps.iconFor(slot.app.appIds[0]))
                    asynchronous: true
                    mipmap: true
                    smooth: true

                    // Icon & widget style (macOS Tahoe):
                    //   Clear  -> translucent liquid-glass icons
                    //   Tinted -> single-colour icons (baked into icons/tinted/)
                    opacity: Appearance.iconClearActive ? 0.55 : 1

                    Rectangle {
                        id: runningDot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -7
                        width: 5
                        height: 5
                        radius: 2.5
                        color: root.accent
                        visible: Appearance.dockIndicators && DockApps.isRunning(slot.app.appIds)
                    }
                }

                Rectangle {
                    id: badge
                    visible: DockApps.badgeFor(slot.app.appIds[0]) > 0
                    anchors.horizontalCenter: icon.horizontalCenter
                    anchors.verticalCenter: icon.top
                    anchors.verticalCenterOffset: 6
                    width: Math.max(20, badgeText.width + 14)
                    height: 20
                    radius: 10
                    color: "#ff3b30"

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: {
                            var count = DockApps.badgeFor(slot.app.appIds[0]);
                            return count > 0 ? count.toString() : "";
                        }
                        color: "#ffffff"
                        font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.Bold }
                    }
                }

                               Rectangle {
                    id: tooltip
                    visible: hoverHandler.hovered && root.dragSourceIndex === -1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: icon.top
                    anchors.bottomMargin: 8
                    width: tipText.width + 16
                    height: 22
                    radius: 6
                    // ── التعديل هنا ليكون أسود داكن ──
                    color: Qt.rgba(0, 0, 0, 0.9) // أسود نقي مع شفافية بسيطة جداً
                    border.color: Qt.rgba(255, 255, 255, 0.15) // تقليل سطوع خط الحدود المحيط بالاسم
                    border.width: 1
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Text {
                        id: tipText
                        anchors.centerIn: parent
                        text: slot.app.name
                        font { family: "SF Pro Display"; pixelSize: 11; weight: Font.Medium }
                        color: "#ffffff"
                    }
                }


                HoverHandler {
                    id: hoverHandler
                    enabled: root.dragSourceIndex === -1
                    onPointChanged: {
                        if (hoverHandler.hovered && root.instantHoveredIndex === slot.index) {
                            root.instantHoveredFraction =
                                Math.max(0.0, Math.min(1.0, hoverHandler.point.position.x / slot.width));
                        }
                    }
                    onHoveredChanged: {
                        if (hoverHandler.hovered) {
                            root.instantHoveredIndex = slot.index;
                            root.instantHoveredFraction = 0.5;
                        } else if (root.instantHoveredIndex === slot.index) {
                            root.instantHoveredIndex = -1;
                            root.instantHoveredFraction = 0.5;
                        }
                    }
                }

                MouseArea {
                    id: _ma
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true

                    property point pressPos: Qt.point(0, 0)
                    property real grabX: 0
                    property bool isDragging: false
                    property bool dragOccurred: false

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            pressPos = Qt.point(mouse.x, mouse.y);
                            grabX = mouse.x;
                            isDragging = false;
                            dragOccurred = false;
                        }
                    }

                    onPositionChanged: (mouse) => {
                        if (mouse.buttons & Qt.LeftButton) {
                            const dist = Math.hypot(mouse.x - pressPos.x, mouse.y - pressPos.y);

                            if (!isDragging && dist > 8) {
                                isDragging = true;
                                dragOccurred = true;

                                if (slot.index >= DockApps.pinned.length && typeof DockApps.pinApp === "function") {
                                    DockApps.pinApp(slot.app);
                                }

                                root.dragSourceIndex = slot.index;
                                root.dragTargetIndex = slot.index;
                            }

                            if (isDragging && root.dragSourceIndex === slot.index) {
                                const cursorDockX = slot.mapToItem(dockRow, mouse.x, 0).x;
                                slot.dragXOffset = cursorDockX - slot.x - grabX;

                                let targetIdx = Math.floor(cursorDockX / root.slotWidth);
                                const maxPinnedIdx = Math.max(0, (DockApps.pinned ? DockApps.pinned.length : DockApps.dockItems.length) - 1);
                                targetIdx = Math.max(0, Math.min(maxPinnedIdx, targetIdx));
                                root.dragTargetIndex = targetIdx;
                            }
                        }
                    }

                    onReleased: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (isDragging && root.dragSourceIndex === slot.index) {
                                const src = root.dragSourceIndex;
                                const tgt = root.dragTargetIndex;

                                slot.dragXOffset = 0;
                                root.dragSourceIndex = -1;
                                root.dragTargetIndex = -1;

                                if (tgt !== -1 && tgt !== src) {
                                    if (typeof DockApps.movePinned === "function") {
                                        DockApps.movePinned(src, tgt);
                                    } else if (typeof DockApps.moveItem === "function") {
                                        DockApps.moveItem(src, tgt);
                                    }
                                }
                            }
                            isDragging = false;
                        }
                    }

                    onCanceled: {
                        slot.dragXOffset = 0;
                        root.dragSourceIndex = -1;
                        root.dragTargetIndex = -1;
                        isDragging = false;
                        dragOccurred = false;
                    }

                    onClicked: (mouse) => {
                        if (dragOccurred) {
                            dragOccurred = false;
                            return;
                        }

                        if (mouse.button === Qt.RightButton) {
                            root.openSlotMenu(slot);
                        } else {
                            if (DockApps.isRunning(slot.app.appIds)) {
                                slot.bounce();
                                DockApps.focusApp(slot.app.appIds);
                            } else {
                                slot.launching = true;
                                
                                if (typeof slot.app.launch === "function") {
                                    slot.app.launch();
                                } else if (slot.app.exec) {
                                    Apps.launch(slot.app.exec);
                                } else if (typeof DockApps.launchApp === "function") {
                                    DockApps.launchApp(slot.app);
                                } else if (slot.app.desktopEntry) {
                                    Apps.launch(slot.app.desktopEntry);
                                }
                            }
                        }
                    }
                }
            }

            component ShotSlot: Item {
                id: sslot
                required property var modelData
                Layout.preferredWidth: root.slotWidth
                Layout.preferredHeight: root.capsuleHeight
                Layout.alignment: Qt.AlignBottom

                opacity: 0
                scale: 0.3
                transformOrigin: Item.Bottom

                readonly property real homeX: (sslot.width - root.iconBase) / 2
                readonly property real homeY: sslot.height - 14 - Math.round(root.iconBase * 0.72)

                Component.onCompleted: popIn.start()

                ParallelAnimation {
                    id: popIn
                    NumberAnimation { target: sslot; property: "opacity"; to: 1; duration: 200 }
                    NumberAnimation { target: sslot; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack }
                }

                Rectangle {
                    id: sIcon
                    width: root.iconBase
                    height: Math.round(root.iconBase * 0.72)
                    x: sslot.homeX
                    y: sslot.homeY
                    radius: 9
                    color: "#18181c"
                    border.color: Qt.rgba(255, 255, 255, 0.22)
                    border.width: 1
                    clip: true
                    opacity: (root.shotOverTrash && sMouse.overTrash) ? 0.35 : 1

                    Behavior on x { enabled: !sMouse.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Behavior on y { enabled: !sMouse.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 140 } }
                    scale: sMouse.pressed ? 1.15 : 1

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1.5
                        source: "file://" + encodeURI(sslot.modelData.path)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        mipmap: true
                        smooth: true
                    }
                }

                Rectangle {
                    visible: sHover.hovered && !sMouse.pressed && !root.shotDragging
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: sIcon.top
                    anchors.bottomMargin: 8
                    width: sTipText.width + 16
                    height: 22
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.9)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    z: 60
                    Text {
                        id: sTipText
                        anchors.centerIn: parent
                        text: sslot.modelData.name
                        font { family: "SF Pro Display"; pixelSize: 11; weight: Font.Medium }
                        color: "#ffffff"
                    }
                }

                HoverHandler { id: sHover }

                MouseArea {
                    id: sMouse
                    anchors.fill: parent
                    property bool dragged: false
                    property bool overTrash: false
                    property real startX: 0
                    property real startY: 0
                    drag.target: sIcon
                    drag.axis: Drag.XAndYAxis
                    drag.threshold: 8

                    onPressed: (mouse) => {
                        sMouse.dragged = false;
                        sMouse.startX = mouse.x;
                        sMouse.startY = mouse.y;
                        root.shotDragging = true;
                        sslot.z = 80;
                    }

                    onPositionChanged: (mouse) => {
                        if (!pressed) return;
                        if (Math.abs(mouse.x - sMouse.startX) > 8 || Math.abs(mouse.y - sMouse.startY) > 8)
                            sMouse.dragged = true;
                        if (!sMouse.dragged) return;
                        const p = sIcon.mapToItem(capsule, sIcon.width / 2, sIcon.height / 2);
                        const t = trashSlot.mapToItem(capsule, trashSlot.width / 2, trashSlot.height / 2);
                        sMouse.overTrash = Math.abs(p.x - t.x) < 65 && Math.abs(p.y - t.y) < 75;
                        root.shotOverTrash = sMouse.overTrash;
                    }

                    onReleased: {
                        root.shotDragging = false;
                        root.shotOverTrash = false;
                        sslot.z = 0;
                        if (sMouse.dragged && sMouse.overTrash) {
                            const p = sslot.modelData.path;
                            shotTrash.command = ["/usr/bin/gio", "trash", p];
                            shotTrash.running = true;
                            root.seenShots[p] = true;
                            root.shotItems = root.shotItems.filter(x => x.path !== p);
                            return;
                        }
                        sIcon.x = sslot.homeX;
                        sIcon.y = sslot.homeY;
                        sMouse.overTrash = false;
                    }

                    onClicked: {
                        if (sMouse.dragged) return;
                        dlOpener.command = ["/usr/bin/xdg-open", sslot.modelData.path];
                        dlOpener.running = true;
                    }
                }
            }

            Repeater {
                model: DockApps.dockItems
                delegate: DockSlot {}
            }

            DockSeparator {
                visible: DockApps.runningApps.length > 0
            }

                        // ── فولدر الداون لودس (ستاك ماك) ──
            Item {
                id: dlSlot
                Layout.preferredWidth: root.slotWidth
                Layout.preferredHeight: root.capsuleHeight
                Layout.alignment: Qt.AlignBottom

                Image {
                    id: dlIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    width: root.iconBase
                    height: root.iconBase
                    source: DockApps.folderSource()
                    asynchronous: true
                    mipmap: true
                    smooth: true

                    opacity: Appearance.iconClearActive ? 0.55 : 1
                }

                Rectangle {
                    visible: dlHover.hovered && root.dragSourceIndex === -1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: dlIcon.top
                    anchors.bottomMargin: 8
                    width: dlTipText.width + 16
                    height: 22
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.9)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    Text {
                        id: dlTipText
                        anchors.centerIn: parent
                        text: "Downloads"
                        font { family: "SF Pro Display"; pixelSize: 11; weight: Font.Medium }
                        color: "#ffffff"
                    }
                }

                HoverHandler { id: dlHover }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.fanSuppressNextClick) {
                            root.fanSuppressNextClick = false;
                            return;
                        }
                        if (root.downloadsOpen) {
                            root.downloadsOpen = false;
                            return;
                        }
                        root.openDownloads();
                    }
                }
            }

            // ── عناصر السكرين شوت (أيقونة التطبيق + شارة) ──
            Repeater {
                model: root.shotItems
                delegate: ShotSlot {}
            }

                        // ── كود سلة المهملات المطوّر ──
            Item {
                id: trashSlot
                Layout.preferredWidth: root.slotWidth
                Layout.preferredHeight: root.capsuleHeight
                Layout.alignment: Qt.AlignBottom

                Image {
                    id: trashIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14 
                    width: root.iconBase
                    height: root.iconBase
                    source: DockApps.iconSource(root.isTrashFull ? "user-trash-full.png" : "Trash.png")
                    asynchronous: true
                    mipmap: true
                    smooth: true
                    scale: root.shotOverTrash ? 1.25 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                }

                Rectangle {
                    visible: root.shotOverTrash
                    anchors.centerIn: trashIcon
                    width: root.iconBase + 16
                    height: root.iconBase + 16
                    radius: 14
                    color: "transparent"
                    border.color: Qt.rgba(0.12, 0.52, 1, 0.9)
                    border.width: 2
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    opacity: root.shotOverTrash ? 1 : 0
                }

                Rectangle {
                    visible: trashHover.hovered && root.dragSourceIndex === -1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: trashIcon.top
                    anchors.bottomMargin: 8
                    width: trashTipText.width + 16
                    height: 22
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.9)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    Text {
                        id: trashTipText
                        anchors.centerIn: parent
                        text: root.isTrashFull ? "Trash (full)" : "Trash"
                        font { family: "SF Pro Display"; pixelSize: 11; weight: Font.Medium }
                        color: "#ffffff"
                    }
                }

                HoverHandler { id: trashHover }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!trashOpener.running) trashOpener.running = true;
                    }
                }
            } // إغلاق حاوية الـ Item لسلة المهملات
        } // إغلاق الـ RowLayout (dockRow)
    } // إغلاق الـ Item الأساسي (capsule)
} // إغلاق الحاوية الكلية للملف (PanelWindow)
