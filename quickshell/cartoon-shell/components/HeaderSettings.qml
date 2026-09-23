import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
    property var name: ""
    property var theme: ThemeService.theme
    property string fontFamily: Settings.appearance.font

    Layout.fillWidth: true
    Text {
        text: name
        color: theme.primary.foreground
        font {
            family: fontFamily
            pixelSize: ScalerService.s(24)
            bold: true
        }
        Layout.alignment: Qt.AlignLeft
    }
    Item {
        Layout.fillWidth: true
    }
}
