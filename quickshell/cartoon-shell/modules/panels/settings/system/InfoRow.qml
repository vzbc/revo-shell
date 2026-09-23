import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
    property string label: ""
    property string value: ""
    property color valueColor: theme.primary.foreground
    property bool labelVisible: true
    
    spacing: ScalerService.s(20)
    
    CustomText {
        visible: labelVisible
        name: label
        size: "xs"
        textColor: theme.primary.dim_foreground
        Layout.preferredWidth: ScalerService.s(120)
    }
    
    CustomText {
        name: value
        size: "xs"
        textColor: valueColor
        isBold: true
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
