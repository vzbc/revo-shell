pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root

    readonly property bool blocked: GitUpdateService.status === "blocked"
    readonly property bool pulling: GitUpdateService.status === "pulling"
    readonly property bool available: GitUpdateService.showBadge
    property bool justSucceeded: false

    visible: available
    icon: "󰚰"
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    Connections {
        target: GitUpdateService // qmllint disable incompatible-type
        function onPullSucceeded() {
            root.justSucceeded = true;
            successTimer.restart();
        }
    }

    Timer {
        id: successTimer
        interval: 1400
        onTriggered: {
            root.justSucceeded = false;
            popup.close();
        }
    }

    SequentialAnimation on opacity {
        running: root.visible && !root.active
        loops: Animation.Infinite
        NumberAnimation {
            to: 0.45
            duration: 900
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1.0
            duration: 900
            easing.type: Easing.InOutSine
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(300 * UIScale.value)
        implicitHeight: Math.round(190 * UIScale.value)
        content: Component {
            ColumnLayout {
                anchors.fill: parent
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    spacing: UIScale.spacingSm

                    Text {
                        text: root.justSucceeded ? "✓" : "󰚰"
                        font.pixelSize: Math.round(20 * UIScale.value)
                        color: root.blocked ? "#e0a25c" : Colors.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.justSucceeded ? I18n.t("gitupdate.updated") : (root.blocked ? I18n.t("gitupdate.updateNeedsHelp") : I18n.t("gitupdate.updateAvailable"))
                        color: Colors.text
                        font.pixelSize: UIScale.fontLead
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    wrapMode: Text.WordWrap
                    text: {
                        if (root.justSucceeded)
                            return I18n.t("gitupdate.updatedMessage");
                        if (root.blocked)
                            return I18n.t("gitupdate.blockedMessage");
                        if (GitUpdateService.status === "pullFailed")
                            return I18n.t("gitupdate.failedMessage");
                        return I18n.t("gitupdate.availableMessage");
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    spacing: UIScale.spacingSm

                    ActionButton {
                        visible: !root.blocked && !root.justSucceeded
                        label: root.pulling ? I18n.t("gitupdate.updating") : (GitUpdateService.status === "pullFailed" ? I18n.t("gitupdate.tryAgain") : I18n.t("gitupdate.updateNow"))
                        onActivated: GitUpdateService.updateNow()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: I18n.t("gitupdate.hide")
                        color: hideMouseArea.containsMouse ? Colors.accent : Colors.muted
                        font.pixelSize: UIScale.fontCaption
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        MouseArea {
                            id: hideMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.close();
                                BarItemsService.toggle("gitupdate");
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
