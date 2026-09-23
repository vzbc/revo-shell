pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland._Screencopy
import "../../wm"
import "../../bar"
import "../../../"

Item {
    id: root

    readonly property int discRadius: Math.round(WorkspaceDiscService.discRadius * UIScale.value)
    readonly property int chamberRadius: Math.round(WorkspaceDiscService.chamberRadius * UIScale.value)
    readonly property int chamberSize: Math.round(WorkspaceDiscService.chamberSize * UIScale.value)
    readonly property int pad: Math.round(16 * UIScale.value)
    readonly property int workSpaceAmount: WorkspaceDiscService.workSpaceAmount

    // Which output this disc represents. When unset, falls back to the single globally
    // focused monitor.
    property var screen: null

    property bool atCorner: false
    property bool cornerFlip: false

    // Prevents startup animation
    property bool positionResolved: true

    implicitWidth: (discRadius + pad) * 2
    implicitHeight: (discRadius + pad) * 2

    readonly property var sortedWsIds: {
        var ids = WmService.workspaces.map(w => parseInt(w.name)).filter(n => !isNaN(n) && n > 0);
        ids.sort((a, b) => a - b);
        return ids;
    }

    readonly property int effectiveN: WorkspaceDiscService.expressive ? Math.max(WorkspaceDiscService.minWorkSpaceAmount, root.sortedWsIds.length) : root.workSpaceAmount

    readonly property int activeIndex: {
        var active = root.screen ? WmService.activeWorkspaceFor(root.screen) : WmService.focusedMonitor?.activeWorkspace;
        if (!active)
            return 0;
        var id = parseInt(active.name);
        if (isNaN(id))
            return 0;
        if (WorkspaceDiscService.expressive) {
            var idx = root.sortedWsIds.indexOf(id);
            return idx >= 0 ? idx : 0;
        }
        return Math.max(0, Math.min(root.effectiveN - 1, id - 1));
    }

    readonly property bool _flipPerp: BarConfig.side === "bottom" || BarConfig.side === "right"

    readonly property real _peekAngle: {
        if (BarConfig.side === "top")
            return 90;
        if (BarConfig.side === "bottom")
            return 270;
        if (BarConfig.side === "right")
            return 180;
        return 0; // left
    }

    // At a sticky corner the gear, the angle points diagonally
    readonly property bool _flipX: BarConfig.isVertical ? root._flipPerp : root.cornerFlip
    readonly property bool _flipY: BarConfig.isVertical ? root.cornerFlip : root._flipPerp
    readonly property real _cornerAngle: {
        if (!root._flipX && !root._flipY)
            return 45;
        if (root._flipX && !root._flipY)
            return 135;
        if (root._flipX && root._flipY)
            return 225;
        return -45; // !flipX && flipY
    }

    property bool forceExpanded: false
    property bool _hoveredExpanded: false

    readonly property bool _interactive: root.forceExpanded || root._hoveredExpanded
    readonly property bool expanded: root.forceExpanded || (WorkspaceDiscService.animateTransition && root._hoveredExpanded)

    readonly property real discRotation: disc.rotation

    // tuckEnabled makes it hug the bar's own perpendicular edge on idle,
    // the parallel axis only needs its own idle/expand split when it is also
    // at a corner.
    readonly property bool _tuck: WorkspaceDiscService.tuckEnabled
    readonly property bool _cornerTuck: root._tuck && root.atCorner

    readonly property real _cornerPeek: root.pad
    function _parallelCoord(size) {
        if (!root._cornerTuck)
            return root.discRadius + root.pad;
        if (root.expanded)
            return root.cornerFlip ? size - root.discRadius - root.pad : root.discRadius + root.pad;
        return root.cornerFlip ? size - root._cornerPeek : root._cornerPeek;
    }

    // Peek/expand animation along the bar's short axis.
    readonly property real _idleBarCenterOffset: BarConfig.edgeGap + Math.round(25 * UIScale.value)
    function _perpCoord(size) {
        if (root.expanded)
            return root._flipPerp ? size - root.discRadius - root.pad : root.discRadius + root.pad;
        if (root._tuck)
            return root._flipPerp ? size - root._cornerPeek : root._cornerPeek;
        return root._flipPerp ? size - root._idleBarCenterOffset : root._idleBarCenterOffset;
    }

    readonly property real discCX: BarConfig.isVertical ? root._perpCoord(root.width) : root._parallelCoord(root.width)
    readonly property real discCY: BarConfig.isVertical ? root._parallelCoord(root.height) : root._perpCoord(root.height)

    // Animated center, tracks the disc's actual visual position during transitions
    readonly property real visualDiscCX: disc.x + discRadius
    readonly property real visualDiscCY: disc.y + discRadius

    readonly property real _skinOrbitRadius: skinLoader.item?.orbitRadius ?? root.chamberRadius

    property var barZoneRow: null

    property real overlayMargin: 0

    // We convert the point already in this window's local coordinates into the
    // bar window's local coordinates.
    function _overlayToBarLocal(p) {
        var overlaySize = (root.discRadius + root.pad) * 2;
        var barThickness = Math.round(50 * UIScale.value);
        var perpOffset = root._flipPerp ? (BarConfig.edgeGap + barThickness - overlaySize) : -BarConfig.edgeGap;
        if (BarConfig.isVertical)
            return Qt.point(p.x + perpOffset, p.y + root.overlayMargin);
        return Qt.point(p.x + root.overlayMargin, p.y + perpOffset);
    }

    property bool _dragging: false

    Timer {
        id: collapseTimer
        interval: Anim.slow
        onTriggered: root._hoveredExpanded = false
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                collapseTimer.stop();
                root._hoveredExpanded = true;
            } else {
                collapseTimer.restart();
            }
        }
    }

    Item {
        id: disc
        width: root.discRadius * 2
        height: root.discRadius * 2
        opacity: root._dragging ? 0.3 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Anim.fast
            }
        }

        x: root.discCX - root.discRadius
        y: root.discCY - root.discRadius

        Behavior on x {
            enabled: root.positionResolved
            NumberAnimation {
                duration: Anim.slow
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on y {
            enabled: root.positionResolved
            NumberAnimation {
                duration: Anim.slow
                easing.type: Easing.InOutCubic
            }
        }

        rotation: (root._cornerTuck ? root._cornerAngle : root._peekAngle) + root.activeIndex * (360 / root.effectiveN)

        Behavior on rotation {
            enabled: root.positionResolved
            RotationAnimation {
                duration: Anim.slow
                direction: RotationAnimation.Shortest
                easing.type: Easing.InOutCubic
            }
        }

        DragHandler {
            id: dragHandler
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType

            onActiveChanged: {
                var row = root.barZoneRow;
                if (active) {
                    var p0 = root._overlayToBarLocal(disc.mapToItem(root, disc.width / 2, disc.height / 2));
                    if (row)
                        row.beginWorkspaceDrag(disc.width, disc.height, p0.x, p0.y);
                    if (disc.grabToImage)
                        disc.grabToImage(function (result) {
                            if (row)
                                row.setWorkspaceDragGrab(result);
                        });
                } else if (row) {
                    row.endWorkspaceDrag();
                }
                root._dragging = active;
            }
            onCentroidChanged: {
                if (!active)
                    return;
                var p = root._overlayToBarLocal(disc.mapToItem(root, centroid.position.x, centroid.position.y));
                if (root.barZoneRow)
                    root.barZoneRow.updateWorkspaceDragPos(p.x, p.y);
            }
        }

        Item {
            id: ringLayer
            anchors.fill: parent

            Loader {
                id: skinLoader
                anchors.fill: parent
                source: {
                    var name = WorkspaceDiscService.skin;
                    return "skins/WorkspaceDiscSkin" + name.charAt(0).toUpperCase() + name.slice(1) + ".qml";
                }
                onLoaded: {
                    item.discRadius = Qt.binding(() => root.discRadius);
                    item.effectiveN = Qt.binding(() => root.effectiveN);
                }
            }

            Component {
                id: defaultChamber
                Rectangle {
                    property bool isActive: false
                    property bool hasWindows: false
                    radius: width / 2
                    color: isActive ? Colors.accent : Colors.surfaceHigh
                    border.color: isActive ? Colors.withAlpha(Colors.onAccent, 0.6) : Colors.withAlpha(Colors.accent, 0.2)
                    border.width: 1
                }
            }

            Repeater {
                model: root.effectiveN
                delegate: Item {
                    id: wsItem
                    required property int index

                    property int wsIndex: WorkspaceDiscService.expressive ? (root.sortedWsIds[wsItem.index] ?? wsItem.index + 1) : wsItem.index + 1
                    property bool isActive: wsItem.index === root.activeIndex
                    property bool hasWindows: WmService.toplevels.some(t => t.workspace && parseInt(t.workspace.name) === wsItem.wsIndex)

                    readonly property real _orbit: root._skinOrbitRadius

                    width: root.chamberSize
                    height: root.chamberSize
                    x: root.discRadius + Math.cos(wsItem.index * 2 * Math.PI / root.effectiveN) * wsItem._orbit - root.chamberSize / 2
                    y: root.discRadius - Math.sin(wsItem.index * 2 * Math.PI / root.effectiveN) * wsItem._orbit - root.chamberSize / 2

                    Loader {
                        anchors.fill: parent
                        rotation: (skinLoader.item?.counterRotateChambers ?? true) ? -root.discRotation : 0
                        sourceComponent: skinLoader.item?.chamberDelegate ?? defaultChamber
                        onLoaded: {
                            item.isActive = Qt.binding(() => wsItem.isActive);
                            item.hasWindows = Qt.binding(() => wsItem.hasWindows);
                            if ("chamberAngle" in item)
                                item.chamberAngle = Qt.binding(() => wsItem.index * (360.0 / root.effectiveN));
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsItem.wsIndex
                        font.pixelSize: UIScale.fontTiny
                        font.bold: wsItem.isActive
                        color: wsItem.isActive ? (skinLoader.item?.activeNumberColor ?? Colors.surface) : Colors.text
                        rotation: -root.discRotation
                    }

                    MouseArea {
                        id: chamberMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root._interactive)
                                WmService.focusWorkspace(wsItem.wsIndex);
                        }
                    }

                    PopupWindow {
                        id: wsPopup
                        visible: chamberMouseArea.containsMouse && root._interactive && wsItem.hasWindows
                        color: "transparent"

                        anchor.item: wsItem
                        anchor.edges: Edges.Right | Edges.Top
                        anchor.gravity: Edges.Right | Edges.Bottom
                        anchor.adjustment: PopupAdjustment.All
                        anchor.margins.left: 8

                        property var wsMonitor: {
                            var ws = WmService.workspaces.find(w => parseInt(w.name) === wsItem.wsIndex);
                            return (ws && ws.monitor) ? ws.monitor : WmService.focusedMonitor;
                        }

                        readonly property int thumbW: 420
                        readonly property int thumbH: wsMonitor ? Math.round(thumbW * wsMonitor.height / wsMonitor.width) : 158
                        readonly property real thumbScale: wsMonitor ? thumbW / wsMonitor.width : 1
                        readonly property real monOffX: wsMonitor ? wsMonitor.x : 0
                        readonly property real monOffY: wsMonitor ? wsMonitor.y : 0

                        implicitWidth: thumbW + 2
                        implicitHeight: thumbH + 2

                        onVisibleChanged: if (visible)
                            WmService.refreshToplevels()

                        Loader {
                            active: wsPopup.visible
                            anchors.fill: parent
                            sourceComponent: Rectangle {
                                color: Colors.bg
                                border.color: Colors.withAlpha(Colors.accent, 0.35)
                                border.width: 1
                                radius: 6
                                clip: true

                                Item {
                                    x: 1
                                    y: 1
                                    width: wsPopup.thumbW
                                    height: wsPopup.thumbH
                                    clip: true

                                    Repeater {
                                        model: WmService.toplevels.filter(t => t.workspace && parseInt(t.workspace.name) === wsItem.wsIndex)
                                        delegate: Item {
                                            id: winItem
                                            required property var modelData

                                            x: {
                                                var at = winItem.modelData.lastIpcObject["at"];
                                                return at ? (at[0] - wsPopup.monOffX) * wsPopup.thumbScale : 0;
                                            }
                                            y: {
                                                var at = winItem.modelData.lastIpcObject["at"];
                                                return at ? (at[1] - wsPopup.monOffY) * wsPopup.thumbScale : 0;
                                            }
                                            width: {
                                                var sz = winItem.modelData.lastIpcObject["size"];
                                                return sz ? sz[0] * wsPopup.thumbScale : 50;
                                            }
                                            height: {
                                                var sz = winItem.modelData.lastIpcObject["size"];
                                                return sz ? sz[1] * wsPopup.thumbScale : 50;
                                            }

                                            ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: winItem.modelData.wayland
                                                live: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
