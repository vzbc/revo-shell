import QtQuick

QtObject {
    id: root

    property string openScreenKey: ""
    readonly property bool anyOpen: openScreenKey.length > 0

    function isOpen(screenKey) {
        return openScreenKey === screenKey;
    }

    function open(screenKey) {
        openScreenKey = screenKey;
    }

    function close() {
        openScreenKey = "";
    }

    function toggle(screenKey) {
        if (isOpen(screenKey))
            close();
        else
            open(screenKey);
    }

}
