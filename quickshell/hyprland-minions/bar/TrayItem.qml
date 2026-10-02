import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.popups

// Left click activates (or opens the menu for menu-only items), right click
// opens the menu, middle click is the secondary action, scroll is passed on.
BarButton {
    id: root

    required property SystemTrayItem modelData

    // Some apps (Electron etc.) hand out "name?path=/dir" instead of a real
    // icon; turn that into a file URL.
    readonly property string iconSource: {
        const icon = modelData.icon
        if (!icon.includes("?path=")) return icon
        const [name, path] = icon.split("?path=")
        return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`
    }

    flat: true
    implicitWidth: 22
    implicitHeight: 22
    active: menu.shown
    tooltip: modelData.tooltipTitle !== "" ? modelData.tooltipTitle : (modelData.title !== "" ? modelData.title : modelData.id)

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            modelData.secondaryActivate()
        else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu)
            modelData.activate()
        else if (modelData.hasMenu)
            menu.toggle()
    }
    onScrolled: wheel => modelData.scroll(wheel.angleDelta.y, false)

    IconImage {
        anchors.centerIn: parent
        implicitSize: 16
        source: root.iconSource
    }

    TrayMenu {
        id: menu
        anchorItem: root
        handle: root.modelData.menu
    }
}
