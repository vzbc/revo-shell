// Stage1Welcome.qml — Welcome + MorphingText + Terminal + Get Started + Avatars
import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    signal getStarted()

    readonly property var morphTexts: [
        "Welcome",
        "Quickshell",
        "Installer",
        "Revo Shell",
        "Dotfiles",
        "Hyprland",
        "Magic"
    ]

    // Terminal welcome sequence
    readonly property var terminalSteps: [
        { type: "cmd", text: "ls", delay: 500 },
        { type: "out", text: "Documents  Downloads  Pictures  Music", color: "default", delay: 700 },
        { type: "cmd", text: "cd Quickshell", delay: 600 },
        { type: "cmd", text: "pwd", delay: 500 },
        { type: "out", text: "/home/user/Quickshell", color: "green", delay: 700 },
        { type: "cmd", text: "./welcome.sh", delay: 600 },
        { type: "out", text: "Welcome to Revo Shell — your dots, one installer.", color: "blue", delay: 900 }
    ]

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 860)
        spacing: 36

        // 1) Morphing welcome
        MorphingText {
            id: morph
            anchors.horizontalCenter: parent.horizontalCenter
            texts: root.morphTexts
            pixelSize: 56
            color: "#FFFFFF"
            intervalMs: 1500
            morphMs: 700
            running: root.visible
        }

        // 2) Terminal welcome
        TerminalTyping {
            id: term
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 620)
            height: 240
            lines: root.terminalSteps
            running: root.visible
        }

        // 3) CTA panel (particles + Get Started)
        ParticleCta {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 720)
            height: 240
            heading: "Build something magical"
            subheading: "A pseudo-3D particle background that stays behind your content with continuous rotation and buoyant drift."
            buttonLabel: "Get Started"
            onGetStarted: root.getStarted()
        }

        // 4) Avatar circles — social proof
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            AvatarCircles {
                anchors.verticalCenter: parent.verticalCenter
                avatars: [
                    { initials: "RV", image: "../../resources/avatars/avatar1.jpg" },
                    { initials: "QS", image: "../../resources/avatars/avatar2.jpg" },
                    { initials: "HY", image: "../../resources/avatars/avatar3.jpg" },
                    { initials: "DX", image: "../../resources/avatars/avatar4.jpg" }
                ]
                numPeople: 128
                avatarSize: 40
                overlap: -16
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Joined by 128+ builders this week"
                size: 14
                tone: "#6E6E73"
            }
        }
    }
}
