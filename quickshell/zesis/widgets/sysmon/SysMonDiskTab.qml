pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../shared"
import "../../"

ColumnLayout {
    id: root
    property bool compact: false

    spacing: root.compact ? Math.round(6 * UIScale.value) : Math.round(8 * UIScale.value)

    Item {
        implicitHeight: UIScale.spacingMd
        visible: !root.compact
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: root.compact ? 0 : UIScale.panelPad
        Layout.rightMargin: root.compact ? 0 : UIScale.panelPad
        spacing: UIScale.spacingSm

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? Math.round(52 * UIScale.value) : Math.round(64 * UIScale.value)
            radius: root.compact ? UIScale.radiusSm : UIScale.radiusMd
            color: Colors.surface

            Column {
                anchors.centerIn: parent
                spacing: Math.round(2 * UIScale.value)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SysMonService.fmtRate(SysMonService.disk.reduce((a, d) => a + d.read_bytes_per_sec, 0))
                    color: Colors.text
                    font.pixelSize: root.compact ? UIScale.fontLead : UIScale.fontHero
                    font.weight: root.compact ? 600 : Font.Bold
                    font.family: "monospace"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.t("sysmon.readAbbrev")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? Math.round(52 * UIScale.value) : Math.round(64 * UIScale.value)
            radius: root.compact ? UIScale.radiusSm : UIScale.radiusMd
            color: Colors.surface

            Column {
                anchors.centerIn: parent
                spacing: Math.round(2 * UIScale.value)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SysMonService.fmtRate(SysMonService.disk.reduce((a, d) => a + d.write_bytes_per_sec, 0))
                    color: Colors.text
                    font.pixelSize: root.compact ? UIScale.fontLead : UIScale.fontHero
                    font.weight: root.compact ? 600 : Font.Bold
                    font.family: "monospace"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.t("sysmon.writeAbbrev")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                }
            }
        }
    }

    SectionLabel {
        text: I18n.t("sysmon.devices")
        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
        visible: !root.compact && SysMonService.diskFlat.length > 0
    }

    Repeater {
        model: root.compact ? SysMonService.diskFlat : []
        delegate: Item {
            id: diskRow
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Math.round(20 * UIScale.value)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: diskRow.modelData.depth * Math.round(14 * UIScale.value)
                anchors.verticalCenter: parent.verticalCenter
                text: (diskRow.modelData.depth > 0 ? "↳ " : "") + diskRow.modelData.name
                color: diskRow.modelData.depth > 0 ? Colors.textDim : Colors.text
                font.pixelSize: UIScale.fontCaption
                font.weight: diskRow.modelData.depth > 0 ? Font.Normal : Font.Medium
            }

            Text {
                id: writeVal
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("sysmon.writeRatePrefix") + SysMonService.fmtRate(diskRow.modelData.write)
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.family: "monospace"
            }

            Text {
                anchors.right: writeVal.left
                anchors.rightMargin: Math.round(12 * UIScale.value)
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("sysmon.readRatePrefix") + SysMonService.fmtRate(diskRow.modelData.read)
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.family: "monospace"
            }
        }
    }

    Repeater {
        model: root.compact ? [] : SysMonService.diskFlat
        delegate: Rectangle {
            id: diskCard
            required property var modelData
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad + diskCard.modelData.depth * Math.round(16 * UIScale.value)
            Layout.rightMargin: UIScale.panelPad
            implicitHeight: Math.round(44 * UIScale.value)
            radius: UIScale.radiusMd
            color: diskCard.modelData.depth > 0 ? Colors.withAlpha(Colors.surface, 0.6) : Colors.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.spacingMd
                anchors.rightMargin: UIScale.spacingMd

                Text {
                    text: (diskCard.modelData.depth > 0 ? "↳ " : "") + diskCard.modelData.name
                    color: diskCard.modelData.depth > 0 ? Colors.textDim : Colors.text
                    font.pixelSize: UIScale.fontSmall
                    font.weight: diskCard.modelData.depth > 0 ? Font.Normal : Font.DemiBold
                    Layout.fillWidth: true
                }
                Text {
                    text: I18n.t("sysmon.readRatePrefix") + SysMonService.fmtRate(diskCard.modelData.read)
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    font.family: "monospace"
                }
                Text {
                    text: I18n.t("sysmon.writeRatePrefix") + SysMonService.fmtRate(diskCard.modelData.write)
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    font.family: "monospace"
                    Layout.leftMargin: UIScale.spacingMd
                }
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: SysMonService.diskFlat.length === 0
        text: I18n.t("sysmon.noDisks")
        color: Colors.textDim
        font.pixelSize: UIScale.fontSmall
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
