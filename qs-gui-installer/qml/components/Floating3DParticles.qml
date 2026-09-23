// Floating3DParticles.qml — pseudo-3D particle field behind content
// Style: magicui Floating3DParticles — continuous rotation + buoyant drift
import QtQuick

Item {
    id: root

    property color particleColor: "#FFFFFF"
    property int particleCount: 80
    property real minSize: 1.0
    property real maxSize: 3.5
    property real driftSpeed: 0.15
    property real rotationSpeed: 0.08
    property real baseOpacity: 0.55
    property bool running: true

    clip: true

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Repeater {
            model: root.running ? root.particleCount : 0

            delegate: Item {
                id: p
                required property int index

                // Deterministic pseudo-random layout per particle
                readonly property real seedX: ((index * 73) % 100) / 100
                readonly property real seedY: ((index * 151) % 100) / 100
                readonly property real seedS: ((index * 37) % 100) / 100
                readonly property real seedO: ((index * 97) % 100) / 100
                readonly property real seedP: ((index * 53) % 100) / 100

                width: root.minSize + seedS * (root.maxSize - root.minSize)
                height: width
                x: seedX * root.width
                y: seedY * root.height
                opacity: root.baseOpacity * (0.35 + seedO * 0.65)
                z: Math.floor(seedP * 10)

                // Buoyant drift + slight scale pulse (3D depth cue)
                property real t: 0

                Timer {
                    interval: 16
                    repeat: true
                    running: root.running
                    onTriggered: {
                        p.t += 0.016
                        p.x = (p.seedX * root.width) + Math.sin(p.t * root.driftSpeed * 6 + p.index) * 18
                        p.y = (p.seedY * root.height) + Math.cos(p.t * root.driftSpeed * 5 + p.index * 0.7) * 14
                        p.scale = 1 + Math.sin(p.t * root.driftSpeed * 4 + p.seedP * 6.28) * 0.18
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: root.particleColor
                    opacity: parent.opacity
                }
            }
        }
    }

    // Soft vignette so particles stay behind content
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#B3000000" }
            GradientStop { position: 0.5; color: "#00000000" }
            GradientStop { position: 1.0; color: "#B3000000" }
        }
        visible: true
    }
}
