import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import "../lockscreen"
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

        Text {
            Layout.fillWidth: true
            text: "LOCKSCREEN CONFIGURATION"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Configure the Wayland session lockscreen, active monitor destination, randomized shape password bar, clock typography, and display toggles."
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

                    Text {
                        text: "LIVE PASSWORD BAR PREVIEW"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // RELIABLE TEST LOCK BUTTON
                    Rectangle {
                        id: testLockBtn
                        implicitWidth: testLockRow.implicitWidth + 16
                        implicitHeight: 30
                        radius: 15
                        color: testLockMouse.containsMouse ? Config.accent : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                        border.width: 1.5
                        border.color: Config.accent

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: testLockRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "lock"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: testLockMouse.containsMouse ? Config.bgBase : Config.accent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: "Test Lock Now"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: testLockMouse.containsMouse ? Config.bgBase : Config.accent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: testLockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.sessionLocked = true
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Type below to test live glyphs, animations, and clearing mechanics:"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    wrapMode: Text.WordWrap
                }

                LockscreenPasswordBar {
                    id: previewPassBar
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    maskStyle: Config.lockscreenMaskStyle || "shapes"
                    paletteMode: Config.lockscreenShapePalette || "vibrant"
                    placeholderText: "Type to test password bar..."

                    onSubmitPassword: (pass) => {
                        previewPassBar.isAuthenticating = true
                        previewSimTimer.restart()
                    }
                }

                Timer {
                    id: previewSimTimer
                    interval: 500
                    onTriggered: {
                        previewPassBar.isAuthenticating = false
                        previewPassBar.isSuccess = true
                        previewResetTimer.restart()
                    }
                }

                Timer {
                    id: previewResetTimer
                    interval: 700
                    onTriggered: {
                        previewPassBar.isSuccess = false
                        previewPassBar.clearInput()
                    }
                }
            }
        }

        // ==========================================
        // 2. TARGET MONITOR SELECTION CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: monitorCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: monitorCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "ACTIVE LOCKSCREEN DISPLAY"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                Text {
                    text: "Select which display renders the active unlock UI. All other displays will remain solid black."
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Option: Hyprland Focused Monitor
                    Rectangle {
                        id: focusedPill
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        implicitHeight: 36
                        radius: Config.cornerRadius / 2

                        readonly property bool isSelected: (Config.lockscreenTargetMonitor || "focused") === "focused"

                        color: isSelected 
                            ? Config.accent 
                            : (focusedMonHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))
                        border.width: isSelected ? 1.5 : 1
                        border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "center_focus_strong"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                color: focusedPill.isSelected ? Config.bgBase : Config.accent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: "Focused Screen"
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: true
                                color: focusedPill.isSelected ? Config.bgBase : Config.textMain
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: focusedMonHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.lockscreenTargetMonitor = "focused"
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }

                    // Dynamic attached monitor pills from Quickshell
                    Repeater {
                        model: Quickshell.screens

                        delegate: Rectangle {
                            id: monitorPill
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            implicitHeight: 36
                            radius: Config.cornerRadius / 2

                            readonly property string scrName: (modelData && modelData.name) ? modelData.name : ""
                            readonly property bool isSelected: Config.lockscreenTargetMonitor === scrName

                            color: isSelected 
                                ? Config.accent 
                                : (scrHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "desktop_windows"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: monitorPill.isSelected ? Config.bgBase : Config.accent
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: monitorPill.scrName
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: monitorPill.isSelected ? Config.bgBase : Config.textMain
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: scrHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (monitorPill.scrName !== "") {
                                        Config.lockscreenTargetMonitor = monitorPill.scrName
                                        if (typeof Config.saveConfig === "function") Config.saveConfig()
                                        else if (typeof Config.save === "function") Config.save()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. PASSWORD MASK STYLE SELECTOR
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: maskStyleCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: maskStyleCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "PASSWORD MASK STYLE"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "shapes",    label: "Shapes",        icon: "category",            desc: "16 vector shapes", preview: "◆ ▲ ■" },
                            { id: "dots",      label: "Dots",          icon: "fiber_manual_record", desc: "Bullet discs",     preview: "● ● ●" },
                            { id: "asterisks", label: "Asterisks",     icon: "emergency",           desc: "Classic asterisks", preview: "✱ ✱ ✱" },
                            { id: "special",   label: "Special Chars", icon: "code",                desc: "Random symbols",   preview: "! @ # ★" }
                        ]

                        delegate: Rectangle {
                            id: maskPill
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            implicitHeight: 68
                            radius: Config.cornerRadius / 2

                            readonly property bool isSelected: (Config.lockscreenMaskStyle || "shapes") === modelData.id

                            color: isSelected 
                                ? Qt.rgba(255, 255, 255, 0.14) 
                                : (maskHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 16
                                        color: maskPill.isSelected ? Config.accent : Config.textMuted
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        color: maskPill.isSelected ? Config.accent : Config.textMain
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                Text {
                                    text: modelData.preview
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: maskPill.isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.5)
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: maskHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.lockscreenMaskStyle = modelData.id
                                    previewPassBar.maskStyle = modelData.id
                                    if (typeof previewPassBar.shuffleShapes === "function") {
                                        previewPassBar.shuffleShapes()
                                    }
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. PALETTE & COLOR THEME
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: paletteCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: paletteCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "RANDOMIZED SHAPE PALETTE"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "vibrant", label: "Vibrant", desc: "Cyber tones", previewColor: "#00f0ff" },
                            { id: "accent", label: "Accent", desc: "Theme match", previewColor: Config.accent },
                            { id: "neon", label: "Neon High", desc: "High contrast", previewColor: "#ff0055" },
                            { id: "pastel", label: "Pastel", desc: "Soft hues", previewColor: "#c4b5fd" },
                            { id: "monochrome", label: "Monochrome", desc: "Silver/Grey", previewColor: "#ffffff" }
                        ]

                        delegate: Rectangle {
                            id: palPill
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            implicitHeight: 64
                            radius: Config.cornerRadius / 2

                            readonly property bool isSelected: (Config.lockscreenShapePalette || "vibrant") === modelData.id

                            color: isSelected 
                                ? Qt.rgba(255, 255, 255, 0.14) 
                                : (palHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 5

                                    Rectangle {
                                        implicitWidth: 10
                                        implicitHeight: 10
                                        radius: 5
                                        color: modelData.previewColor
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        color: palPill.isSelected ? Config.accent : Config.textMain
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    color: Config.textMuted
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: palHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.lockscreenShapePalette = modelData.id
                                    if (typeof previewPassBar.shuffleShapes === "function") {
                                        previewPassBar.shuffleShapes()
                                    }
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. TIME & DATE FORMAT CONFIGURATION
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: timeFormatCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: timeFormatCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Text {
                    text: "TIME & DATE FORMAT"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // TIME FORMAT (12-HOUR VS 24-HOUR) & CLOCK SIZE
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    // 12-Hour vs 24-Hour Compact Pills
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 8

                        Text {
                            text: "Time Mode:"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                        }

                        Repeater {
                            model: [
                                { label: "12-Hour", use12: true, icon: "schedule" },
                                { label: "24-Hour", use12: false, icon: "military_tech" }
                            ]

                            delegate: Rectangle {
                                id: hourPill
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0
                                implicitHeight: 30
                                radius: 15

                                readonly property bool isSelected: (Config.lockscreenUse12Hour !== false) === modelData.use12

                                color: isSelected 
                                    ? Config.accent 
                                    : (hourModeHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: hourPill.isSelected ? Config.bgBase : Config.accent
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: Config.sysFont
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: hourPill.isSelected ? Config.bgBase : Config.textMain
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    id: hourModeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.lockscreenUse12Hour = modelData.use12
                                        if (typeof Config.saveConfig === "function") Config.saveConfig()
                                        else if (typeof Config.save === "function") Config.save()
                                    }
                                }
                            }
                        }
                    }

                    // CLOCK TYPOGRAPHY SIZE
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: "Clock Size:"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                        }

                        Repeater {
                            model: [
                                { label: "100px", size: 100 },
                                { label: "150px", size: 150 },
                                { label: "200px", size: 200 }
                            ]

                            delegate: Rectangle {
                                id: clockPill
                                implicitWidth: sizeText.implicitWidth + 20
                                implicitHeight: 30
                                radius: 15
                                readonly property bool isSelected: (Config.lockscreenClockSize || 150) === modelData.size
                                color: isSelected ? Config.accent : (sizeHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                                Text {
                                    id: sizeText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: clockPill.isSelected ? Config.bgBase : Config.textMain
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: sizeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.lockscreenClockSize = modelData.size
                                        if (typeof Config.saveConfig === "function") Config.saveConfig()
                                        else if (typeof Config.save === "function") Config.save()
                                    }
                                }
                            }
                        }
                    }
                }

                // TIME DISPLAY TOGGLES (SECONDS & AM/PM)
                // SHOW SECONDS
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
                            text: "Show Seconds"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Display seconds in the clock (e.g. 10:42:30)."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.lockscreenShowSeconds !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.lockscreenShowSeconds = (Config.lockscreenShowSeconds === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // SHOW AM/PM BADGE
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: Config.lockscreenUse12Hour !== false

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Show AM/PM Badge"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Display the AM/PM indicator alongside the 12-hour clock."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.lockscreenShowAmPm !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.lockscreenShowAmPm = (Config.lockscreenShowAmPm === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // DATE FORMAT SELECTOR
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Date Display Style:"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // Live Date Preview String
                        RowLayout {
                            spacing: 6

                            Text {
                                text: "Preview:"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: 11
                            }

                            Text {
                                text: {
                                    let d = new Date()
                                    let mode = Config.lockscreenDateFormat || "long"
                                    if (mode === "standard") return Qt.formatDate(d, "ddd, MMM d, yyyy")
                                    if (mode === "iso") return Qt.formatDate(d, "yyyy-MM-dd")
                                    if (mode === "dayFirst") return Qt.formatDate(d, "d MMMM yyyy")
                                    return Qt.formatDate(d, "dddd, MMMM d, yyyy")
                                }
                                color: Config.accent
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    // Compact Segmented Pills
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { id: "long", label: "Long" },
                                { id: "standard", label: "Standard" },
                                { id: "dayFirst", label: "Day First" },
                                { id: "iso", label: "ISO 8601" }
                            ]

                            delegate: Rectangle {
                                id: datePill
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.minimumWidth: 0
                                implicitHeight: 32
                                radius: 16

                                readonly property bool isSelected: (Config.lockscreenDateFormat || "long") === modelData.id
                                color: isSelected ? Config.accent : (dateHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: datePill.isSelected ? Config.bgBase : Config.textMain
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: dateHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.lockscreenDateFormat = modelData.id
                                        if (typeof Config.saveConfig === "function") Config.saveConfig()
                                        else if (typeof Config.save === "function") Config.save()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 6. LOCKSCREEN VISUALS & TOGGLES
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: togglesCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: togglesCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "LOCKSCREEN DISPLAY OPTIONS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // TOGGLE 1: MEDIA CONTROLLER
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
                            text: "Show Media Player Mini Controller"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Display currently playing track metadata and playback controls on the lock screen."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.lockscreenShowMedia !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.lockscreenShowMedia = (Config.lockscreenShowMedia === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // TOGGLE 2: POWER CONTROLS
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
                            text: "Show Power Actions on Lockscreen"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Allow suspending, rebooting, and powering off the system directly from the lock surface."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.lockscreenShowPower !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.lockscreenShowPower = (Config.lockscreenShowPower === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // BLUR RADIUS PRESETS
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Wallpaper Blur Effect:"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { label: "Light (18px)", value: 18 },
                            { label: "Medium (36px)", value: 36 },
                            { label: "Heavy (60px)", value: 60 }
                        ]

                        delegate: Rectangle {
                            id: blurPill
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            implicitHeight: 30
                            radius: 15
                            readonly property bool isSelected: (Config.lockscreenBlurRadius || 36) === modelData.value
                            color: isSelected ? Config.accent : (blurHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: blurPill.isSelected ? Config.bgBase : Config.textMain
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: blurHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.lockscreenBlurRadius = modelData.value
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            implicitHeight: 20
        }
    }
}