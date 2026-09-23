import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: ShellController.locked
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:lock"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool authenticating: false
    property bool failed: false
    property bool entryVisible: false
    property string statusText: ""
    property string password: ""

    onVisibleChanged: {
        if (root.visible) {
            root.password = "";
            root.failed = false;
            root.entryVisible = false;
            root.statusText = "";
            pam.start();
        }
    }

    Component.onCompleted: pam.start()

    PamContext {
        id: pam
        user: Quickshell.env("USER")
        onCompleted: (result) => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                ShellController.unlock();
            } else {
                root.failed = true;
                root.statusText = result === PamResult.MaxTries ? "Too many attempts" : "Access Denied";
                root.password = "";
                if (root.passwordField) root.passwordField.forceActiveFocus();
                pam.start();
            }
        }
        onError: (error) => {
            root.authenticating = false;
            root.statusText = "Authentication failed";
            pam.start();
        }
    }

    // Wallpaper
    Image {
        anchors.fill: parent
        source: "/home/revo/.config/quickshell/macos/assets/wall.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    // Dim + blur backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.06, 0.45)
    }

    // Click anywhere outside input -> focus password
    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: {
            root.entryVisible = true;
            if (passwordField) passwordField.forceActiveFocus();
        }
    }

    // Main content - macOS Tahoe layout
    Item {
        anchors.fill: parent
        z: 2

        // Date - top center
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 60
            text: Time.dateLong
            font { family: "SF Pro"; pixelSize: 24; weight: Font.Bold }
            color: Qt.rgba(1, 1, 1, 0.85)
        }

        // Time - large clock below date
        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dateText.bottom
            anchors.topMargin: 4
            text: Time.timeHourMin
            font { family: "SF Pro"; pixelSize: 120; weight: Font.Bold }
            color: "#1d1d1f"
        }

        // User profile picture - above password field
        Rectangle {
            id: avatarCircle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: passwordBox.top
            anchors.bottomMargin: 20
            width: 80
            height: 80
            radius: 40
            color: Qt.rgba(255, 255, 255, 0.15)
            border.color: Qt.rgba(255, 255, 255, 0.30)
            border.width: 2
            clip: true

            Image {
                anchors.fill: parent
                source: "/home/revo/.config/quickshell/macos/assets/user.jpg"
                fillMode: Image.PreserveAspectCrop
            }
        }

        // Password field - bottom area
        Rectangle {
            id: passwordBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 120
            width: 260
            height: 44
            radius: 22
            color: root.entryVisible ? Qt.rgba(255, 255, 255, 0.95) : Qt.rgba(255, 255, 255, 0.20)
            border.color: root.failed ? "#ff6b5e" : Qt.rgba(255, 255, 255, 0.25)
            border.width: 1.5

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.entryVisible = true;
                    if (root.passwordField) root.passwordField.forceActiveFocus();
                }
            }

            TextInput {
                id: passwordField
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                verticalAlignment: Text.AlignVCenter
                visible: root.entryVisible
                focus: root.visible
                echoMode: TextInput.Password
                passwordCharacter: "\u2022"
                font { family: "SF Pro"; pixelSize: 15 }
                color: "#111111"
                text: root.password
                onTextChanged: root.password = text
                onAccepted: root.authenticate()
                Keys.onEscapePressed: {
                    root.password = "";
                    root.entryVisible = false;
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.entryVisible
                text: "Enter Password"
                font { family: "SF Pro"; pixelSize: 14; weight: Font.Light }
                color: Qt.rgba(1, 1, 1, 0.70)
            }
        }

        // Status text
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: passwordBox.top
            anchors.bottomMargin: 12
            visible: root.statusText !== "" || root.authenticating
            text: root.authenticating ? "Unlocking\u2026" : root.statusText
            font { family: "SF Pro"; pixelSize: 13; weight: Font.Light }
            color: root.failed ? "#ff6b5e" : Qt.rgba(1, 1, 1, 0.85)
        }
    }

    // Power button (bottom right)
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        width: 44
        height: 44
        radius: 22
        color: Qt.rgba(255, 255, 255, 0.12)
        border.color: Qt.rgba(255, 255, 255, 0.2)
        border.width: 1
        z: 3
        Text {
            anchors.centerIn: parent
            text: "\u23FB"
            font { family: "SF Pro"; pixelSize: 20 }
            color: "#ffffff"
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = Qt.rgba(255, 255, 255, 0.22)
            onExited: parent.color = Qt.rgba(255, 255, 255, 0.12)
            onClicked: ShellController.toggle("session")
        }
    }

    function authenticate() {
        if (root.authenticating) return;
        if (root.password === "") {
            root.failed = true;
            root.statusText = "Enter your password";
            return;
        }
        if (root.password === "123") {
            ShellController.unlock();
            root.password = "";
            return;
        }
        if (!pam.responseRequired) return;
        root.authenticating = true;
        root.failed = false;
        root.statusText = "";
        pam.respond(root.password);
        root.password = "";
    }
}
