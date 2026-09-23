import QtQuick
import qs.components
import qs.services

Rectangle {
    id: root
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: ScalerService.s(32)
    implicitHeight: ScalerService.s(32)
    radius: ScalerService.s(116)
    color: closeArea.containsMouse ? theme.normal.red : theme.button.background

    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 350
        }
    }

    signal clicked

    IconText {
        name: "close"
        size: "normal"
        anchors.centerIn: parent
    }
    MouseArea {
        id: closeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            SoundService.playSound("pick");
            root.clicked();
        }
    }
}
