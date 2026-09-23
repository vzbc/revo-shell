pragma ComponentBehavior: Bound

// TypographyRing — rotating type ring (Motion Frames)
// Characters distributed on a circle; parent rotates with a linear loop.

import QtQuick

Item {
    id: ring

    property string ringText: "MOTION · FRAME · "
    property color accent: "#E23D28"
    property color ink: "#0E0E0C"
    property int periodMs: 16000
    property real ringRadiusScale: 0.42
    property int fontSize: 11
    property bool counterClockwise: false

    // outer guide circle
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.92
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Qt.rgba(ink.r, ink.g, ink.b, 0.2)
        border.width: 1
    }

    // rotating group
    Item {
        id: rotor
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width

        RotationAnimation on rotation {
            running: true
            loops: Animation.Infinite
            from: 0
            to: ring.counterClockwise ? -360 : 360
            duration: ring.periodMs
        }

        Repeater {
            model: ring.ringText.length
            delegate: Item {
                required property int index
                // place glyph at angle around center
                readonly property real angle: (index / ring.ringText.length) * 360
                readonly property real radius: rotor.width * ring.ringRadiusScale
                x: rotor.width / 2 + radius * Math.cos(angle * Math.PI / 180) - width / 2
                y: rotor.height / 2 + radius * Math.sin(angle * Math.PI / 180) - height / 2
                width: glyph.implicitWidth
                height: glyph.implicitHeight
                rotation: angle + 90

                Text {
                    id: glyph
                    text: ring.ringText.charAt(index)
                    color: (index % 7 === 0) ? ring.accent : ring.ink
                    font.pixelSize: ring.fontSize
                    font.bold: index % 7 === 0
                    font.family: "SF Pro"
                    textFormat: Text.PlainText
                }
            }
        }
    }

    // center tick dot — pulses each second (ticking component)
    Rectangle {
        anchors.centerIn: parent
        width: 10; height: 10; radius: 5
        color: ring.accent
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.25; duration: 500; easing.type: Easing.OutQuad }
            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InQuad }
        }
    }

    // second-hand sweep (12s mechanical feel, continuous loop)
    Rectangle {
        id: hand
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: 2
        height: Math.min(parent.width, parent.height) * 0.32
        color: ring.ink
        transformOrigin: Item.Bottom
        RotationAnimation on rotation {
            running: true
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 12000
        }
    }
}
