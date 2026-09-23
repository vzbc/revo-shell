pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

PanelWindow {
    id: root

    readonly property real panelW: Math.round(360 * UIScale.value)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors {
        top: true
        right: true
        bottom: true
    }
    exclusiveZone: 0
    implicitWidth: panelW
    color: "transparent"
    visible: false

    property bool _whOpen: WidgetHomeService.open
    on_WhOpenChanged: {
        if (_whOpen) {
            sidebarRect.offsetScale = 1;
            visible = true;
            slideIn.start();
            sidebarRect.forceActiveFocus();
        } else {
            slideOut.start();
        }
    }

    NumberAnimation {
        id: slideIn
        target: sidebarRect
        property: "offsetScale"
        to: 0
        duration: Anim.slow
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.emphasizedDecel
    }

    NumberAnimation {
        id: slideOut
        target: sidebarRect
        property: "offsetScale"
        to: 1
        duration: Anim.medium
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anim.emphasizedAccel
        onFinished: root.visible = false
    }

    Rectangle {
        id: sidebarRect
        property real offsetScale: 1

        anchors.top: parent.top
        anchors.topMargin: 60
        width: root.panelW
        height: WidgetHomeService.anySelected ? Math.round(490 * UIScale.value) : Math.round(295 * UIScale.value)
        Behavior on height {
            NumberAnimation {
                duration: Anim.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anim.spatial
            }
        }
        topLeftRadius: Math.round(12 * UIScale.value)
        bottomLeftRadius: Math.round(12 * UIScale.value)
        x: root.panelW * offsetScale
        opacity: 1 - offsetScale
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1

        WidgetHomePanel {
            anchors.fill: parent
        }
    }
}
