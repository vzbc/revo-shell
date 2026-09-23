pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland._Screencopy
import "../wm"
import "../../"

Item {
    id: root

    // Parent item for drag re-parenting, caller should pass a stable container
    property Item dragParent: root

    // Drag state
    property int _dragFromWs: -1
    property string _draggingAddr: ""  // address of window currently being dragged
    property int _dragOverTileCount: 0 // how many workspace tiles the drag is currently over
    property bool _showNewWsTile: false
    property bool _newTileDropHandled: false

    readonly property var wsMonitor: WmService.focusedMonitor
    readonly property real monW: (wsMonitor ? wsMonitor.width / (wsMonitor.scale || 1) : 1920)
    readonly property real monH: (wsMonitor ? wsMonitor.height / (wsMonitor.scale || 1) : 1080)

    readonly property var allWorkspaces: {
        var ws = WmService.workspaces.filter(w => w.name !== "qs_drag_temp").slice();
        ws.sort((a, b) => (parseInt(a.name) || 0) - (parseInt(b.name) || 0));
        return ws;
    }

    // cols fixed by actual workspace count so tileW doesn't change when "+" tile appears
    readonly property int cols: Math.min(root.allWorkspaces.length, 3)
    readonly property int _totalItems: root.allWorkspaces.length + (root._showNewWsTile ? 1 : 0)
    readonly property int rows: Math.ceil(root._totalItems / Math.max(root.cols, 1))
    readonly property real gap: 16
    readonly property real tileW: root.width > 0 ? Math.floor((root.width - gap * (cols + 1)) / cols) : 200
    readonly property real tileH: Math.round(tileW * root.monH / root.monW)

    implicitWidth: cols * tileW + gap * (cols + 1)
    implicitHeight: rows * tileH + gap * (rows + 1)

    // Start the "show new workspace" timer when drag leaves all tiles.
    // Only eligible if source workspace has >1 window (so it won't be emptied).
    function _checkOutsideTimer() {
        if (root._draggingAddr !== "" && root._dragOverTileCount === 0) {
            var srcWs = root.allWorkspaces.find(w => parseInt(w.name) === root._dragFromWs);
            if (srcWs && srcWs.toplevels.values.length > 1) {
                if (!outsideTimer.running)
                    outsideTimer.start();
                return;
            }
        }
        outsideTimer.stop();
    }

    Timer {
        id: outsideTimer
        interval: 1000
        repeat: false
        onTriggered: root._showNewWsTile = true
    }

    Flow {
        anchors.fill: parent
        anchors.margins: root.gap
        spacing: root.gap

        Repeater {
            model: root.allWorkspaces

            Item {
                id: tile
                required property var modelData
                required property int index

                readonly property int wsId: parseInt(tile.modelData.name) || (tile.index + 1)
                readonly property bool isSelected: AppSwitcherService.selectedWorkspace === tile.wsId

                readonly property var wsMon: tile.modelData.monitor ? tile.modelData.monitor : root.wsMonitor
                readonly property real _wsMonW: tile.wsMon ? tile.wsMon.width / (tile.wsMon.scale || 1) : root.monW
                readonly property real scaleFactor: tile._wsMonW > 0 ? (root.tileW / tile._wsMonW) : 1

                readonly property var stackedToplevels: {
                    var arr = tile.modelData.toplevels.values.slice();
                    arr.sort((a, b) => {
                        var af = a.lastIpcObject["floating"] ? 1 : 0;
                        var bf = b.lastIpcObject["floating"] ? 1 : 0;
                        return af - bf;
                    });
                    return arr;
                }

                // Hover tracking, updated by the DropArea as a drag moves across the tile
                property string dropTargetAddr: ""
                property string dropTargetSide: "" // "l", "r", "t", "b"

                function findDropTarget(dx, dy) {
                    var tops = tile.stackedToplevels;
                    var monOX = tile.wsMon ? tile.wsMon.x : 0;
                    var monOY = tile.wsMon ? tile.wsMon.y : 0;
                    var sf = tile.scaleFactor;
                    // Walk topmost-first so an overlapping floating window wins
                    // the hit test over a tiled window underneath it.
                    for (var i = tops.length - 1; i >= 0; i--) {
                        var at = tops[i].lastIpcObject["at"];
                        var sz = tops[i].lastIpcObject["size"];
                        var addr = tops[i].lastIpcObject["address"] ?? "";
                        if (!at || !sz || !addr)
                            continue;
                        // +2 for clip margin offset
                        var wx = (at[0] - monOX) * sf + 2;
                        var wy = (at[1] - monOY) * sf + 2;
                        var ww = sz[0] * sf;
                        var wh = sz[1] * sf;
                        if (dx >= wx && dx <= wx + ww && dy >= wy && dy <= wy + wh) {
                            // Diagonal-quadrant detection from center: whichever axis
                            // the cursor is further from center on determines the side.
                            // This gives 4 equal triangular zones instead of a 30/70 band
                            // that always eats top/bottom when near the corners.
                            var relX = (dx - wx) - ww / 2;
                            var relY = (dy - wy) - wh / 2;
                            var side;
                            if (Math.abs(relX) > Math.abs(relY))
                                side = relX < 0 ? "l" : "r";
                            else
                                side = relY < 0 ? "t" : "b";
                            return {
                                addr: addr,
                                side: side
                            };
                        }
                    }
                    return null;
                }

                width: root.tileW
                height: root.tileH

                DropArea {
                    anchors.fill: parent

                    onEntered: {
                        if (root._draggingAddr !== "") {
                            root._dragOverTileCount++;
                            outsideTimer.stop();
                        }
                    }

                    onPositionChanged: function (drag) {
                        var hit = tile.findDropTarget(drag.x, drag.y);
                        tile.dropTargetAddr = hit ? hit.addr : "";
                        tile.dropTargetSide = hit ? hit.side : "";
                    }

                    onExited: {
                        tile.dropTargetAddr = "";
                        tile.dropTargetSide = "";
                        if (root._draggingAddr !== "") {
                            root._dragOverTileCount = Math.max(0, root._dragOverTileCount - 1);
                            root._checkOutsideTimer();
                        }
                    }

                    onDropped: function (drag) {
                        // Capture before clearing
                        var targetAddr = tile.dropTargetAddr;
                        var side = tile.dropTargetSide;
                        tile.dropTargetAddr = "";
                        tile.dropTargetSide = "";

                        var addr = drag.source.windowAddress;
                        if (!addr)
                            return;

                        if (targetAddr && targetAddr !== addr) {
                            // Arm dwindle's preselect: t->u, b->d, l->l, r->r
                            var dwindleDir = ({
                                    "t": "u",
                                    "b": "d",
                                    "l": "l",
                                    "r": "r"
                                })[side] || "r";

                            if (root._dragFromWs === tile.wsId) {
                                // Same-workspace rearrange: focus target so dwindle splits its space,
                                // then park in temp workspace and re-add. Always follows since we're
                                // already on this workspace.
                                WmService.focusWindow(targetAddr);
                                WmService.preselect(dwindleDir);
                                WmService.moveWindowToName(addr, "qs_drag_temp");
                                WmService.moveWindow(addr, tile.wsId);
                            } else if (AppSwitcherService.followMovedWindow) {
                                // Cross-workspace, follow mode: focus target (switches workspace),
                                // arm dwindle, then move the dragged window in.
                                WmService.focusWindow(targetAddr);
                                WmService.preselect(dwindleDir);
                                WmService.moveWindow(addr, tile.wsId);
                            } else {
                                // Cross-workspace, silent mode: preselect only affects the active
                                // workspace, so targeted placement isn't possible here without a
                                // visible workspace switch. Just move silently.
                                WmService.moveWindowSilent(addr, tile.wsId);
                            }
                        } else {
                            // No specific target, drop onto empty space, always silent
                            WmService.moveWindowSilent(addr, tile.wsId);
                        }

                        WmService.refreshToplevels();
                        WmService.refreshWorkspaces();
                    }
                }

                // Tile background + border
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Colors.surface
                    border.color: tile.isSelected ? Colors.accent : Colors.outline
                    border.width: tile.isSelected ? 2 : 1
                    Behavior on border.color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                // Workspace number label (behind windows, shown when empty)
                Text {
                    anchors.centerIn: parent
                    text: tile.wsId
                    font.pixelSize: 22
                    font.bold: true
                    color: Colors.withAlpha(Colors.muted, 0.4)
                    visible: tile.modelData.toplevels.values.length === 0
                }

                // Clip area for window thumbnails
                Item {
                    id: thumbClip
                    anchors.fill: parent
                    anchors.margins: 2
                    clip: true

                    Repeater {
                        model: tile.stackedToplevels

                        Item {
                            id: winTile
                            required property var modelData

                            readonly property string windowAddress: winTile.modelData.lastIpcObject["address"] ?? ""
                            readonly property bool isDropTarget: tile.dropTargetAddr === winTile.windowAddress && winTile.windowAddress !== ""
                            readonly property bool isDragging: root._draggingAddr === winTile.windowAddress

                            opacity: winTile.isDragging ? 0 : 1
                            readonly property var _at: winTile.modelData.lastIpcObject["at"]
                            readonly property var _sz: winTile.modelData.lastIpcObject["size"]
                            readonly property real monOffX: tile.wsMon ? tile.wsMon.x : 0
                            readonly property real monOffY: tile.wsMon ? tile.wsMon.y : 0

                            x: (_at && _at.length >= 2) ? (_at[0] - monOffX) * tile.scaleFactor : 0
                            y: (_at && _at.length >= 2) ? (_at[1] - monOffY) * tile.scaleFactor : 0
                            width: (_sz && _sz.length >= 2) ? _sz[0] * tile.scaleFactor : 40
                            height: (_sz && _sz.length >= 2) ? _sz[1] * tile.scaleFactor : 30

                            ScreencopyView {
                                id: scView
                                x: 0
                                y: 0
                                width: winTile.width
                                height: winTile.height
                                captureSource: winTile.modelData.wayland
                                live: true

                                scale: dragHandler.active ? 0.55 : 1.0
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Anim.fast
                                        easing.type: Easing.OutBack
                                    }
                                }

                                property string windowAddress: winTile.windowAddress

                                DragHandler {
                                    id: dragHandler
                                    target: scView
                                    onActiveChanged: {
                                        if (active) {
                                            root._dragFromWs = tile.wsId;
                                            root._draggingAddr = winTile.windowAddress;
                                            root._dragOverTileCount = 0;
                                            root._newTileDropHandled = false;
                                            // The source tile's DropArea will fire onEntered shortly
                                            // which increments the count; don't start timer here.
                                        } else {
                                            var wasShowingNew = root._showNewWsTile;
                                            var wasAddr = root._draggingAddr;
                                            scView.Drag.drop();
                                            outsideTimer.stop();
                                            root._showNewWsTile = false;
                                            root._dragOverTileCount = 0;
                                            root._dragFromWs = -1;
                                            root._draggingAddr = "";
                                            // If the + tile appeared under a stationary cursor,
                                            // DropArea.onEntered never fired so onDropped won't either.
                                            // Handle the drop here if the DropArea didn't catch it.
                                            if (wasShowingNew && wasAddr && !root._newTileDropHandled) {
                                                var nextId = AppSwitcherService.nextWorkspaceId();
                                                WmService.moveWindowSilent(wasAddr, nextId);
                                                WmService.refreshToplevels();
                                                WmService.refreshWorkspaces();
                                            }
                                        }
                                    }
                                }

                                Drag.active: dragHandler.active
                                Drag.source: scView
                                Drag.supportedActions: Qt.MoveAction
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                states: State {
                                    when: dragHandler.active
                                    ParentChange {
                                        target: scView
                                        parent: root.dragParent
                                    }
                                }
                            }

                            // Drop-target highlight overlay
                            Rectangle {
                                anchors.fill: parent
                                visible: winTile.isDropTarget
                                color: Colors.withAlpha(Colors.accent, 0.18)
                                radius: 3

                                // Side indicator, a bright bar on the drop side
                                Rectangle {
                                    visible: tile.dropTargetSide !== ""
                                    color: Colors.accent
                                    x: tile.dropTargetSide === "r" ? parent.width - 3 : 0
                                    y: tile.dropTargetSide === "b" ? parent.height - 3 : 0
                                    width: (tile.dropTargetSide === "l" || tile.dropTargetSide === "r") ? 3 : parent.width
                                    height: (tile.dropTargetSide === "t" || tile.dropTargetSide === "b") ? 3 : parent.height
                                }
                            }
                        }
                    }
                }

                // Workspace label chip
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    width: 22
                    height: 22
                    radius: 11
                    color: tile.isSelected ? Colors.accent : Colors.withAlpha(Colors.accent, 0.25)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: tile.wsId
                        font.pixelSize: 11
                        font.bold: true
                        color: tile.isSelected ? Colors.surface : Colors.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        AppSwitcherService.selectedWorkspace = tile.wsId;
                        AppSwitcherService.confirmWorkspace();
                    }
                }
            }
        }

        // "Create new workspace" drop target, appears after 1s of dragging outside all tiles
        Item {
            id: newWsTile
            width: root.tileW
            height: root.tileH
            visible: root._showNewWsTile
            opacity: root._showNewWsTile ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }

            property bool isDragOver: false

            DropArea {
                anchors.fill: parent
                onEntered: newWsTile.isDragOver = true
                onExited: newWsTile.isDragOver = false
                onDropped: function (drag) {
                    root._newTileDropHandled = true;
                    newWsTile.isDragOver = false;
                    var addr = drag.source.windowAddress;
                    if (!addr)
                        return;
                    var nextId = AppSwitcherService.nextWorkspaceId();
                    WmService.moveWindowSilent(addr, nextId);
                    WmService.refreshToplevels();
                    WmService.refreshWorkspaces();
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: newWsTile.isDragOver ? Colors.withAlpha(Colors.accent, 0.18) : Colors.withAlpha(Colors.accent, 0.06)
                border.color: Colors.accent
                border.width: newWsTile.isDragOver ? 2 : 1.5

                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on border.width {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 36
                    font.weight: Font.Light
                    color: Colors.accent
                    opacity: newWsTile.isDragOver ? 1.0 : 0.6

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                        }
                    }
                }
            }
        }
    }
}
