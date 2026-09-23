import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: leftCard

    property var rootRef
    signal popoutRequested(var item)

    // Direct O(1) button registry (Fix #23)
    property var buttonMap: ({})

    function registerButton(key, item) {
        buttonMap[key] = item
    }

    function getButton(key) {
        if (Config.leftCardCollapsed && !Config.isPinned(key)) return null
        let btn = buttonMap[key]
        return (btn && btn.visible) ? btn : null
    }

    readonly property real maxAllowedWidth: parent ? Math.max(100, parent.width - 320) : 1920
    readonly property real maxAllowedHeight: parent ? Math.max(100, parent.height - 260) : 1080

    readonly property real contentTargetWidth: Math.min(leftModules.implicitWidth + 8, maxAllowedWidth)
    readonly property real contentTargetHeight: Math.min(leftModules.implicitHeight + 8, maxAllowedHeight)

    width: (rootRef && rootRef.isHorizontal) ? contentTargetWidth : Math.max(36, leftModules.implicitWidth + 8)
    height: (rootRef && rootRef.isHorizontal) ? 36 : Math.max(36, contentTargetHeight)
    radius: Config.cornerRadius / 2
    color: Qt.rgba(255, 255, 255, 0.05)
    border.width: 1
    border.color: Qt.rgba(255, 255, 255, 0.1)
    clip: true

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    states: [
        State {
            name: "horizontal"
            when: rootRef && rootRef.isHorizontal
            AnchorChanges {
                target: leftCard
                anchors.left: leftCard.parent.left
                anchors.verticalCenter: leftCard.parent.verticalCenter
                anchors.top: undefined
                anchors.horizontalCenter: undefined
            }
        },
        State {
            name: "vertical"
            when: rootRef && !rootRef.isHorizontal
            AnchorChanges {
                target: leftCard
                anchors.top: leftCard.parent.top
                anchors.horizontalCenter: leftCard.parent.horizontalCenter
                anchors.left: undefined
                anchors.verticalCenter: undefined
            }
        }
    ]

    anchors.leftMargin: rootRef.isHorizontal ? 30 : 0
    anchors.topMargin: !rootRef.isHorizontal ? 30 : 0

    property bool iconsFullyExpanded: false

    Component.onCompleted: {
        if (!Config.leftCardCollapsed) {
            iconsFullyExpanded = true
        }
    }

    Connections {
        target: Config
        ignoreUnknownSignals: true
        function onLeftCardCollapsedChanged() {
            if (!Config.leftCardCollapsed) {
                iconsFullyExpanded = false
                expandTimer.restart()
            } else {
                iconsFullyExpanded = false
            }
        }
    }

    readonly property bool showUnpinnedLoaders: !Config.leftCardCollapsed

    Timer {
        id: expandTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (!Config.leftCardCollapsed) {
                iconsFullyExpanded = true
            }
        }
    }

    GridLayout {
        id: leftModules

        states: [
            State {
                name: "horizontal"
                when: rootRef && rootRef.isHorizontal
                AnchorChanges {
                    target: leftModules
                    anchors.left: leftCard.left
                    anchors.verticalCenter: leftCard.verticalCenter
                    anchors.top: undefined
                    anchors.horizontalCenter: undefined
                }
                PropertyChanges {
                    target: leftModules
                    anchors.leftMargin: 4
                    anchors.topMargin: 0
                }
            },
            State {
                name: "vertical"
                when: rootRef && !rootRef.isHorizontal
                AnchorChanges {
                    target: leftModules
                    anchors.top: leftCard.top
                    anchors.horizontalCenter: leftCard.horizontalCenter
                    anchors.left: undefined
                    anchors.verticalCenter: undefined
                }
                PropertyChanges {
                    target: leftModules
                    anchors.leftMargin: 0
                    anchors.topMargin: 4
                }
            }
        ]

        columns: (rootRef && rootRef.isHorizontal) ? 99 : 1
        rows: (rootRef && rootRef.isHorizontal) ? 1 : 99
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            id: repeater
            model: Config.leftCardOrder || [
                "power",
                "recorder",
                "mirror",
                "network",
                "clipboard",
                "wallpaper",
                "launcher",
                "audio",
                "settings",
                "screenshot"
            ]

            delegate: Loader {
                readonly property string itemKey: modelData
                
                visible: sourceComponent !== null && (
                    (itemKey === "batt" && typeof shellRoot !== "undefined" && !shellRoot.hasBattery) 
                        ? false 
                        : (leftCard.showUnpinnedLoaders || Config.isPinned(itemKey))
                )

                opacity: {
                    if (Config.isPinned(itemKey)) return 1.0
                    return leftCard.iconsFullyExpanded ? 1.0 : 0.0
                }

                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }

                onLoaded: {
                    if (item) {
                        leftCard.registerButton(itemKey, item)
                    }
                }

                sourceComponent: {
                    switch(itemKey) {
                        case "power": return powerComp
                        case "recorder": return recorderComp
                        case "mirror": return mirrorComp
                        case "network": return networkComp
                        case "clipboard": return clipComp
                        case "wallpaper": return wallpaperComp
                        case "launcher": return launcherComp
                        case "audio": return audioComp
                        case "settings": return settingsComp
                        case "screenshot": return screenshotComp
                        case "batt": return battComp
                        default: return null
                    }
                }
            }
        }

        Rectangle {
            implicitWidth: 32; implicitHeight: 32; radius: 10
            color: "transparent"

            Item {
                anchors.centerIn: parent
                implicitWidth: chevronIconText.implicitWidth
                implicitHeight: chevronIconText.implicitHeight
                scale: chevronLeftHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: chevronIconText
                    source: chevronIconText
                    radius: chevronLeftHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: chevronLeftHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: chevronIconText
                    anchors.centerIn: parent
                    text: {
                        if (rootRef.isHorizontal) return Config.leftCardCollapsed ? "chevron_right" : "chevron_left"
                        return Config.leftCardCollapsed ? "expand_more" : "expand_less"
                    }
                    color: chevronLeftHover.hovered ? Config.accent : Config.textMuted
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            TapHandler { onTapped: Config.leftCardCollapsed = !Config.leftCardCollapsed }
            HoverHandler { id: chevronLeftHover; cursorShape: Qt.PointingHandCursor }
        }
    }

    Component {
        id: powerComp
        Rectangle {
            id: btnPower
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Config.showPower ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: powerIconText.implicitWidth
                implicitHeight: powerIconText.implicitHeight
                scale: powerHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: powerIconText
                    source: powerIconText
                    radius: powerHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: powerHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: powerIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("power")
                    color: (Config.showPower || powerHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("power")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnPower)
                    Config.showPower = !Config.showPower 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("power") }
            HoverHandler { 
                id: powerHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnPower)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: recorderComp
        Rectangle {
            id: btnRecorder
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Config.showScreenRecorder ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

            // Local recording state polled continuously
            property bool isRecording: false

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: recorderCheckProc.running = true
            }

            Process {
                id: recorderCheckProc
                command: ["pgrep", "-x", "wf-recorder"]
                running: false
                onExited: (code, status) => {
                    btnRecorder.isRecording = (code === 0)
                }
            }

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: recordIconText.implicitWidth
                implicitHeight: recordIconText.implicitHeight
                scale: recordHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: recordIconText
                    source: recordIconText
                    radius: (btnRecorder.isRecording || recordHover.hovered) ? 8 : 0
                    samples: 16
                    color: btnRecorder.isRecording ? "#ef4444" : Config.accent
                    spread: btnRecorder.isRecording ? 0.35 : 0.2
                    transparentBorder: true
                    visible: btnRecorder.isRecording || recordHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    id: recordIconText
                    anchors.centerIn: parent
                    text: btnRecorder.isRecording ? "radio_button_checked" : Config.getIcon("recorder")
                    color: btnRecorder.isRecording ? "#ef4444" : ((Config.showScreenRecorder || recordHover.hovered) ? Config.accent : Config.textMain)
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: btnRecorder.isRecording ? "#ef4444" : Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("recorder")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnRecorder)
                    Config.showScreenRecorder = !Config.showScreenRecorder 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("recorder") }
            HoverHandler { 
                id: recordHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnRecorder)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: mirrorComp
        Rectangle {
            id: btnMirror
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Config.showMirror ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: mirrorIconText.implicitWidth
                implicitHeight: mirrorIconText.implicitHeight
                scale: mirrorHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: mirrorIconText
                    source: mirrorIconText
                    radius: mirrorHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: mirrorHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: mirrorIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("mirror")
                    color: (Config.showMirror || mirrorHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("mirror")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    Config.showMirror = !Config.showMirror 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("mirror") }
            HoverHandler { 
                id: mirrorHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnMirror)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: screenshotComp
        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: snapIconText.implicitWidth
                implicitHeight: snapIconText.implicitHeight
                scale: screenshotHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: snapIconText
                    source: snapIconText
                    radius: screenshotHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: screenshotHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: snapIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("screenshot")
                    color: screenshotHover.hovered ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("screenshot")
            }

            TapHandler { onTapped: Quickshell.execDetached(["fish", "-c", "sleep 0.1; and grim -g (slurp) -t ppm - | satty --filename -"]) }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("screenshot") }
            HoverHandler { id: screenshotHover; cursorShape: Qt.PointingHandCursor }
        }
    }

    Component {
        id: wallpaperComp
        Rectangle {
            id: btnWallpaper
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Config.showWallpaper ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: wallIconText.implicitWidth
                implicitHeight: wallIconText.implicitHeight
                scale: wallpaperHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: wallIconText
                    source: wallIconText
                    radius: wallpaperHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: wallpaperHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: wallIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("wallpaper")
                    color: (Config.showWallpaper || wallpaperHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("wallpaper")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnWallpaper)
                    Config.showWallpaper = !Config.showWallpaper 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("wallpaper") }
            HoverHandler { 
                id: wallpaperHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnWallpaper)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: settingsComp
        Rectangle {
            id: btnSettings
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Config.showSettings ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: settingsIconText.implicitWidth
                implicitHeight: settingsIconText.implicitHeight
                scale: settingsHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: settingsIconText
                    source: settingsIconText
                    radius: settingsHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: settingsHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: settingsIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("settings")
                    color: (Config.showSettings || settingsHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("settings")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnSettings)
                    Config.showSettings = !Config.showSettings 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("settings") }
            HoverHandler { 
                id: settingsHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnSettings)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: launcherComp
        Rectangle {
            id: btnLauncher
            implicitWidth: 32
            implicitHeight: 32
            radius: 10
            color: Config.showAppLauncher ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: launcherIconText.implicitWidth
                implicitHeight: launcherIconText.implicitHeight
                scale: launcherHover.hovered ? 1.25 : 1.0

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: launcherIconText
                    source: launcherIconText
                    radius: launcherHover.hovered ? 8 : 0
                    samples: 16
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: launcherHover.hovered

                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: launcherIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("launcher")
                    color: (Config.showAppLauncher || launcherHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("launcher")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnLauncher)
                    Config.showAppLauncher = !Config.showAppLauncher 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("launcher") }
            HoverHandler { 
                id: launcherHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnLauncher)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: audioComp
        Rectangle {
            id: btnAudio
            implicitWidth: 32; implicitHeight: 32; radius: 10
            color: Config.showAudio ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: audioIconText.implicitWidth; implicitHeight: audioIconText.implicitHeight
                scale: audioHover.hovered ? 1.25 : 1.0
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: audioIconText; source: audioIconText
                    radius: audioHover.hovered ? 8 : 0; samples: 16
                    color: Config.accent; spread: 0.2; transparentBorder: true
                    visible: audioHover.hovered
                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: audioIconText
                    anchors.centerIn: parent
                    text: shellRoot.audioMuted ? "hearing_disabled" : (shellRoot.audioVolume === 0 ? "hearing_disabled" : Config.getIcon("audio"))
                    color: (Config.showAudio || audioHover.hovered) ? Config.accent : (shellRoot.audioMuted ? Config.textMuted : Config.textMain)
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 18
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("audio")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnAudio)
                    Config.showAudio = !Config.showAudio 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("audio") }
            HoverHandler { 
                id: audioHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnAudio)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: battComp
        Rectangle {
            id: btnBatt
            implicitWidth: 32; implicitHeight: 32; radius: 10
            color: Config.showBattery ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: battIconText.implicitWidth; implicitHeight: battIconText.implicitHeight
                scale: battHover.hovered ? 1.25 : 1.0
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: battIconText; source: battIconText
                    radius: battHover.hovered ? 8 : 0; samples: 16
                    color: Config.accent; spread: 0.2; transparentBorder: true
                    visible: battHover.hovered
                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: battIconText
                    anchors.centerIn: parent
                    text: {
                        if (shellRoot.battStatus === "Charging") return "battery_android_frame_bolt"
                        if (shellRoot.battCapacity <= 10) return "battery_android_0"
                        if (shellRoot.battCapacity <= 25) return "battery_android_frame_1"
                        if (shellRoot.battCapacity <= 40) return "battery_android_frame_2"
                        if (shellRoot.battCapacity <= 60) return "battery_android_frame_3"
                        if (shellRoot.battCapacity <= 75) return "battery_android_frame_4"
                        if (shellRoot.battCapacity <= 90) return "battery_android_frame_5"
                        if (shellRoot.battCapacity < 100) return "battery_android_frame_6"
                        return "battery_android_frame_full"
                    }
                    color: (Config.showBattery || battHover.hovered) ? Config.accent : (shellRoot.battCapacity <= 15 ? "#ef4444" : Config.textMain)
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 18
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("batt")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnBatt)
                    Config.showBattery = !Config.showBattery 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("batt") }
            HoverHandler { 
                id: battHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnBatt)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: networkComp
        Rectangle {
            id: btnNetwork
            implicitWidth: 32; implicitHeight: 32; radius: 10
            color: Config.showNetwork ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: netIconText.implicitWidth; implicitHeight: netIconText.implicitHeight
                scale: networkHover.hovered ? 1.25 : 1.0
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: netIconText; source: netIconText
                    radius: networkHover.hovered ? 8 : 0; samples: 16
                    color: Config.accent; spread: 0.2; transparentBorder: true
                    visible: networkHover.hovered
                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: netIconText
                    anchors.centerIn: parent
                    text: shellRoot.vpnActive ? "vpn_key" : Config.getIcon("network")
                    color: (Config.showNetwork || networkHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 18
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("network")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnNetwork)
                    Config.showNetwork = !Config.showNetwork 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("network") }
            HoverHandler { 
                id: networkHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnNetwork)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }

    Component {
        id: clipComp
        Rectangle {
            id: btnClipboard
            implicitWidth: 32; implicitHeight: 32; radius: 10
            color: Config.showClipboard ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Item {
                anchors.centerIn: parent
                implicitWidth: clipIconText.implicitWidth; implicitHeight: clipIconText.implicitHeight
                scale: clipHover.hovered ? 1.25 : 1.0
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                Glow {
                    anchors.fill: clipIconText; source: clipIconText
                    radius: clipHover.hovered ? 8 : 0; samples: 16
                    color: Config.accent; spread: 0.2; transparentBorder: true
                    visible: clipHover.hovered
                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                Text {
                    id: clipIconText
                    anchors.centerIn: parent
                    text: Config.getIcon("clipboard")
                    color: (Config.showClipboard || clipHover.hovered) ? Config.accent : Config.textMain
                    font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 20
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.topMargin: 2; anchors.rightMargin: 2
                width: 5; height: 5; radius: 2.5
                color: Config.accent
                visible: !Config.leftCardCollapsed && Config.isPinned("clipboard")
            }

            TapHandler { 
                onTapped: { 
                    if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    popoutRequested(btnClipboard)
                    Config.showClipboard = !Config.showClipboard 
                } 
            }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: Config.togglePin("clipboard") }
            HoverHandler { 
                id: clipHover
                cursorShape: Qt.PointingHandCursor 
                onHoveredChanged: {
                    if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnClipboard)
                    else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                }
            }
        }
    }
}