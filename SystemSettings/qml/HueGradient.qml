import QtQuick

Rectangle {
    id: hg

    property real shift: 0

    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.hsla(hg.shift % 1, 0.55, 0.55, 1) }
        GradientStop { position: 0.5; color: Qt.hsla((hg.shift + 0.33) % 1, 0.5, 0.45, 1) }
        GradientStop { position: 1.0; color: Qt.hsla((hg.shift + 0.66) % 1, 0.45, 0.30, 1) }
    }

    Timer {
        interval: 40
        running: hg.visible
        repeat: true
        onTriggered: hg.shift = (hg.shift + 0.006) % 1
    }
}
