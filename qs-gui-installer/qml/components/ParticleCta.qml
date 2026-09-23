// ParticleCta.qml — stage-1 hero panel: particles behind headline + Get Started
// Style: magicui Floating3DParticles + content overlay + arrow button
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string heading: "Build something magical"
    property string subheading: "A pseudo-3D particle background that stays behind your content with continuous rotation and buoyant drift."
    property string buttonLabel: "Get Started"
    property color particleColor: "#FFFFFF"
    property string fontFamily: "SF Pro Display"

    signal getStarted()

    clip: true

    Floating3DParticles {
        id: particles
        anchors.fill: parent
        particleColor: root.particleColor
        particleCount: 90
        running: root.visible
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 640)
        spacing: 24
        z: 10

        Text {
            width: parent.width
            text: root.heading
            font.family: root.fontFamily
            font.pixelSize: 40
            font.weight: Font.Bold
            font.letterSpacing: -0.5
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: root.subheading
            font.family: root.fontFamily
            font.pixelSize: 17
            color: "#A1A1A1"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 1.45
        }

        // Get Started button
        Rectangle {
            id: btn
            anchors.horizontalCenter: parent.horizontalCenter
            height: 44
            width: btnRow.implicitWidth + 48
            radius: 10
            color: btnMouse.containsMouse ? "#E5E5EA" : "#FFFFFF"

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 120 } }

            Row {
                id: btnRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: root.buttonLabel
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: "#000000"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Arrow-right icon
                Text {
                    text: "→"
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: "#000000"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: btn.scale = 0.97
                onReleased: btn.scale = 1.0
                onCanceled: btn.scale = 1.0
                onClicked: root.getStarted()
            }
        }
    }
}
