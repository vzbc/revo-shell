import QtQuick
import QtQuick.Controls
import qs.services
import qs.modules.win

/**
 * Vertical grid of app tiles for the store.
 */
GridView {
    id: root

    property var apps: []
    property int cellW: 252
    signal openAppRequested(var app)

    clip: true
    cellWidth: root.cellW
    cellHeight: 124
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { }

    model: root.apps

    delegate: WinAppTile {
        required property var modelData
        width: root.cellWidth - 14
        height: 112
        x: 7
        app: modelData
        installing: StoreCatalog.isInstalling(modelData)
        onInstallRequested: StoreCatalog.install(modelData)
        onOpenRequested: root.openAppRequested(modelData)
    }
}
