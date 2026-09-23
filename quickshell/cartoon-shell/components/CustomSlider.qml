//Customslider
import QtQuick
import Quickshell.Services.Pipewire
import QtQuick.Layouts
import QtQuick.Controls
import qs.components
import qs.services

Slider {
    id: root
    from: 0
    to: 1
    enabled: false
    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: ScalerService.s(200)
        implicitHeight: ScalerService.s(6)
        width: root.availableWidth
        height: implicitHeight
        radius: ScalerService.s(5)
        color: theme.button.background

        // Progress fill
        Rectangle {
            width: root.visualPosition * parent.width
            Behavior on width {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
            height: parent.height
            color: theme.button.text
            radius: ScalerService.s(3)
            Behavior on color {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    handle: CustomRectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        Behavior on x {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        implicitWidth: root.pressed ? ScalerService.s(18) : ScalerService.s(16)
        implicitHeight: root.pressed ? ScalerService.s(18) : ScalerService.s(16)
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on radius {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        radius: root.pressed ? ScalerService.s(9) : ScalerService.s(8)
        color: theme.primary.background
        border.color: theme.button.dim_foreground
        border.width: ScalerService.s(1)

        // Inner dot
        Rectangle {
            anchors.centerIn: parent
            width: root.pressed ? ScalerService.s(10) : ScalerService.s(8)
            height: root.pressed ? ScalerService.s(10) : ScalerService.s(8)
            radius: root.pressed ? ScalerService.s(5) : ScalerService.s(4)
            color: theme.button.text
            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
