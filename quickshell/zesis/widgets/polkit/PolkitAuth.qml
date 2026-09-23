pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../../"
import "../shared"

Item {
    id: root

    PolkitAgent {
        id: polkit
    }

    Connections {
        target: polkit.flow
        function onInputPromptChanged() {
            responseInput.text = "";
            responseInput.forceActiveFocus();
        }
    }

    PanelWindow {
        visible: polkit.isActive
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.withAlpha(Colors.bg, 0.65)

            MouseArea {
                anchors.fill: parent
                onClicked: polkit.flow?.cancelAuthenticationRequest()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.round(300 * UIScale.value)
            implicitHeight: dialogCol.implicitHeight + Math.round(40 * UIScale.value)
            radius: UIScale.radiusMd
            color: Colors.surface
            border.color: Colors.outline
            border.width: 1

            ColumnLayout {
                id: dialogCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Math.round(20 * UIScale.value)
                }
                spacing: UIScale.spacingSm

                RowLayout {
                    spacing: UIScale.spacingSm
                    Text {
                        text: ""
                        font.family: "Material Icons"
                        font.pixelSize: Math.round(18 * UIScale.value)
                        color: Colors.accent
                    }
                    Text {
                        text: I18n.t("polkit.authRequired")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    visible: (polkit.flow?.supplementaryMessage ?? "").length > 0
                    text: polkit.flow?.supplementaryMessage ?? ""
                    color: (polkit.flow?.supplementaryIsError ?? false) ? Colors.accent : Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    visible: (polkit.flow?.inputPrompt ?? "").length > 0
                    text: polkit.flow?.inputPrompt ?? ""
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                }

                StyledTextInput {
                    id: responseInput
                    visible: polkit.flow?.isResponseRequired ?? false
                    echoMode: (polkit.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                    onAccepted: {
                        polkit.flow?.submit(responseInput.text);
                        responseInput.text = "";
                    }
                    onEscapePressed: polkit.flow?.cancelAuthenticationRequest()
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        implicitWidth: cancelLabel.implicitWidth + UIScale.spacingMd * 2
                        implicitHeight: Math.round(30 * UIScale.value)
                        radius: Math.round(15 * UIScale.value)
                        color: cancelMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                        border.color: Colors.withAlpha(Colors.accent, 0.4)
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            id: cancelLabel
                            anchors.centerIn: parent
                            text: I18n.t("common.cancel")
                            color: Colors.accent
                            font.pixelSize: UIScale.fontCaption
                        }

                        MouseArea {
                            id: cancelMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: polkit.flow?.cancelAuthenticationRequest()
                        }
                    }

                    Rectangle {
                        visible: polkit.flow?.isResponseRequired ?? false
                        implicitWidth: authLabel.implicitWidth + UIScale.spacingMd * 2
                        implicitHeight: Math.round(30 * UIScale.value)
                        radius: Math.round(15 * UIScale.value)
                        color: authMa.containsMouse ? Colors.accent : Colors.withAlpha(Colors.accent, 0.8)
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            id: authLabel
                            anchors.centerIn: parent
                            text: I18n.t("polkit.authenticate")
                            color: Colors.bg
                            font.pixelSize: UIScale.fontCaption
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: authMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                polkit.flow?.submit(responseInput.text);
                                responseInput.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
