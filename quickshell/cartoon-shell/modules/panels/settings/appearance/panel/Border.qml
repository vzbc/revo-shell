import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

ColumnLayout {
    id: root
    spacing: ScalerService.s(20)
    Layout.fillWidth: true
    RowLayout {
        CustomText {
            isBold: true
            name: "enable border: "
        }
        Item {
            Layout.fillWidth: true
        }
        CustomToggleSwitch {
            adapter: Settings.appearance.enableBorder
            onClicked: {
                Settings.appearance.enableBorder = !Settings.appearance.enableBorder;
            }
        }
    }
}
