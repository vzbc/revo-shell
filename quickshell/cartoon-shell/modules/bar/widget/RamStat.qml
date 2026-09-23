import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services.ram
import qs.commons
import qs.services

RowLayout {
  id: root

  property int style: Settings.bar.ram.style
  property bool textBefore: style <= 4
  property bool compact: [3,4,7,8].includes(style)

  spacing: ScalerService.s(2)

  ColumnLayout {
    visible: textBefore
    spacing: 0

    CustomText {
      name: RamSimpleService.ramPercent + "%"
      isBold: !compact
      size: compact ? "normal" : "small"
    }

    CustomText {
      visible: !compact
      name: "Ram"
      textColor: theme.primary.dim_foreground
      size: "2xs"
    }
  }

  IconImage {
    visible: [1,3,5,7].includes(root.style)
    path: "panel/memory.png"
  }

  IconText {
    visible: [2,4,6,8].includes(root.style)
    name: "memory_alt"
    textColor: theme.button.text
  }

  ColumnLayout {
    visible: !textBefore
    spacing: 0

    CustomText {
      name: RamSimpleService.ramPercent + "%"
      isBold: !compact
      size: compact ? "normal" : "small"
    }

    CustomText {
      visible: !compact
      name: "Ram"
      textColor: theme.primary.dim_foreground
      size: "2xs"
    }
  }
}
