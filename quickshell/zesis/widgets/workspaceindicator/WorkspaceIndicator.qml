pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "./disc"
import "../bar"
import "../../"

// The workspace bar atom
// The actual pixels are painted by the PanelWindow nested.
Item {
    id: root

    property string screenName: ""

    property var barZoneRow: null

    readonly property bool available: WorkspaceDiscService.monitors.length === 0 || WorkspaceDiscService.monitors.includes(root.screenName)

    readonly property real _restRadius: Math.round(WorkspaceDiscService.discRadius * UIScale.value)
    implicitWidth: root._restRadius * 2
    implicitHeight: implicitWidth

    readonly property var _screen: Quickshell.screens.find(s => s.name === root.screenName) || null
    readonly property real _stripSpan: root._screen ? (BarConfig.isVertical ? root._screen.height : root._screen.width) : 0

    // Pushed by BarZoneRow._publishWorkspaceRect
    property real atomPos: 0
    property real atomSize: 0
    property bool atCorner: false
    property bool cornerFlip: false

    property bool _positionResolved: false

    function setAtomRect(rect) {
        root.atomPos = rect.pos;
        root.atomSize = rect.size;
        root.atCorner = rect.atCorner;
        root.cornerFlip = rect.cornerFlip;
        root._positionResolved = true;
    }
    function clearAtomRect() {
        root.atomSize = 0;
    }

    readonly property bool _cornerTuck: root.atCorner && WorkspaceDiscService.tuckEnabled

    property real slideMargin: {
        var size = BarConfig.isVertical ? overlay.height : overlay.width;
        if (root._cornerTuck)
            return root.cornerFlip ? Math.max(0, root._stripSpan - size) : 0;
        if (root.atomSize <= 0)
            return 0;
        var ideal = root.atomPos - size / 2;
        return Math.max(0, Math.min(root._stripSpan - size, ideal));
    }

    Behavior on slideMargin {
        enabled: root._positionResolved
        NumberAnimation {
            duration: Anim.slow
            easing.type: Easing.InOutCubic
        }
    }

    PanelWindow {
        id: overlay

        screen: root._screen
        visible: root.available

        WlrLayershell.layer: WlrLayer.Top

        anchors {
            top: BarConfig.side === "top" || BarConfig.isVertical
            bottom: BarConfig.side === "bottom"
            left: BarConfig.side === "left" || !BarConfig.isVertical
            right: BarConfig.side === "right"
        }
        margins {
            left: BarConfig.isVertical ? 0 : root.slideMargin
            top: BarConfig.isVertical ? root.slideMargin : 0
        }
        exclusiveZone: -1
        implicitWidth: disc.implicitWidth
        implicitHeight: disc.implicitHeight
        color: "transparent"

        mask: Region {
            shape: RegionShape.Ellipse
            x: disc.visualDiscCX - disc.discRadius
            y: disc.visualDiscCY - disc.discRadius
            width: disc.discRadius * 2
            height: disc.discRadius * 2
        }

        WorkspaceDisc {
            id: disc
            anchors.fill: parent
            screen: root._screen
            atCorner: root.atCorner
            cornerFlip: root.cornerFlip
            barZoneRow: root.barZoneRow
            overlayMargin: root.slideMargin
            positionResolved: root._positionResolved
        }
    }
}
