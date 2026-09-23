// services/TrayService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    // Sử dụng trực tiếp SystemTray.items thay vì Repeater
    readonly property var items: SystemTray.items
    readonly property bool hasTray: SystemTray.items.values.length> 0
    readonly property int trayCount: items.count

    // Hàm tiện ích để lấy item theo index
    function getItem(index) {
        if (index >= 0 && index < items.count) {
            return items.get(index);
        }
        return null;
    }

    // Hàm để lấy danh sách các icon hợp lệ
    function getValidItems() {
        var validItems = [];
        for (var i = 0; i < items.count; i++) {
            var item = items.get(i);
            if (item.icon !== "") {
                validItems.push(item);
            }
        }
        return validItems;
    }

    // Property để theo dõi số lượng items hợp lệ
    readonly property int validTrayCount: {
        var count = 0;
        for (var i = 0; i < items.count; i++) {
            if (items.get(i).icon !== "") {
                count++;
            }
        }
        return count;
    }

    // Khởi tạo và log để debug
    Component.onCompleted: {
        console.log("TrayService initialized with", hasTray, "items")
        for (var i = 0; i < items.count; i++) {
            var item = items.get(i);
            console.log("Item", i, ":", item.icon, "hasMenu:", item.hasMenu)
        }
    }
}
