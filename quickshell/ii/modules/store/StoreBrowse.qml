import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win
import qs.modules.store

/**
 * Store browse page: all / flathub / arch / AUR tabs with filtering.
 */
Item {
    id: root

    signal openAppRequested(var app)

    property string source: StoreCatalog.browseSource
    property string filterText: ""

    readonly property var allApps: {
        if (!StoreCatalog.ready) return []
        const out = StoreCatalog.flathub.slice()
        for (const a of StoreCatalog.arch)
            if (a.desktop) out.push(a)
        return out
    }

    readonly property var modelApps: {
        let base = []
        switch (root.source) {
            case "flathub": base = StoreCatalog.flathub; break
            case "arch": base = StoreCatalog.arch; break
            case "aur": base = []; break
            default: base = root.allApps
        }
        const q = root.filterText.trim().toLowerCase()
        if (q.length === 0)
            return base
        const out = []
        for (const a of base) {
            if ((a.name && a.name.toLowerCase().includes(q)) ||
                (a.summary && a.summary.toLowerCase().includes(q)))
                out.push(a)
        }
        return out
    }

    readonly property int shownCount: root.modelApps.length

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 20
        anchors.bottomMargin: 16
        spacing: 14

        // --------------------------------------------------------- header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                StyledText {
                    text: "Apps"
                    color: WinTheme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                StyledText {
                    text: root.shownCount.toLocaleString() + " results"
                    color: WinTheme.textSecondary
                    font.pixelSize: 12
                }
            }

            WinSearchField {
                Layout.preferredWidth: 240
                visible: root.source !== "aur"
                placeholder: "Filter"
                text: root.filterText
                onTextChanged: root.filterText = text
            }
        }

        // --------------------------------------------------------- chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { key: "all", label: "All" },
                    { key: "flathub", label: "Flathub" },
                    { key: "arch", label: "Arch" },
                    { key: "aur", label: "AUR" }
                ]
                Rectangle {
                    required property var modelData
                    Layout.preferredHeight: 30
                    implicitWidth: label.implicitWidth + 26
                    radius: 15
                    color: root.source === modelData.key ? WinTheme.accent : (hover.hovered ? WinTheme.card : "transparent")
                    HoverHandler { id: hover }
                    StyledText {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.source === modelData.key ? WinTheme.onAccentColor : WinTheme.textSecondary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.source = modelData.key
                    }
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                visible: root.source === "aur" && StoreCatalog.aurBusy
                text: "Searching AUR…"
                color: WinTheme.textTertiary
                font.pixelSize: 12
            }
        }

        // ------------------------------------------------------ AUR panel
        Rectangle {
            Layout.fillWidth: true
            visible: root.source === "aur"
            Layout.preferredHeight: 56
            radius: 8
            color: WinTheme.card

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                MaterialSymbol { text: "terminal"; iconSize: 18; color: WinTheme.textSecondary }
                WinSearchField {
                    id: aurSearchInput
                    Layout.fillWidth: true
                    placeholder: "Search the AUR (e.g. visual-studio-code-bin)"
                    onAccepted: StoreCatalog.aurSearch(text)
                }
                WinButton {
                    text: "Search AUR"
                    accent: true
                    onClicked: StoreCatalog.aurSearch(aurSearchInput.text)
                }
            }
        }

        // ----------------------------------------------------------- grid
        AppGrid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.source !== "aur"
            apps: root.modelApps
            onOpenAppRequested: (app) => root.openAppRequested(app)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.source === "aur"
            spacing: 12

            AppGrid {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: StoreCatalog.aurResults.length > 0
                apps: StoreCatalog.aurResults
                onOpenAppRequested: (app) => root.openAppRequested(app)
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: StoreCatalog.aurResults.length === 0 && !StoreCatalog.aurBusy
                text: aurSearchInput.text.trim().length === 0
                    ? "Enter a search term above to look up community packages."
                    : "No results found on the AUR."
                color: WinTheme.textTertiary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
    }
}
