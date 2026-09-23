import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons

Item {
    id: effectsSettings

    property string homePath: {
        try {
            return Directories.home;
        } catch (e) {
            console.log("Directories.home unavailable, falling back to $HOME:", e);
            return Quickshell.env ? (Quickshell.env("HOME") || "") : "";
        }
    }

    // Workspace scrolling effects list
    property var effectsModel: [
        {
            key: "android",
            name: lang?.effects?.android_name || "Android Fluent",
            previewType: "android",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 4.0, bezier = \"quick\", style = \"slidefade 20%\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 4.0, bezier = \"quick\", style = \"slidefade 20%\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 4.0, bezier = \"quick\", style = \"slidefade 20%\" })"
        },
        {
            key: "zorin",
            name: lang?.effects?.zorin_name || "Zorin OS Glide",
            previewType: "zorin",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 6.0, bezier = \"easeInOutCubic\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 6.0, bezier = \"easeInOutCubic\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 6.0, bezier = \"easeInOutCubic\", style = \"slide\" })"
        },
        {
            key: "jelly",
            name: lang?.effects?.jelly_name || "Jelly Bounce",
            previewType: "jelly",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 5.0, spring = \"easy\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 5.0, spring = \"easy\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 5.0, spring = \"easy\", style = \"slide\" })"
        },
        {
            key: "deck",
            name: lang?.effects?.deck_name || "Vertical Deck",
            previewType: "deck",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 5.0, bezier = \"easeOutQuint\", style = \"slidevert\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 5.0, bezier = \"easeOutQuint\", style = \"slidevert\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 5.0, bezier = \"easeOutQuint\", style = \"slidevert\" })"
        },
        {
            key: "cinematic",
            name: lang?.effects?.cinematic_name || "Cinematic Fade",
            previewType: "cinematic",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 3.5, bezier = \"almostLinear\", style = \"fade\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 3.5, bezier = \"almostLinear\", style = \"fade\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 3.5, bezier = \"almostLinear\", style = \"fade\" })"
        },
        {
            key: "swift",
            name: lang?.effects?.swift_name || "Swift Glitch",
            previewType: "swift",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 1.8, bezier = \"linear\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 1.8, bezier = \"linear\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 1.8, bezier = \"linear\", style = \"slide\" })"
        },
        {
            key: "zorin-plus",
            name: lang?.effects?.zorinplus_name || "Zorin Glide+ (Deluxe)",
            previewType: "zorinPlus",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 7.0, bezier = \"silk\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 7.0, bezier = \"silk\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 7.0, bezier = \"silk\", style = \"slide\" })"
        },
        {
            key: "zorin-bounce",
            name: lang?.effects?.zorinbounce_name || "Zorin Soft Bounce",
            previewType: "zorinBounce",
            hyprConfig: "hl.animation({ leaf = \"workspaces\", enabled = true, speed = 5.2, bezier = \"overshot\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesIn\", enabled = true, speed = 5.2, bezier = \"overshot\", style = \"slide\" })\nhl.animation({ leaf = \"workspacesOut\", enabled = true, speed = 5.2, bezier = \"overshot\", style = \"slide\" })"
        }
    ]

    property string currentEffect: {
        try {
            return Settings.effects.workspaceAnimation || "android";
        } catch (e) {
            return "android";
        }
    }

    Process {
        id: applyEffectProcess
        stdout: StdioCollector {
            onTextChanged: {}
        }
        onRunningChanged: {
            if (!running) {
                showNotification(lang?.effects?.success_apply || "Effect applied successfully!");
            }
        }
    }

    function applyEffect(effectData) {
        var confDir = homePath + "/.config/hypr/custom/effects";
        var confFile = confDir + "/workspace-animation.lua";
        var script = "mkdir -p '" + confDir + "' && cat > '" + confFile + "' <<'EOF'\n" + effectData.hyprConfig + "\nEOF\nhyprctl reload";
        applyEffectProcess.command = ["bash", "-c", script];
        applyEffectProcess.running = true;
        try {
            Settings.effects.workspaceAnimation = effectData.key;
        } catch (e) {
            console.log("Settings.effects.workspaceAnimation not initialized.");
        }
        effectsSettings.currentEffect = effectData.key;
    }

    ListView {
        id: scrollView
        anchors.fill: parent
        clip: true
        anchors.margins: ScalerService.s(20)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        focus: true
        model: 1

        delegate: ColumnLayout {
            id: mainLayout
            width: scrollView.width
            spacing: ScalerService.s(15)

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)
                Text {
                    text: lang?.effects?.title || "Hyprland Effects"
                    color: theme.primary.foreground
                    font.pixelSize: ScalerService.s(24)
                    font.bold: true
                    font.family: "ComicShannsMono Nerd Font"
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
            }

            Text {
                Layout.fillWidth: true
                text: lang?.effects?.subtitle || "Hover to preview animation. Click to apply."
                color: theme.primary.dim_foreground
                font.pixelSize: ScalerService.s(13)
                font.family: "ComicShannsMono Nerd Font"
                wrapMode: Text.WordWrap
            }

            // Grid 3 columns
            GridLayout {
                id: effectsGrid
                Layout.fillWidth: true
                columns: 3
                columnSpacing: ScalerService.s(8)
                rowSpacing: ScalerService.s(8)

                Repeater {
                    model: effectsSettings.effectsModel

                    delegate: Rectangle {
                        id: effectCard
                        Layout.fillWidth: true
                        Layout.minimumWidth: ScalerService.s(120)
                        Layout.preferredHeight: ScalerService.s(180)
                        radius: ScalerService.s(12)
                        color: Qt.alpha(theme.button.background, 0.5)
                        border.color: cardMouseArea.containsMouse ? theme.normal.blue : theme.button.border
                        border.width: ScalerService.s(effectsSettings.currentEffect === modelData.key ? 2 : 1)

                        property var effectData: modelData
                        property bool isCurrent: effectsSettings.currentEffect === modelData.key

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: ScalerService.s(10)
                            spacing: ScalerService.s(8)

                            // Preview Box
                            Rectangle {
                                id: previewBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScalerService.s(85)
                                radius: ScalerService.s(8)
                                clip: true
                                color: Qt.alpha(theme.primary.background, 0.6)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: ScalerService.s(25)
                                    Repeater {
                                        model: 3
                                        delegate: Rectangle {
                                            width: ScalerService.s(8)
                                            height: ScalerService.s(8)
                                            radius: ScalerService.s(4)
                                            color: theme.primary.dim_foreground
                                            opacity: 0.3
                                        }
                                    }
                                }

                                // Animated Block
                                Rectangle {
                                    id: previewBlock
                                    width: ScalerService.s(22)
                                    height: ScalerService.s(22)
                                    radius: ScalerService.s(6)
                                    color: theme.normal.blue
                                    anchors.verticalCenter: previewBox.verticalCenter
                                    x: ScalerService.s(12)

                                    // Animation definitions
                                    PropertyAnimation {
                                        id: animAndroid
                                        target: previewBlock
                                        property: "x"
                                        to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                        duration: 600
                                        easing.type: Easing.OutQuart
                                    }
                                    PropertyAnimation {
                                        id: animZorin
                                        target: previewBlock
                                        property: "x"
                                        to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                        duration: 900
                                        easing.type: Easing.InOutCubic
                                    }
                                    PropertyAnimation {
                                        id: animJelly
                                        target: previewBlock
                                        property: "x"
                                        to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                        duration: 800
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.0
                                    }
                                    SequentialAnimation {
                                        id: animDeck
                                        PropertyAnimation {
                                            target: previewBlock
                                            property: "anchors.verticalCenterOffset"
                                            to: previewBox.height
                                            duration: 250
                                            easing.type: Easing.InQuint
                                        }
                                        PropertyAnimation {
                                            target: previewBlock
                                            property: "x"
                                            to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                            duration: 1
                                        }
                                        PropertyAnimation {
                                            target: previewBlock
                                            property: "anchors.verticalCenterOffset"
                                            to: 0
                                            duration: 250
                                            easing.type: Easing.OutQuint
                                        }
                                    }
                                    SequentialAnimation {
                                        id: animCinematic
                                        PropertyAnimation {
                                            target: previewBlock
                                            property: "opacity"
                                            to: 0.0
                                            duration: 400
                                            easing.type: Easing.Linear
                                        }
                                        PropertyAnimation {
                                            target: previewBlock
                                            property: "x"
                                            to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                            duration: 1
                                        }
                                        PropertyAnimation {
                                            target: previewBlock
                                            property: "opacity"
                                            to: 1.0
                                            duration: 400
                                            easing.type: Easing.Linear
                                        }
                                    }
                                    PropertyAnimation {
                                        id: animSwift
                                        target: previewBlock
                                        property: "x"
                                        to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                        duration: 250
                                        easing.type: Easing.Linear
                                    }
                                    PropertyAnimation {
                                        id: animZorinPlus
                                        target: previewBlock
                                        property: "x"
                                        to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                        duration: 1100
                                        easing.type: Easing.InOutCubic
                                    }
                                    PropertyAnimation {
                                        id: animZorinBounce
                                        target: previewBlock
                                        property: "x"
                                        to: previewBox.width - previewBlock.width - ScalerService.s(12)
                                        duration: 850
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 1.3
                                    }

                                    function getAnimation() {
                                        switch (effectCard.effectData.previewType) {
                                        case "android":
                                            return animAndroid;
                                        case "zorin":
                                            return animZorin;
                                        case "jelly":
                                            return animJelly;
                                        case "deck":
                                            return animDeck;
                                        case "cinematic":
                                            return animCinematic;
                                        case "swift":
                                            return animSwift;
                                        case "zorinPlus":
                                            return animZorinPlus;
                                        case "zorinBounce":
                                            return animZorinBounce;
                                        default:
                                            return animAndroid;
                                        }
                                    }

                                    function stopAll() {
                                        var anims = [animAndroid, animZorin, animJelly, animDeck, animCinematic, animSwift, animZorinPlus, animZorinBounce];
                                        for (var i = 0; i < anims.length; i++) {
                                            anims[i].stop();
                                        }
                                    }

                                    // Auto-play animation loop
                                    Timer {
                                        id: loopTimer
                                        interval: 3000
                                        repeat: true
                                        running: true
                                        onTriggered: {
                                            previewBlock.stopAll();
                                            previewBlock.x = ScalerService.s(12);
                                            previewBlock.scale = 1.0;
                                            previewBlock.rotation = 0.0;
                                            previewBlock.opacity = 1.0;
                                            previewBlock.anchors.verticalCenterOffset = 0;
                                            previewBlock.getAnimation().start();
                                        }
                                    }

                                    Component.onCompleted: {
                                        loopTimer.start();
                                    }
                                }

                                // Checkmark
                                Rectangle {
                                    visible: effectCard.isCurrent
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: ScalerService.s(6)
                                    width: ScalerService.s(22)
                                    height: ScalerService.s(22)
                                    radius: ScalerService.s(11)
                                    color: theme.normal.green
                                    z: 5
                                    Text {
                                        text: "✓"
                                        color: theme.primary.background
                                        font.pixelSize: ScalerService.s(12)
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            // Effect name
                            Text {
                                Layout.fillWidth: true
                                text: effectCard.effectData.name
                                color: theme.primary.foreground
                                font.pixelSize: ScalerService.s(14)
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            // Apply button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScalerService.s(32)
                                radius: ScalerService.s(6)
                                color: effectCard.isCurrent ? theme.normal.green : theme.normal.blue
                                Text {
                                    anchors.centerIn: parent
                                    text: effectCard.isCurrent ? "✓ Applied" : "Apply"
                                    color: theme.primary.background
                                    font.pixelSize: ScalerService.s(12)
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: {
                                // Pause auto-loop and play preview once
                                loopTimer.stop();
                                previewBlock.stopAll();
                                previewBlock.x = ScalerService.s(12);
                                previewBlock.scale = 1.0;
                                previewBlock.rotation = 0.0;
                                previewBlock.opacity = 1.0;
                                previewBlock.anchors.verticalCenterOffset = 0;
                                previewBlock.getAnimation().start();
                            }

                            onExited: {
                                previewBlock.stopAll();
                                previewBlock.x = ScalerService.s(12);
                                previewBlock.scale = 1.0;
                                previewBlock.rotation = 0.0;
                                previewBlock.opacity = 1.0;
                                previewBlock.anchors.verticalCenterOffset = 0;
                                loopTimer.start();
                            }

                            onClicked: {
                                effectsSettings.applyEffect(effectCard.effectData);
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // Notification
    Rectangle {
        id: successNotification
        visible: false
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: ScalerService.s(30)
        width: ScalerService.s(280)
        height: ScalerService.s(45)
        radius: ScalerService.s(22)
        color: theme.normal.green
        z: 1001

        Row {
            anchors.centerIn: parent
            spacing: ScalerService.s(10)
            Text {
                text: "✓"
                color: theme.primary.background
                font.bold: true
                font.pixelSize: ScalerService.s(16)
            }
            Text {
                id: notificationText
                color: theme.primary.background
                text: ""
                font.bold: true
                font.pixelSize: ScalerService.s(14)
            }
        }

        Timer {
            id: notificationTimer
            interval: 3500
            onTriggered: successNotification.visible = false
        }
    }

    function showNotification(message) {
        notificationText.text = message;
        successNotification.visible = true;
        notificationTimer.start();
    }
}
