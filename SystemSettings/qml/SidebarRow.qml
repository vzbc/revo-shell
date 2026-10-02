import QtQuick
import QtQuick.Window

Item {
    id: row

    property string rowId
    property string title
    property string iconFile
    property bool selected: false
    property bool show: true
    readonly property bool highlighted: selected && row.Window.window && row.Window.window.active

    signal clicked(string rowId)

    width: parent ? parent.width : 100
    height: show ? Theme.rowHeight : 0
    visible: show

    Rectangle {
        id: highlight
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        radius: 8
        color: row.selected ? (row.highlighted ? Theme.accent : Theme.selectedBg) : "transparent"

        Behavior on color {
            ColorAnimation { duration: 60 }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 16
        spacing: 7

        Image {
            source: Theme.icon(row.iconFile, Theme.sidebarIconSize)
            width: Theme.sidebarIconSize
            height: Theme.sidebarIconSize
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            mipmap: true
        }

        Text {
            text: row.title
            font.family: Theme.fontText
            font.pixelSize: 13
            color: row.highlighted ? "white" : Theme.textPrimary
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked(row.rowId)
    }
}
