import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    required property int index
    property real rowHeight: Math.round(20 * UIScale.value)

    Layout.fillWidth: true
    implicitHeight: rowHeight

    Rectangle {
        width: Math.round(8 * UIScale.value)
        height: Math.round(8 * UIScale.value)
        radius: Math.round(2 * UIScale.value)
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(1, 1, 1, 0.08)
    }
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: Math.round(16 * UIScale.value)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * (0.35 + (index % 4) * 0.07)
        height: Math.round(8 * UIScale.value)
        radius: Math.round(3 * UIScale.value)
        color: Qt.rgba(1, 1, 1, 0.07)
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(36 * UIScale.value)
        height: Math.round(8 * UIScale.value)
        radius: Math.round(3 * UIScale.value)
        color: Qt.rgba(1, 1, 1, 0.07)
    }
}
