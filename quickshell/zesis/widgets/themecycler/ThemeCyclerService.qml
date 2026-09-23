pragma Singleton
import QtQuick
import Quickshell
import "../../"

// Alt-Tab-style quick switcher for pinned themes (Themes.pinned - only themes
// that are both pinned and have a wallpaper attached, see Themes.qml). Driven
// by the "themecycler" IpcHandler in shell.qml, same show/cycle/confirm/cancel
// shape as AppSwitcherService.
Singleton {
    id: root

    property bool open: false
    property int selectedIndex: 0

    readonly property var entries: Themes.pinned

    onEntriesChanged: {
        if (selectedIndex >= entries.length)
            selectedIndex = Math.max(0, entries.length - 1);
    }

    // Each keybind spawns its own `qs ipc call` process (see shell.qml's
    // "themecycler" IpcHandler), so cycle/confirm/cancel arrive as separate,
    // independently-scheduled processes - nothing guarantees the last
    // autorepeated "cycle" from a held Tab lands at the shell before a
    // "confirm"/"cancel" fired by releasing the modifier a moment later. A
    // reordered cycle would otherwise call show() and reopen what confirm()
    // just closed, since cycleForward()/cycleBack() treat "not open" as "the
    // user wants to open it". This short guard window makes a stray cycle
    // arriving right after a close a no-op instead of a re-open.
    property bool _justClosed: false

    Timer {
        id: closeGuardTimer
        interval: 600
        onTriggered: root._justClosed = false
    }

    function _markClosed() {
        root._justClosed = true;
        closeGuardTimer.restart();
    }

    function show() {
        if (entries.length === 0)
            return;
        selectedIndex = 0;
        open = true;
    }

    function cycleForward() {
        if (!open) {
            if (root._justClosed)
                return;
            show();
            return;
        }
        if (entries.length === 0)
            return;
        selectedIndex = (selectedIndex + 1) % entries.length;
    }

    function cycleBack() {
        if (!open) {
            if (root._justClosed)
                return;
            show();
            return;
        }
        if (entries.length === 0)
            return;
        selectedIndex = (selectedIndex - 1 + entries.length) % entries.length;
    }

    function confirm() {
        if (!open)
            return;
        var idx = selectedIndex;
        var list = entries;
        open = false;
        root._markClosed();
        if (idx >= 0 && idx < list.length)
            Themes.apply(list[idx].name);
    }

    function cancel() {
        if (!open)
            return;
        open = false;
        root._markClosed();
    }
}
