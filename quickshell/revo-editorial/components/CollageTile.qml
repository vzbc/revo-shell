pragma ComponentBehavior: Bound

// CollageTile — overlapping editorial tile with hover lift + print noise edge
import QtQuick

Rectangle {
    id: tile

    property string headline: ""
    property string kicker: ""
    property color paper: "#F4F1EA"
    property color ink: "#0E0E0C"
    property color accent: "#E23D28"
    property real baseRotation: 0
    property bool featured: false

    // hard editorial shadow (static offset = single-frame motion look)
    readonly property int shadowOffset: featured ? 8 : 5

    color: paper
    border.color: ink
    border.width: 2
    rotation: baseRotation
    scale: hoverMa.containsMouse ? 1.03 : 1.0
    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

    // offset shadow plate
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: tile.shadowOffset
        anchors.topMargin: tile.shadowOffset
        z: -1
        color: tile.accent
        opacity: tile.featured ? 1 : 0.35
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6

        Text {
            text: tile.kicker
            color: tile.accent
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 3
            textFormat: Text.PlainText
        }
        Text {
            width: parent.width
            text: tile.headline
            color: tile.ink
            font.pixelSize: tile.featured ? 28 : 18
            font.bold: true
            font.letterSpacing: tile.featured ? -0.5 : 0
            wrapMode: Text.Wrap
            maximumLineCount: 3
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        id: hoverMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
