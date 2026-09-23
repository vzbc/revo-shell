pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../shared"
import "../home"

Item {
    implicitHeight: _wbLayout.implicitHeight

    ColumnLayout {
        id: _wbLayout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Repeater {
            model: ScriptModel {
                values: {
                    if (!NetworkService.showWarnings)
                        return [];
                    var w = [];
                    if (!NetworkService.smbAvailable)
                        w.push({
                            msg: I18n.t("network.warnSmbclientMissing")
                        });
                    if (NetworkService.mountBackend === "smbnetfs" && !NetworkService.smbnetfsAvailable)
                        w.push({
                            msg: I18n.t("network.warnSmbnetfsMissing")
                        });
                    if (NetworkService.mountBackend === "smbnetfs" && !NetworkService.fusermountAvailable)
                        w.push({
                            msg: I18n.t("network.warnFusermountMissing")
                        });
                    if (NetworkService.mountBackend === "mountcifs" && NetworkService.mountCifsPath === "")
                        w.push({
                            msg: I18n.t("network.warnMountCifsMissing")
                        });
                    if (NetworkService.mountBackend === "smbnetfs" && !NetworkService.keychainAvailable)
                        w.push({
                            msg: I18n.t("network.warnSecretToolMissing")
                        });
                    if (KeychainService.tool === "oo7-cli" && KeychainService.promptChecked && !KeychainService.promptAvailable)
                        w.push({
                            msg: I18n.t("network.warnNoUnlockPrompt")
                        });
                    return w;
                }
            }

            delegate: Rectangle {
                id: warnDelegate
                required property var modelData
                Layout.fillWidth: true
                Layout.leftMargin: UIScale.spacingMd
                Layout.rightMargin: UIScale.spacingMd
                Layout.bottomMargin: Math.round(6 * UIScale.value)
                implicitHeight: warnRow.implicitHeight + Math.round(16 * UIScale.value)
                radius: UIScale.radiusSm
                color: Colors.withAlpha(Colors.accent, 0.08)
                border.color: Colors.withAlpha(Colors.accent, 0.25)
                border.width: 1

                RowLayout {
                    id: warnRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: UIScale.spacingMd
                    anchors.rightMargin: UIScale.spacingSm
                    spacing: UIScale.spacingSm

                    Text {
                        text: warnDelegate.modelData.msg
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "x"
                        font.pixelSize: Math.round(16 * UIScale.value)
                        color: dismissHover.hovered ? Colors.accent : Colors.textDim
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        HoverHandler {
                            id: dismissHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -Math.round(4 * UIScale.value)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkService.saveShowWarnings(false)
                        }
                    }
                }
            }
        }

        Rectangle {
            id: keychainBanner
            readonly property bool showLocked: KeychainService.checked && KeychainService.locked
            readonly property bool showTimeout: !showLocked && NetworkService.keychainUnavailable && NetworkService.keychainAvailable
            visible: showLocked || showTimeout
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.spacingMd
            Layout.rightMargin: UIScale.spacingMd
            Layout.bottomMargin: Math.round(6 * UIScale.value)
            implicitHeight: keychainBannerRow.implicitHeight + Math.round(16 * UIScale.value)
            radius: UIScale.radiusSm
            color: Colors.withAlpha(Colors.accent, 0.08)
            border.color: Colors.withAlpha(Colors.accent, 0.25)
            border.width: 1

            RowLayout {
                id: keychainBannerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: UIScale.spacingMd
                anchors.rightMargin: UIScale.spacingMd
                spacing: UIScale.spacingSm

                Text {
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(14 * UIScale.value)
                    color: Colors.accent
                }

                Text {
                    text: keychainBanner.showLocked ? (KeychainService.unlocking ? I18n.t("network.unlockingKeyring") : I18n.t("network.keyringLocked")) : I18n.t("network.keyringLockedOrUnavailable")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: !(keychainBanner.showLocked && KeychainService.unlocking)
                    implicitWidth: retryLabel.implicitWidth + UIScale.spacingMd * 2
                    implicitHeight: Math.round(26 * UIScale.value)
                    radius: Math.round(13 * UIScale.value)
                    color: retryMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.1)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        id: retryLabel
                        anchors.centerIn: parent
                        text: keychainBanner.showLocked ? I18n.t("network.unlock") : I18n.t("network.retry")
                        color: Colors.accent
                        font.pixelSize: UIScale.fontCaption
                    }

                    MouseArea {
                        id: retryMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (keychainBanner.showLocked) {
                                // The unlock prompter is a normal GTK window, and the
                                // Home Panel renders on the wlr-layer-shell "overlay"
                                // layer, which always sits above regular application
                                // windows, the prompt would otherwise appear hidden
                                // behind the panel. Close it first so the dialog is
                                // reachable.
                                HomePanelService.open = false;
                                KeychainService.unlock();
                            } else {
                                NetworkService.retryKeychain();
                            }
                        }
                    }
                }
            }
        }
    }
}
