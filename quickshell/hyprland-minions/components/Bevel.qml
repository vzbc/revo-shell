import QtQuick
import qs.config

// Moulded-plastic shape: a rounded, pillow-like body shaded like a solid
// piece of toy plastic. The top edge catches the light, the underside falls
// into shade, the sides roll off, and a faint reflection runs along the
// bottom lip. There's no glassy shine band. `sunken` turns it into an inset
// well instead (inner shadow along the top, a light lip along the bottom),
// for pressed buttons, text fields, lists and slider tracks.
//
// Colours: faceColor is the plastic itself; the theme's bevelHighlight is the
// light on the top edge, bevelLight the reflection along the bottom lip,
// bevelDark the rim and bevelShadow the drop / inner shadow.
Item {
    id: root

    property bool sunken: false
    property color faceColor: Theme.face
    property real radius: Theme.radius
    property bool shadow: !sunken
    // The bright highlight along the top edge.
    property bool gloss: true

    readonly property real r: Math.max(0, Math.min(radius, height / 2, width / 2))

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function shade(a) {
        return Qt.tint(root.faceColor, root.alpha(Theme.bevelShadow, a))
    }

    function light(a) {
        return Qt.tint(root.faceColor, root.alpha(Theme.bevelHighlight, a))
    }

    // Soft two-step drop shadow under the body.
    Rectangle {
        visible: root.shadow
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: -2
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        radius: root.r
        color: root.alpha(Theme.bevelShadow, 0.12)
    }

    Rectangle {
        visible: root.shadow
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: -1
        radius: root.r
        color: root.alpha(Theme.bevelShadow, 0.22)
    }

    // ---- Raised ----------------------------------------------------------

    // Rim: the same plastic, deeper in colour.
    Rectangle {
        visible: !root.sunken
        anchors.fill: parent
        radius: root.r
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.tint(root.faceColor, root.alpha(Theme.bevelDark, 0.45)) }
            GradientStop { position: 1; color: Qt.tint(root.faceColor, root.alpha(Theme.bevelDark, 0.85)) }
        }

        // Body, shaded like a rounded tube lit from above.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.r - 1)
            gradient: Gradient {
                GradientStop { position: 0; color: root.light(root.gloss ? 0.6 : 0.3) }
                GradientStop { position: 0.14; color: root.light(0.22) }
                GradientStop { position: 0.45; color: root.faceColor }
                GradientStop { position: 0.82; color: root.shade(0.13) }
                GradientStop { position: 0.94; color: root.shade(0.2) }
                GradientStop { position: 1; color: Qt.tint(root.shade(0.1), root.alpha(Theme.bevelLight, 0.3)) }
            }
        }

        // The sides rolling away from the light.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.r - 1)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.alpha(Theme.bevelShadow, 0.1) }
                GradientStop { position: Math.min(0.3, root.r * 1.2 / Math.max(1, root.width)); color: "transparent" }
                GradientStop { position: 1 - Math.min(0.3, root.r * 1.2 / Math.max(1, root.width)); color: "transparent" }
                GradientStop { position: 1; color: root.alpha(Theme.bevelShadow, 0.1) }
            }
        }
    }

    // ---- Sunken ----------------------------------------------------------

    Rectangle {
        visible: root.sunken
        anchors.fill: parent
        radius: root.r
        // Lip: dark where the top edge dips in, light where the bottom one
        // catches the light.
        gradient: Gradient {
            GradientStop { position: 0; color: root.alpha(Theme.bevelShadow, 0.55) }
            GradientStop { position: 1; color: root.alpha(Theme.bevelLight, 0.9) }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, root.r - 1)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.tint(root.faceColor, root.alpha(Theme.bevelShadow, 0.12)) }
                GradientStop { position: 0.4; color: root.faceColor }
                GradientStop { position: 1; color: root.faceColor }
            }
        }

        // Inner shadow falling from the top edge.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: Math.min(8, parent.height / 2)
            radius: Math.max(0, Math.min(root.r - 1, height / 2))
            gradient: Gradient {
                GradientStop { position: 0; color: root.alpha(Theme.bevelShadow, 0.22) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
}
