pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../"
import "../bar"
import "../shared"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("bar.breadcrumb")
            title: I18n.t("bar.title")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: content.implicitHeight + UIScale.spacingLg * 2
            clip: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: content
                x: UIScale.panelPad
                y: UIScale.spacingLg
                width: parent.width - UIScale.panelPad * 2
                spacing: UIScale.spacingMd

                // Bar side
                Text {
                    text: I18n.t("bar.side")
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm
                    Repeater {
                        model: [
                            {
                                value: "top",
                                label: I18n.t("bar.top")
                            },
                            {
                                value: "bottom",
                                label: I18n.t("bar.bottom")
                            },
                            {
                                value: "left",
                                label: I18n.t("bar.left")
                            },
                            {
                                value: "right",
                                label: I18n.t("bar.right")
                            }
                        ]
                        delegate: Rectangle {
                            id: sideBtn
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: Math.round(32 * UIScale.value)
                            radius: UIScale.radiusSm
                            color: BarConfig.side === sideBtn.modelData.value ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                            border.color: BarConfig.side === sideBtn.modelData.value ? Colors.accent : "transparent"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: sideBtn.modelData.label
                                color: Colors.text
                                font.pixelSize: UIScale.fontCaption
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BarConfig.write(sideBtn.modelData.value)
                            }
                        }
                    }
                }

                Divider {
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }

                // Edge gap
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: I18n.t("bar.edgeGap")
                        color: Colors.text
                        font.bold: true
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    Text {
                        text: BarConfig.edgeGap + "px"
                        color: Colors.accent
                        font.bold: true
                        font.pixelSize: UIScale.fontBody
                    }
                }
                SettingSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 40
                    step: 1
                    value: BarConfig.edgeGap
                    onMoved: function (v) {
                        BarConfig.writeEdgeGap(Math.round(v));
                    }
                }

                Divider {
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }

                // End gap
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: I18n.t("bar.endGap")
                        color: Colors.text
                        font.bold: true
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    Text {
                        text: BarConfig.endGap + "px"
                        color: Colors.accent
                        font.bold: true
                        font.pixelSize: UIScale.fontBody
                    }
                }
                SettingSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 60
                    step: 1
                    value: BarConfig.endGap
                    onMoved: function (v) {
                        BarConfig.writeEndGap(Math.round(v));
                    }
                }

                Divider {
                    visible: Quickshell.screens.length > 1
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }

                // Bar monitor
                Text {
                    visible: Quickshell.screens.length > 1
                    text: I18n.t("bar.monitor")
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }
                Text {
                    visible: Quickshell.screens.length > 1
                    Layout.fillWidth: true
                    text: I18n.t("bar.monitorDescription")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: Quickshell.screens
                    delegate: RowLayout {
                        id: monitorRow
                        required property var modelData
                        readonly property string _name: monitorRow.modelData.name
                        visible: Quickshell.screens.length > 1
                        Layout.fillWidth: true

                        Text {
                            text: monitorRow._name + " (" + monitorRow.modelData.width + "×" + monitorRow.modelData.height + ")"
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: BarConfig.monitors.length === 0 || BarConfig.monitors.includes(monitorRow._name)
                            onToggled: {
                                var current = BarConfig.monitors.length === 0 ? Quickshell.screens.map(s => s.name) : BarConfig.monitors.slice();
                                var idx = current.indexOf(monitorRow._name);
                                if (idx >= 0) {
                                    // Refuse to uncheck the last monitor.
                                    if (current.length <= 1)
                                        return;
                                    current.splice(idx, 1);
                                } else {
                                    current.push(monitorRow._name);
                                }
                                if (current.length === Quickshell.screens.length)
                                    current = [];
                                BarConfig.writeMonitors(current);
                            }
                        }
                    }
                }

                Divider {
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }

                // Bar items
                Text {
                    text: I18n.t("bar.items")
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                }

                Repeater {
                    model: BarItemsService.orderedItems
                    delegate: RowLayout {
                        id: itemRow
                        required property var modelData
                        Layout.fillWidth: true

                        Text {
                            text: itemRow.modelData.label
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: BarItemsService.isEnabled(itemRow.modelData.id)
                            onToggled: BarItemsService.toggle(itemRow.modelData.id)
                        }
                    }
                }

                Divider {
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }

                // Pinned to center, probably temporary...
                Column {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * UIScale.value)

                    Text {
                        text: I18n.t("bar.pinnedToCenter")
                        color: Colors.text
                        font.bold: true
                        font.pixelSize: UIScale.fontBody
                    }
                    Text {
                        width: parent.width
                        text: I18n.t("bar.pinnedToCenterHint")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        wrapMode: Text.WordWrap
                    }
                }

                Repeater {
                    model: BarItemsService.orderedItems
                    delegate: RowLayout {
                        id: pinRow
                        required property var modelData
                        Layout.fillWidth: true

                        Text {
                            text: pinRow.modelData.label
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: BarItemsService.isPinned(pinRow.modelData.id)
                            onToggled: BarItemsService.togglePin(pinRow.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
