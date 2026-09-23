import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: root

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

        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
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
                text: "RETRO SCREEN SHADER CONFIGURATION"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontSubhead)
                font.bold: true
            }

            // MASTER TOGGLE
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
                        text: "Enable Screen Shader"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontBody)
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Apply custom post-processing fragment shaders across your displays"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        wrapMode: Text.WordWrap
                    }
                }

                ToggleSwitch {
                    checked: Config.pixelShaderEnabled === true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.pixelShaderEnabled = !Config.pixelShaderEnabled
                            Config.updateShader()
                        }
                    }
                }
            }

            // OPTIONS CONTAINER
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                enabled: Config.pixelShaderEnabled === true
                opacity: Config.pixelShaderEnabled ? 1.0 : 0.4

                Behavior on opacity { NumberAnimation { duration: 160 } }

                // SHADER MODE SELECTOR
                ColumnLayout {
                    spacing: 6

                    Text {
                        text: "SHADER PRESET"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "Pixelate / 8-Bit", id: "pixelate" },
                                { name: "Arcade CRT", id: "crt" },
                                { name: "Macintosh 1-Bit", id: "mac1bit" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 140
                                implicitHeight: 36
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: (Config.pixelShaderMode || "pixelate") === modelData.id
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (modeHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 2 : 0
                                border.color: Config.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: isSelected
                                }

                                TapHandler { 
                                    onTapped: {
                                        Config.pixelShaderMode = modelData.id
                                        Config.updateShader()
                                    }
                                }
                                HoverHandler { id: modeHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // PIXEL DENSITY / SCALE (PIXELATE ONLY)
                ColumnLayout {
                    spacing: 6
                    visible: (Config.pixelShaderMode || "pixelate") === "pixelate"

                    Text {
                        text: "PIXEL SCALE"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "Subtle (2px)", val: 2.0 },
                                { name: "Retro (3px)", val: 3.0 },
                                { name: "Chunky (4px)", val: 4.0 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 130
                                implicitHeight: 36
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: (Config.pixelShaderSize || 2.0) === modelData.val
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (szHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 2 : 0
                                border.color: Config.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: isSelected
                                }

                                TapHandler { 
                                    onTapped: {
                                        Config.pixelShaderSize = modelData.val
                                        Config.updateShader()
                                    }
                                }
                                HoverHandler { id: szHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // COLOR DEPTH (PIXELATE ONLY)
                ColumnLayout {
                    spacing: 6
                    visible: (Config.pixelShaderMode || "pixelate") === "pixelate"

                    Text {
                        text: "COLOR DEPTH"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "32 Steps (Clean)", val: 32.0 },
                                { name: "16 Steps (16-Bit)", val: 16.0 },
                                { name: "8 Steps (8-Bit)", val: 8.0 },
                                { name: "256 (True Color)", val: 256.0 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 130
                                implicitHeight: 36
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: (Config.pixelShaderLevels || 32.0) === modelData.val
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (clHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 2 : 0
                                border.color: Config.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: isSelected
                                }

                                TapHandler { 
                                    onTapped: {
                                        Config.pixelShaderLevels = modelData.val
                                        Config.updateShader()
                                    }
                                }
                                HoverHandler { id: clHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // PALETTE PRESET (PIXELATE ONLY)
                ColumnLayout {
                    spacing: 6
                    visible: (Config.pixelShaderMode || "pixelate") === "pixelate"

                    Text {
                        text: "COLOR PALETTE"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    RowLayout {
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "RGB True", id: "default" },
                                { name: "Game Boy DMG", id: "gameboy" },
                                { name: "Amber CRT", id: "amber" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 130
                                implicitHeight: 36
                                radius: Config.cornerRadius / 2

                                readonly property bool isSelected: (Config.pixelShaderPalette || "default") === modelData.id
                                color: isSelected ? Qt.rgba(255, 255, 255, 0.12) : (palHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(255, 255, 255, 0.03))
                                border.width: isSelected ? 2 : 0
                                border.color: Config.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    color: isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: isSelected
                                }

                                TapHandler { 
                                    onTapped: {
                                        Config.pixelShaderPalette = modelData.id
                                        Config.updateShader()
                                    }
                                }
                                HoverHandler { id: palHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }

                // TOGGLE OPTIONS (PIXELATE ONLY)
                ColumnLayout {
                    spacing: 8
                    visible: (Config.pixelShaderMode || "pixelate") === "pixelate"

                    Text {
                        text: "SHADER OPTIONS"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    // BAYER DITHER
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; text: "Ordered Bayer Dithering"; color: Config.textMain; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontBody); font.bold: true }
                            Text { Layout.fillWidth: true; text: "Cross-hatch color transitions instead of flat banding"; color: Config.textMuted; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption) }
                        }

                        ToggleSwitch {
                            checked: Config.pixelShaderDither !== false
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.pixelShaderDither = (Config.pixelShaderDither === false)
                                    Config.updateShader()
                                }
                            }
                        }
                    }

                    // PIXEL GRID
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; text: "Pixel Grid Lines"; color: Config.textMain; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontBody); font.bold: true }
                            Text { Layout.fillWidth: true; text: "Simulate physical phosphor gaps between virtual pixels"; color: Config.textMuted; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption) }
                        }

                        ToggleSwitch {
                            checked: Config.pixelShaderGrid === true
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.pixelShaderGrid = (Config.pixelShaderGrid !== true)
                                    Config.updateShader()
                                }
                            }
                        }
                    }

                    // ARCADE CONTRAST
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; text: "Arcade Contrast Boost"; color: Config.textMain; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontBody); font.bold: true }
                            Text { Layout.fillWidth: true; text: "Slightly lifts saturation and contrast on dark UI elements"; color: Config.textMuted; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption) }
                        }

                        ToggleSwitch {
                            checked: Config.pixelShaderBoost !== false
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.pixelShaderBoost = (Config.pixelShaderBoost === false)
                                    Config.updateShader()
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