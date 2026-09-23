import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    readonly property int firstWorkspace: 1
    readonly property int lastWorkspace: 10
    property int revision: 0
    property Connections hyprlandEvents
    property Connections workspaceModelEvents
    property Connections toplevelModelEvents
    property Timer startupRefreshTimer

    function monitorFor(screen) {
        return screen === null ? null : Hyprland.monitorFor(screen);
    }

    function activeWorkspaceId(screen) {
        const currentRevision = revision;
        const monitor = monitorFor(screen);
        return monitor !== null && monitor.activeWorkspace !== null ? monitor.activeWorkspace.id : firstWorkspace;
    }

    function workspaceInfo(workspaceId, screen) {
        const currentRevision = revision;
        const monitor = monitorFor(screen);
        const monitorName = monitor !== null ? monitor.name : "";
        const active = activeWorkspaceId(screen) === workspaceId;
        const workspaces = Hyprland.workspaces.values;
        for (const workspace of workspaces) {
            const ipcState = workspace.lastIpcObject;
            const workspaceMonitorName = workspace.monitor !== null ? workspace.monitor.name : String(ipcState.monitor ?? "");
            if (workspace.id === workspaceId && (monitorName.length === 0 || workspaceMonitorName === monitorName)) {
                const windows = workspace.toplevels !== null ? workspace.toplevels.values : [];
                const windowCount = Math.max(windows.length, Number(ipcState.windows ?? 0));
                return {
                    "active": active,
                    "occupied": windowCount > 0,
                    "urgent": workspace.urgent,
                    "windowCount": windowCount
                };
            }
        }
        return {
            "active": active,
            "occupied": false,
            "urgent": false,
            "windowCount": 0
        };
    }

    function activate(workspaceId) {
        if (workspaceId < firstWorkspace || workspaceId > lastWorkspace)
            return ;

        Hyprland.dispatch("workspace " + workspaceId);
    }

    function cycle(delta, screen) {
        const current = activeWorkspaceId(screen);
        let next = current + delta;
        if (next < firstWorkspace)
            next = lastWorkspace;
        else if (next > lastWorkspace)
            next = firstWorkspace;
        activate(next);
    }

    function refresh(includeToplevels) {
        Hyprland.refreshWorkspaces();
        if (includeToplevels)
            Hyprland.refreshToplevels();

        revision++;
    }

    Component.onCompleted: {
        refresh(true);
        startupRefreshTimer.start();
    }

    startupRefreshTimer: Timer {
        interval: 600
        repeat: false
        onTriggered: root.refresh(true)
    }

    hyprlandEvents: Connections {
        function onRawEvent(event) {
            if (event === null)
                return ;

            const workspaceEvents = ["workspace", "workspacev2", "focusedmon", "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "moveworkspace", "moveworkspacev2"];
            const windowEvents = ["openwindow", "closewindow", "movewindow", "movewindowv2", "urgent"];
            if (workspaceEvents.indexOf(event.name) >= 0)
                root.refresh(false);
            else if (windowEvents.indexOf(event.name) >= 0)
                root.refresh(true);
        }

        target: Hyprland
    }

    workspaceModelEvents: Connections {
        function onValuesChanged() {
            root.revision++;
        }

        target: Hyprland.workspaces
    }

    toplevelModelEvents: Connections {
        function onValuesChanged() {
            root.revision++;
        }

        target: Hyprland.toplevels
    }

}
