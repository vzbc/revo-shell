import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons
import qs.components
import "../../widget/" as Com

Rectangle {
    id: root
    color: theme.primary.background
    radius: ScalerService.s(Settings.appearance.radius2)
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    anchors.centerIn: parent
    property real animationProgress: 0
    implicitWidth: root.animationProgress > 0.3 ? parent.width : 0
    implicitHeight: root.animationProgress > 0.3 ? parent.height : 0
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

    property string selectedFlag: Settings.appearance.countryFlag
    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    // UI Layout
    Component {
        id: horizontalComponent
        Com.InfoSectionHorizontal {
            animationProgress: root.animationProgress
        }
    }

    Component {
        id: verticalComponent
        Com.InfoSectionVertical {
            animationProgress: root.animationProgress
        }
    }
    Loader {
        anchors.fill: parent
        sourceComponent: isVertical ? verticalComponent : horizontalComponent
    }
}
