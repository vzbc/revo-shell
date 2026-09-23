import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import qs.services
import qs.components

Rectangle {
  id: root
  property string icon: ""
  property string label: ""
  property real revealThreshold: 0.6
  property real animationProgress: 0

  Layout.fillWidth: true
  Layout.preferredHeight: ScalerService.s(35)
  radius: ScalerService.s(12)
  color: mouseArea.containsMouse ? theme.button.background_select : theme.primary.background

  Behavior on color {
    ColorAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(5)
    spacing: ScalerService.s(10)

    IconImage {
      path: root.icon
      scale: mouseArea.containsMouse ? 1.1 : 1.0
      opacity: root.animationProgress > root.revealThreshold ? 1 : 0

    }

    CustomText {
      name: root.label
      isBold: mouseArea.containsMouse
      opacity: root.animationProgress > root.revealThreshold + 0.05 ? 1 : 0
    }

    Item {
      Layout.fillWidth: true
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      // Add click action here
      console.log("Clicked:", root.label);
    }
  }
}
