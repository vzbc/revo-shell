import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.commons
import qs.components
import "../../widget/" as Com

Rectangle {
  id: root

  // Properties thuần cho layout / UI State
  property real animationProgress: 0
  property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

  border.color: theme.button.border
  border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
  radius: ScalerService.s(Settings.appearance.radius2)
  color: theme.primary.background
  anchors.centerIn: parent

  implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
  implicitHeight: root.animationProgress > 0.1 ? parent.height : 0

  Behavior on implicitHeight {
    NumberAnimation {
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  Behavior on implicitWidth {
    NumberAnimation {
      duration: 500
      easing.type: Easing.OutCubic
    }
  }

  Loader {
    anchors.centerIn: parent
    sourceComponent: isVertical ? verticalLayout : horizontalLayout
  }

  // Layout Ngang
  Component {
    id: horizontalLayout
    Com.WorkspaceSectionHorizontal {
    }
  }

  // Layout Dọc
  Component {
    id: verticalLayout
    Com.WorkspaceSectionVertical {
    }
  }
}
