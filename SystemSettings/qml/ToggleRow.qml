import QtQuick

Item {
    id: row

    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool showInfo: false
    property bool separator: true
    signal toggled
    signal infoClicked

    width: parent ? parent.width : 400
    height: subtitle.length > 0 ? 62 : Theme.detailRowHeight

    Rectangle {
        visible: row.separator
        anchors.top: parent.top
        x: 16
        width: parent.width - 28
        height: 1
        color: Theme.separator
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        width: parent.width - 16 - 60 - (row.showInfo ? 24 : 0)

        Text {
            text: row.title
            font.family: Theme.fontText
            font.pixelSize: 13
            color: Theme.textPrimary
        }

        Text {
            visible: row.subtitle.length > 0
            text: row.subtitle
            font.family: Theme.fontText
            font.pixelSize: 12
            color: Theme.textSecondary
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    MacToggle {
        id: tgl
        anchors.right: parent.right
        anchors.rightMargin: row.showInfo ? 32 : 16
        anchors.verticalCenter: parent.verticalCenter
        checked: row.checked
        onToggled: (checked) => {
            row.checked = checked
            row.toggled()
        }
    }

    InfoDot {
        visible: row.showInfo
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        onClicked: row.infoClicked()
    }
}
