import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.commons
import qs.components
import "../../widget/" as Com

Rectangle {
    id: root
    color: theme.primary.background
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    radius: ScalerService.s(Settings.appearance.radius2)
    anchors.centerIn: parent
    property real animationProgress: 0
    implicitWidth: root.animationProgress > 0.2 ? parent.width : 0
    implicitHeight: root.animationProgress > 0.2 ? parent.height : 0
    Behavior on implicitHeight {
        NumberAnimation {
            id: heightAnim
            duration: 500
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            id: widthAnim
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    Component {
        id: horizontalLayout
        Com.MediaSectionHorizontal {
            animationProgress: root.animationProgress
        }
    }

    Component {
        id: verticalLayout
        Com.MediaSectionVertical {
            animationProgress: root.animationProgress
        }
    }
    // UI Layout
    Loader {
        anchors.fill: parent
        anchors.margins: isVertical ? ScalerService.s(8) : ScalerService.s(10)
        sourceComponent: isVertical ? verticalLayout : horizontalLayout
    }
}
