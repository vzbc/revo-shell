pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Shared state for the Waffle (Windows look) context menus.
Singleton {
    id: root

    // Root menus register themselves here so only one can be open at a time.
    property var menus: []

    function registerMenu(menu) {
        if (menu.parentMenu !== null) return;
        if (root.menus.indexOf(menu) !== -1) return;
        root.menus = root.menus.concat([menu]);
    }

    function unregisterMenu(menu) {
        const index = root.menus.indexOf(menu);
        if (index === -1) return;
        const copy = root.menus.slice();
        copy.splice(index, 1);
        root.menus = copy;
    }

    function closeAll() {
        for (const menu of root.menus.slice()) menu.closeMenu();
    }
}
