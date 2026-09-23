import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    required property string hostname

    implicitHeight: Math.round(44 * UIScale.value)
    radius: UIScale.radiusMd
    color: Colors.surface

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingMd

        Text {
            text: I18n.t("network.credentialsSaved")
            color: Colors.textDim
            font.pixelSize: UIScale.fontCaption
            Layout.fillWidth: true
        }

        Rectangle {
            implicitWidth: forgetLabel.implicitWidth + UIScale.spacingMd * 2
            implicitHeight: Math.round(30 * UIScale.value)
            radius: Math.round(15 * UIScale.value)
            color: "transparent"
            border.color: Colors.withAlpha(Colors.accent, 0.4)
            border.width: 1

            Text {
                id: forgetLabel
                anchors.centerIn: parent
                text: I18n.t("network.forget")
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.forgetSmbnetfs(hostname)
            }
        }

        Rectangle {
            implicitWidth: reconnectLabel.implicitWidth + UIScale.spacingMd * 2
            implicitHeight: Math.round(30 * UIScale.value)
            radius: Math.round(15 * UIScale.value)
            color: reconnectMa.containsMouse ? Colors.accent : Colors.withAlpha(Colors.accent, 0.75)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                id: reconnectLabel
                anchors.centerIn: parent
                text: I18n.t("network.reconnect")
                color: Colors.bg
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: reconnectMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.reconnectSmbnetfs(hostname)
            }
        }
    }
}
