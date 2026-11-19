import QtQuick
import QtQuick.Window

Item {
    id: row

    property string rowId
    property string title
    property string iconFile
    property bool selected: false
    property bool show: true
    readonly property bool windowActive: row.Window.window ? row.Window.window.active : true
    readonly property bool highlighted: selected && windowActive

    signal clicked(string rowId)

    width: parent ? parent.width : 100
    height: show ? Theme.rowHeight : 0
    visible: show

    Rectangle {
        id: highlight
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        radius: Theme.rowRadius
        color: row.selected ? (row.highlighted ? Theme.accent : Theme.selectedBg)
                            : (mouse.containsMouse ? Theme.hoverBg : "transparent")

        Behavior on color {
            ColorAnimation { duration: 90 }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 14
        spacing: 8

        Image {
            source: Theme.icon(row.iconFile, Theme.sidebarIconSize)
            width: Theme.sidebarIconSize
            height: Theme.sidebarIconSize
            sourceSize.width: Theme.sidebarIconSize * 2
            sourceSize.height: Theme.sidebarIconSize * 2
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            mipmap: true
            smooth: true
        }

        Text {
            text: row.title
            font.family: Theme.fontText
            font.pixelSize: 13
            font.weight: row.highlighted ? Font.Medium : Font.Normal
            color: row.highlighted ? "white" : Theme.textPrimary
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: row.width - 14 - Theme.sidebarIconSize - 8 - 16
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.clicked(row.rowId)
    }
}
