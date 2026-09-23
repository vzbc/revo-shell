import QtQuick
import QtQuick.Layouts

Item {
    Layout.preferredWidth: 2
    Layout.preferredHeight: root.iconSize * 0.6
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.centerIn: parent
        width: 2
        height: parent.height
        radius: 1
        color: Qt.rgba(1, 1, 1, 0.3)
    }
}
