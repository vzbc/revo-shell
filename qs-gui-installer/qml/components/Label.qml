// Label.qml — SF Pro text helper
import QtQuick

Text {
    property int size: 16
    property int weight: Font.Normal
    property color tone: "#FFFFFF"

    font.family: "SF Pro Display"
    font.pixelSize: size
    font.weight: weight
    color: tone
}
