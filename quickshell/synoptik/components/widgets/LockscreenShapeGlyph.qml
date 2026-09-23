import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: glyphRoot

    property int shapeIndex: 0
    property color shapeColor: Config.accent
    property real targetRotation: 0
    property bool isOutline: false
    property bool isError: false
    property bool isSuccess: false
    property bool isAuthenticating: false
    property int animIndex: 0
    property string maskStyle: "shapes" // "shapes", "dots", "asterisks", "special"
    property string charGlyph: "*"

    implicitWidth: 26
    implicitHeight: 26

    // Palette / dynamic color computation
    readonly property color effectiveColor: {
        if (isError) return "#ef4444"
        if (isSuccess) return "#10b981"
        return shapeColor
    }

    // Curated SVG Path definitions (Normalized to a 24x24 viewport)
    readonly property var shapePaths: [
        // 0: Circle Disc / Ring
        "M 12,2 A 10,10 0 1 0 12,22 A 10,10 0 1 0 12,2 Z",
        // 1: Diamond / Rhombus
        "M 12,2 L 22,12 L 12,22 L 2,12 Z",
        // 2: Rounded Square
        "M 5,3 L 19,3 C 20.1,3 21,3.9 21,5 L 21,19 C 21,20.1 20.1,21 19,21 L 5,21 C 3.9,21 3,20.1 3,19 L 3,5 C 3,3.9 3.9,3 5,3 Z",
        // 3: Equilateral Triangle
        "M 12,2.5 L 22.5,20.5 L 1.5,20.5 Z",
        // 4: Inverted Triangle
        "M 1.5,3.5 L 22.5,3.5 L 12,21.5 Z",
        // 5: Hexagon
        "M 12,2 L 21.5,7.5 L 21.5,16.5 L 12,22 L 2.5,16.5 L 2.5,7.5 Z",
        // 6: Pentagon
        "M 12,2 L 22,9.2 L 18.2,21 L 5.8,21 L 2,9.2 Z",
        // 7: Octagon
        "M 7.5,2 L 16.5,2 L 22,7.5 L 22,16.5 L 16.5,22 L 7.5,22 L 2,16.5 L 2,7.5 Z",
        // 8: 4-Point Sparkle / Star
        "M 12,2 Q 12,12 2,12 Q 12,12 12,22 Q 12,12 22,12 Q 12,12 12,2 Z",
        // 9: 5-Point Star
        "M 12,2 L 15,8.5 L 22,9.3 L 17,14 L 18.5,21 L 12,17.5 L 5.5,21 L 7,14 L 2,9.3 L 9,8.5 Z",
        // 10: Plus / Cross
        "M 9,3 L 15,3 L 15,9 L 21,9 L 21,15 L 15,15 L 15,21 L 9,21 L 9,15 L 3,15 L 3,9 L 9,9 Z",
        // 11: Heart
        "M 12,21.35 L 10.55,20.03 C 5.4,15.36 2,12.28 2,8.5 C 2,5.42 4.42,3 7.5,3 C 9.24,3 10.91,3.81 12,5.09 C 13.09,3.81 14.76,3 16.5,3 C 19.58,3 22,5.42 22,8.5 C 22,12.28 18.6,15.36 13.45,20.03 Z",
        // 12: Crescent Moon
        "M 12,2 A 10,10 0 0 0 22,14 A 10,10 0 1 1 12,2 Z",
        // 13: Shield
        "M 12,2 L 20.5,5.5 L 20.5,11.5 C 20.5,16.8 16.9,21.2 12,22 C 7.1,21.2 3.5,16.8 3.5,11.5 L 3.5,5.5 Z",
        // 14: Asterisk / Flower (6-petals)
        "M 11,2 L 13,2 L 13,7.5 L 17.5,4.8 L 18.5,6.5 L 14,9.5 L 19,12 L 19,14 L 14,14.5 L 18.5,17.5 L 17.5,19.2 L 13,16.5 L 13,22 L 11,22 L 11,16.5 L 6.5,19.2 L 5.5,17.5 L 10,14.5 L 5,14 L 5,12 L 10,9.5 L 5.5,6.5 L 6.5,4.8 L 11,7.5 Z",
        // 15: Ring / Donut
        "M 12,2 A 10,10 0 1 0 12,22 A 10,10 0 1 0 12,2 Z M 12,6 A 6,6 0 1 1 12,18 A 6,6 0 1 1 12,6 Z"
    ]

    readonly property string currentSvgPath: {
        let idx = Math.abs(glyphRoot.shapeIndex) % shapePaths.length
        return shapePaths[idx]
    }

    Item {
        id: transformContainer
        anchors.fill: parent
        scale: 0.0
        rotation: (glyphRoot.maskStyle === "shapes") ? (glyphRoot.targetRotation - 60) : 0
        opacity: 0.0

        // Entrance Spring Animation
        ParallelAnimation {
            id: entranceAnim
            running: true

            NumberAnimation {
                target: transformContainer
                property: "scale"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.8
            }

            NumberAnimation {
                target: transformContainer
                property: "rotation"
                from: (glyphRoot.maskStyle === "shapes") ? (glyphRoot.targetRotation - 60) : 0
                to: (glyphRoot.maskStyle === "shapes") ? glyphRoot.targetRotation : 0
                duration: 340
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: transformContainer
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 180
                easing.type: Easing.OutQuad
            }
        }

        // Authenticating Wave Pulse Animation
        SequentialAnimation {
            running: glyphRoot.isAuthenticating
            loops: Animation.Infinite

            PauseAnimation {
                duration: (glyphRoot.animIndex % 8) * 80
            }

            NumberAnimation {
                target: transformContainer
                property: "scale"
                from: 1.0
                to: 1.28
                duration: 220
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: transformContainer
                property: "scale"
                from: 1.28
                to: 1.0
                duration: 220
                easing.type: Easing.InOutQuad
            }

            PauseAnimation {
                duration: Math.max(0, 640 - ((glyphRoot.animIndex % 8) * 80))
            }
        }

        // Soft Glowing Aura
        RectangularGlow {
            anchors.fill: visualContainer
            glowRadius: 6
            spread: 0.2
            color: Qt.rgba(effectiveColor.r, effectiveColor.g, effectiveColor.b, 0.45)
            cornerRadius: 12
            visible: Config.clockShowGlow !== false
        }

        Item {
            id: visualContainer
            anchors.centerIn: parent
            width: 20
            height: 20

            // 1. RANDOM GEOMETRIC SHAPES
            Shape {
                id: shapeItem
                anchors.centerIn: parent
                width: 20
                height: 20
                scale: width / 24.0
                visible: glyphRoot.maskStyle === "shapes"
                smooth: true
                asynchronous: false
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    fillColor: glyphRoot.isOutline ? "transparent" : glyphRoot.effectiveColor
                    strokeColor: glyphRoot.isOutline ? glyphRoot.effectiveColor : "transparent"
                    strokeWidth: glyphRoot.isOutline ? 2.5 : 0
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    PathSvg {
                        path: glyphRoot.currentSvgPath
                    }
                }
            }

            // 2. DOTS (Bullet Discs)
            Rectangle {
                anchors.centerIn: parent
                width: glyphRoot.isOutline ? 12 : 10
                height: width
                radius: width / 2
                visible: glyphRoot.maskStyle === "dots"
                color: glyphRoot.isOutline ? "transparent" : glyphRoot.effectiveColor
                border.width: glyphRoot.isOutline ? 2 : 0
                border.color: glyphRoot.effectiveColor
            }

            // 3. ASTERISKS (*)
            Text {
                anchors.centerIn: parent
                visible: glyphRoot.maskStyle === "asterisks"
                text: "✱"
                font.family: Config.sysFont
                font.pixelSize: 18
                font.bold: true
                color: glyphRoot.effectiveColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            // 4. RANDOM SPECIAL CHARACTERS (!@#$%^&*)
            Text {
                anchors.centerIn: parent
                visible: glyphRoot.maskStyle === "special"
                text: glyphRoot.charGlyph !== "" ? glyphRoot.charGlyph : "*"
                font.family: Config.sysFont
                font.pixelSize: 16
                font.bold: true
                color: glyphRoot.effectiveColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
