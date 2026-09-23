pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

GridLayout {
    readonly property bool available: SystemTray.items.values.length > 0
    visible: available

    rows: BarConfig.isVertical ? -1 : 1
    columns: BarConfig.isVertical ? 1 : -1
    rowSpacing: 4
    columnSpacing: 4

    Repeater {
        model: SystemTray.items
        delegate: TrayIcon {
            required property SystemTrayItem modelData
            item: modelData
        }
    }
}
