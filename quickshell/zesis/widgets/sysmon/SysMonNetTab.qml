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
                    text: SysMonService.fmtRate(SysMonService.net.reduce((a, i) => a + i.rx_bytes_per_sec, 0))
                    color: Colors.text
                    font.pixelSize: root.compact ? UIScale.fontLead : UIScale.fontHero
                    font.weight: root.compact ? 600 : Font.Bold
                    font.family: "monospace"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.compact ? "↓ RX" : "↓ Download"
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
                    text: SysMonService.fmtRate(SysMonService.net.reduce((a, i) => a + i.tx_bytes_per_sec, 0))
                    color: Colors.text
                    font.pixelSize: root.compact ? UIScale.fontLead : UIScale.fontHero
                    font.weight: root.compact ? 600 : Font.Bold
                    font.family: "monospace"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.compact ? "↑ TX" : "↑ Upload"
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                }
            }
        }
    }

    SectionLabel {
        text: I18n.t("sysmon.interfaces")
        Layout.leftMargin: UIScale.panelPad + UIScale.spacingXs
        visible: !root.compact && SysMonService.net.length > 0
    }

    Repeater {
        model: root.compact ? SysMonService.net : []
        delegate: Item {
            id: netRow
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Math.round(20 * UIScale.value)

            Text {
                id: ifaceName
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: netRow.modelData.name
                color: Colors.text
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Medium
            }

            Text {
                id: txVal
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "↑ " + SysMonService.fmtRate(netRow.modelData.tx_bytes_per_sec)
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.family: "monospace"
            }

            Text {
                anchors.right: txVal.left
                anchors.rightMargin: Math.round(12 * UIScale.value)
                anchors.verticalCenter: parent.verticalCenter
                text: "↓ " + SysMonService.fmtRate(netRow.modelData.rx_bytes_per_sec)
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.family: "monospace"
            }
        }
    }

    Repeater {
        model: root.compact ? [] : SysMonService.net
        delegate: Rectangle {
            id: netCard
            required property var modelData
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad
            implicitHeight: Math.round(44 * UIScale.value)
            radius: UIScale.radiusMd
            color: Colors.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.spacingMd
                anchors.rightMargin: UIScale.spacingMd

                Text {
                    text: netCard.modelData.name
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }
                Text {
                    text: "↓ " + SysMonService.fmtRate(netCard.modelData.rx_bytes_per_sec)
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    font.family: "monospace"
                }
                Text {
                    text: "↑ " + SysMonService.fmtRate(netCard.modelData.tx_bytes_per_sec)
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
        visible: SysMonService.net.length === 0
        text: I18n.t("sysmon.noInterfaces")
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
