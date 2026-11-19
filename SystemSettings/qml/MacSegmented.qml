import QtQuick

// Tahoe segmented control: glass capsule, the selected segment is a raised
// lighter capsule that slides between segments.
Item {
    id: seg

    property var options: []
    property int currentIndex: 0
    signal activated(int index)

    readonly property real segW: Math.max(110, maxLabel + 28)
    property real maxLabel: 0

    implicitWidth: segW * options.length + 4
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.055)
        border.width: 1
        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
    }

    Rectangle {
        id: knob
        y: 2
        x: 2 + seg.currentIndex * seg.segW
        width: seg.segW
        height: parent.height - 4
        radius: height / 2
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.20) : "#FFFFFF"
        border.width: 1
        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.06)
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    Row {
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: seg.options
            delegate: Item {
                required property var modelData
                required property int index
                width: seg.segW
                height: seg.height - 4
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.fontText
                    font.pixelSize: 13
                    font.weight: index === seg.currentIndex ? Font.DemiBold : Font.Normal
                    color: Theme.textPrimary
                    Component.onCompleted: seg.maxLabel = Math.max(seg.maxLabel, implicitWidth)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { seg.currentIndex = index; seg.activated(index) }
                }
            }
        }
    }
}
