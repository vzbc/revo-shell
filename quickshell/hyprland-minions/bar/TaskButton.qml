import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.popups

// A window on the taskbar. Left click focuses, middle click closes, right
// click opens a small window menu. Urgent windows flash.
BarButton {
    id: root

    required property var modelData // HyprlandToplevel

    readonly property var toplevel: modelData.wayland
    readonly property string appId: toplevel?.appId ?? modelData.lastIpcObject?.class ?? ""
    readonly property var entry: appId !== "" ? DesktopEntries.heuristicLookup(appId) : null
    readonly property string title: modelData.title !== "" ? modelData.title : (entry?.name ?? appId)

    property bool flash: false

    active: modelData.activated || flash || menu.shown
    tooltip: title

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            toplevel?.close()
        else if (mouse.button === Qt.RightButton)
            menu.toggle()
        else
            toplevel?.activate()
    }

    Timer {
        running: root.modelData.urgent && !root.modelData.activated
        interval: 500
        repeat: true
        onTriggered: root.flash = !root.flash
        onRunningChanged: if (!running) root.flash = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        IconImage {
            implicitSize: 14
            source: Quickshell.iconPath(root.entry?.icon ?? root.appId, "application-x-executable")
        }

        BarText {
            Layout.fillWidth: true
            text: root.title
            color: root.textColor
        }
    }

    TaskMenu {
        id: menu
        anchorItem: root
        toplevel: root.toplevel
    }
}
