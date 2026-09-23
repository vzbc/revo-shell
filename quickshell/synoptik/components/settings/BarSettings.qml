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

    // Reusable Geometric / Square Toggle Switch Component (Matching AppearanceSettings)
    component ToggleSwitch : Rectangle {
        id: sw
        property bool checked: false
        
        implicitWidth: 40
        implicitHeight: 22
        radius: 6
        color: checked ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.4)
        border.width: sw.checked ? 2 : 1
        border.color: checked ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Square Thumb / Slider
        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
            border.width: 0
            border.color: sw.checked ? Qt.lighter(Config.accent, 1.2) : Qt.rgba(255, 255, 255, 0.25)

            Behavior on x { 
                NumberAnimation { 
                    duration: 160
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
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
                text: "BAR CONFIGURATION"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontSubhead)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "Configure panel edge orientation, floating geometry frame styles, multi-monitor display targeting, and auto-hide behaviors."
                color: Config.textMuted
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                wrapMode: Text.WordWrap
            }
        }

        // ==========================================
        // 1. LIVE INTERACTIVE SHOWCASE CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: previewCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: previewCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                // Header Row
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "LIVE BAR PREVIEW & DOCK CONTROLS"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Click edge buttons to position bar or switch frame styles below."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Interactive Hint Badge
                    Rectangle {
                        implicitWidth: hintRow.implicitWidth + 14
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.4)

                        RowLayout {
                            id: hintRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "touch_app"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 13
                                color: Config.accent
                            }
                            Text {
                                text: "Live Docking Controls"
                                font.family: Config.sysFont
                                font.pixelSize: 10
                                font.bold: true
                                color: Config.accent
                            }
                        }
                    }
                }

                // Interactive Monitor Display Canvas
                Rectangle {
                    id: monitorCanvas
                    Layout.fillWidth: true
                    implicitHeight: 240
                    radius: Config.cornerRadius - 2
                    color: Qt.rgba(255, 255, 255, 0.03)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    clip: true

                    // Ambient Background Gradient Representation
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12) }
                            GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.02) }
                        }
                    }

                    // Clean Desktop Watermark Badge
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        opacity: 0.3

                        Text {
                            text: "desktop_windows"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 32
                            color: Config.accent
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "SYNOPTIK DESKTOP VIEWPORT"
                            font.family: Config.sysFont
                            font.pixelSize: 10
                            font.bold: true
                            color: Config.textMain
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Screen Frame Highlight Overlay (when screen frame mode is active)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: "transparent"
                        radius: 8
                        border.width: (Config.barFrameStyle === "screen" || Config.showScreenFrame) ? 3 : 0
                        border.color: Config.accent
                        visible: Config.barFrameStyle === "screen" || Config.showScreenFrame
                        Behavior on border.width { enabled: miniBar.allowAnimation; NumberAnimation { duration: 150 } }
                    }

                    // Simulated Interactive Status Bar
                    Rectangle {
                        id: miniBar
                        z: 5
                        readonly property bool isVertical: Config.barPosition === "left" || Config.barPosition === "right"
                        readonly property bool isIslandStyle: Config.barFrameStyle === "island"
                        readonly property bool isFloatingStyle: Config.barFrameStyle === "floating" || isIslandStyle

                        property bool allowAnimation: false

                        Timer {
                            id: animDisableTimer
                            interval: 300
                            onTriggered: miniBar.allowAnimation = false
                        }

                        function triggerAnimation() {
                            miniBar.allowAnimation = true
                            animDisableTimer.restart()
                        }

                        Connections {
                            target: Config
                            function onBarPositionChanged() {
                                if (miniBar.Component.isCompleted) miniBar.triggerAnimation()
                            }
                            function onBarFrameStyleChanged() {
                                if (miniBar.Component.isCompleted) miniBar.triggerAnimation()
                            }
                        }

                        // Position & Dimensions Animation
                        x: {
                            if (Config.barPosition === "left") return isFloatingStyle ? 36 : 0
                            if (Config.barPosition === "right") return monitorCanvas.width - width - (isFloatingStyle ? 36 : 0)
                            if (isIslandStyle) return (monitorCanvas.width - width) / 2
                            return isFloatingStyle ? 12 : 0
                        }
                        y: {
                            if (Config.barPosition === "top") return isFloatingStyle ? 36 : 0
                            if (Config.barPosition === "bottom") return monitorCanvas.height - height - (isFloatingStyle ? 36 : 0)
                            if (isIslandStyle) return (monitorCanvas.height - height) / 2
                            return isFloatingStyle ? 12 : 0
                        }
                        width: {
                            if (isVertical) return 36
                            if (isIslandStyle) return monitorCanvas.width * 0.6
                            return isFloatingStyle ? (monitorCanvas.width - 24) : monitorCanvas.width
                        }
                        height: {
                            if (!isVertical) return 32
                            if (isIslandStyle) return monitorCanvas.height * 0.55
                            return isFloatingStyle ? (monitorCanvas.height - 24) : monitorCanvas.height
                        }
                        radius: isIslandStyle ? 16 : (isFloatingStyle ? 10 : (Config.barFrameStyle === "screen" ? 6 : 0))

                        color: Qt.rgba(18, 20, 29, 0.92)
                        border.width: isFloatingStyle ? 1 : 0
                        border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.4)

                        Behavior on x { enabled: miniBar.allowAnimation; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on y { enabled: miniBar.allowAnimation; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on width { enabled: miniBar.allowAnimation; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on height { enabled: miniBar.allowAnimation; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on radius { enabled: miniBar.allowAnimation; NumberAnimation { duration: 150 } }

                        // Bar Modules Layout inside simulated bar
                        Item {
                            anchors.fill: parent
                            anchors.margins: 6

                            // Horizontal Layout (Top / Bottom)
                            RowLayout {
                                anchors.fill: parent
                                visible: !miniBar.isVertical
                                spacing: 8

                                // Left Modules
                                RowLayout {
                                    spacing: 6
                                    Text { text: "grid_view"; font.family: "Material Symbols Outlined"; font.pixelSize: 13; color: Config.accent }
                                    Rectangle { implicitWidth: 20; implicitHeight: 14; radius: 7; color: Config.accent }
                                    Rectangle { implicitWidth: 14; implicitHeight: 14; radius: 7; color: Qt.rgba(255, 255, 255, 0.15) }
                                    Rectangle { implicitWidth: 14; implicitHeight: 14; radius: 7; color: Qt.rgba(255, 255, 255, 0.15) }
                                }

                                Item { Layout.fillWidth: true }

                                // Center Clock
                                Text {
                                    text: "09:49 AM"
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.textMain
                                    visible: miniBar.width > 220
                                }

                                Item { Layout.fillWidth: true }

                                // Right Modules
                                RowLayout {
                                    spacing: 6
                                    Text { text: "wifi"; font.family: "Material Symbols Outlined"; font.pixelSize: 12; color: Config.textMain }
                                    Text { text: "volume_up"; font.family: "Material Symbols Outlined"; font.pixelSize: 12; color: Config.textMain }
                                    Rectangle {
                                        implicitWidth: 32; implicitHeight: 16; radius: 8
                                        color: Qt.rgba(255, 255, 255, 0.1)
                                        Text { anchors.centerIn: parent; text: "85%"; font.family: Config.sysFont; font.pixelSize: 9; font.bold: true; color: Config.textMain }
                                    }
                                    Text { text: "power_settings_new"; font.family: "Material Symbols Outlined"; font.pixelSize: 12; color: Config.accent }
                                }
                            }

                            // Vertical Layout (Left / Right)
                            ColumnLayout {
                                anchors.fill: parent
                                visible: miniBar.isVertical
                                spacing: 8

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6
                                    Text { text: "grid_view"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; color: Config.accent; Layout.alignment: Qt.AlignHCenter }
                                    Rectangle { implicitWidth: 16; implicitHeight: 22; radius: 6; color: Config.accent; Layout.alignment: Qt.AlignHCenter }
                                    Rectangle { implicitWidth: 16; implicitHeight: 16; radius: 6; color: Qt.rgba(255, 255, 255, 0.15); Layout.alignment: Qt.AlignHCenter }
                                }

                                Item { Layout.fillHeight: true }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6
                                    Text { text: "wifi"; font.family: "Material Symbols Outlined"; font.pixelSize: 13; color: Config.textMain; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: "volume_up"; font.family: "Material Symbols Outlined"; font.pixelSize: 13; color: Config.textMain; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: "power_settings_new"; font.family: "Material Symbols Outlined"; font.pixelSize: 13; color: Config.accent; Layout.alignment: Qt.AlignHCenter }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // FLUSH ROTATED EDGE DOCK BUTTONS
                    // ==========================================

                    // 1. TOP DOCK BUTTON (Flush Top)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        z: 10
                        implicitWidth: topDockRow.implicitWidth + 20
                        implicitHeight: 24
                        radius: 12
                        color: Config.barPosition === "top"
                            ? Config.accent
                            : (topDockMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08))
                        border.width: 1
                        border.color: Config.barPosition === "top" ? Config.accent : Qt.rgba(255, 255, 255, 0.25)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: topDockRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "north"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 13
                                color: Config.barPosition === "top" ? Config.bgBase : Config.textMain
                            }
                            Text {
                                text: Config.barPosition === "top" ? "DOCK TOP (ACTIVE)" : "DOCK TOP"
                                font.family: Config.sysFont
                                font.pixelSize: 10
                                font.bold: true
                                color: Config.barPosition === "top" ? Config.bgBase : Config.textMain
                            }
                        }

                        MouseArea {
                            id: topDockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.barPosition = "top"
                        }
                    }

                    // 2. BOTTOM DOCK BUTTON (Flush Bottom)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        z: 10
                        implicitWidth: bottomDockRow.implicitWidth + 20
                        implicitHeight: 24
                        radius: 12
                        color: Config.barPosition === "bottom"
                            ? Config.accent
                            : (bottomDockMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08))
                        border.width: 1
                        border.color: Config.barPosition === "bottom" ? Config.accent : Qt.rgba(255, 255, 255, 0.25)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: bottomDockRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "south"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 13
                                color: Config.barPosition === "bottom" ? Config.bgBase : Config.textMain
                            }
                            Text {
                                text: Config.barPosition === "bottom" ? "DOCK BOTTOM (ACTIVE)" : "DOCK BOTTOM"
                                font.family: Config.sysFont
                                font.pixelSize: 10
                                font.bold: true
                                color: Config.barPosition === "bottom" ? Config.bgBase : Config.textMain
                            }
                        }

                        MouseArea {
                            id: bottomDockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.barPosition = "bottom"
                        }
                    }

                    // 3. LEFT DOCK BUTTON (Rotated -90° Flush Left)
                    Item {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        z: 10
                        implicitWidth: 24
                        implicitHeight: leftDockRow.implicitWidth + 20

                        Rectangle {
                            anchors.centerIn: parent
                            width: leftDockRow.implicitWidth + 20
                            height: 24
                            radius: 12
                            rotation: -90
                            color: Config.barPosition === "left"
                                ? Config.accent
                                : (leftDockMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08))
                            border.width: 1
                            border.color: Config.barPosition === "left" ? Config.accent : Qt.rgba(255, 255, 255, 0.25)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: leftDockRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    text: "north"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 13
                                    color: Config.barPosition === "left" ? Config.bgBase : Config.textMain
                                }
                                Text {
                                    text: Config.barPosition === "left" ? "DOCK LEFT (ACTIVE)" : "DOCK LEFT"
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.barPosition === "left" ? Config.bgBase : Config.textMain
                                }
                            }
                        }

                        MouseArea {
                            id: leftDockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.barPosition = "left"
                        }
                    }

                    // 4. RIGHT DOCK BUTTON (Rotated 90° Flush Right)
                    Item {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        z: 10
                        implicitWidth: 24
                        implicitHeight: rightDockRow.implicitWidth + 20

                        Rectangle {
                            anchors.centerIn: parent
                            width: rightDockRow.implicitWidth + 20
                            height: 24
                            radius: 12
                            rotation: 90
                            color: Config.barPosition === "right"
                                ? Config.accent
                                : (rightDockMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08))
                            border.width: 1
                            border.color: Config.barPosition === "right" ? Config.accent : Qt.rgba(255, 255, 255, 0.25)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: rightDockRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    text: Config.barPosition === "right" ? "DOCK RIGHT (ACTIVE)" : "DOCK RIGHT"
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Config.barPosition === "right" ? Config.bgBase : Config.textMain
                                }
                                Text {
                                    text: "north"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 13
                                    color: Config.barPosition === "right" ? Config.bgBase : Config.textMain
                                }
                            }
                        }

                        MouseArea {
                            id: rightDockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.barPosition = "right"
                        }
                    }
                }

                // ==========================================
                // FRAME STYLE SELECTOR SEGMENT BAR
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "FRAME & GEOMETRY STYLE:"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: [
                                { id: "floating", name: "Floating Capsule", icon: "crop_21_9", desc: "Elevated bar with rounded corners & gaps" },
                                { id: "island",   name: "Compact Island",  icon: "crop_16_9", desc: "Centered pill bar detached from sides" },
                                { id: "edge",     name: "Flush Edge",      icon: "border_left", desc: "Full-width panel flush with display" },
                                { id: "screen",   name: "Screen Frame",    icon: "web_asset",  desc: "Continuous outer frame around viewport" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 48
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: Config.barFrameStyle === modelData.id

                                color: isSelected 
                                    ? Qt.rgba(255, 255, 255, 0.14) 
                                    : (qStyleHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 1.5 : 1
                                border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: isSelected ? Config.accent : Config.textMuted
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: modelData.name
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                            font.bold: true
                                            color: isSelected ? Config.accent : Config.textMain
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.desc
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontMicro)
                                            color: Config.textMuted
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        text: "check_circle"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: Config.accent
                                        visible: isSelected
                                    }
                                }

                                MouseArea {
                                    id: qStyleHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.barFrameStyle = modelData.id
                                }
                            }
                        }
                    }

                    // Peek Panels Toggle Row
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: peekRow.implicitHeight + 16
                        radius: Config.cornerRadius / 2
                        color: peekHover.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        RowLayout {
                            id: peekRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Peek Panels"
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    font.bold: true
                                }

                                Text {
                                    text: "Extend rounded protrusion tabs when hovering over active bar modules."
                                    color: Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            ToggleSwitch {
                                checked: Config.enableHoverPeek
                            }
                        }

                        MouseArea {
                            id: peekHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.enableHoverPeek = !Config.enableHoverPeek
                        }
                    }

                    // Auto-hide Status Bar Toggle Row
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: autoHideRow.implicitHeight + 16
                        radius: Config.cornerRadius / 2
                        color: autoHideHover.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        RowLayout {
                            id: autoHideRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Auto-hide Status Bar"
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    font.bold: true
                                }

                                Text {
                                    text: "Automatically slide the bar out of view when not hovered to maximize screen real estate."
                                    color: Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }

                            ToggleSwitch {
                                checked: Config.autoHideBar
                            }
                        }

                        MouseArea {
                            id: autoHideHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.autoHideBar = !Config.autoHideBar
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. DISPLAY TARGET ASSIGNMENT CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: dispCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: dispCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "DISPLAY TARGET ASSIGNMENT"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Select which connected monitors render the status bar."
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // Reset / Enable All Button
                    Rectangle {
                        implicitWidth: enableAllRow.implicitWidth + 16
                        implicitHeight: 28
                        radius: 14
                        color: enableAllMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.15)

                        RowLayout {
                            id: enableAllRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "desktop_windows"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: Config.textMain
                            }
                            Text {
                                text: "Enable All Displays"
                                font.family: Config.sysFont
                                font.pixelSize: 10
                                font.bold: true
                                color: Config.textMain
                            }
                        }

                        MouseArea {
                            id: enableAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.enabledBarScreens = []
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: Quickshell.screens

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 56
                            radius: Config.cornerRadius / 2

                            readonly property bool isSelected: Config.enabledBarScreens.length === 0 || Config.enabledBarScreens.includes(modelData.name)

                            color: isSelected 
                                ? Qt.rgba(255, 255, 255, 0.1) 
                                : (dispHover.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                            border.width: 1
                            border.color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.5) : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    implicitWidth: 34; implicitHeight: 34; radius: 17
                                    color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.06)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "desktop_windows"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: isSelected ? Config.accent : Config.textMuted
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        color: Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontBody)
                                        font.bold: true
                                    }

                                    Text {
                                        text: (modelData.width && modelData.height) ? (modelData.width + " × " + modelData.height + " Resolution") : "Connected Display Monitor"
                                        color: Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                    }
                                }

                                // Status Badge
                                Rectangle {
                                    implicitWidth: badgeText.implicitWidth + 12
                                    implicitHeight: 22
                                    radius: 11
                                    color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.08)
                                    border.width: 1
                                    border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                                    Text {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: isSelected ? "ACTIVE ON BAR" : "INACTIVE"
                                        font.family: Config.sysFont
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: isSelected ? Config.accent : Config.textMuted
                                    }
                                }

                                ToggleSwitch {
                                    checked: isSelected
                                }
                            }

                            MouseArea {
                                id: dispHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.toggleBarScreen(modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }
}
