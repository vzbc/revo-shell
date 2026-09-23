import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property QtObject theme
    required property url iconSource
    required property string label
    required property string value
    property string detail: ""
    property color accent: theme.peach

    implicitWidth: 148
    implicitHeight: 82
    radius: theme.radiusCard
    color: theme.surfaceRaised
    border.width: theme.borderWidth
    border.color: theme.ink

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.theme.space3
        spacing: root.theme.space2

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: root.theme.radiusControl
            color: root.accent
            border.width: 1
            border.color: root.theme.ink

            Image {
                anchors.centerIn: parent
                width: root.theme.iconSm
                height: root.theme.iconSm
                source: root.iconSource
                sourceSize.width: root.theme.iconSm
                sourceSize.height: root.theme.iconSm
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.label.toUpperCase()
                color: root.theme.inkMuted
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.Bold
            }

            Text {
                Layout.fillWidth: true
                text: root.value
                color: root.theme.ink
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textMd
                font.weight: Font.Bold
            }

            Text {
                visible: root.detail.length > 0
                Layout.fillWidth: true
                text: root.detail
                color: root.theme.inkMuted
                elide: Text.ElideRight
                font.family: root.theme.fontFamily
                font.pixelSize: 8
            }

        }

    }

}
