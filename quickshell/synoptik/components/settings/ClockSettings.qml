import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: root

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

    RowLayout {
        anchors.fill: parent
        spacing: 20

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Text {
                text: "DESKTOP CLOCK CONFIGURATION"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontSubhead)
                font.bold: true
            }

            // TOGGLE: ENABLE WIDGET
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
                        text: "Enable Desktop Clock Widget"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontBody)
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Show the desktop clock overlay on your displays"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        wrapMode: Text.WordWrap
                    }
                }

                ToggleSwitch {
                    checked: Config.showDesktopClock !== false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.showDesktopClock = (Config.showDesktopClock === false)
                            if (typeof Config.saveConfig === "function") Config.saveConfig()
                            else if (typeof Config.save === "function") Config.save()
                        }
                    }
                }
            }

            // SUB-OPTIONS WRAPPER (Dims and disables interaction when clock toggle is off)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                enabled: Config.showDesktopClock !== false
                opacity: enabled ? 1.0 : 0.35

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                // STYLE SELECTOR
                ColumnLayout {
                    spacing: 6

                    Text {
                        text: "CLOCK STYLE"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "Digital", style: "digital" },
                                { name: "Modern", style: "modern" },
                                { name: "Analog", style: "analog" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 130
                                implicitHeight: 36
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: Config.clockStyle === modelData.style
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (styleHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 1 : 0
                                border.color: Config.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: isSelected
                                }

                                TapHandler { onTapped: Config.clockStyle = modelData.style }
                                HoverHandler { id: styleHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // TARGET DISPLAYS SECTION
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Text {
                        text: "SHOW CLOCK ON THESE DISPLAYS:"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: Quickshell.screens

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 90
                                implicitHeight: 32
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: Config.enabledClockScreens.length === 0 || Config.enabledClockScreens.includes(modelData.name)
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (dispHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 1 : 0
                                border.color: Config.accent

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                Text {
                                    text: modelData.name
                                    color: isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: isSelected
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: isSelected ? "✓" : "+"
                                    color: isSelected ? Config.accent : Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: isSelected
                                }
                            }

                            TapHandler { onTapped: Config.toggleClockScreen(modelData.name) }
                            HoverHandler { id: dispHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

                // DISPLAY OPTIONS
                ColumnLayout {
                    spacing: 8

                    Text {
                        text: "DISPLAY OPTIONS"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    // TOGGLE BORDER
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
                                text: "Show Border"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Draw a decorative border around the clock widget"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: Config.clockShowBorder !== false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.clockShowBorder = (Config.clockShowBorder === false)
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }

                    // TOGGLE BACKGROUND
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
                                text: "Show Background"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Display a background panel behind the clock"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: Config.clockShowBackground !== false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.clockShowBackground = (Config.clockShowBackground === false)
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }

                    // TOGGLE GLOW EFFECT
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
                                text: "Glow Effect"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Apply a soft glow effect to the clock display"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: Config.clockShowGlow !== false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.clockShowGlow = (Config.clockShowGlow === false)
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }

                    // TOGGLE SECONDS
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
                                text: "Include seconds in the clock time display"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: Config.clockShowSeconds !== false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.clockShowSeconds = (Config.clockShowSeconds === false)
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }

                    // TOGGLE 12-HOUR FORMAT
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
                                text: "Use 12-Hour Format"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Display time in 12-hour instead of 24-hour format"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: Config.clockUse12Hour !== false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.clockUse12Hour = (Config.clockUse12Hour === false)
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }

                    // TOGGLE AM/PM (DIGITAL & 12-HOUR ONLY)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: Config.clockUse12Hour && Config.clockStyle === "digital"

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: "Show AM/PM"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Show the AM/PM indicator next to the time (digital 12-hour mode only)"
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: Config.clockShowAmPm !== false

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.clockShowAmPm = (Config.clockShowAmPm === false)
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}