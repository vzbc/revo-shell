import QtQuick

Item {
    id: toggle

    property bool checked: false
    signal toggled(bool checked)

    width: 38
    height: 22

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: toggle.checked ? Theme.accent : Theme.toggleOff
        border.width: 1
        border.color: toggle.checked ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(0, 0, 0, 0.07)

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    Rectangle {
        id: knob
        width: 18
        height: 18
        radius: 9
        color: "white"
        border.width: 0.5
        border.color: Qt.rgba(0, 0, 0, 0.08)
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - 2 : 2

        Behavior on x {
            NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled(!toggle.checked)
    }
}
