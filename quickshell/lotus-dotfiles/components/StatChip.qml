import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property QtObject theme
    required property url iconSource
    required property string label
    required property string value
    property color accent: theme.green

    implicitWidth: content.implicitWidth + theme.space3 * 2
    implicitHeight: 28
    radius: theme.radiusPill
    color: theme.alpha(accent, 0.58)
    border.width: 1
    border.color: theme.ink

    RowLayout {
        id: content

        anchors.centerIn: parent
        spacing: root.theme.space1

        Image {
            Layout.preferredWidth: root.theme.iconSm
            Layout.preferredHeight: root.theme.iconSm
            source: root.iconSource
            sourceSize.width: root.theme.iconSm
            sourceSize.height: root.theme.iconSm
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        Text {
            text: root.label
            color: root.theme.inkMuted
            font.family: root.theme.fontFamily
            font.pixelSize: 8
            font.weight: Font.DemiBold
        }

        Text {
            text: root.value
            color: root.theme.ink
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.textXs
            font.weight: Font.Bold
        }

    }

}
