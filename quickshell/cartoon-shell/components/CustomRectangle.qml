import QtQuick

Rectangle {
    id: root
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 100
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 200
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: 100
        }
    }
}
