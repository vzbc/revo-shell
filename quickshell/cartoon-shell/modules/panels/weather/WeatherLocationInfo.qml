import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

RowLayout {
  id: root
  property real animationProgress: 0

  spacing: ScalerService.s(22)

  IconText {
    name: "location_on"
    size: "small"
    textColor: theme.button.text
  }

  CustomText {
    name: Settings.weather.location.slice(0, 40)
    size: "small"
  }
}
