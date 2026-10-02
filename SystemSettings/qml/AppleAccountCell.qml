import QtQuick
import QtQuick.Window

Item {
    id: cell

    property bool signedIn: false
    property string accountName: ""
    property bool selected: false
    readonly property bool highlighted: selected && cell.Window.window && cell.Window.window.active

    signal clicked

    width: parent ? parent.width : 200
    height: 44

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        radius: 8
        color: cell.selected ? (cell.highlighted ? Theme.accent : Theme.selectedBg) : "transparent"
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 16
        spacing: 8

        Avatar {
            size: 32
            avatarPath: { var m = Shell.userCfg; return String(Shell.uget("avatarPath", "")) }
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: cell.signedIn ? cell.accountName : "Sign in"
                font.family: Theme.fontText
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: cell.highlighted ? "white" : Theme.textPrimary
                width: 150
                elide: Text.ElideRight
            }

            Text {
                text: cell.signedIn ? "Apple Account" : "with your Apple Account"
                font.family: Theme.fontText
                font.pixelSize: 12
                color: cell.highlighted ? Qt.rgba(1, 1, 1, 0.85) : Theme.textSecondary
                width: 150
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cell.clicked()
    }
}
