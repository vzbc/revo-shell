import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win
import qs.modules.store

/**
 * Store home page: welcome hero, source shortcuts, featured apps, library row.
 */
Item {
    id: root

    signal openAppRequested(var app)
    signal searchRequested(string text)
    signal browseRequested()

    property var featuredIds: [
        "org.mozilla.firefox", "org.videolan.VLC", "io.github.zen_browser.zen",
        "com.valvesoftware.Steam", "org.gnome.Nautilus", "org.kde.kdenlive",
        "org.gimp.GIMP", "com.spotify.Client", "org.telegram.desktop",
        "io.missioncenter.MissionCenter", "org.gnome.Loupe", "com.obsproject.Studio"
    ]

    readonly property var featuredApps: {
        if (!StoreCatalog.ready) return []
        const out = []
        for (const id of root.featuredIds) {
            for (const app of StoreCatalog.flathub) {
                if (app.id === id) { out.push(app); break }
            }
        }
        return out
    }
    readonly property int totalApps: StoreCatalog.flathub.length + StoreCatalog.arch.length

    ScrollView {
        anchors.fill: parent
        ScrollBar.vertical: ScrollBar { }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width - 52
            x: 26
            spacing: 18

            Item { Layout.preferredHeight: 22 }

            // ------------------------------------------------------- hero
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1a2a3a" }
                    GradientStop { position: 1.0; color: "#0f1420" }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.margins: 28
                    spacing: 10

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Welcome to the Store"
                        color: WinTheme.text
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `Discover apps from Flathub, Arch repositories and the AUR — ${root.totalApps.toLocaleString()} available`
                        color: WinTheme.textSecondary
                        font.pixelSize: 13
                    }

                    WinSearchField {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 420
                        Layout.topMargin: 6
                        placeholder: "Search apps"
                        onAccepted: root.searchRequested(text)
                    }
                }
            }

            // ------------------------------------------------- sources
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                WinCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    onClicked: { StoreCatalog.browseSource = "flathub"; root.browseRequested() }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        MaterialSymbol { text: "apps"; iconSize: 26; color: "#8ab4f8" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText { text: "Flathub"; color: WinTheme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                            StyledText { text: StoreCatalog.flathub.length.toLocaleString() + " apps"; color: WinTheme.textSecondary; font.pixelSize: 11 }
                        }
                        MaterialSymbol { text: "chevron_right"; iconSize: 18; color: WinTheme.textTertiary }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    onClicked: { StoreCatalog.browseSource = "arch"; root.browseRequested() }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        MaterialSymbol { text: "package"; iconSize: 26; color: "#f9ab00" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText { text: "Arch"; color: WinTheme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                            StyledText { text: StoreCatalog.arch.length.toLocaleString() + " packages"; color: WinTheme.textSecondary; font.pixelSize: 11 }
                        }
                        MaterialSymbol { text: "chevron_right"; iconSize: 18; color: WinTheme.textTertiary }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    onClicked: { StoreCatalog.browseSource = "aur"; root.browseRequested() }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        MaterialSymbol { text: "terminal"; iconSize: 26; color: "#f28b82" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText { text: "AUR"; color: WinTheme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                            StyledText { text: "Community packages"; color: WinTheme.textSecondary; font.pixelSize: 11 }
                        }
                        MaterialSymbol { text: "chevron_right"; iconSize: 18; color: WinTheme.textTertiary }
                    }
                }
            }

            // ------------------------------------------------- featured
            StyledText {
                text: "Featured apps"
                color: WinTheme.text
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            AppRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                visible: root.featuredApps.length > 0
                apps: root.featuredApps
                onOpenAppRequested: (app) => root.openAppRequested(app)
            }

            // -------------------------------------------------- library
            StyledText {
                text: "From your library"
                color: WinTheme.text
                font.pixelSize: 17
                font.weight: Font.DemiBold
                visible: StoreCatalog.ready && StoreCatalog.library.length > 0
            }

            AppRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                visible: StoreCatalog.ready && StoreCatalog.library.length > 0
                apps: StoreCatalog.library
                onOpenAppRequested: (app) => root.openAppRequested(app)
            }

            Item { Layout.preferredHeight: 22 }
        }
    }
}
