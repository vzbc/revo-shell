import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("appswitcher.breadcrumb")
            title: I18n.t("appswitcher.title")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: settingsCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingSm
                }

                Text {
                    text: I18n.t("appswitcher.defaultView")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: [I18n.t("appswitcher.windowCards"), I18n.t("appswitcher.workspaceGrid")]
                    currentIndex: AppSwitcherService.defaultMode
                    onActivated: index => AppSwitcherService.defaultMode = index
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: I18n.t("appswitcher.confirmOnRelease")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: AppSwitcherService.confirmOnRelease
                        onToggled: AppSwitcherService.confirmOnRelease = !AppSwitcherService.confirmOnRelease
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: I18n.t("appswitcher.rememberLastView")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: AppSwitcherService.rememberLastMode
                        onToggled: AppSwitcherService.rememberLastMode = !AppSwitcherService.rememberLastMode
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: I18n.t("appswitcher.followMovedWindow")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }

                    ToggleSwitch {
                        checked: AppSwitcherService.followMovedWindow
                        onToggled: AppSwitcherService.followMovedWindow = !AppSwitcherService.followMovedWindow
                    }
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Text {
                    text: I18n.t("appswitcher.newWorkspace")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: [I18n.t("appswitcher.fillGaps"), I18n.t("appswitcher.append")]
                    currentIndex: AppSwitcherService.newWorkspaceStrategy === "fill" ? 0 : 1
                    onActivated: index => AppSwitcherService.newWorkspaceStrategy = index === 0 ? "fill" : "append"
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
