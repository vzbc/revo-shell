// CircularImage.qml — true circular crop via MultiEffect mask
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source: ""
    property string initials: ""
    property string fontFamily: "SF Pro Display"
    property color fallbackColor: "#2C2C2E"
    property color textColor: "#FFFFFF"
    property int fontPixelSize: Math.max(10, Math.round(width * 0.34))
    property bool asynchronous: true

    readonly property bool hasSource: source.toString().length > 0
    readonly property bool imageReady: img.status === Image.Ready

    implicitWidth: 36
    implicitHeight: 36

    // Background / fallback circle
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: width / 2
        color: root.imageReady ? "transparent" : root.fallbackColor
    }

    Text {
        id: initialsLabel
        anchors.centerIn: parent
        visible: !root.imageReady && root.initials.length > 0
        text: root.initials
        font.family: root.fontFamily
        font.pixelSize: root.fontPixelSize
        font.weight: Font.DemiBold
        color: root.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: root.asynchronous
        visible: false
        sourceSize: Qt.size(Math.max(1, width), Math.max(1, height))
    }

    // Alpha mask — only present when image is ready so fallback is clean
    Rectangle {
        id: mask
        z: 0
        width: root.width
        height: root.height
        radius: width / 2
        color: "#FFFFFF"
        visible: root.imageReady
        layer.enabled: true
        layer.smooth: true
    }

    MultiEffect {
        id: circleMask
        z: 1
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        visible: root.imageReady
    }
}
