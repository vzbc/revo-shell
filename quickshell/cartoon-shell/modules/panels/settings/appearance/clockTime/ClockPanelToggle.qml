// components/Settings/ClockPanelToggle.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Item {
    implicitHeight: clockPanelToggle.implicitHeight
    RowLayout {
        id: clockPanelToggle

        spacing: ScalerService.s(10)

        Text {
            text: lang.appearance?.clock_panel_label || "Bảng đồng hồ:"
            color: theme.primary.foreground
            font.family: "ComicShannsMono Nerd Font"
            font.pixelSize: ScalerService.s(16)
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        }

        Item {
            Layout.fillWidth: true
        }
        CustomToggleSwitch {
            adapter: Settings.clock.enableWidget
            onClicked: {
                Settings.clock.enableWidget = !Settings.clock.enableWidget;
            }
        }
    }
}
