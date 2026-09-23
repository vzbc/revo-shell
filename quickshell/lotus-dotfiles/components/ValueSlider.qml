import QtQuick
import QtQuick.Layouts

FocusScope {
    id: root

    required property QtObject theme
    required property url iconSource
    required property string label
    property string statusText: ""
    property real value: 0
    property color accent: theme.green
    property bool iconClickable: false
    property string iconAccessibleName: label
    readonly property real clampedValue: Math.max(0, Math.min(1, value))

    signal userChanged(real value)
    signal iconClicked()

    implicitHeight: 54
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.45
    Accessible.role: Accessible.Slider
    Accessible.name: label + ". " + (statusText.length > 0 ? statusText : Math.round(clampedValue * 100) + " percent")
    Keys.onLeftPressed: root.userChanged(Math.max(0, root.clampedValue - 0.05))
    Keys.onRightPressed: root.userChanged(Math.min(1, root.clampedValue + 0.05))

    ColumnLayout {
        anchors.fill: parent
        spacing: root.theme.space2

        RowLayout {
            Layout.fillWidth: true
            spacing: root.theme.space2

            Item {
                Layout.preferredWidth: root.iconClickable ? 28 : root.theme.iconSm
                Layout.preferredHeight: root.iconClickable ? 28 : root.theme.iconSm

                Image {
                    visible: !root.iconClickable
                    anchors.fill: parent
                    source: root.iconSource
                    sourceSize.width: root.theme.iconSm
                    sourceSize.height: root.theme.iconSm
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                IconButton {
                    visible: root.iconClickable
                    anchors.centerIn: parent
                    theme: root.theme
                    controlSize: 28
                    iconSource: root.iconSource
                    accessibleName: root.iconAccessibleName
                    onClicked: root.iconClicked()
                }

            }

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.theme.ink
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
                font.weight: Font.Bold
            }

            Text {
                text: root.statusText.length > 0 ? root.statusText : Math.round(root.clampedValue * 100) + "%"
                color: root.theme.inkMuted
                font.family: root.theme.fontFamily
                font.pixelSize: 9
            }

        }

        Rectangle {
            id: track

            Layout.fillWidth: true
            Layout.preferredHeight: 14
            radius: 7
            color: root.theme.surfaceMuted
            border.width: root.theme.borderWidth
            border.color: root.activeFocus ? root.theme.focus : root.theme.ink

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: root.theme.borderWidth
                width: Math.max(0, (parent.width - root.theme.borderWidth * 2) * root.clampedValue)
                radius: 5
                color: root.accent
            }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                x: root.theme.borderWidth + Math.max(0, (track.width - width - root.theme.borderWidth * 2) * root.clampedValue)
                anchors.verticalCenter: parent.verticalCenter
                color: root.theme.surfaceRaised
                border.width: root.theme.borderWidth
                border.color: root.theme.ink
            }

            MouseArea {
                function updateValue(mouseX) {
                    root.userChanged(Math.max(0, Math.min(1, mouseX / width)));
                }

                anchors.fill: parent
                enabled: root.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => {
                    return updateValue(mouse.x);
                }
                onPositionChanged: (mouse) => {
                    if (pressed)
                        updateValue(mouse.x);

                }
            }

        }

    }

}
