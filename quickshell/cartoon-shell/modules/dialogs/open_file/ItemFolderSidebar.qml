import QtQuick
import QtQuick.Layouts
import qs.components
import QtQuick.Controls
import qs.services

Rectangle {
  id: root
  property string image : ""
  property string name: ""
  property bool hovered: false

  Layout.preferredHeight: ScalerService.s(40)
  Layout.fillWidth: true
  border.width: ScalerService.s(1)
  radius: ScalerService.s(8)
  color: mouseArea.containsMouse ? theme.button.background_select : theme.button.background
  border.color: mouseArea.containsMouse ? theme.button.border_select : theme.button.border
  scale: mouseArea.containsMouse ? 0.98 : 1.0
  Behavior on scale {
    NumberAnimation {
      duration: 100
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: 200
    }
  }
  Behavior on border.color {
    ColorAnimation {
      duration: 100
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(5)
    spacing: ScalerService.s(5)
    clip: true
    IconImage{
      path: root.image
      size: "normal"
    }
    CustomText {
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignLeft
      textColor: mouseArea.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
      name: root.name
      size: "small"
    }
  }
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      root.clicked()
    }
  }
}
