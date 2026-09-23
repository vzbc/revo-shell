pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Windows 11 taskbar context menu, hosted by the bar's empty area.
// Item order mirrors Windows 11 (22H2+).
ContextMenu {
    id: root

    model: [
        { text: Translation.tr("Search"), action: () => GlobalStates.searchOpen = !GlobalStates.searchOpen },
        { text: Translation.tr("Task view"), action: () => GlobalStates.overviewOpen = !GlobalStates.overviewOpen },
        { type: "separator" },
        { text: Translation.tr("Cascade windows"), action: () => arrangeRunner.run("cascade") },
        { text: Translation.tr("Show windows side by side"), action: () => arrangeRunner.run("sidebyside") },
        { text: Translation.tr("Show windows stacked"), action: () => arrangeRunner.run("stacked") },
        { type: "separator" },
        { text: Translation.tr("Show the desktop"), action: () => arrangeRunner.run("showdesktop") },
        { text: Translation.tr("Task manager"), action: () => Quickshell.execDetached(["missioncenter"]) },
        { type: "separator" },
        { text: Translation.tr("Taskbar settings"), action: () => Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]) },
    ]

    Process {
        id: arrangeRunner
        function run(mode) {
            arrangeRunner.command = [Directories.arrangeWindowsScriptPath, mode];
            arrangeRunner.running = true;
        }
    }
}
