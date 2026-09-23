pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar"
import "../../"

// Taskbar pill. Groups open windows by appId,
// shows one icon per app with macOS-style dots and a hover popup.
Item {
    id: root

    readonly property int _itemSz: Math.round(44 * UIScale.value)
    readonly property int _gap: Math.round(2 * UIScale.value)
    readonly property bool _vertical: BarConfig.isVertical

    // Deduplicated, ordered list of appIds from open toplevels
    readonly property var _appIds: {
        var seen = {};
        var result = [];
        var arr = ToplevelManager.toplevels.values;
        for (var i = 0; i < arr.length; i++) {
            var t = arr[i];
            if (!t.appId)
                continue;
            var key = t.appId.toLowerCase();
            if (!seen[key]) {
                seen[key] = true;
                result.push(t.appId);
            }
        }
        return result;
    }

    readonly property bool available: _appIds.length > 0
    visible: available

    readonly property int _pillLength: _appIds.length > 0 ? _appIds.length * (_itemSz + _gap) - _gap : 0

    implicitWidth: _vertical ? _itemSz : _pillLength
    implicitHeight: _vertical ? _pillLength : _itemSz

    Grid {
        anchors.centerIn: parent
        columns: root._vertical ? 1 : root._appIds.length
        rows: root._vertical ? root._appIds.length : 1
        spacing: root._gap

        Repeater {
            model: root._appIds
            delegate: TaskbarItem {
                required property string modelData
                appId: modelData
                itemSize: root._itemSz
            }
        }
    }
}
