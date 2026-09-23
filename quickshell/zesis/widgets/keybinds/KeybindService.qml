pragma Singleton
import QtQuick
import Quickshell

// Inspired by asteriau
// https://asteria.cat/

Singleton {
    id: root

    property bool popupOpen: false
    property var sections: backend.sections

    // Swap HyprlandBackend for another compositor's backend here.
    HyprlandBackend {
        id: backend
    }

    // Refresh when the popup is opened so data is always current.
    onPopupOpenChanged: if (popupOpen)
        backend.refresh()
}
