import QtQuick

FocusScope {
    id: root
    implicitWidth: 80
    implicitHeight: 80

    property string iconText: ""
    signal clicked

    // colors from parent Powermenu panel
    property color bgDefault: "#261d20"
    property color bgFocus:   "#5a3f48"
    property color fgDefault: "#efdfe2"
    property color fgFocus:   "#ffd9e3"

    Rectangle {
        anchors.fill: parent
        radius: root.activeFocus ? 28 : 20
        color: root.activeFocus ? root.bgFocus : root.bgDefault

        Behavior on radius { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: root.iconText
            color: root.activeFocus ? root.fgFocus : root.fgDefault
            font.family: "Iosevka Nerd Font"
            font.pixelSize: 32

            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            root.focus = true
            root.clicked()
        }
    }

    Keys.onEnterPressed: clicked()
    Keys.onReturnPressed: clicked()
    Keys.onEscapePressed: {
        var p = root.parent
        while (p && !p.hasOwnProperty("hide")) p = p.parent
        if (p && p.hide) p.hide()
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Down) {
            var next = KeyNavigation.down
            if (next) { next.focus = true; event.accepted = true }
        } else if (event.key === Qt.Key_Up) {
            var prev = KeyNavigation.up
            if (prev) { prev.focus = true; event.accepted = true }
        } else if (event.key === Qt.Key_Tab) {
            var n = KeyNavigation.down || KeyNavigation.tab
            if (n) { n.focus = true; event.accepted = true }
        } else if (event.key === Qt.Key_Backtab) {
            var p = KeyNavigation.up || KeyNavigation.backtab
            if (p) { p.focus = true; event.accepted = true }
        }
    }
}
