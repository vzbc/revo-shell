pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        id: win
        width: 340
        height: 340

        Rectangle {
            anchors.fill: parent
            color: Colors.bg
        }

        ShaderEffect {
            anchors.centerIn: parent
            width: 340
            height: 220

            property real time
            property real toothWidth: 0.40
            property real toothDepth: 0.28
            property color gearColor: Colors.surface
            property color edgeColor: Colors.accent
            property real aspect: width / height
            property real phaseOffset: 2.1  // half a tooth period - correct mesh
            property int teeth: 6

            fragmentShader: "gear.qsb"

            NumberAnimation on time {
                from: 0.0
                to: Math.PI * 2.0
                duration: 4000
                loops: Animation.Infinite
            }
        }
    }
}
