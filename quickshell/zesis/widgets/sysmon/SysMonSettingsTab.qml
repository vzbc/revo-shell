pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../shared"
import "../../"

ColumnLayout {
    id: root
    property bool compact: false

    spacing: root.compact ? Math.round(10 * UIScale.value) : UIScale.spacingMd

    Item {
        implicitHeight: UIScale.spacingMd
        visible: !root.compact
    }

    SectionLabel {
        text: I18n.t("sysmon.pullRate")
        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
        visible: !root.compact
    }
    Text {
        text: I18n.t("sysmon.pullRateLabel")
        color: Colors.text
        font.pixelSize: UIScale.fontSmall
        font.weight: Font.Bold
        visible: root.compact
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: root.compact ? 0 : UIScale.panelPad
        Layout.rightMargin: root.compact ? 0 : UIScale.panelPad
        spacing: root.compact ? Math.round(6 * UIScale.value) : UIScale.spacingSm

        Repeater {
            model: [
                {
                    label: "0.5s",
                    ms: 500
                },
                {
                    label: "1s",
                    ms: 1000
                },
                {
                    label: "2s",
                    ms: 2000
                },
                {
                    label: "5s",
                    ms: 5000
                }
            ]
            delegate: Rectangle {
                id: rateBtn
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: root.compact ? Math.round(32 * UIScale.value) : Math.round(40 * UIScale.value)
                radius: root.compact ? UIScale.radiusSm : UIScale.radiusMd
                property bool selected: SysMonService.pullRateMs === rateBtn.modelData.ms
                color: rateBtn.selected ? Colors.withAlpha(Colors.accent, 0.15) : (root.compact ? Colors.surfaceHigh : Colors.surface)
                border.color: rateBtn.selected ? (root.compact ? Colors.accent : Colors.withAlpha(Colors.accent, 0.4)) : "transparent"
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: rateBtn.modelData.label
                    color: rateBtn.selected ? Colors.accent : (root.compact ? Colors.text : Colors.textDim)
                    font.pixelSize: root.compact ? UIScale.fontCaption : UIScale.fontSmall
                    font.weight: rateBtn.selected ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysMonService.pullRateMs = rateBtn.modelData.ms
                }
            }
        }
    }

    SectionLabel {
        text: I18n.t("sysmon.processLimit")
        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
        visible: !root.compact
    }
    Text {
        text: I18n.t("sysmon.processLimitLabel")
        color: Colors.text
        font.pixelSize: UIScale.fontSmall
        font.weight: Font.Bold
        visible: root.compact
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: root.compact ? 0 : UIScale.panelPad
        Layout.rightMargin: root.compact ? 0 : UIScale.panelPad
        spacing: root.compact ? Math.round(6 * UIScale.value) : UIScale.spacingSm

        Repeater {
            model: [
                {
                    label: "5",
                    n: 5
                },
                {
                    label: "10",
                    n: 10
                },
                {
                    label: "20",
                    n: 20
                },
                {
                    label: "50",
                    n: 50
                },
                {
                    label: "∞",
                    n: 0
                }
            ]
            delegate: Rectangle {
                id: limitBtn
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: root.compact ? Math.round(32 * UIScale.value) : Math.round(40 * UIScale.value)
                radius: root.compact ? UIScale.radiusSm : UIScale.radiusMd
                property bool selected: SysMonService.procLimit === limitBtn.modelData.n
                color: limitBtn.selected ? Colors.withAlpha(Colors.accent, 0.15) : (root.compact ? Colors.surfaceHigh : Colors.surface)
                border.color: limitBtn.selected ? (root.compact ? Colors.accent : Colors.withAlpha(Colors.accent, 0.4)) : "transparent"
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: limitBtn.modelData.label
                    color: limitBtn.selected ? Colors.accent : (root.compact ? Colors.text : Colors.textDim)
                    font.pixelSize: root.compact ? UIScale.fontCaption : UIScale.fontSmall
                    font.weight: limitBtn.selected ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysMonService.procLimit = limitBtn.modelData.n
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: root.compact ? 0 : UIScale.panelPad
        Layout.rightMargin: root.compact ? 0 : UIScale.panelPad

        Text {
            text: I18n.t("sysmon.hideIdleProcesses")
            color: Colors.text
            font.pixelSize: UIScale.fontSmall
            Layout.fillWidth: true
        }

        ToggleSwitch {
            checked: SysMonService.filterZero
            onToggled: SysMonService.filterZero = !SysMonService.filterZero
        }
    }

    Item {
        implicitHeight: UIScale.spacingMd
        visible: !root.compact
    }
    Item {
        Layout.fillHeight: true
        visible: root.compact
    }
}
