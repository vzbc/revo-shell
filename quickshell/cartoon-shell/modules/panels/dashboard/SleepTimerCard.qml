import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import qs.services
import qs.components
import qs.commons

Item {
  id: root

  property real animationProgress: 0

  Layout.fillWidth: true
  Layout.preferredHeight: ScalerService.s(120)

  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.animationProgress > 0.3 ? parent.width : 0
    implicitHeight: root.animationProgress > 0.3 ? parent.height : 0
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
    color: theme.primary.background
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    border.color: theme.button.border

    RowLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(20)

      IconImage {
        path: "dashboard/clock.png"
        size: "2xl"
        opacity: root.animationProgress > 0.6 ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: 200
          }
        }

      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(2)

        CustomText {
          name: UptimeService.uptimeHours + " hours"
          isBold: true
          textColor: theme.button.text
          size: "xl"
          opacity: root.animationProgress > 0.65 ? 1 : 0
          Behavior on opacity {
            NumberAnimation {
              duration: 200
            }
          }
        }
        CustomText {
          name: UptimeService.uptimeMinutes + " minutes"
          textColor: theme.primary.foreground
          size: "normal"
          opacity: root.animationProgress > 0.7 ? 1 : 0
          Behavior on opacity {
            NumberAnimation {
              duration: 200
            }
          }

        }

      }
    }
  }
}
