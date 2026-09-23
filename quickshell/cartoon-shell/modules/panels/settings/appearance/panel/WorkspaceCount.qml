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
            name: "Workspace count: "
            isBold: true
        }
        Item {
            Layout.fillWidth: true
        }
        ButtonIconText {
            name: "add"
            onClicked: {
                // Giới hạn tối đa là 10
                if (Settings.bar.workspaceCount < 10) {
                    Settings.bar.workspaceCount += 1;
                }
            }
        }
        CustomText {
            id: workspaceCountText
            name: Settings.bar.workspaceCount
            size: "normal"
        }
        ButtonIconText {
            name: "remove"
            onClicked: {
                // Giới hạn tối thiểu là 2
                if (Settings.bar.workspaceCount > 2) {
                    Settings.bar.workspaceCount -= 1;
                }
            }
        }
    }
}
