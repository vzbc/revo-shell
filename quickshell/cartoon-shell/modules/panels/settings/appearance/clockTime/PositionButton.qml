// components/Settings/PositionButton.qml
import QtQuick
import qs.services

Rectangle {
  id: positionButton
  property string label: ""
  property string position: ""
  property bool isSelected: false
  signal clicked

  width: ScalerService.s(80)
  height: ScalerService.s(40)
  radius: ScalerService.s(8)
  color: isSelected ? theme.button.text : (mouseArea.containsMouse ? theme.button.background_select : theme.button.background)
  border.color: isSelected ? theme.button.text : (mouseArea.containsPress ? theme.button.border_select : theme.button.border)
  border.width: ScalerService.s(2)

  Text {
    text: label
    color: isSelected ? theme.primary.background : theme.primary.foreground
    font {
      family: "ComicShannsMono Nerd Font"
      pixelSize: ScalerService.s(14)
      bold: isSelected
    }
    anchors.centerIn: parent
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: positionButton.clicked()
  }
}
