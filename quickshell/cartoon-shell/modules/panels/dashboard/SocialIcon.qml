import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons
import qs.components

Item {
  id: root
  property string image: ""
  property string linkSocial: ""
  property color bgColor: "white"
  property real hoverScale: 1.2 // Tỷ lệ phóng to khi hover
  property real revealThreshold: 0
  property real animationProgress: 0

  Layout.fillHeight: true
  Layout.preferredWidth: height

  Process { id: linkProcess }

  // Hiệu ứng chuyển đổi mượt mà

  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.animationProgress > root.revealThreshold - 0.05 ? parent.width : 0
    implicitHeight: root.animationProgress > root.revealThreshold - 0.05 ? parent.height : 0
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
    color: bgColor
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    border.color: theme.button.border

    IconImage {
      path: image
      anchors.centerIn: parent
      size: "xl"
      opacity: root.animationProgress > root.revealThreshold ? 1 : 0
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        linkProcess.command = ["xdg-open", linkSocial]
        linkProcess.startDetached()
        // Bạn có thể thêm hành động khi click ở đây
      }
    }
  }

}
