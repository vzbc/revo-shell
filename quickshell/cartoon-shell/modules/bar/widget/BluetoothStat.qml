import QtQuick
import QtQuick.Layouts
import qs.components
import qs.commons
import qs.services

RowLayout {
    id: root

    property int style: Settings.bar.bluetooth.style
    spacing: ScalerService.s(2)

    IconImage {
        visible: [1].includes(root.style)
        path: "settings/bluetooth.png"
    }

    IconText {
        visible: [2].includes(root.style)
        name: "bluetooth"
        textColor: theme.button.text
        size: isVertical ? "small" : "normal"
    }
}
