pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    property int selWidth: DisplayService.currentWidth
    property int selHeight: DisplayService.currentHeight
    property real selRefresh: DisplayService.currentRefresh

    readonly property bool hasChange: selWidth !== DisplayService.currentWidth || selHeight !== DisplayService.currentHeight || Math.abs(selRefresh - DisplayService.currentRefresh) > 0.01

    readonly property string selModeStr: selWidth + "x" + selHeight + "@" + selRefresh.toFixed(2) + "Hz"

    onVisibleChanged: if (visible)
        resetSelection()
    function resetSelection() {
        selWidth = DisplayService.currentWidth;
        selHeight = DisplayService.currentHeight;
        selRefresh = DisplayService.currentRefresh;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("display.breadcrumb")
            title: I18n.t("display.title")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: bodyCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.04)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(16 * UIScale.value)
                        anchors.rightMargin: Math.round(16 * UIScale.value)
                        spacing: UIScale.spacingMd

                        Text {
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: Math.round(22 * UIScale.value)
                            color: Colors.accent
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: DisplayService.monitorModel || DisplayService.monitorName || I18n.t("display.monitorFallback")
                                color: Colors.text
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: {
                                    var parts = [];
                                    if (DisplayService.monitorName)
                                        parts.push(DisplayService.monitorName);
                                    if (DisplayService.diagonalInches > 0)
                                        parts.push(DisplayService.diagonalInches + '"');
                                    if (DisplayService.currentWidth > 0)
                                        parts.push(I18n.t("display.resolutionSummary", [DisplayService.currentWidth, DisplayService.currentHeight, Math.round(DisplayService.currentRefresh)]));
                                    return parts.join("  ·  ");
                                }
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.family: "monospace"
                            }
                        }
                    }
                }

                Text {
                    text: I18n.t("display.resolutionLabel")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    model: DisplayService.uniqueResolutions.map(r => ({
                                value: r.width + "x" + r.height,
                                label: r.width + "x" + r.height
                            }))
                    selectedValue: root.selWidth + "x" + root.selHeight

                    onChosen: value => {
                        var parts = value.split("x");
                        root.selWidth = parseInt(parts[0]);
                        root.selHeight = parseInt(parts[1]);
                        var rates = DisplayService.refreshRatesFor(root.selWidth, root.selHeight);
                        root.selRefresh = rates.length > 0 ? rates[0] : 0;
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Text {
                    text: I18n.t("display.refreshRateLabel")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                StyledComboBox {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    model: DisplayService.refreshRatesFor(root.selWidth, root.selHeight).map(r => {
                        var rounded = Math.round(r);
                        return {
                            value: r.toFixed(4),
                            label: I18n.t("display.hzValue", [Math.abs(r - rounded) < 0.01 ? rounded : r.toFixed(2)])
                        };
                    })
                    selectedValue: root.selRefresh.toFixed(4)

                    onChosen: value => root.selRefresh = parseFloat(value)
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(38 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: root.hasChange ? Colors.accent : Colors.surfaceHigh
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.hasChange ? I18n.t("display.apply") : I18n.t("display.active")
                        color: root.hasChange ? Colors.bg : Colors.muted
                        font.pixelSize: UIScale.fontBody
                        font.weight: Font.DemiBold
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.hasChange ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.hasChange)
                                DisplayService.apply(root.selModeStr);
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
