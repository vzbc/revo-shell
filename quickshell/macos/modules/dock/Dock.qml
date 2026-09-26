import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors {
        bottom: true
        left: true
        right: true
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
    readonly property int capsuleHeight: 92
    readonly property int totalSlots: DockApps.dockItems.length + 1
    readonly property int sepCount: DockApps.runningApps.length > 0 ? 1 : 0
    readonly property int capsuleWidth: root.totalSlots * root.slotWidth + root.sepCount * 9 + 20
    
    margins {
        bottom: 8
        left: Math.max(0, (Quickshell.screens[0].width - root.capsuleWidth) / 2)
        right: Math.max(0, (Quickshell.screens[0].width - root.capsuleWidth) / 2)
    }
    height: root.capsuleHeight
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
        function onDismissed() { root.menuOpen = false; }
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

    ShaderLiquidGlass {
        id: capsuleBg
        anchors.fill: parent
        radius: 26
        tint: "#121217"
        tintAlpha: 0.5
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
                Layout.preferredHeight: parent.height - 30
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.alignment: Qt.AlignVCenter
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
                    color: Qt.rgba(20, 20, 25, 0.75)
                    border.color: Qt.rgba(255, 255, 255, 0.3)
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

            Repeater {
                model: DockApps.dockItems
                delegate: DockSlot {}
            }

            DockSeparator {
                visible: DockApps.runningApps.length > 0
            }

            Item {
                Layout.preferredWidth: root.slotWidth
                Layout.preferredHeight: parent.height
                Image {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    source: DockApps.iconsDir + "Trash.png"
                    asynchronous: true
                    mipmap: true
                    smooth: true
                }
            }
        }
    }
}