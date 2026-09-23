import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick.Controls
import qs.services
import qs.commons
import qs.components
import "../../widget/" as Com

Rectangle {
    id: root
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    radius: ScalerService.s(Settings.appearance.radius2)
    color: theme.primary.background
    anchors.centerIn: parent
    property real animationProgress: 0

    implicitWidth: root.animationProgress > 0.5 ? parent.width : 0
    implicitHeight: root.animationProgress > 0.5 ? parent.height : 0

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

    // UI Layout
    Component {
        id: horizontalComponent
        Com.StatusTraySectionHorizontal {
            animationProgress: root.animationProgress
            isVertical: root.isVertical
        }
    }

    Component {
        id: verticalComponent
        Com.StatusTraySectionVertical {
            animationProgress: root.animationProgress
            isVertical: root.isVertical
        }
    }

    Loader {
        anchors.fill: parent
        anchors.margins: isVertical ? ScalerService.s(6) : ScalerService.s(5)
        sourceComponent: isVertical ? verticalComponent : horizontalComponent
    }
}
