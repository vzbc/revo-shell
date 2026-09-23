import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Flickable {
    id: flickable
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: flickable.moving || flickable.flicking
    }

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Reusable Geometric / Square Toggle Switch Component
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
        width: Math.min(flickable.width - (flickable.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: flickable.cardMargin

        // SECTION HEADER
        Text {
            Layout.fillWidth: true
            text: "SCREENSAVER CONFIGURATION"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Configure the full-screen bouncing screensaver with font rendering, classic DVD Video mode, and physics speed."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // ==========================================
        // 1. INTERACTIVE LIVE PREVIEW CARD
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
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: "LIVE PREVIEW"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }

                        Text {
                            text: "Real-time viewport of the floating bounce animation."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitWidth: 110
                        implicitHeight: 32
                        radius: 16
                        color: Config.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "play_arrow"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                color: Config.bgBase
                            }

                            Text {
                                text: "Test Now"
                                font.family: Config.sysFont
                                font.pixelSize: 12
                                font.bold: true
                                color: Config.bgBase
                            }
                        }

                        TapHandler {
                            onTapped: Config.showScreensaver = true
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }

                // Mini Preview Box
                Rectangle {
                    id: miniBox
                    Layout.fillWidth: true
                    implicitHeight: 180
                    radius: Config.cornerRadius - 2
                    color: "#000000"
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    clip: true

                    property real pX: 30
                    property real pY: 30
                    property real pDx: 1.8
                    property real pDy: 1.4
                    readonly property var previewColors: ["#FF0055", "#00F0FF", "#FFE600", "#00FF66", "#FF6B00", "#9D00FF"]
                    property int colorIdx: 0
                    property color pColor: previewColors[colorIdx]

                    Timer {
                        interval: 16
                        running: flickable.visible
                        repeat: true
                        onTriggered: {
                            let bw = miniBox.width
                            let bh = miniBox.height
                            let ow = miniLogo.width
                            let oh = miniLogo.height
                            if (bw <= 0 || bh <= 0 || ow <= 0 || oh <= 0) return

                            let nx = miniBox.pX + miniBox.pDx
                            let ny = miniBox.pY + miniBox.pDy
                            let hit = false

                            if (nx + ow >= bw) { miniBox.pDx = -Math.abs(miniBox.pDx); nx = bw - ow; hit = true; }
                            else if (nx <= 0) { miniBox.pDx = Math.abs(miniBox.pDx); nx = 0; hit = true; }

                            if (ny + oh >= bh) { miniBox.pDy = -Math.abs(miniBox.pDy); ny = bh - oh; hit = true; }
                            else if (ny <= 0) { miniBox.pDy = Math.abs(miniBox.pDy); ny = 0; hit = true; }

                            if (hit) {
                                miniBox.colorIdx = (miniBox.colorIdx + 1) % miniBox.previewColors.length
                                miniBox.pColor = miniBox.previewColors[miniBox.colorIdx]
                            }

                            miniBox.pX = nx
                            miniBox.pY = ny
                        }
                    }

                    Item {
                        id: miniLogo
                        x: miniBox.pX
                        y: miniBox.pY
                        width: miniCol.implicitWidth + 8
                        height: miniCol.implicitHeight + 4

                        Column {
                            id: miniCol
                            anchors.centerIn: parent
                            spacing: 1

                            // DVD Mode in Preview
                            Column {
                                visible: (Config.screensaverMode || "text") === "dvd"
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: -2

                                Text {
                                    text: "DVD"
                                    font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                    font.pixelSize: 22
                                    font.bold: true
                                    font.letterSpacing: 2
                                    font.italic: true
                                    color: miniBox.pColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Rectangle {
                                    width: parent.width * 0.95
                                    height: 1.5
                                    color: miniBox.pColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: "V I D E O"
                                    font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                    font.pixelSize: 6
                                    font.bold: true
                                    font.letterSpacing: 3
                                    color: miniBox.pColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    topPadding: 1
                                }
                            }

                            // Activate Linux Mode in Preview
                            Column {
                                visible: Config.screensaverMode === "activate" || Config.screensaverMode === "clock"
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 1

                                Text {
                                    text: "Activate Linux"
                                    font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                    font.pixelSize: 17
                                    font.bold: true
                                    font.letterSpacing: 1
                                    color: miniBox.pColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: "Go to Settings to activate Linux"
                                    font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                    font.pixelSize: 8
                                    color: Qt.rgba(miniBox.pColor.r, miniBox.pColor.g, miniBox.pColor.b, 0.8)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            // Custom Text Mode in Preview
                            Column {
                                visible: (Config.screensaverMode || "text") === "text"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: (Config.screensaverText !== undefined && Config.screensaverText !== "") ? Config.screensaverText : "SYNOPTIK"
                                    font.family: Config.sysFont !== "" ? Config.sysFont : "system-ui"
                                    font.pixelSize: 20
                                    font.bold: true
                                    font.letterSpacing: 2
                                    color: miniBox.pColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. DISPLAY MODE & TYPOGRAPHY CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: modeCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: modeCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "DISPLAY MODE"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    font.bold: true
                }

                // MODE SELECTOR BUTTONS
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { label: "Custom Text", value: "text", icon: "title" },
                            { label: "DVD Logo", value: "dvd", icon: "disc_full" },
                            { label: "Activate Linux", value: "activate", icon: "verified" }
                        ]

                        delegate: Rectangle {
                            id: modeBtn
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 38
                            radius: 19
                            readonly property bool isSelected: (Config.screensaverMode || "text") === modelData.value
                            color: isSelected ? Config.accent : (modeBtnHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: modeBtn.isSelected ? Config.bgBase : Config.textMuted
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Config.sysFont
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modeBtn.isSelected ? Config.bgBase : Config.textMain
                                }
                            }

                            MouseArea {
                                id: modeBtnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.screensaverMode = modelData.value
                            }
                        }
                    }
                }

                // CUSTOM TEXT INPUT
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: (Config.screensaverMode || "text") === "text"
                    spacing: 6

                    Text {
                        text: "Floating Text String:"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.35)
                        border.width: 1
                        border.color: textInputHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                        TextInput {
                            id: customTextInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            text: Config.screensaverText !== undefined ? Config.screensaverText : ""
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            selectByMouse: true
                            onTextChanged: {
                                if (Config.screensaverText !== text) {
                                    Config.screensaverText = text
                                }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Type floating text (e.g. SYNOPTIK)..."
                            color: Qt.rgba(255, 255, 255, 0.3)
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            visible: customTextInput.text.length === 0
                        }

                        HoverHandler { id: textInputHover }
                    }
                }

                // FONT SIZE PRESETS
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Font Size:"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { label: "Medium (42px)", value: 42 },
                            { label: "Large (54px)", value: 54 },
                            { label: "Huge (72px)", value: 72 }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            radius: 15
                            readonly property bool isSelected: (Config.screensaverFontSize || 54) === modelData.value
                            color: isSelected ? Config.accent : (fontHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: isSelected ? Config.bgBase : Config.textMain
                            }

                            MouseArea {
                                id: fontHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.screensaverFontSize = modelData.value
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. ANIMATION & PHYSICS CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: physicsCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: physicsCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "ANIMATION & PHYSICS"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    font.bold: true
                }

                // SPEED PRESETS
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Speed:"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { label: "Relaxed (2.2)", value: 2.2 },
                            { label: "Normal (3.5)", value: 3.5 },
                            { label: "Fast (5.5)", value: 5.5 },
                            { label: "Turbo (8.0)", value: 8.0 }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            radius: 15
                            readonly property bool isSelected: Math.abs((Config.screensaverSpeed || 3.5) - modelData.value) < 0.1
                            color: isSelected ? Config.accent : (speedHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: isSelected ? Config.bgBase : Config.textMain
                            }

                            MouseArea {
                                id: speedHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.screensaverSpeed = modelData.value
                            }
                        }
                    }
                }

                // CORNER HIT COUNTER TOGGLE
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Corner Hit Counter & Flash Effect"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Display a running corner-hit count and trigger a flash animation each time the logo bounces into a corner."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.screensaverCornerCounter !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.screensaverCornerCounter = (Config.screensaverCornerCounter === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
    }
}