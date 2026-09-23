import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    property string title: ""
    
    spacing: ScalerService.s(8)
    
    Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.1
        Layout.topMargin: ScalerService.s(5)
    }
    
    CustomText {
        name: title
        size: "small"
        textColor: theme.primary.dim_foreground
        isBold: true
        Layout.topMargin: ScalerService.s(2)
    }
    
    ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(4)
        Layout.leftMargin: ScalerService.s(10)
    }
}
