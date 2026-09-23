import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Store product / detail page for a single app.
 */
Item {
    id: root

    readonly property var app: StoreCatalog.currentApp
    readonly property bool isAur: root.app ? root.app.source === "aur" : false
    readonly property bool isFlathub: root.app ? root.app.source === "flathub" : false
    readonly property bool installing: StoreCatalog.isInstalling(root.app)

    function launch() {
        if (!root.app) return
        if (root.app.source === "flathub")
            Quickshell.execDetached(["flatpak", "run", root.app.id])
        else
            Quickshell.execDetached(["gtk-launch", root.app.name])
    }

    ScrollView {
        anchors.fill: parent
        ScrollBar.vertical: ScrollBar { }
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }
        clip: true

        ColumnLayout {
            width: parent.width - 60
            x: 30
            spacing: 20

            Item { Layout.preferredHeight: 24 }

            // ------------------------------------------------------- header
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                Item {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96

                    Image {
                        id: heroIcon
                        anchors.fill: parent
                        source: root.app?.icon ?? ""
                        sourceSize: Qt.size(96, 96)
                        smooth: true
                        visible: (root.app?.icon ?? "").length > 0 && heroIcon.status !== Image.Error
                        fillMode: Image.PreserveAspectFit
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: (root.app?.icon ?? "").length === 0 || heroIcon.status === Image.Error
                        radius: 12
                        color: root.app?.installed ? "#3a3a3a" : "#214a63"
                        StyledText {
                            anchors.centerIn: parent
                            text: (root.app?.name ?? "?")[0].toUpperCase()
                            color: WinTheme.text
                            font.pixelSize: 42
                            font.weight: Font.DemiBold
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: root.app?.name ?? ""
                        color: WinTheme.text
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 10
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            color: "transparent"
                            border.color: root.app ? root.sourceBadgeColor : WinTheme.textTertiary
                            border.width: 1
                            radius: 3
                            height: 18
                            implicitWidth: badgeText.implicitWidth + 10
                            StyledText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.app ? root.sourceBadgeText : ""
                                color: root.app ? root.sourceBadgeColor : WinTheme.textTertiary
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }
                        StyledText {
                            text: root.app?.developer || root.app?.maintainer || root.app?.repo || ""
                            color: WinTheme.textSecondary
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 600
                        text: root.app?.summary ?? ""
                        color: WinTheme.textSecondary
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }

                WinButton {
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 34
                    text: root.installing ? "Installing…" : (root.app?.installed ? "Open" : "Install")
                    accent: root.app ? !root.app.installed && !root.installing : false
                    busy: root.installing
                    enabled: !root.installing
                    onClicked: root.app?.installed ? root.launch() : StoreCatalog.install(root.app)
                }
            }

            // -------------------------------------------------- screenshot
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                radius: 10
                clip: true
                color: WinTheme.bgAlt
                visible: (root.app?.screenshots ?? []).length > 0

                Image {
                    id: shotImage
                    anchors.fill: parent
                    source: root.app?.screenshots?.[0] ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                StyledText {
                    visible: shotImage.status === Image.Loading
                    anchors.centerIn: parent
                    text: "Loading preview…"
                    color: WinTheme.textTertiary
                    font.pixelSize: 12
                }
            }

            // ------------------------------------------------- description
            StyledText {
                Layout.fillWidth: true
                visible: (root.app?.description ?? "").length > 0
                text: root.app?.description ?? ""
                color: WinTheme.text
                font.pixelSize: 13
                lineHeight: 1.35
                wrapMode: Text.WordWrap
            }

            // ------------------------------------------------------ details
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                radius: 10
                color: WinTheme.card
                visible: root.app != null

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    columns: 2
                    columnSpacing: 40
                    rowSpacing: 12

                    Repeater {
                        model: root.app ? [
                            { k: "Version", v: root.app.version || "—" },
                            { k: "Source", v: root.sourceBadgeText },
                            { k: "License", v: root.app.license || "—" },
                            { k: "Last update", v: root.app.last_release || "—" },
                            { k: "Votes", v: root.isAur ? (root.app.votes ?? "—") : "—" },
                            { k: "Popularity", v: root.isAur ? (root.app.popularity ?? "—") : "—" },
                            { k: "Maintainer", v: root.app.maintainer || "—" },
                            { k: "Website", v: root.app.url || "—" }
                        ] : []
                        Item {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 26
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 1
                                StyledText {
                                    text: modelData.k
                                    color: WinTheme.textTertiary
                                    font.pixelSize: 10
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.v
                                    color: WinTheme.text
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }

    readonly property color sourceBadgeColor: {
        switch (root.app?.source) {
            case "flathub": return "#8ab4f8"
            case "arch": return "#f9ab00"
            case "aur": return "#f28b82"
            default: return WinTheme.textSecondary
        }
    }
    readonly property string sourceBadgeText: {
        switch (root.app?.source) {
            case "flathub": return "FLATHUB"
            case "arch": return "PACMAN"
            case "aur": return "AUR"
            default: return "?"
        }
    }
}
