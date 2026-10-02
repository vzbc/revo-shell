import QtQuick

// Launchpad-class glass panel: dark tint + hairline border + top sheen.
// The colored backdrop comes from Hyprland's layer blur behind the surface.
Item {
    id: root

    property real radius: 36
    property color tint: Qt.rgba(0.10, 0.10, 0.11, 0.55)
    property color borderColor: Qt.rgba(1, 1, 1, 0.16)
    property real sheenStrength: 0.07
    property real sheenEnd: 0.28

    default property alias content: body.children

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        border.width: 1
        border.color: root.borderColor
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.sheenStrength) }
                GradientStop { position: root.sheenEnd; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }
}
