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
    
    height: root.capsuleHeight + root.iconZoomFactor
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

    property real fanOx: 210
    property real fanOy: 518
    property real fanRc: 500
    property real fanRowH: 58
    property bool fanFlip: false

    readonly property var fanModel: {
        const arr = root.dlItems.slice(0, 10).map(p => ({ path: p }));
        arr.push({ openFinder: true });
        return arr;
    }

    function refreshDownloads() {
        if (!dlScan.running) dlScan.running = true;
    }

    function isThumb(p) {
        return /\.(png|jpe?g|webp|gif|bmp|svg|avif)$/i.test(p);
    }

    function dlIconFor(p) {
        const e = (p.split(".").pop() || "").toLowerCase();
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(e)) return DockApps.iconsDir + "video-player.png";
        if (["mp3", "flac", "wav", "ogg", "m4a"].includes(e)) return DockApps.iconsDir + "elisa.png";
        if (["deb", "rpm", "appimage"].includes(e)) return DockApps.iconsDir + "app-store.png";
        return DockApps.iconsDir + "file-doc.svg";
    }

    function fanPosAt(i) {
        const n = Math.max(1, root.fanModel.length);
        const last = Math.max(1, n - 1);
        const f = i / last;
        return {
            x: 300 + 150 * f,
            y: 12 + (n - 1 - i) * root.fanRowH
        };
    }

    function openDownloads() {
        ShellController.closeAll();
        const pos = dlSlot.mapToItem(null, dlSlot.width / 2, 14);
        const screenW = Quickshell.screens[0].width;
        const n = Math.max(1, root.fanModel.length);
        downloadsFan.width = 440;
        root.fanOy = n * root.fanRowH + 24;
        downloadsFan.height = root.fanOy;
        root.fanOx = 300;
        downloadsFan.relativeX = Math.max(6, Math.min(screenW - downloadsFan.width - 6, pos.x - root.fanOx));
        downloadsFan.relativeY = pos.y - root.fanOy + 8;
        root.downloadsOpen = true;
        root.refreshDownloads();
    }

    onDownloadsOpenChanged: {
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

    Component.onCompleted: { dlScan.running = true; fanTestTimer.start(); }

    Timer {
        id: fanTestTimer
        interval: 2500
        running: false
        onTriggered: root.openDownloads()
    }

    Process {
        id: dlScan
        running: false
        command: ["sh", "-c", "find \"$HOME/Downloads\" -mindepth 1 -maxdepth 1 -printf '%T@|%p\\n' 2>/dev/null | sort -rn | head -10"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("|");
                    if (i > 0) out.push(line.slice(i + 1));
                }
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
        bottom: 8
        left: Math.max(0, (Quickshell.screens[0].width - root.capsuleWidth) / 2)
        right: Math.max(0, (Quickshell.screens[0].width - root.capsuleWidth) / 2)
    }
   color: "transparent"
    WlrLayershell.namespace: "macos:dock"

    readonly property int iconZoomFactor: Appearance.dockMagnification ? 55 : 0
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
            radius: 26
            color: Qt.rgba(15, 15, 22, 0.03) // زيادة الشفافية مع الحفاظ على بقاء القطر مقروءاً لـ hyprglass
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
            tintAlpha: 0.85

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
        parentWindow: root
        screen: Quickshell.screens[0]
        width: 360
        height: 500
        visible: root.downloadsOpen
        color: "transparent"

        Repeater {
            model: root.fanModel
            delegate: Item {
                id: fanItem
                required property int index
                required property var modelData
                width: 200
                height: root.fanRowH
                readonly property real fx: root.fanPosAt(fanItem.index).x
                readonly property real fy: root.fanPosAt(fanItem.index).y
                property real t: root.downloadsOpen ? 1 : 0
                z: 100 - fanItem.index

                x: root.fanOx + (fanItem.fx - root.fanOx) * fanItem.t - (fanItem.width - 46)
                y: root.fanOy + (fanItem.fy - root.fanOy) * fanItem.t
                opacity: Math.min(1, fanItem.t * 1.5)
                scale: 0.35 + 0.65 * fanItem.t
                transformOrigin: Item.BottomRight

                Behavior on t {
                    SequentialAnimation {
                        PauseAnimation { duration: fanItem.index * 45 }
                        NumberAnimation { duration: 340; easing.type: Easing.OutBack }
                    }
                }

                Rectangle {
                    id: fanIcon
                    readonly property bool thumbBg: !fanItem.modelData.openFinder && root.isThumb(fanItem.modelData.path)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46
                    height: 46
                    radius: 10
                    color: fanIcon.thumbBg ? "#1c1c1e" : "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.18)
                    border.width: fanIcon.thumbBg ? 1 : 0
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: fanIcon.thumbBg ? 2 : 4
                        source: fanItem.modelData.openFinder
                            ? DockApps.iconsDir + "Finder.png"
                            : (root.isThumb(fanItem.modelData.path)
                                ? "file://" + encodeURI(fanItem.modelData.path)
                                : root.dlIconFor(fanItem.modelData.path))
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
                    height: 24
                    width: Math.min(fanPillText.implicitWidth + 20, 150)
                    radius: 12
                    color: fanPillHover.hovered ? "#ffffff" : Qt.rgba(0.93, 0.93, 0.95, 0.95)
                    border.color: Qt.rgba(0, 0, 0, 0.12)
                    border.width: 1

                    Text {
                        id: fanPillText
                        anchors.centerIn: parent
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: fanItem.modelData.openFinder
                            ? "Open in Finder"
                            : fanItem.modelData.path.split("/").pop()
                        font { family: Appearance.fontFamily; pixelSize: 11; weight: Font.Medium }
                        color: "#1a1a1a"
                    }
                }

                HoverHandler { id: fanPillHover }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (fanItem.modelData.openFinder) {
                            dlOpener.command = ["/home/revo/.local/bin/nautilus", "--new-window", "file:///home/revo/Downloads"];
                        } else {
                            dlOpener.command = ["/usr/bin/xdg-open", fanItem.modelData.path];
                        }
                        dlOpener.running = true;
                        root.downloadsOpen = false;
                    }
                }
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

                    Rectangle {
                        id: runningDot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -7
                        width: 5
                        height: 5
                        radius: 2.5
                        color: root.accent
                        visible: DockApps.isRunning(slot.app.appIds)
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
                    source: DockApps.iconsDir + "folder-downloads.svg"
                    asynchronous: true
                    mipmap: true
                    smooth: true
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
                    source: root.isTrashFull ? DockApps.iconsDir + "user-trash-full.png" : DockApps.iconsDir + "Trash.png"
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
