import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services.cpu
import qs.commons
import qs.services

RowLayout {
    id: root

    property int style: Settings.bar.cpu.style
    property bool textBefore: style <= 4
    property bool compact: [3, 4, 7, 8].includes(style)

    spacing: ScalerService.s(2)

    ColumnLayout {
        visible: textBefore
        spacing: 0

        CustomText {
            name: CpuSimpleService.cpuPercent + "%"
            isBold: !compact
            size: compact ? "normal" : "small"
        }

        CustomText {
            visible: !compact
            name: "Cpu"
            textColor: theme.primary.dim_foreground
            size: "2xs"
        }
    }

    IconImage {
        visible: [1, 3, 5, 7].includes(root.style)
        path: "cpu/cpu.png"
    }

    IconText {
        visible: [2, 4, 6, 8].includes(root.style)
        name: "memory"
        textColor: theme.button.text
    }

    ColumnLayout {
        visible: !textBefore
        spacing: 0

        CustomText {
            name: CpuSimpleService.cpuPercent + "%"
            isBold: !compact
            size: compact ? "normal" : "small"
        }

        CustomText {
            visible: !compact
            name: "Cpu"
            textColor: theme.primary.dim_foreground
            size: "2xs"
        }
    }
}
