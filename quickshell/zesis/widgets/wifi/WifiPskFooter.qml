pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Rectangle {
    id: root

    property var pendingNetwork: null
    property var _lastPskNetwork: null
    property bool pskVisible: false
    property string errorMsg: ""

    property real sidePadding: UIScale.spacingSm
    property real bottomRadius: 0

    function connectNetwork(network) {
        root.errorMsg = "";
        if (network.connected) {
            network.disconnect();
        } else {
            network.connect();
        }
    }

    function handleConnectionFailed(network) {
        if (WifiService.needsPsk(network)) {
            root.pendingNetwork = network;
            root.errorMsg = (root._lastPskNetwork === network) ? I18n.t("wifi.wrongPassword") : "";
            root._lastPskNetwork = null;
        } else {
            root.errorMsg = I18n.t("wifi.connectionFailed");
        }
    }

    visible: pendingNetwork !== null
    implicitHeight: Math.round(72 * UIScale.value)
    color: Colors.withAlpha(Colors.accent, 0.04)
    border.color: Colors.withAlpha(Colors.accent, 0.15)
    border.width: 1
    bottomLeftRadius: bottomRadius
    bottomRightRadius: bottomRadius

    Column {
        anchors.fill: parent
        anchors.leftMargin: root.sidePadding
        anchors.rightMargin: root.sidePadding
        anchors.topMargin: UIScale.spacingSm
        anchors.bottomMargin: UIScale.spacingSm
        spacing: Math.round(5 * UIScale.value)

        Text {
            visible: root.errorMsg.length > 0
            text: root.errorMsg
            color: "#e05c5c"
            font.pixelSize: UIScale.fontTiny
            leftPadding: Math.round(2 * UIScale.value)
        }

        RowLayout {
            width: parent.width
            spacing: UIScale.spacingSm

            StyledTextInput {
                id: pskInput
                Layout.fillWidth: true
                placeholder: I18n.t("wifi.passwordForPlaceholder", [root.pendingNetwork ? root.pendingNetwork.name : ""])
                echoMode: root.pskVisible ? TextInput.Normal : TextInput.Password
                onAccepted: root._submitPsk()
            }

            Text {
                text: root.pskVisible ? "󰛐" : "󰛑"
                font.pixelSize: Math.round(16 * UIScale.value)
                color: eyeHov.hovered ? Colors.text : Colors.textDim
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                HoverHandler {
                    id: eyeHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pskVisible = !root.pskVisible
                }
            }

            Rectangle {
                implicitWidth: joinTxt.implicitWidth + UIScale.spacingMd
                implicitHeight: Math.round(36 * UIScale.value)
                radius: UIScale.radiusSm
                opacity: pskInput.text.length > 0 ? 1.0 : 0.45
                color: joinHov.hovered ? Colors.withAlpha(Colors.accent, 0.3) : Colors.withAlpha(Colors.accent, 0.18)
                border.color: Colors.withAlpha(Colors.accent, 0.35)
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }

                Text {
                    id: joinTxt
                    anchors.centerIn: parent
                    text: I18n.t("wifi.join")
                    color: Colors.accent
                    font.pixelSize: UIScale.fontSmall
                    font.weight: Font.Bold
                }

                HoverHandler {
                    id: joinHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: pskInput.text.length > 0
                    onClicked: root._submitPsk()
                }
            }
        }
    }

    function _submitPsk() {
        if (!root.pendingNetwork || pskInput.text.length === 0)
            return;
        root._lastPskNetwork = root.pendingNetwork;
        root.pendingNetwork.connectWithPsk(pskInput.text);
        root.pendingNetwork = null;
    }
}
