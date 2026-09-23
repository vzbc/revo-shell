import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import "./style/" as Com

ColumnLayout {
    id: root
    property real animationProgress: 0
    spacing: ScalerService.s(20)
    Com.Bar1 {}
    Com.Bar2 {}
    Com.Bar3 {}
}
