// MusicHeader.qml
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: root
  property real animationProgress: 0

  // Title centered
  CustomText {
    anchors.centerIn: parent

    name: lang.musicPanel?.title || "Music Player"
    isBold: true
    size: "large"
    opacity: root.animationProgress > 0.1 ? 1 : 0

  }

  // Close button (right side)
  CloseButton{
    onClicked: VisibleService.togglePanel("music")
    opacity: root.animationProgress > 0.2 ? 1 : 0
  }
}
