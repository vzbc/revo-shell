import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

CustomRectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(32)
    radius: ScalerService.s(Settings.appearance.radius1)
    color: theme.button.background
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: ScalerService.s(12)
        anchors.rightMargin: ScalerService.s(12)
        anchors.topMargin: ScalerService.s(5)
        anchors.bottomMargin: ScalerService.s(5)
        spacing: ScalerService.s(12)
        IconText {
            fontFamily: "Symbols Nerd Font"
            name: ""
            textColor: theme.primary.dim_foreground
            size: "small"
            Layout.alignment: Qt.AlignVCenter
        }
        CustomText {
            name: "Search"
            size: "small"
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
