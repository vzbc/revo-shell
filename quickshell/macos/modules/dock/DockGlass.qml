import QtQuick
import Quickshell

// Control Center glass (eqsh ui/controls/advanced/BoxGlass.qml + GlassRim.qml)
// copied for the dock: same grxframe rim shader, same values the Control
// Center panels use (Theme.glassColor Clear, glassRimColor,
// glassRimStrengthStrong, glassLightDirStrong). The refraction/blur behind it
// comes from the same hyprliquid "liquid_glass" rule as eqsh:blur.
Item {
    id: box

    property real  radius: 24
    property color color: "#06ffffff"             // clear glass: background shows through
    property color light: "#14ffffff"             // 1px inner light, ~+11 like the reference
    property real  rimStrength: 1.0
    property vector2d lightDir: Qt.vector2d(0, 1) // brightest on top/bottom
    property real  rimSize: 0.015                 // ~1.5px band
    property real  darkRim: 1                     // 1px outer line
    property color darkRimColor: Qt.rgba(0, 0, 0, 0.08)

    readonly property real smallerVal: Math.min(width, height)
    readonly property real r: Math.min(smallerVal / 2, radius)

    ShaderEffect {
        anchors.fill: parent
        property vector2d iResolution: Qt.vector2d(box.width + 2, box.height + 2)
        property vector2d boxSize: Qt.vector2d(box.width / 2, box.height / 2)
        property vector4d cornerRadii: Qt.vector4d(box.r, box.r, box.r, box.r)
        property vector4d glowColor: Qt.vector4d(box.light.r, box.light.g, box.light.b, box.light.a * box.rimStrength)
        property real glowEdgeBand: box.rimSize
        property vector4d baseColor: Qt.vector4d(box.color.r, box.color.g, box.color.b, box.color.a)
        property var source: null
        property var lightDir: box.lightDir
        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/media/shaders/grxframe.frag.qsb")
        vertexShader: Qt.resolvedUrl(Quickshell.shellDir + "/media/shaders/grxframe.vert.qsb")
    }

    // 1px dark line just outside the platter, on the background (as macOS)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -box.darkRim
        radius: box.radius + box.darkRim
        color: "transparent"
        border.width: box.darkRim
        border.color: box.darkRimColor
        visible: box.darkRim > 0
    }
}
