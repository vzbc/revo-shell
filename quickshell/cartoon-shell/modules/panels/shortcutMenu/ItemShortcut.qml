import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

CustomRectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(32)
    property string icon: ""
    property string name: ""
    color: mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : "transparent"
    radius: ScalerService.s(Settings.appearance.radius3)
    RowLayout {
        spacing: ScalerService.s(12)

        Item {
            Layout.preferredWidth: ScalerService.s(8)
        }
        Item {
            Layout.preferredHeight: ScalerService.s(28)
            Layout.preferredWidth: ScalerService.s(28)
            Image {
                source: root.icon
                anchors.fill: parent
                anchors.margins: ScalerService.s(2)

                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }
        CustomText {
            name: root.name
            size: "small"
            isBold: true
        }

        Item {
            Layout.fillWidth: true
        }
        Item {
            Layout.preferredWidth: ScalerService.s(8)
        }
    }
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            SoundService.playSound("pick");
        }
        onEntered: {
            SoundService.playSound("hover");
        }
    }
}
