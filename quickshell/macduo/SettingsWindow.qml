import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: settingsWin

    screen: Quickshell.screens.find(s => s.name === "eDP-1") || Quickshell.screens[0]
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    visible: root.settingsOpen

    WlrLayershell.namespace: "macduo:settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Shortcut {
        sequence: "Escape"
        enabled: root.settingsOpen
        onActivated: root.settingsOpen = false
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.settingsOpen = false
    }

    Rectangle {
        id: panel
        width: 540
        height: Math.min(col.implicitHeight + 40, screen.height - 160)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        radius: 20
        color: Qt.rgba(0.07, 0.07, 0.09, 0.97)
        border.color: Qt.rgba(1, 1, 1, 0.13)
        border.width: 1

        Flickable {
            anchors.fill: parent
            anchors.margins: 4
            clip: true
            contentHeight: col.implicitHeight + 36
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: parent.width - 32
                x: 16
                y: 20
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    Label {
                        text: "Mac-Duo"
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        color: "#f5f5f7"
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "Lid Close Effect"
                        font.pixelSize: 13
                        color: "#7d7d85"
                    }
                }

                // master switch
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Label {
                        text: "Enable lid-close animation"
                        font.pixelSize: 14
                        color: "#e8e8ed"
                        Layout.fillWidth: true
                    }
                    Switch {
                        checked: root.pref("enabled", true)
                        onToggled: root.setPref("enabled", checked)
                    }
                }

                Repeater {
                    model: [
                        { k: "threshold",       l: "Threshold angle",    d: 90,   min: 60,  max: 100, step: 1,    dp: 0, sfx: "°" },
                        { k: "blurSpan",        l: "Blur span",          d: 60,   min: 20,  max: 120, step: 1,    dp: 0, sfx: "°" },
                        { k: "maxBlur",         l: "Max blur radius",    d: 135,  min: 40,  max: 250, step: 1,    dp: 0, sfx: " px" },
                        { k: "maxDim",          l: "Max dim",            d: 1.0,  min: 0,   max: 1,   step: 0.05, dp: 2, sfx: "" },
                        { k: "viewingDistance", l: "Viewing distance",   d: 6,    min: 2,   max: 12,  step: 0.5,  dp: 1, sfx: "" },
                        { k: "recession",       l: "Recession",          d: 1,    min: 0,   max: 3,  step: 0.1,  dp: 1, sfx: "" },
                        { k: "dimReach",        l: "Dim reach",          d: 0.5,  min: 0.1, max: 1,   step: 0.05, dp: 2, sfx: "" },
                        { k: "blurEvenness",    l: "Blur evenness",      d: 0,    min: 0,   max: 1,   step: 0.05, dp: 2, sfx: "" },
                        { k: "previewOpen",     l: "Preview open angle", d: 125,  min: 100, max: 135, step: 1,    dp: 0, sfx: "°" },
                        { k: "previewShut",     l: "Preview shut angle", d: 21,   min: 5,   max: 45,  step: 1,    dp: 0, sfx: "°" }
                    ]

                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: modelData.l
                                font.pixelSize: 13
                                color: "#b8b8bd"
                                Layout.preferredWidth: 160
                            }
                            Slider {
                                id: sl
                                Layout.fillWidth: true
                                from: modelData.min
                                to: modelData.max
                                stepSize: modelData.step
                                value: root.pref(modelData.k, modelData.d)
                                onMoved: root.setPref(modelData.k, value)
                            }
                            Label {
                                text: Number(root.pref(modelData.k, modelData.d)).toFixed(modelData.dp) + modelData.sfx
                                font.pixelSize: 13
                                font.family: "monospace"
                                color: "#f5f5f7"
                                Layout.preferredWidth: 74
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    Layout.topMargin: 10

                    Button {
                        text: "Preview"
                        onClicked: {
                            root.settingsOpen = false;
                            root.startRun("preview");
                        }
                        background: Rectangle {
                            radius: 9
                            color: parent.down ? "#2647ad" : (parent.hovered ? "#3a6ae8" : "#315bdc")
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 7
                        bottomPadding: 7
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Done"
                        onClicked: root.settingsOpen = false
                        background: Rectangle {
                            radius: 9
                            color: parent.down ? "#2a2a2e" : (parent.hovered ? "#232327" : "#1b1b1e")
                            border.color: Qt.rgba(1, 1, 1, 0.14)
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#f5f5f7"
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 7
                        bottomPadding: 7
                    }
                }
            }
        }
    }
}
