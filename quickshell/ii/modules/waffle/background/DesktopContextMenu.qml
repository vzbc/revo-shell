pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.waffle.looks

// Windows 11 desktop context menu, hosted by the wallpaper background.
// Item order mirrors Windows 11.
ContextMenu {
    id: root

    // The shell doesn't manage desktop icons (yet), so View/Sort by state is
    // purely visual. It's kept as plain properties so it can be wired up later.
    property string iconSize: "medium"          // large | medium | small
    property string sortBy: "name"              // name | size | type | date
    property bool autoArrange: true
    property bool alignToGrid: true
    property bool showDesktopIcons: true
    property bool showIconLabels: true

    function buildModel() {
        return [
            {
                type: "submenu",
                text: Translation.tr("View"),
                submenu: [
                    { text: Translation.tr("Large icons"), checkmark: root.iconSize === "large", action: () => root.iconSize = "large" },
                    { text: Translation.tr("Medium icons"), checkmark: root.iconSize === "medium", action: () => root.iconSize = "medium" },
                    { text: Translation.tr("Small icons"), checkmark: root.iconSize === "small", action: () => root.iconSize = "small" },
                    { type: "separator" },
                    { text: Translation.tr("Auto arrange icons"), checkmark: root.autoArrange, action: () => root.autoArrange = !root.autoArrange },
                    { text: Translation.tr("Align icons to grid"), checkmark: root.alignToGrid, action: () => root.alignToGrid = !root.alignToGrid },
                    { type: "separator" },
                    { text: Translation.tr("Show desktop icons"), checkmark: root.showDesktopIcons, action: () => root.showDesktopIcons = !root.showDesktopIcons },
                    { text: Translation.tr("Show icon labels"), checkmark: root.showIconLabels, action: () => root.showIconLabels = !root.showIconLabels }
                ]
            },
            {
                type: "submenu",
                text: Translation.tr("Sort by"),
                submenu: [
                    { text: Translation.tr("Name"), checkmark: root.sortBy === "name", action: () => root.sortBy = "name" },
                    { text: Translation.tr("Size"), checkmark: root.sortBy === "size", action: () => root.sortBy = "size" },
                    { text: Translation.tr("Item type"), checkmark: root.sortBy === "type", action: () => root.sortBy = "type" },
                    { text: Translation.tr("Date modified"), checkmark: root.sortBy === "date", action: () => root.sortBy = "date" }
                ]
            },
            { type: "separator" },
            { text: Translation.tr("Refresh"), action: () => Wallpapers.load() },
            { type: "separator" },
            {
                type: "submenu",
                text: Translation.tr("New"),
                submenu: [
                    { text: Translation.tr("Folder"), action: () => Qt.openUrlExternally(Directories.home) },
                    { text: Translation.tr("Shortcut"), action: () => Qt.openUrlExternally(Directories.home) }
                ]
            },
            { type: "separator" },
            { text: Translation.tr("Display settings"), action: () => Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]) },
            { text: Translation.tr("Personalize"), action: () => Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]) }
        ];
    }
}
