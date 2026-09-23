import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.bar
import qs.commons
import qs.services
import "./layout/style1/"

PanelWindow {
    id: panel
    readonly property var widthBar: ({
            "style1": 40,
            "style2": 38,
            "style3": 35
        })

    readonly property var heightBar: ({
            "style1": 50,
            "style2": 40,
            "style3": 50
        })

    implicitWidth: isVertical ? ScalerService.s(widthBar[Settings.bar.style] ?? 40) : Screen.width
    implicitHeight: !isVertical ? ScalerService.s(heightBar[Settings.bar.style] ?? 50) : Screen.height

    color: "transparent"

    anchors {
        left: (Settings.bar.position === "left" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? true : false
        right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? true : false
        top: (Settings.bar.position === "top" || Settings.bar.position === "left" || Settings.bar.position === "right") ? true : false
        bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? true : false
    }

    margins {
        top: (Settings.bar.position === "top" || Settings.bar.position === "left" || Settings.bar.position === "right") ? (Settings.bar.style === "style1" || Settings.bar.style === "style2") ? ScalerService.s(10) : 0 : 0
        left: (Settings.bar.position === "left" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? (Settings.bar.style === "style1" || Settings.bar.style === "style2") ? ScalerService.s(10) : 0 : 0
        right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? (Settings.bar.style === "style1" || Settings.bar.style === "style2") ? ScalerService.s(10) : 0 : 0
        bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? (Settings.bar.style === "style1" || Settings.bar.style === "style2") ? ScalerService.s(10) : 0 : 0
    }

    Loader {
        anchors.fill: parent
        source: isVertical ? `./layout/${Settings.bar.style}/VerticalLayout.qml` : `./layout/${Settings.bar.style}/HorizontalLayout.qml`
    }
}
