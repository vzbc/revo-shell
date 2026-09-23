import QtQuick
import Quickshell.Services.SystemTray

QtObject {
    id: root

    property int revision: 0
    readonly property int count: rankedItems().length
    property Connections trayModelEvents

    function rank(item) {
        if (item.status === Status.NeedsAttention)
            return 0;

        if (item.status === Status.Active)
            return 1;

        return 2;
    }

    function rankedItems() {
        const currentRevision = revision;
        const items = SystemTray.items.values.slice();
        items.sort((left, right) => {
            const rankDifference = rank(left) - rank(right);
            if (rankDifference !== 0)
                return rankDifference;

            return String(left.title || left.id).localeCompare(String(right.title || right.id));
        });
        return items;
    }

    function inlineItems(limit) {
        return rankedItems().slice(0, limit);
    }

    function overflowItems(limit) {
        return rankedItems().slice(limit);
    }

    function title(item) {
        const tooltip = String(item.tooltipTitle || "").trim();
        return tooltip.length > 0 ? tooltip : String(item.title || item.id || "Tray item");
    }

    function description(item) {
        return String(item.tooltipDescription || "").trim();
    }

    function needsAttention(item) {
        return item.status === Status.NeedsAttention;
    }

    trayModelEvents: Connections {
        function onValuesChanged() {
            root.revision++;
        }

        target: SystemTray.items
    }

}
