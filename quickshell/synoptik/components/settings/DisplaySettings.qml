import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Flickable {
    id: flickableRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: flickableRoot.moving || flickableRoot.flicking
    }

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Auto-aligns the leftmost monitor to x: 0 while preserving relative layout spacing
    function normalizeLeftmostMonitor() {
        let screens = Quickshell.screens
        if (!screens || screens.length === 0) return

        let minX = Number.MAX_VALUE
        for (let i = 0; i < screens.length; i++) {
            let cfg = Config.getMonitorConfig(screens[i].name)
            if (cfg && cfg.x < minX) {
                minX = cfg.x
            }
        }

        if (minX !== Number.MAX_VALUE && minX !== 0) {
            for (let j = 0; j < screens.length; j++) {
                let name = screens[j].name
                let cfg = Config.getMonitorConfig(name)
                Config.updateDraftMonitorConfig(name, { x: cfg.x - minX })
            }
        }
    }

    // Auto-arrange all screens side-by-side cleanly
    function autoArrangeMonitors() {
        let screens = Quickshell.screens
        if (!screens || screens.length === 0) return

        let currentX = 0
        for (let i = 0; i < screens.length; i++) {
            let name = screens[i].name
            let cfg = Config.getMonitorConfig(name)
            let rot = cfg.transform === 1 || cfg.transform === 3
            let w = rot ? cfg.height : cfg.width

            Config.updateDraftMonitorConfig(name, { x: currentX, y: 0 })
            currentX += w
        }
    }

    // Swap relative left/right ordering of connected screens
    function swapMonitors() {
        let screens = Quickshell.screens
        if (!screens || screens.length < 2) return

        let name1 = screens[0].name
        let name2 = screens[1].name

        let cfg1 = Config.getMonitorConfig(name1)
        let cfg2 = Config.getMonitorConfig(name2)

        Config.updateDraftMonitorConfig(name1, { x: cfg2.x, y: cfg2.y })
        Config.updateDraftMonitorConfig(name2, { x: cfg1.x, y: cfg1.y })
        normalizeLeftmostMonitor()
    }

    Component.onCompleted: {
        normalizeLeftmostMonitor()
        Config.refreshActiveWallpapers()
    }

    ColumnLayout {
        id: contentColumn
        width: Math.min(flickableRoot.width - (flickableRoot.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: flickableRoot.cardMargin

        // ==========================================
        // HEADER TITLE BLOCK
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: "DISPLAY & MULTI-MONITOR MANAGEMENT"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontSubhead)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "Arrange physical monitor viewports, set target display resolutions, refresh rates, DPI scaling factors, and screen orientation."
                color: Config.textMuted
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                wrapMode: Text.WordWrap
            }
        }

        // ==========================================
        // 1. INTERACTIVE MONITOR CANVAS & ARRANGEMENT
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: canvasCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: canvasCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Header Row with Interactive Quick Toolbar
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "INTERACTIVE MONITOR CANVAS"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Drag monitor viewports to configure relative physical positioning."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Interactive Quick Canvas Toolbar
                    RowLayout {
                        spacing: 6

                        // Auto Arrange Pill
                        Rectangle {
                            implicitWidth: autoArrRow.implicitWidth + 14
                            implicitHeight: 26
                            radius: 13
                            color: autoArrMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.12)

                            RowLayout {
                                id: autoArrRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "auto_awesome"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 13
                                    color: Config.accent
                                }
                                Text {
                                    text: "Auto Arrange"
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.textMain
                                }
                            }

                            MouseArea {
                                id: autoArrMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: flickableRoot.autoArrangeMonitors()
                            }
                        }

                        // Swap Positions Pill
                        Rectangle {
                            implicitWidth: swapRow.implicitWidth + 14
                            implicitHeight: 26
                            radius: 13
                            color: swapMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.12)
                            visible: Quickshell.screens.length > 1

                            RowLayout {
                                id: swapRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "swap_horiz"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 14
                                    color: Config.accent
                                }
                                Text {
                                    text: "Swap"
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.textMain
                                }
                            }

                            MouseArea {
                                id: swapMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: flickableRoot.swapMonitors()
                            }
                        }
                    }
                }

                // Monitor Viewport Canvas Box
                Rectangle {
                    id: displayCanvas
                    Layout.fillWidth: true
                    implicitHeight: 230
                    radius: Config.cornerRadius - 2
                    color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    clip: true

                    property real snapGuideX: -1
                    property real snapGuideY: -1

                    // Dynamic Scale Factor to guarantee all monitors fit inside canvas bounds
                    readonly property real canvasScaleFactor: {
                        let maxW = 2560
                        let maxH = 1440
                        let screens = Quickshell.screens
                        for (let i = 0; i < screens.length; i++) {
                            let m = Config.getMonitorConfig(screens[i].name)
                            if (m) {
                                let rot = m.transform === 1 || m.transform === 3
                                let w = rot ? m.height : m.width
                                let h = rot ? m.width : m.height
                                maxW = Math.max(maxW, m.x + w)
                                maxH = Math.max(maxH, m.y + h)
                            }
                        }
                        let availW = Math.max(200, displayCanvas.width - 60)
                        let availH = Math.max(140, displayCanvas.height - 60)
                        let scaleX = availW / Math.max(maxW, 1)
                        let scaleY = availH / Math.max(maxH, 1)
                        return Math.min(0.065, Math.min(scaleX, scaleY))
                    }

                    // Ambient Grid Pattern
                    Grid {
                        anchors.fill: parent
                        rows: 8
                        columns: 16

                        Repeater {
                            model: parent.rows * parent.columns
                            Item {
                                width: displayCanvas.width / 16
                                height: displayCanvas.height / 8

                                Rectangle {
                                    width: parent.width; height: 1
                                    color: Qt.rgba(255, 255, 255, 0.03)
                                }
                                Rectangle {
                                    width: 1; height: parent.height
                                    color: Qt.rgba(255, 255, 255, 0.03)
                                }
                            }
                        }
                    }

                    // Animated Magnetic Snap Crosshair Guide Lines
                    Rectangle {
                        x: displayCanvas.snapGuideX
                        width: 1.5
                        height: displayCanvas.height
                        color: Config.accent
                        opacity: displayCanvas.snapGuideX >= 0 ? 0.8 : 0
                        visible: displayCanvas.snapGuideX >= 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    Rectangle {
                        y: displayCanvas.snapGuideY
                        width: displayCanvas.width
                        height: 1.5
                        color: Config.accent
                        opacity: displayCanvas.snapGuideY >= 0 ? 0.8 : 0
                        visible: displayCanvas.snapGuideY >= 0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    // Draggable Monitor Viewports
                    Repeater {
                        model: Quickshell.screens

                        delegate: Item {
                            id: screenWrapper
                            required property var modelData
                            required property int index

                            readonly property var monCfg: Config.getMonitorConfig(modelData.name)
                            readonly property bool isSelected: Config.selectedScreenConfig === modelData.name
                            readonly property bool isPrimary: monCfg.x === 0 && monCfg.y === 0

                            x: 30 + (monCfg.x * displayCanvas.canvasScaleFactor)
                            y: 30 + (monCfg.y * displayCanvas.canvasScaleFactor)

                            readonly property bool isRotated: monCfg.transform === 1 || monCfg.transform === 3
                            readonly property real renderWidth: isRotated ? monCfg.height : monCfg.width
                            readonly property real renderHeight: isRotated ? monCfg.width : monCfg.height

                            width: Math.max(80, renderWidth * displayCanvas.canvasScaleFactor)
                            height: Math.max(55, renderHeight * displayCanvas.canvasScaleFactor)

                            Rectangle {
                                id: monitorBox
                                anchors.fill: parent
                                radius: 6
                                color: screenHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                                border.width: isSelected ? 2 : 1
                                border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: monitorBox.width
                                        height: monitorBox.height
                                        radius: monitorBox.radius
                                    }
                                }

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: screenHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: dragHandler.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    onClicked: Config.selectedScreenConfig = screenWrapper.modelData.name
                                }

                                // Live Active Wallpaper Preview Thumbnail
                                Image {
                                    anchors.fill: parent
                                    source: Config.getMonitorWallpaper(screenWrapper.modelData.name)
                                    fillMode: Image.PreserveAspectCrop
                                    opacity: 0.35
                                    asynchronous: true
                                }

                                // Dark Overlay for Content Contrast
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(0, 0, 0, 0.35)
                                }

                                // Top Header Bar inside Monitor Viewport
                                Item {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 18
                                    anchors.margins: 4
                                    z: 10

                                    // Primary Display Badge (Origin 0,0)
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitWidth: primaryPillRow.implicitWidth + 8
                                        implicitHeight: 14
                                        radius: 7
                                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3)
                                        border.width: 1
                                        border.color: Config.accent
                                        visible: isPrimary

                                        RowLayout {
                                            id: primaryPillRow
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Text {
                                                text: "star"
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 9
                                                color: Config.accent
                                            }
                                            Text {
                                                text: "MAIN"
                                                font.family: Config.sysFont
                                                font.pixelSize: 7
                                                font.bold: true
                                                color: Config.accent
                                            }
                                        }
                                    }

                                    // 1-Click Quick Rotate Button
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        radius: 8
                                        color: quickRotMouse.containsMouse ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "rotate_right"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 10
                                            color: quickRotMouse.containsMouse ? Config.bgBase : Config.textMain
                                        }

                                        MouseArea {
                                            id: quickRotMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let nextTransform = (screenWrapper.monCfg.transform + 1) % 4
                                                Config.updateDraftMonitorConfig(screenWrapper.modelData.name, { transform: nextTransform })
                                            }
                                        }
                                    }
                                }

                                // Center Content Layout
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 1

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 4
                                        Text {
                                            text: screenWrapper.modelData.name
                                            color: isSelected ? Config.accent : Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontBody)
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        text: monCfg.width + " × " + monCfg.height
                                        color: Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                // Bottom Footer Badges inside Monitor Viewport
                                RowLayout {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    spacing: 4

                                    // Workspace Badge
                                    Rectangle {
                                        implicitWidth: wsBadgeText.implicitWidth + 8
                                        implicitHeight: 13
                                        radius: 6
                                        color: Qt.rgba(0, 0, 0, 0.5)

                                        Text {
                                            id: wsBadgeText
                                            anchors.centerIn: parent
                                            text: "WS " + (index + 1)
                                            font.family: Config.sysFont
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Config.accent
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Scale & Orientation Badge
                                    Rectangle {
                                        implicitWidth: scaleBadgeText.implicitWidth + 8
                                        implicitHeight: 13
                                        radius: 6
                                        color: Qt.rgba(0, 0, 0, 0.5)

                                        Text {
                                            id: scaleBadgeText
                                            anchors.centerIn: parent
                                            text: (monCfg.scale === "auto" || !monCfg.scale) ? "AUTO" : parseFloat(monCfg.scale).toFixed(2) + "x"
                                            font.family: Config.sysFont
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Config.textMain
                                        }
                                    }
                                }
                            }

                            DragHandler {
                                id: dragHandler
                                target: null

                                property real startX: 0
                                property real startY: 0

                                onActiveChanged: {
                                    if (active) {
                                        Config.selectedScreenConfig = screenWrapper.modelData.name
                                        startX = screenWrapper.monCfg.x
                                        startY = screenWrapper.monCfg.y
                                    } else {
                                        displayCanvas.snapGuideX = -1
                                        displayCanvas.snapGuideY = -1
                                        flickableRoot.normalizeLeftmostMonitor()
                                    }
                                }

                                onTranslationChanged: {
                                    if (!active) return

                                    let calcX = Math.round(startX + (translation.x / displayCanvas.canvasScaleFactor))
                                    let calcY = Math.round(startY + (translation.y / displayCanvas.canvasScaleFactor))

                                    let selfW = screenWrapper.renderWidth
                                    let selfH = screenWrapper.renderHeight
                                    let snapThreshold = 120

                                    let snappedX = false
                                    let snappedY = false

                                    if (Math.abs(calcX) < snapThreshold) {
                                        calcX = 0
                                        snappedX = true
                                        displayCanvas.snapGuideX = 30
                                    }
                                    if (Math.abs(calcY) < snapThreshold) {
                                        calcY = 0
                                        snappedY = true
                                        displayCanvas.snapGuideY = 30
                                    }

                                    let screens = Quickshell.screens
                                    for (let i = 0; i < screens.length; i++) {
                                        let otherName = screens[i].name
                                        if (otherName === screenWrapper.modelData.name) continue

                                        let other = Config.getMonitorConfig(otherName)
                                        if (!other) continue

                                        let otherRot = other.transform === 1 || other.transform === 3
                                        let otherW = otherRot ? other.height : other.width
                                        let otherH = otherRot ? other.width : other.height

                                        if (Math.abs(calcX - (other.x + otherW)) < snapThreshold) {
                                            calcX = other.x + otherW
                                            snappedX = true
                                            displayCanvas.snapGuideX = 30 + ((other.x + otherW) * displayCanvas.canvasScaleFactor)
                                        } else if (Math.abs((calcX + selfW) - other.x) < snapThreshold) {
                                            calcX = other.x - selfW
                                            snappedX = true
                                            displayCanvas.snapGuideX = 30 + (other.x * displayCanvas.canvasScaleFactor)
                                        } else if (Math.abs(calcX - other.x) < snapThreshold) {
                                            calcX = other.x
                                            snappedX = true
                                            displayCanvas.snapGuideX = 30 + (other.x * displayCanvas.canvasScaleFactor)
                                        }

                                        if (Math.abs(calcY - other.y) < snapThreshold) {
                                            calcY = other.y
                                            snappedY = true
                                            displayCanvas.snapGuideY = 30 + (other.y * displayCanvas.canvasScaleFactor)
                                        } else if (Math.abs(calcY - (other.y + otherH)) < snapThreshold) {
                                            calcY = other.y + otherH
                                            snappedY = true
                                            displayCanvas.snapGuideY = 30 + ((other.y + otherH) * displayCanvas.canvasScaleFactor)
                                        } else if (Math.abs((calcY + selfH) - other.y) < snapThreshold) {
                                            calcY = other.y - selfH
                                            snappedY = true
                                            displayCanvas.snapGuideY = 30 + (other.y * displayCanvas.canvasScaleFactor)
                                        } else if (Math.abs((calcY + selfH) - (other.y + otherH)) < snapThreshold) {
                                            calcY = other.y + otherH - selfH
                                            snappedY = true
                                            displayCanvas.snapGuideY = 30 + ((other.y + otherH) * displayCanvas.canvasScaleFactor)
                                        }
                                    }

                                    if (!snappedX) displayCanvas.snapGuideX = -1
                                    if (!snappedY) displayCanvas.snapGuideY = -1

                                    Config.updateDraftMonitorConfig(screenWrapper.modelData.name, { x: calcX, y: calcY })
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. MONITOR PROPERTIES & RESOLUTION INSPECTOR
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: inspectorCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: inspectorCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                readonly property var activeCfg: Config.getMonitorConfig(Config.selectedScreenConfig)
                readonly property real formLabelWidth: 110

                // Header & Target Switcher
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "DISPLAY CONFIGURATION INSPECTOR"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Adjust mode resolution, DPI scaling factor, and screen orientation."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Monitor Selector Pills
                    RowLayout {
                        spacing: 6

                        Repeater {
                            model: Quickshell.screens

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: targetPillRow.implicitWidth + 16
                                implicitHeight: 28
                                radius: 14

                                readonly property bool isTarget: Config.selectedScreenConfig === modelData.name

                                color: isTarget ? Config.accent : (targetHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06))
                                border.width: 1
                                border.color: isTarget ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                                RowLayout {
                                    id: targetPillRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "desktop_windows"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 13
                                        color: isTarget ? Config.bgBase : Config.textMuted
                                    }
                                    Text {
                                        text: modelData.name
                                        font.family: Config.sysFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: isTarget ? Config.bgBase : Config.textMain
                                    }
                                }

                                MouseArea {
                                    id: targetHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.selectedScreenConfig = modelData.name
                                }
                            }
                        }
                    }
                }

                // Row 1: Resolution Combo
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: resRowLayout.implicitHeight + 16
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    RowLayout {
                        id: resRowLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: "Resolution & Rate:"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            Layout.preferredWidth: inspectorCol.formLabelWidth
                        }

                        ComboBox {
                            id: resCombo
                            Layout.fillWidth: true
                            implicitHeight: 32

                            model: {
                                let modes = Config.detectedModes[Config.selectedScreenConfig]
                                if (modes && modes.length > 0) return modes

                                return [
                                    { text: "2560x1440@165Hz", w: 2560, h: 1440, r: 164.84 },
                                    { text: "2560x1440@120Hz", w: 2560, h: 1440, r: 120.00 },
                                    { text: "2560x1440@60Hz",  w: 2560, h: 1440, r: 60.00 },
                                    { text: "1920x1080@165Hz", w: 1920, h: 1080, r: 164.83 },
                                    { text: "1920x1080@60Hz",  w: 1920, h: 1080, r: 60.00 }
                                ]
                            }
                            textRole: "text"

                            currentIndex: {
                                let cfg = Config.getMonitorConfig(Config.selectedScreenConfig)
                                for (let i = 0; i < model.length; i++) {
                                    let m = model[i]
                                    let matchW = m.w === cfg.width
                                    let matchH = m.h === cfg.height
                                    let matchR = m.r ? Math.abs(m.r - cfg.refreshRate) < 0.2 : true
                                    if (matchW && matchH && matchR) return i
                                }
                                return 0
                            }

                            onActivated: (index) => {
                                let sel = model[index]
                                let opts = { width: sel.w, height: sel.h }
                                if (sel.r) opts.refreshRate = sel.r
                                Config.updateDraftMonitorConfig(Config.selectedScreenConfig, opts)
                            }

                            background: Rectangle {
                                color: resCombo.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                                border.color: resCombo.activeFocus || resCombo.pressed ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                                border.width: 1
                                radius: Config.cornerRadius / 2
                            }

                            indicator: Text {
                                x: resCombo.width - width - 10
                                y: (resCombo.height - height) / 2
                                text: "expand_more"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                color: Config.accent
                            }

                            contentItem: Text {
                                text: resCombo.displayText
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                                rightPadding: 24
                            }

                            delegate: ItemDelegate {
                                width: resCombo.width
                                height: 32

                                contentItem: Text {
                                    text: modelData.text || modelData
                                    color: parent.hovered ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: parent.hovered
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                }

                                background: Rectangle {
                                    color: parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                                    radius: Config.cornerRadius / 4
                                }
                            }

                            popup: Popup {
                                y: resCombo.height + 4
                                width: resCombo.width
                                implicitHeight: Math.min(contentItem.implicitHeight + 10, 220)
                                padding: 4

                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: resCombo.popup.visible ? resCombo.delegateModel : null
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                }

                                background: Rectangle {
                                    color: Config.bgPanel
                                    border.color: Config.accent
                                    border.width: 1
                                    radius: Config.cornerRadius / 2
                                }
                            }
                        }
                    }
                }

                // Row 2: DPI Scaling
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: scaleRowLayout.implicitHeight + 16
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    RowLayout {
                        id: scaleRowLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: "DPI Scaling:"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            Layout.preferredWidth: inspectorCol.formLabelWidth
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "Auto", val: "auto" },
                                    { label: "1.0x", val: 1.0 },
                                    { label: "1.25x", val: 1.25 },
                                    { label: "1.33x", val: 1.333333 },
                                    { label: "1.5x", val: 1.5 },
                                    { label: "1.75x", val: 1.75 },
                                    { label: "2.0x", val: 2.0 }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: Config.cornerRadius / 2

                                    readonly property bool isSelected: {
                                        let activeScale = inspectorCol.activeCfg.scale
                                        let isAutoMode = (activeScale === "auto" || !activeScale)

                                        if (modelData.val === "auto") return isAutoMode
                                        if (isAutoMode) return false

                                        let parsedActive = parseFloat(activeScale)
                                        let parsedTarget = parseFloat(modelData.val)
                                        if (isNaN(parsedActive) || isNaN(parsedTarget)) return false
                                        return parsedActive.toFixed(2) === parsedTarget.toFixed(2)
                                    }

                                    color: isSelected ? Config.accent : (scaleBtnHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04))
                                    border.width: 1
                                    border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: parent.isSelected ? Config.bgBase : Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: scaleBtnHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.updateDraftMonitorConfig(Config.selectedScreenConfig, { scale: modelData.val })
                                    }
                                }
                            }
                        }
                    }
                }

                // Row 3: Orientation
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: orientRowLayout.implicitHeight + 16
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    RowLayout {
                        id: orientRowLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: "Orientation:"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            Layout.preferredWidth: inspectorCol.formLabelWidth
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { name: "Normal (0°)", transform: 0, icon: "screenshot_monitor" },
                                    { name: "90°", transform: 1, icon: "rotate_right" },
                                    { name: "180°", transform: 2, icon: "autorenew" },
                                    { name: "270°", transform: 3, icon: "rotate_left" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: Config.cornerRadius / 2

                                    readonly property bool isOrient: inspectorCol.activeCfg.transform === modelData.transform

                                    color: isOrient ? Config.accent : (orientBtnHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04))
                                    border.width: 1
                                    border.color: isOrient ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: modelData.icon
                                            color: isOrient ? Config.bgBase : Config.textMuted
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            text: modelData.name
                                            color: isOrient ? Config.bgBase : Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontMicro)
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        id: orientBtnHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.updateDraftMonitorConfig(Config.selectedScreenConfig, { transform: modelData.transform })
                                    }
                                }
                            }
                        }
                    }
                }

                // Row 4: Position Offset & Action Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Offset Nudge:"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 4

                        Rectangle {
                            implicitWidth: 30; implicitHeight: 26; radius: 4
                            color: nLeft.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.12)
                            Text { anchors.centerIn: parent; text: "←"; color: Config.textMain; font.bold: true }
                            MouseArea {
                                id: nLeft; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let cfg = Config.getMonitorConfig(Config.selectedScreenConfig)
                                    Config.updateDraftMonitorConfig(Config.selectedScreenConfig, { x: (cfg ? cfg.x : 0) - 50 })
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 30; implicitHeight: 26; radius: 4
                            color: nRight.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.12)
                            Text { anchors.centerIn: parent; text: "→"; color: Config.textMain; font.bold: true }
                            MouseArea {
                                id: nRight; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let cfg = Config.getMonitorConfig(Config.selectedScreenConfig)
                                    Config.updateDraftMonitorConfig(Config.selectedScreenConfig, { x: (cfg ? cfg.x : 0) + 50 })
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 30; implicitHeight: 26; radius: 4
                            color: nUp.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.12)
                            Text { anchors.centerIn: parent; text: "↑"; color: Config.textMain; font.bold: true }
                            MouseArea {
                                id: nUp; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let cfg = Config.getMonitorConfig(Config.selectedScreenConfig)
                                    Config.updateDraftMonitorConfig(Config.selectedScreenConfig, { y: (cfg ? cfg.y : 0) - 50 })
                                }
                            }
                        }

                        Rectangle {
                            implicitWidth: 30; implicitHeight: 26; radius: 4
                            color: nDown.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1; border.color: Qt.rgba(255, 255, 255, 0.12)
                            Text { anchors.centerIn: parent; text: "↓"; color: Config.textMain; font.bold: true }
                            MouseArea {
                                id: nDown; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let cfg = Config.getMonitorConfig(Config.selectedScreenConfig)
                                    Config.updateDraftMonitorConfig(Config.selectedScreenConfig, { y: (cfg ? cfg.y : 0) + 50 })
                                }
                            }
                        }
                    }

                    Text {
                        text: {
                            let cfg = Config.getMonitorConfig(Config.selectedScreenConfig)
                            return "(" + (cfg ? cfg.x : 0) + ", " + (cfg ? cfg.y : 0) + ")"
                        }
                        color: Config.accent
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Discard Button
                    Rectangle {
                        implicitWidth: 90
                        implicitHeight: 32
                        radius: 16
                        color: discMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: "Discard"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: discMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.resetDraftMonitorConfigs()
                                flickableRoot.normalizeLeftmostMonitor()
                            }
                        }
                    }

                    // Apply & Save Button
                    Rectangle {
                        implicitWidth: 140
                        implicitHeight: 32
                        radius: 16
                        color: applyMouse.containsMouse ? Config.accent : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                        border.width: 1.5
                        border.color: Config.accent

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "check"
                                color: applyMouse.containsMouse ? Config.bgBase : Config.accent
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                            }

                            Text {
                                text: "Apply & Save"
                                color: applyMouse.containsMouse ? Config.bgBase : Config.accent
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: applyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.applyMonitorConfigs()
                        }
                    }
                }
            }
        }
    }
}