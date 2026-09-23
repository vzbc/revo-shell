import QtQuick

QtObject {
    id: root

    property var openScreens: ({
    })
    property int closeRevision: 0
    readonly property bool anyOpen: Object.keys(openScreens).length > 0

    function setOpen(screenName, open) {
        const next = Object.assign({
        }, openScreens);
        if (open)
            next[screenName] = true;
        else
            delete next[screenName];
        openScreens = next;
    }

    function closeAll() {
        openScreens = ({
        });
        closeRevision++;
    }

}
