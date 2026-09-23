pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

PanelWindow {
    id: root

    property real dimmerOpacity: 0.45
    property color dimmerColor: "black"
    property real initialScale: 0
    property real showOvershoot: 1.4
    property real maxContentWidth: 0
    property real maxContentHeight: 0
    property Component content: null

    signal dimmerTapped
    signal contentLoaded(var item)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: -1
    color: "transparent"
    visible: false

    function open() {
        if (!visible) {
            dimmer.opacity = 0;
            overlayContent.scale = initialScale;
            overlayContent.opacity = 0;
            visible = true;
        }
        hideAnim.stop();
        showAnim.start();
    }

    function close() {
        if (!visible)
            return;
        showAnim.stop();
        hideAnim.start();
    }

    onVisibleChanged: {
        if (!visible) {
            dimmer.opacity = 0;
            overlayContent.scale = initialScale;
            overlayContent.opacity = 0;
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation {
            target: dimmer
            property: "opacity"
            to: root.dimmerOpacity
            duration: Anim.medium
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: overlayContent
            property: "opacity"
            to: 1
            duration: Anim.medium
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: overlayContent
            property: "scale"
            to: 1
            duration: Anim.slow
            easing.type: Easing.OutBack
            easing.overshoot: root.showOvershoot
        }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation {
            target: dimmer
            property: "opacity"
            to: 0
            duration: Anim.medium
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: overlayContent
            property: "opacity"
            to: 0
            duration: Anim.fast
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: overlayContent
            property: "scale"
            to: root.initialScale
            duration: Anim.fast
            easing.type: Easing.InCubic
        }
        onStopped: root.visible = false
    }

    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: root.dimmerColor
        opacity: 0

        TapHandler {
            onTapped: root.dimmerTapped()
        }
    }

    Item {
        id: overlayContent
        anchors.centerIn: parent
        width: root.maxContentWidth > 0 ? Math.min(root.width - 80, root.maxContentWidth) : root.width
        height: root.maxContentHeight > 0 ? Math.min(root.height - 80, root.maxContentHeight) : root.height
        scale: root.initialScale
        opacity: 0

        Loader {
            anchors.fill: parent
            active: root.visible
            sourceComponent: root.content
            onLoaded: root.contentLoaded(item)
        }
    }
}
