import QtQuick
import qs.services

Rectangle {
    id: root
    width: ScalerService.s(56)
    height: ScalerService.s(32)
    implicitWidth: ScalerService.s(56)
    implicitHeight: ScalerService.s(32)
    radius: ScalerService.s(16)
    color: adapter ? theme.button.text : theme.button.background

    scale: toggleMouseArea.containsPress ? 0.95 : (toggleMouseArea.containsMouse ? 1.05 : 1.0)
    property bool adapter: true
    signal clicked

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutBack
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    Rectangle {
        id: toggleIndicator
        x: root.adapter ? parent.width - width - ScalerService.s(4) : ScalerService.s(4)
        y: ScalerService.s(4)
        width: ScalerService.s(24)
        height: ScalerService.s(24)
        radius: ScalerService.s(24) / 2
        color: theme.primary.dim_background
        border.width: ScalerService.s(1)
        border.color: theme.normal.black

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: toggleMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.adapter) {
                SoundService.playSound("switch-on");
            } else {
                SoundService.playSound("switch-off");
            }
            root.clicked();
        }
    }
}
