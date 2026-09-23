import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win
import qs.modules.store

/**
 * Store library page: everything installed from Flathub + Arch (GUI apps).
 */
Item {
    id: root

    signal openAppRequested(var app)

    readonly property var sortedLibrary: {
        const out = StoreCatalog.library.slice()
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
        return out
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 20
        anchors.bottomMargin: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                StyledText {
                    text: "Library"
                    color: WinTheme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                StyledText {
                    text: StoreCatalog.ready
                        ? StoreCatalog.library.length.toLocaleString() + " installed apps"
                        : "Loading catalog…"
                    color: WinTheme.textSecondary
                    font.pixelSize: 12
                }
            }
        }

        AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            apps: root.sortedLibrary
            onOpenAppRequested: (app) => root.openAppRequested(app)
        }
    }
}
