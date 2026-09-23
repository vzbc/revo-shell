pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services

Singleton {
    id: root

    property bool isNiri: false
    property bool isHyprland: false
    property bool isSway: false

    property var lockscreen: null

    property ListModel workspaces: ListModel {}
    property ListModel windows: ListModel {}
    property int focusedWindowIndex: -1

    property alias displayScales: displayCacheAdapter.displays
    property bool displayScalesLoaded: false

    property var backend: null
    property string displayCachePath: Directories.shellDisplayCachePath

    // --- BỔ SUNG STATE & LOGIC CHO WORKSPACE UI ---
    property var uiWorkspaces: []
    property string activeWorkspace: "1"
    property real scrollAccumulator: 0

    signal workspaceChanged
    signal activeWindowChanged
    signal windowListChanged

    Timer {
        id: idleResetTimer
        interval: 80
        repeat: false
        onTriggered: root.scrollAccumulator = 0
    }

    Component.onCompleted: {
        detectCompositor();
    }

    FileView {
        id: displayCacheFileView
        path: root.displayCachePath
        printErrors: false
        watchChanges: false
        onLoaded: {
            root.displayScalesLoaded = true;
        }
        onLoadFailed: {
            root.displayScalesLoaded = true;
        }
        onAdapterUpdated: {
            writeAdapter();
        }

        JsonAdapter {
            id: displayCacheAdapter
            property var displays: ({})
        }
    }

    function detectCompositor() {
        const niriSocket = Quickshell.env("NIRI_SOCKET");
        const hyprlandSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
        const swaySock = Quickshell.env("SWAYSOCK");

        if (niriSocket && niriSocket.length > 0) {
            isNiri = true;
            backendLoader.sourceComponent = niriComponent;
        } else if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true;
            backendLoader.sourceComponent = hyprlandComponent;
        } else if (swaySock && swaySock.length > 0) {
            isSway = true;
        } else {
            isNiri = true;
            backendLoader.sourceComponent = niriComponent;
        }
    }

    Loader {
        id: backendLoader
        onLoaded: {
            if (item) {
                root.backend = item;
                root.setupBackendConnections();
                root.backend.initialize();
            }
        }
    }

    Component {
        id: niriComponent
        NiriService {}
    }
    Connections {
        target: Settings.bar

        function onWorkspaceCountChanged() {
            syncWorkspaces();
        }
    }
    Component {
        id: hyprlandComponent
        HyprlandService {}
    }

    function setupBackendConnections() {
        if (!backend)
            return;

        backend.workspaceChanged.connect(() => {
            syncWorkspaces();
            workspaceChanged();
        });

        backend.activeWindowChanged.connect(() => {
            syncWindows();
            activeWindowChanged();
        });

        backend.windowListChanged.connect(() => {
            syncWindows();
            windowListChanged();
        });

        backend.focusedWindowIndexChanged.connect(() => {
            focusedWindowIndex = backend.focusedWindowIndex;
        });

        syncWorkspaces();
        syncWindows();

        focusedWindowIndex = backend.focusedWindowIndex;
    }

    function syncWorkspaces() {
        workspaces.clear();
        const ws = backend ? backend.workspaces : null;
        if (!ws)
            return;

        var wsMap = {};
        for (var i = 0; i < ws.count; i++) {
            var item = ws.get(i);
            workspaces.append(item);
            if (item && item.id) {
                wsMap[item.id.toString()] = item;
                if (item.isActive || item.isFocused) {
                    activeWorkspace = item.id.toString();
                }
            }
        }

        // Tự động build lại mảng uiWorkspaces cho UI dùng
        var count = Settings.bar.workspaceCount || 10;
        var arr = [];
        for (var j = 1; j <= count; j++) {
            var idStr = j.toString();
            var wsData = wsMap[idStr];
            arr.push({
                id: idStr,
                exists: wsData ? (wsData.isOccupied || false) : false,
                isActive: idStr === activeWorkspace
            });
        }
        uiWorkspaces = arr;
    }

    function syncWindows() {
        windows.clear();
        const ws = backend ? backend.windows : [];
        for (var i = 0; i < ws.length; i++) {
            windows.append(ws[i]);
        }
        windowListChanged();
    }

    function switchToWorkspaceById(wsId) {
        if (!backend || !wsId)
            return;
        var workspaceObj = null;
        for (var i = 0; i < workspaces.count; i++) {
            var ws = workspaces.get(i);
            if (ws && ws.id.toString() === wsId.toString()) {
                workspaceObj = ws;
                break;
            }
        }
        if (!workspaceObj) {
            workspaceObj = {
                id: parseInt(wsId),
                idx: parseInt(wsId)
            };
        }
        if (backend.switchToWorkspace) {
            backend.switchToWorkspace(workspaceObj);
            activeWorkspace = wsId.toString();
            syncWorkspaces();
        }
    }

    function handleScroll(angleDeltaY, angleDeltaX, isVertical) {
        idleResetTimer.restart();
        var raw = isVertical ? (angleDeltaX !== 0 ? angleDeltaX : angleDeltaY) : (angleDeltaY !== 0 ? angleDeltaY : angleDeltaX);
        var current = parseInt(activeWorkspace);
        var maxWorkspace = Settings.bar.workspaceCount || 10;

        if ((raw < 0 && current >= maxWorkspace) || (raw > 0 && current <= 1)) {
            scrollAccumulator = 0;
            return;
        }
        scrollAccumulator -= raw;
        var threshold = 120;
        if (scrollAccumulator >= threshold) {
            var next = current + 1;
            if (next <= maxWorkspace)
                switchToWorkspaceById(next.toString());
            scrollAccumulator -= threshold;
        } else if (scrollAccumulator <= -threshold) {
            var prev = current - 1;
            if (prev >= 1)
                switchToWorkspaceById(prev.toString());
            scrollAccumulator += threshold;
        }
    }

    // System Actions
    function logout() {
        if (backend && backend.logout)
            backend.logout();
    }
    function shutdown() {
        Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"]);
    }
    function reboot() {
        Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"]);
    }
    function suspend() {
        Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"]);
    }
    function lock() {
        try {
            if (root.lockscreen) {
                root.lockscreen.locked = true;
                CavaService.registerComponent("lockscreen");
            }
        } catch (e) {}
    }
}
