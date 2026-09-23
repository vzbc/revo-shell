//SystemStatsSection
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons
import qs.components
import qs.services.cpu
import "../../widget/" as Com

Rectangle {
    id: root
    color: theme.primary.background
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    radius: ScalerService.s(Settings.appearance.radius2)
    anchors.centerIn: parent
    property real animationProgress: 0
    implicitWidth: root.animationProgress > 0.4 ? parent.width : 0
    implicitHeight: root.animationProgress > 0.4 ? parent.height : 0
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
    clip: true

    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    RamService {
        id: ramService
        useSimpleCalculation: true
    }

    // UI Layout
    Loader {
        anchors.fill: parent
        anchors.margins: isVertical ? ScalerService.s(6) : ScalerService.s(4)
        sourceComponent: isVertical ? verticalLayout : horizontalLayout
    }

    Component {
        id: horizontalLayout
        Com.SystemStatsSectionHorizontal {}
    }

    Component {
        id: verticalLayout
        Com.SystemStatsSectionVertical {}
    }
}
