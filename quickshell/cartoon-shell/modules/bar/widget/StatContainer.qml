import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons

Item {
  id: root

  property string panelName: ""

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      VisibleService.togglePanel(root.panelName)
      SoundService.playSound("pick")
    }
    onEntered: root.opacity = 0.8
    onExited: root.opacity = 1.0
  }

  Behavior on opacity {
    NumberAnimation {
      duration: 200
    }
  }
}
