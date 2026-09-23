// components/Settings/ClockPositionButton.qml
import QtQuick
import qs.services

Rectangle {
  id: clockPositionButton
  property string position: ""
  property bool isSelected: false

  property var anchorConfig: ({})

  signal clicked

  width: ScalerService.s(60)
  height: ScalerService.s(60)
  radius: ScalerService.s(12)
  color: isSelected ? theme.button.text : (mouseArea.containsMouse ? theme.button.background_select : theme.button.background)
  border.color: isSelected ? theme.button.text : (mouseArea.containsPress ? theme.button.border_select : theme.button.border)
  border.width: ScalerService.s(3)

  Rectangle {
    width: ScalerService.s(25)
    height: ScalerService.s(15)
    radius: ScalerService.s(6)
    color: isSelected ? theme.primary.dim_background : theme.button.text

    anchors.top: anchorConfig.top ? parent.top : undefined
    anchors.bottom: anchorConfig.bottom ? parent.bottom : undefined
    anchors.left: anchorConfig.left ? parent.left : undefined
    anchors.right: anchorConfig.right ? parent.right : undefined
    anchors.horizontalCenter: anchorConfig.hCenter ? parent.horizontalCenter : undefined
    anchors.verticalCenter: anchorConfig.vCenter ? parent.verticalCenter : undefined

    anchors.topMargin: anchorConfig.top ? ScalerService.s(10) : 0
    anchors.bottomMargin: anchorConfig.bottom ? ScalerService.s(10) : 0
    anchors.leftMargin: anchorConfig.left ? ScalerService.s(10) : 0
    anchors.rightMargin: anchorConfig.right ? ScalerService.s(10) : 0
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: clockPositionButton.clicked()
  }
}
