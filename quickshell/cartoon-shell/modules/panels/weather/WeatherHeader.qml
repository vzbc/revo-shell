import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: headerCard

  property bool showSettings: false  // Thêm property để kiểm soát trạng thái

  IconText{
    anchors.left: parent.left
    name: "settings"
    visible: !showSettings
    rotation: mouseAreaSettings.containsMouse? 90 : 0
    Behavior on rotation {
      NumberAnimation {
        duration: 200
      }
    }
    MouseArea {
      id: mouseAreaSettings
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: {
        showSettings =  true
      }
    }
  }

  ButtonIconText {
    name: "arrow_back"
    visible: showSettings
    onClicked: {
      showSettings =  false
    }

  }

  CustomText {
    name: lang?.weather?.title || "Thời Tiết"
    size: "large"
    isBold: true
    anchors.centerIn: parent
    visible: !headerCard.showSettings  // Chỉ hiển thị khi không ở chế độ settings
  }

  CloseButton{
    onClicked: VisibleService.togglePanel("weather")
  }
}
