import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

RowLayout {
  id: root
  property real animationProgress: 0

  Layout.fillWidth: true
  spacing: ScalerService.s(15)
  Layout.alignment: Qt.AlignHCenter
  Item { Layout.fillWidth: true }

  IconImage {
    path: WeatherService.getWeatherIcon(
      WeatherService.dataModel.current.condition.code,
      WeatherService.dataModel.current.is_day
    )
    size: "4xl"
    opacity: root.animationProgress > 0.75 ? 1 : 0
    Behavior on opacity {
      NumberAnimation { duration: 200 }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: ScalerService.s(5)

    RowLayout {
      spacing: 0
      CustomText {
        name: `${WeatherService.dataModel.current.temp_c}` || "Đang tải..."
        Layout.alignment: Qt.AlignVCenter
        size: "2xl"
        isBold: true
        opacity: root.animationProgress > 0.77 ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: 200 }
        }
      }
      CustomText {
        textColor: theme.button.text
        isBold: true
        size: "large"
        name: "°C"
      }
    }

    CustomText {
      id: textCondition
      name: WeatherService.dataModel.current.condition.text.slice(0, 20) || "..."
      size: "large"
      elide: Text.ElideRight
      maximumLineCount: 1
      opacity: root.animationProgress > 0.8 ? 1 : 0
      Behavior on opacity {
        NumberAnimation { duration: 200 }
      }
    }

    RowLayout {
      spacing: 0
      CustomText {
        name: "Feels like: "
        size: "small"
      }
      CustomText {
        name: `${WeatherService.dataModel.current.feelslike_c}°C`
        isBold: true
        size: "small"
      }
    }
  }
  Item { Layout.fillWidth: true }
}
