import QtQuick
import QtQuick.Layouts

FocusScope {
    id: root

    required property QtObject theme
    required property url iconSource
    required property string label
    required property string status
    property bool checked: false
    property color accent: theme.green

    signal clicked()

    implicitWidth: 98
    implicitHeight: 62
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.45
    scale: tap.pressed ? theme.pressScale : 1
    Accessible.role: Accessible.Button
    Accessible.name: label + ". " + status
    Keys.onEnterPressed: {
        if (root.enabled)
            root.clicked();

    }
    Keys.onReturnPressed: {
        if (root.enabled)
            root.clicked();

    }
    Keys.onSpacePressed: {
        if (root.enabled)
            root.clicked();

    }

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusControl
        color: root.checked ? root.theme.alpha(root.accent, 0.72) : root.theme.surfaceMuted
        border.width: root.theme.borderWidth
        border.color: root.activeFocus ? root.theme.focus : root.theme.ink

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.theme.borderWidth + 1
            radius: Math.max(0, parent.radius - root.theme.borderWidth - 1)
            color: hover.hovered && root.enabled ? root.theme.alpha(root.theme.ink, 0.06) : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.theme.space2
            spacing: root.theme.space2

            Image {
                Layout.preferredWidth: root.theme.iconMd
                Layout.preferredHeight: root.theme.iconMd
                source: root.iconSource
                sourceSize.width: root.theme.iconMd
                sourceSize.height: root.theme.iconMd
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    elide: Text.ElideRight
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.status
                    elide: Text.ElideRight
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: 8
                }

            }

        }

        HoverHandler {
            id: hover
        }

        TapHandler {
            id: tap

            enabled: root.enabled
            onTapped: root.clicked()
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: root.theme.motionFast
            easing.type: root.theme.easingStandard
        }

    }

}
