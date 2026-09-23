pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root
    property var model: []
    property int currentIndex: -1
    signal activated(int index)

    implicitHeight: Math.round(32 * UIScale.value)

    RowLayout {
        anchors.fill: parent
        spacing: UIScale.spacingSm

        Repeater {
            model: root.model
            delegate: Rectangle {
                id: optBtn
                required property string modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: Math.round(32 * UIScale.value)
                radius: UIScale.radiusSm
                color: root.currentIndex === optBtn.index ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                border.color: root.currentIndex === optBtn.index ? Colors.accent : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: optBtn.modelData
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(optBtn.index)
                }
            }
        }
    }
}
