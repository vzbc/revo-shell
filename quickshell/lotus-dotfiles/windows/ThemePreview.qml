import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: win

    required property QtObject theme

    visible: true
    implicitWidth: 820
    implicitHeight: 560
    color: theme.canvas

    Rectangle {
        anchors.fill: parent
        color: win.theme.canvas

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: win.theme.space8
            spacing: win.theme.space5

            ColumnLayout {
                spacing: win.theme.space1

                Text {
                    text: "LOTUS PAPER"
                    color: win.theme.ink
                    font.family: win.theme.fontFamily
                    font.pixelSize: win.theme.textXl
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }

                Text {
                    text: "Theme foundation · version " + win.theme.version
                    color: win.theme.inkMuted
                    font.family: win.theme.fontFamily
                    font.pixelSize: win.theme.textSm
                }

            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: win.theme.space5

                Ui.RaisedSurface {
                    theme: win.theme
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1.25
                    fill: win.theme.surfaceRaised
                    surfaceRadius: win.theme.radiusPanel
                    padding: win.theme.space5

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: win.theme.space4

                        Text {
                            text: "Component proof"
                            color: win.theme.ink
                            font.family: win.theme.fontFamily
                            font.pixelSize: win.theme.textLg
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Hard outlines, offset shadows, warm paper surfaces and restrained pastel controls."
                            wrapMode: Text.WordWrap
                            color: win.theme.inkMuted
                            font.family: win.theme.fontFamily
                            font.pixelSize: win.theme.textMd
                            lineHeight: 1.35
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: win.theme.space3

                            Ui.PixelButton {
                                theme: win.theme
                                label: "Primary"
                                fill: win.theme.peach
                            }

                            Ui.PixelButton {
                                theme: win.theme
                                label: "Confirm"
                                fill: win.theme.green
                            }

                            Ui.PixelButton {
                                theme: win.theme
                                label: "Quiet"
                                fill: win.theme.lilac
                            }

                        }

                    }

                }

                Ui.RaisedSurface {
                    theme: win.theme
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 0.75
                    fill: win.theme.surface
                    surfaceRadius: win.theme.radiusPanel
                    padding: win.theme.space5

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: win.theme.space3

                        Text {
                            text: "Palette"
                            color: win.theme.ink
                            font.family: win.theme.fontFamily
                            font.pixelSize: win.theme.textLg
                            font.weight: Font.Bold
                        }

                        Repeater {
                            model: [{
                                "name": "Peach",
                                "value": win.theme.peach
                            }, {
                                "name": "Pink",
                                "value": win.theme.pink
                            }, {
                                "name": "Green",
                                "value": win.theme.green
                            }, {
                                "name": "Lilac",
                                "value": win.theme.lilac
                            }, {
                                "name": "Blue",
                                "value": win.theme.blue
                            }, {
                                "name": "Gold",
                                "value": win.theme.gold
                            }]

                            RowLayout {
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: win.theme.space3

                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 8
                                    color: modelData.value
                                    border.width: win.theme.borderWidth
                                    border.color: win.theme.ink
                                }

                                Text {
                                    text: modelData.name
                                    color: win.theme.ink
                                    font.family: win.theme.fontFamily
                                    font.pixelSize: win.theme.textSm
                                }

                            }

                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Text {
                            text: "07 : 47"
                            color: win.theme.ink
                            font.family: win.theme.fontFamily
                            font.pixelSize: win.theme.textDisplay
                            font.weight: Font.Medium
                        }

                    }

                }

            }

        }

    }

}
