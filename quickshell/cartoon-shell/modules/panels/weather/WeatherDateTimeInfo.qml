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
    name: "calendar_month"
    size: "small"
    textColor: theme.button.text
  }

  CustomText {
    name: DateTimeService.currentTime
    isBold: true
    size: "small"
  }

  CustomText {
    name: DateTimeService.currentDate
    size: "small"
    color: theme.primary.dim_foreground
    isBold: true
  }
}
