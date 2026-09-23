import QtQuick
import QtQuick.Controls
import qs.services
import qs.modules.win

/**
 * Horizontal row of app tiles for the store home page.
 */
ListView {
    id: root

    property var apps: []
    signal openAppRequested(var app)

    orientation: Qt.Horizontal
    clip: true
    spacing: 12
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

    model: root.apps

    delegate: WinAppTile {
        required property var modelData
        width: 234
        height: 112
        app: modelData
        installing: StoreCatalog.isInstalling(modelData)
        onInstallRequested: StoreCatalog.install(modelData)
        onOpenRequested: root.openAppRequested(modelData)
    }
}
