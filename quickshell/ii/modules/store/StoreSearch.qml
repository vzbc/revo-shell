import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win
import qs.modules.store

/**
 * Store search results: local catalog + AUR, combined.
 */
Item {
    id: root

    signal openAppRequested(var app)

    readonly property string query: StoreCatalog.activeQuery
    readonly property var localResults: StoreCatalog.localSearch(root.query, 60)

    Component.onCompleted: {
        if (root.query.length >= 2)
            StoreCatalog.aurSearch(root.query)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 20
        anchors.bottomMargin: 16
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                text: `Results for “${root.query}”`
                color: WinTheme.text
                font.pixelSize: 22
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            StyledText {
                text: root.localResults.length.toLocaleString() + " from Flathub & Arch"
                    + (StoreCatalog.aurBusy ? " · searching AUR…" : "")
                color: WinTheme.textSecondary
                font.pixelSize: 12
            }
        }

        StyledText {
            visible: StoreCatalog.ready && root.localResults.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Layout.topMargin: 30
            text: "No local results. The AUR may still have something — check below."
            color: WinTheme.textTertiary
            font.pixelSize: 13
        }

        AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.localResults.length > 0
            apps: root.localResults
            onOpenAppRequested: (app) => root.openAppRequested(app)
        }

        StyledText {
            visible: root.localResults.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: "AUR results"
            color: WinTheme.text
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: StoreCatalog.aurResults.length > 0
            apps: StoreCatalog.aurResults
            onOpenAppRequested: (app) => root.openAppRequested(app)
        }

        StyledText {
            visible: !StoreCatalog.aurBusy && StoreCatalog.aurResults.length === 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: StoreCatalog.aurBusy ? "" : "No AUR results."
            color: WinTheme.textTertiary
            font.pixelSize: 13
        }
    }
}
