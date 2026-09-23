import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Rectangle {
    required property string hostname
    required property var srvState
    required property string authUser
    required property string authPass
    required property bool authPassVisible

    signal authUserEdited(string text)
    signal authPassEdited(string text)
    signal passVisibilityToggled
    signal connectRequested

    implicitHeight: authCol.implicitHeight + Math.round(20 * UIScale.value)
    radius: UIScale.radiusMd
    color: Colors.surface

    ColumnLayout {
        id: authCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Math.round(10 * UIScale.value)
        spacing: Math.round(6 * UIScale.value)

        Text {
            visible: srvState.status === "error"
            Layout.fillWidth: true
            text: srvState.error
            color: Colors.accent
            font.pixelSize: UIScale.fontCaption
            wrapMode: Text.WordWrap
        }

        StyledTextInput {
            id: userField
            placeholder: I18n.t("network.userPlaceholder")
            text: authUser
            onTextChanged: authUserEdited(userField.text)
            onAccepted: passField.field.forceActiveFocus()
            onTabPressed: passField.field.forceActiveFocus()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(34 * UIScale.value)
            radius: UIScale.radiusSm
            color: Colors.surfaceHigh
            border.color: passField.activeFocus ? Colors.withAlpha(Colors.accent, 0.6) : "transparent"
            border.width: 1
            Behavior on border.color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Math.round(10 * UIScale.value)
                text: I18n.t("network.passwordPlaceholder")
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                visible: passField.text.length === 0 && !passField.activeFocus
            }

            TextInput {
                id: passField
                anchors.left: parent.left
                anchors.right: eyeToggle.left
                anchors.leftMargin: Math.round(10 * UIScale.value)
                anchors.rightMargin: Math.round(4 * UIScale.value)
                height: parent.height
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.text
                selectionColor: Colors.withAlpha(Colors.accent, 0.35)
                font.pixelSize: UIScale.fontSmall
                echoMode: authPassVisible ? TextInput.Normal : TextInput.Password
                text: authPass
                onTextChanged: authPassEdited(text)
                Keys.onReturnPressed: {
                    if (!authUser)
                        return;
                    connectRequested();
                }
            }

            Text {
                id: eyeToggle
                anchors.right: parent.right
                anchors.rightMargin: Math.round(8 * UIScale.value)
                anchors.verticalCenter: parent.verticalCenter
                text: authPassVisible ? "" : ""
                font.family: "Material Icons"
                font.pixelSize: Math.round(16 * UIScale.value)
                color: eyeMa.containsMouse ? Colors.accent : Colors.muted
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                MouseArea {
                    id: eyeMa
                    anchors.fill: parent
                    anchors.margins: -Math.round(4 * UIScale.value)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: passVisibilityToggled()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: connectLabel.implicitWidth + UIScale.spacingMd * 2
                implicitHeight: Math.round(30 * UIScale.value)
                radius: Math.round(15 * UIScale.value)
                enabled: authUser.length > 0
                opacity: enabled ? 1.0 : 0.4
                color: connectMa.containsMouse ? Colors.accent : Colors.withAlpha(Colors.accent, 0.75)
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                Text {
                    id: connectLabel
                    anchors.centerIn: parent
                    text: I18n.t("network.connect")
                    color: Colors.bg
                    font.pixelSize: UIScale.fontCaption
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: connectMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!authUser)
                            return;
                        connectRequested();
                    }
                }
            }
        }
    }
}
