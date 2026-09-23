import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
    id: flagItem

    property string flagName: ""
    property string displayName: ""
    property bool isSelected: false
    property real animationProgress: 0

    color: isSelected ? Qt.alpha(theme.button.background_select, 0.5) : Qt.alpha(theme.button.background, 0.5)
    border.color: isSelected ? theme.button.border_select : theme.button.border
    radius: ScalerService.s(Settings.appearance.radius3)
    border.width: Settings.appearance.enableBorder ? (isSelected ? ScalerService.s(2) : ScalerService.s(1)) : 0

    signal clicked

    scale: 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 150
        }
    }

    Behavior on border.width {
        NumberAnimation {
            duration: 150
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: ScalerService.s(0)

        IconImage {
            path: `flags/${flagName}.png`
            size: "xl"
            Layout.alignment: Qt.AlignHCenter
            opacity: 0

            SequentialAnimation on opacity {
                running: root.animationProgress > 0.7

                PauseAnimation {
                    duration: index * 15
                }

                NumberAnimation {
                    to: 1
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }

        CustomText {
            name: displayName
            size: "small"
            isBold: isSelected
            Layout.alignment: Qt.AlignHCenter
            opacity: 0

            SequentialAnimation on opacity {
                running: root.animationProgress > 0.8

                PauseAnimation {
                    duration: index * 15
                }

                NumberAnimation {
                    to: 1
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            flagItem.clicked();
            SoundService.playSound("pick");
        }

        onEntered: parent.scale = 1.05
        onExited: parent.scale = 1.0
    }
}
