import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows Store app tile: icon, name, summary, source badge, install button.
 * modelData: { source, id, name, summary, icon, installed, version, repo }
 */
WinCard {
    id: root

    property var app
    property bool installed: root.app?.installed ?? false
    property bool installing: false
    signal installRequested()
    signal openRequested()

    implicitHeight: 112
    implicitWidth: 210
    clickable: true
    hoverable: true

    readonly property string actionText: root.installing ? "Installing…" : (root.installed ? "Open" : "Install")

    onClicked: root.openRequested()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Item {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            Image {
                id: appIcon
                anchors.fill: parent
                source: root.app?.icon ?? ""
                sourceSize: Qt.size(48, 48)
                smooth: true
                visible: (root.app?.icon ?? "").length > 0 && appIcon.status !== Image.Error
                fillMode: Image.PreserveAspectFit
            }

            Rectangle {
                anchors.fill: parent
                visible: (root.app?.icon ?? "").length === 0 || appIcon.status === Image.Error
                radius: 6
                color: root.installed ? "#3a3a3a" : "#214a63"
                StyledText {
                    anchors.centerIn: parent
                    text: (root.app?.name ?? "?")[0].toUpperCase()
                    color: WinTheme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.app?.name ?? ""
                color: WinTheme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                Layout.maximumHeight: 30
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                text: root.app?.summary ?? ""
                color: WinTheme.textSecondary
                font.pixelSize: 11
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    color: "transparent"
                    border.color: sourceBadgeColor
                    border.width: 1
                    radius: 3
                    height: 16
                    implicitWidth: badgeText.implicitWidth + 8
                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.sourceBadgeText
                        color: sourceBadgeColor
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.app?.version ?? ""
                    color: WinTheme.textTertiary
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Item { Layout.fillWidth: true }

                WinButton {
                    Layout.alignment: Qt.AlignVCenter
                    accent: !root.installed && !root.installing
                    text: root.actionText
                    implicitHeight: 26
                    busy: root.installing
                    enabled: !root.installing
                    onClicked: root.installed ? root.openRequested() : root.installRequested()
                }
            }
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
