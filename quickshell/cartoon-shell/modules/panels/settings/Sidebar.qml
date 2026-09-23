import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Rectangle {
    id: root
    property int currentIndex: 0
    property bool anyItemHovered: false

    signal categoryChanged(int index)
    signal backRequested

    Layout.preferredWidth: ScalerService.s(200)
    Layout.fillHeight: true
    color: Qt.alpha(theme.primary.dim_background, 0.6)
    radius: ScalerService.s(Settings.appearance.radius2)

    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 700
            easing.type: Easing.Linear
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(12)
        anchors.topMargin: ScalerService.s(32)
        spacing: ScalerService.s(10)
        clip: true

        CustomText {
            name: lang.settings.title
            Layout.alignment: Qt.AlignHCenter
            size: "normal"
            isBold: true
            opacity: root.animationProgress > 0.3 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        // General
        Item {
            id: generalItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.3 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: generalButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.3 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.3 ? parent.height : 0
                color: mouseAreaGeneral.containsMouse || root.currentIndex === 0 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaGeneral.containsMouse || root.currentIndex === 0 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaGeneral.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/home.png"
                        opacity: root.animationProgress > 0.5 ? 1 : 0
                        rotation: mouseAreaGeneral.containsMouse ? 20 : 0
                        scale: mouseAreaGeneral.containsMouse ? 1.05 : 1.0
                        visible: Settings.appearance.styleIcons === "image"
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "home"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.general
                        size: "small"
                        textColor: mouseAreaGeneral.containsMouse || root.currentIndex === 0 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 0
                        opacity: root.animationProgress > 0.6 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 0 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 0 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 0
                        scale: root.currentIndex === 0 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaGeneral
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 0;
                        root.categoryChanged(0);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Appearance
        Item {
            id: appearanceItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.35 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: appearanceButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.35 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.35 ? parent.height : 0
                color: mouseAreaAppearance.containsMouse || root.currentIndex === 1 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaAppearance.containsMouse || root.currentIndex === 1 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaAppearance.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/paint-brush.png"
                        opacity: root.animationProgress > 0.55 ? 1 : 0
                        rotation: mouseAreaAppearance.containsMouse ? -20 : 0
                        scale: mouseAreaAppearance.containsMouse ? 1.05 : 1.0
                        visible: Settings.appearance.styleIcons === "image"
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "format_paint"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.appearance
                        size: "small"
                        textColor: mouseAreaAppearance.containsMouse || root.currentIndex === 1 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 1
                        opacity: root.animationProgress > 0.65 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 1 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 1 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 1
                        scale: root.currentIndex === 1 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaAppearance
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 1;
                        root.categoryChanged(1);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Network
        Item {
            id: networkItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.4 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: networkButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.4 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.4 ? parent.height : 0
                color: mouseAreaNetwork.containsMouse || root.currentIndex === 2 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaNetwork.containsMouse || root.currentIndex === 2 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaNetwork.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/network.png"
                        opacity: root.animationProgress > 0.6 ? 1 : 0
                        rotation: mouseAreaNetwork.containsMouse ? 15 : 0
                        scale: mouseAreaNetwork.containsMouse ? 1.05 : 1.0
                        visible: Settings.appearance.styleIcons === "image"
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "captive_portal"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.network
                        size: "small"
                        textColor: mouseAreaNetwork.containsMouse || root.currentIndex === 2 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 2
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 2 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 2 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 2
                        scale: root.currentIndex === 2 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaNetwork
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 2;
                        root.categoryChanged(2);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Audio
        Item {
            id: audioItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.45 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: audioButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.45 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.45 ? parent.height : 0
                color: mouseAreaAudio.containsMouse || root.currentIndex === 3 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaAudio.containsMouse || root.currentIndex === 3 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaAudio.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/volume.png"
                        opacity: root.animationProgress > 0.65 ? 1 : 0
                        rotation: mouseAreaAudio.containsMouse ? -10 : 0
                        scale: mouseAreaAudio.containsMouse ? 1.05 : 1.0
                        visible: Settings.appearance.styleIcons === "image"
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "brand_awareness"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.audio
                        size: "small"
                        textColor: mouseAreaAudio.containsMouse || root.currentIndex === 3 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 3
                        opacity: root.animationProgress > 0.75 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 3 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 3 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 3
                        scale: root.currentIndex === 3 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaAudio
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 3;
                        root.categoryChanged(3);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Performance
        Item {
            id: performanceItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.5 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: performanceButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.5 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.5 ? parent.height : 0
                color: mouseAreaPerformance.containsMouse || root.currentIndex === 4 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaPerformance.containsMouse || root.currentIndex === 4 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaPerformance.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/speedometer.png"
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                        rotation: mouseAreaPerformance.containsMouse ? 30 : 0
                        scale: mouseAreaPerformance.containsMouse ? 1.05 : 1.0
                        visible: Settings.appearance.styleIcons === "image"
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "avg_pace"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.performance
                        size: "small"
                        textColor: mouseAreaPerformance.containsMouse || root.currentIndex === 4 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 4
                        opacity: root.animationProgress > 0.8 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 4 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 4 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 4
                        scale: root.currentIndex === 4 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaPerformance
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 4;
                        root.categoryChanged(4);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Shortcuts
        Item {
            id: shortcutsItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.55 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: shortcutsButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.55 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.55 ? parent.height : 0
                color: mouseAreaShortcuts.containsMouse || root.currentIndex === 5 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaShortcuts.containsMouse || root.currentIndex === 5 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaShortcuts.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/keyboard.png"
                        opacity: root.animationProgress > 0.75 ? 1 : 0
                        rotation: mouseAreaShortcuts.containsMouse ? -15 : 0
                        visible: Settings.appearance.styleIcons === "image"
                        scale: mouseAreaShortcuts.containsMouse ? 1.05 : 1.0
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "keyboard"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.shortcuts
                        size: "small"
                        textColor: mouseAreaShortcuts.containsMouse || root.currentIndex === 5 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 5
                        opacity: root.animationProgress > 0.85 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 5 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 5 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 5
                        scale: root.currentIndex === 5 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaShortcuts
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 5;
                        root.categoryChanged(5);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // System
        Item {
            id: systemItem
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(50)
            opacity: root.animationProgress > 0.6 ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            CustomRectangle {
                id: systemButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.6 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.6 ? parent.height : 0
                color: mouseAreaSystem.containsMouse || root.currentIndex === 6 ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaSystem.containsMouse || root.currentIndex === 6 ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaSystem.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(12)

                    IconImage {
                        path: "settings/mark.png"
                        opacity: root.animationProgress > 0.8 ? 1 : 0
                        rotation: mouseAreaSystem.containsMouse ? 10 : 0
                        scale: mouseAreaSystem.containsMouse ? 1.05 : 1.0
                        visible: Settings.appearance.styleIcons === "image"
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    IconText {
                        name: "info"
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.system
                        size: "small"
                        textColor: mouseAreaSystem.containsMouse || root.currentIndex === 6 ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: root.currentIndex === 6
                        opacity: root.animationProgress > 0.9 ? 1 : 0
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: root.currentIndex === 6 ? ScalerService.s(4) : 0
                        Layout.preferredHeight: root.currentIndex === 6 ? ScalerService.s(20) : 0
                        radius: ScalerService.s(2)
                        color: theme.button.text
                        visible: root.currentIndex === 6
                        scale: root.currentIndex === 6 ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaSystem
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        root.currentIndex = 6;
                        root.categoryChanged(6);
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
