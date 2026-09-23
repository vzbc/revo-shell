import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./theme" as Com
import qs.services
import qs.components

Item {
  id: root
  property real animationProgress: 0

  SequentialAnimation on animationProgress {
    running: true

    NumberAnimation {
      from: 0
      to: 1
      duration: 500
      easing.type: Easing.Linear
    }
  }

  ScrollView {
    id: scrollView
    anchors.fill: parent
    clip: true
    anchors.margins: ScalerService.s(20)

    // Cấu hình scrollbar
    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
    ScrollBar.vertical.interactive: true

    // Content area
    contentWidth: contentLayout.width
    contentHeight: contentLayout.height

    // Nền cho scrollview
    background: Rectangle {
      color: "transparent"
    }

    ColumnLayout {
      id: contentLayout
      width: scrollView.availableWidth
      spacing: ScalerService.s(25)
      // Tiêu đề chính
      HeaderSettings {
        opacity: root.animationProgress > 0.1 ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: 200
          }
        }
        name: "Theme"
      }

      // Đường phân cách
      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: root.animationProgress > 0.15 ? 0.2 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: 200
          }
        }
        Layout.bottomMargin: ScalerService.s(5)
      }

      // Container chính cho nội dung
      Rectangle {
        id: contentContainer
        Layout.fillWidth: true
        color: "transparent"

        ColumnLayout {
          width: parent.width
          spacing: ScalerService.s(25)

          // Phần chọn theme
          Com.ThemeSelection {
            id: themeSelection
            width: parent.width
            Layout.fillWidth: true
          }
          Com.ListTheme {

          }
        }
      }

      // Spacer để đảm bảo nội dung không bị che ở dưới
      Item {
        Layout.fillHeight: true
        Layout.minimumHeight: ScalerService.s(20)
      }
    }
  }

  // Tùy chọn: Hiển thị thanh scrollbar custom nếu muốn
  Component {
    id: customScrollBar

    Rectangle {
      id: scrollBar
      width: ScalerService.s(8)
      radius: ScalerService.s(4)
      color: theme.normal.blue
      opacity: 0.5

      Behavior on opacity {
        NumberAnimation {
          duration: 200
        }
      }

      states: State {
        name: "hovered"
        when: scrollBar.MouseArea.containsMouse
        PropertyChanges {
          target: scrollBar
          opacity: 0.8
          width: ScalerService.s(10)
        }
      }
    }
  }

  // Debug: Hiển thị kích thước scrollview (có thể xóa)
  Rectangle {
    visible: false // Đặt true để debug
    anchors.fill: scrollView
    color: "transparent"
    border.color: "red"
    border.width: ScalerService.s(1)

    Text {
      anchors.centerIn: parent
      text: `SV: ${scrollView.width}x${scrollView.height}\nContent: ${scrollView.contentWidth}x${scrollView.contentHeight}`
      color: "red"
      font.pixelSize: ScalerService.s(10)
    }
  }
}
