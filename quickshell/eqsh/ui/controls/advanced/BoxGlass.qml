import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Effects
import qs.ui.controls.advanced

Item {
    id: box

    property color color: "#10000000"
    property bool highlightEnabled: true
    property bool transparent: false
    
    property color light: '#40ffffff'
    property vector2d   lightDir: Qt.vector2d(0, -1)
    property real  rimSize: 0.05
    property real  rimStrength: 1.0
    property real  darkRim: 2
    property color darkRimColor: Qt.rgba(0, 0, 0, 0.32)

    property var negLight: ""
    property var highlight: ""
    property var shadowOpacity: ""

    // Individual corner radii
    property real radius: 50

    property int animationSpeed: 16
    property int animationSpeed2: 16

    Behavior on color { PropertyAnimation { duration: animationSpeed; easing.type: Easing.InSine } }
    
    GlassRim {
        id: boxContainer
        anchors.fill: parent
        baseColor: box.transparent ? "transparent" : box.color
        radius: box.radius
        glowColor: box.highlightEnabled ? Qt.rgba(box.light.r, box.light.g, box.light.b, box.light.a * box.rimStrength) : "#00000000"
        lightDir: box.lightDir
        glowEdgeBand: box.rimSize
    }

    // iOS 27 "darkened edges": thin dark silhouette under the specular glow
    Rectangle {
        anchors.fill: parent
        radius: box.radius
        color: "transparent"
        border.width: box.darkRim
        border.color: box.darkRimColor
        visible: box.darkRim > 0 && box.highlightEnabled
    }
}
