import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import ".."

Scope {
    id: lockscreenScope

    // Session lock state bound to ShellRoot or Config
    property bool sessionLocked: Config.sessionLocked
    property var shellRef: null

    onSessionLockedChanged: {
        if (sessionLocked) {
            lockscreenScope.clearInput()
        }
    }

    // Shared global password state across ALL monitor surfaces
    property string currentPassword: ""
    property bool isAuthenticating: false
    property bool isError: false
    property bool isSuccess: false
    property bool capsLockActive: false
    property string authStatus: "System Locked"
    property var shapeItems: []

    // Active User Information
    readonly property string currentUsername: Quickshell.env("USER") || "user"
    property string realName: Quickshell.env("USER") || "User"
    property string userAvatarPath: ""

    // Fetch user real name from getent / passwd
    Process {
        id: userInfoProc
        command: ["bash", "-c", "getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let name = this.text.trim()
                if (name.length > 0) {
                    lockscreenScope.realName = name
                }
            }
        }
    }

    // Check for user avatar (.face, .face.icon, or AccountsService)
    Process {
        id: avatarDetectProc
        command: [
            "bash", "-c",
            "for p in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$USER\"; do " +
            "if [ -f \"$p\" ]; then echo \"$p\"; break; fi; done"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let path = this.text.trim()
                if (path.length > 0) {
                    lockscreenScope.userAvatarPath = path
                }
            }
        }
    }

    // Media Control via MPRIS / Playerctl
    property string currentTrackTitle: ""
    property string currentTrackArtist: ""
    property string currentTrackStatus: "Stopped"
    property bool hasActiveMedia: currentTrackStatus === "Playing" || currentTrackStatus === "Paused"

    Process {
        id: mediaInfoProc
        command: ["playerctl", "metadata", "--format", "{{title}}|||{{artist}}|||{{status}}"]
        running: lockscreenScope.sessionLocked
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim()
                if (out.length > 0) {
                    let parts = out.split("|||")
                    lockscreenScope.currentTrackTitle = parts[0] || ""
                    lockscreenScope.currentTrackArtist = parts[1] || ""
                    lockscreenScope.currentTrackStatus = parts[2] || "Stopped"
                    lockscreenScope.hasActiveMedia = (lockscreenScope.currentTrackStatus === "Playing" || lockscreenScope.currentTrackStatus === "Paused")
                } else {
                    lockscreenScope.hasActiveMedia = false
                }
            }
        }
    }

    Timer {
        id: mediaPollTimer
        interval: 2500
        running: lockscreenScope.sessionLocked
        repeat: true
        onTriggered: lockscreenScope.refreshMedia()
    }

    function refreshMedia() {
        mediaInfoProc.running = false
        mediaInfoProc.running = true
    }

    function mediaPlayPause() {
        // Instant optimistic toggle for immediate 0ms UI feedback
        if (lockscreenScope.currentTrackStatus === "Playing") {
            lockscreenScope.currentTrackStatus = "Paused"
        } else if (lockscreenScope.currentTrackStatus === "Paused") {
            lockscreenScope.currentTrackStatus = "Playing"
        }

        // Pause polling timer during transition to avoid stale DBus bounceback
        mediaPollTimer.stop()
        Quickshell.execDetached(["playerctl", "play-pause"])
        mediaSyncTimer.restart()
    }

    function mediaPrevious() {
        mediaPollTimer.stop()
        Quickshell.execDetached(["playerctl", "previous"])
        mediaSyncTimer.restart()
    }

    function mediaNext() {
        mediaPollTimer.stop()
        Quickshell.execDetached(["playerctl", "next"])
        mediaSyncTimer.restart()
    }

    // Debounce sync so DBus finishes updating before re-checking true status
    Timer {
        id: mediaSyncTimer
        interval: 650
        repeat: false
        onTriggered: {
            lockscreenScope.refreshMedia()
            mediaPollTimer.restart()
        }
    }

    // PAM Authentication Context
    PamContext {
        id: pam
        user: lockscreenScope.currentUsername
        property string pendingPassword: ""

        onResponseRequiredChanged: {
            if (responseRequired && pendingPassword !== "") {
                respond(pendingPassword)
                pendingPassword = ""
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                lockscreenScope.authStatus = "Unlocked!"
                lockscreenScope.isSuccess = true
                lockscreenScope.isAuthenticating = false

                if (Quickshell.env("XDG_CURRENT_DESKTOP") === "Hyprland" || Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== "") {
                    Quickshell.execDetached(["hyprctl", "keyword", "misc:allow_session_lock_restore", "1"])
                }
                Quickshell.execDetached(["loginctl", "unlock-session"])

                unlockTimer.start()
            } else {
                lockscreenScope.isAuthenticating = false
                lockscreenScope.isError = true
                lockscreenScope.authStatus = "Incorrect password. Try again."
                errorResetTimer.restart()
                pendingPassword = ""
            }
        }
    }

    Timer {
        id: errorResetTimer
        interval: 650
        repeat: false
        onTriggered: {
            lockscreenScope.clearInput()
            lockscreenScope.isError = false
        }
    }

    Timer {
        id: unlockTimer
        interval: 320
        repeat: false
        onTriggered: {
            Config.sessionLocked = false
            if (lockscreenScope.shellRef) lockscreenScope.shellRef.sessionLocked = false
            lockscreenScope.clearInput()
        }
    }

    function authenticate(password) {
        if (password.length === 0 || lockscreenScope.isAuthenticating) return
        pam.pendingPassword = password
        lockscreenScope.isAuthenticating = true
        lockscreenScope.authStatus = "Verifying..."
        pam.start()
    }

    function clearInput() {
        lockscreenScope.currentPassword = ""
        lockscreenScope.shapeItems = []
        lockscreenScope.authStatus = "System Locked"
        lockscreenScope.isSuccess = false
        lockscreenScope.isError = false
        lockscreenScope.isAuthenticating = false
    }

    // Shape Generation Logic Shared Across All Screens
    readonly property var specialChars: [
        "!", "@", "#", "$", "%", "^", "&", "*", "~", "?",
        "+", "=", "<", ">", "/", "§", "★", "◆", "▲", "■",
        "✦", "❖", "◈", "⚡", "λ", "π", "Ω", "¥", "€", "∞",
        "∆", "∑", "√", "⬡", "⌘"
    ]

    function getRandomColor() {
        let paletteMode = Config.lockscreenShapePalette || "vibrant"
        if (paletteMode === "accent") return Config.accent
        let vibrant = ["#00f0ff", "#a855f7", "#f59e0b", "#10b981", "#ec4899", "#38bdf8", "#f43f5e", "#84cc16", "#06b6d4", "#e879f9"]
        return vibrant[Math.floor(Math.random() * vibrant.length)]
    }

    function generateShapeToken(charIndex) {
        let rotations = [0, 45, 90, 135, 180, 225, 270, 315]
        let pickedChar = specialChars[Math.floor(Math.random() * specialChars.length)]
        return {
            id: Date.now() + "_" + Math.random(),
            shapeIndex: Math.floor(Math.random() * 16),
            color: getRandomColor(),
            rotation: rotations[Math.floor(Math.random() * rotations.length)],
            isOutline: Math.random() < 0.22,
            charGlyph: pickedChar,
            maskStyle: Config.lockscreenMaskStyle || "shapes",
            animIndex: charIndex
        }
    }

    function updateShapes(newPass) {
        let currentLen = lockscreenScope.shapeItems.length
        let targetLen = newPass.length

        if (targetLen === 0) {
            lockscreenScope.shapeItems = []
            return
        }

        if (targetLen > currentLen) {
            let updated = lockscreenScope.shapeItems.slice()
            for (let i = currentLen; i < targetLen; i++) {
                updated.push(generateShapeToken(i))
            }
            lockscreenScope.shapeItems = updated
        } else if (targetLen < currentLen) {
            lockscreenScope.shapeItems = lockscreenScope.shapeItems.slice(0, targetLen)
        }
    }

    // ==========================================
    // WAYLAND SESSION LOCK
    // ==========================================
    WlSessionLock {
        id: sessionLock
        locked: lockscreenScope.sessionLocked

        surface: Component {
            WlSessionLockSurface {
                id: surfaceRoot

                property var currentTime: new Date()

                readonly property bool isTargetScreen: {
                    let target = Config.lockscreenTargetMonitor || "focused"
                    if (target === "focused") {
                        let focused = (typeof Hyprland !== "undefined" && Hyprland.focusedMonitor) ? Hyprland.focusedMonitor.name : ""
                        return focused !== "" ? (screen && screen.name === focused) : (Quickshell.screens.length > 0 && Quickshell.screens[0] === screen)
                    }
                    if (target !== "") {
                        return screen && screen.name === target
                    }
                    return Quickshell.screens.length > 0 && Quickshell.screens[0] === screen
                }

                Timer {
                    interval: 1000
                    running: lockscreenScope.sessionLocked && surfaceRoot.isTargetScreen
                    repeat: true
                    onTriggered: surfaceRoot.currentTime = new Date()
                }

                color: "#000000"

                PinchHandler { target: null }
                WheelHandler { target: null }

                // Universal Hidden Input (z: -1 allows click events to reach buttons on top)
                TextInput {
                    id: globalScreenInput
                    anchors.fill: parent
                    opacity: 0.001
                    color: "transparent"
                    z: -1
                    focus: true
                    echoMode: TextInput.NoEcho
                    clip: true
                    cursorVisible: false
                    selectByMouse: false

                    text: lockscreenScope.currentPassword

                    onTextChanged: {
                        if (lockscreenScope.currentPassword !== text) {
                            lockscreenScope.currentPassword = text
                            lockscreenScope.updateShapes(text)
                        }
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_CapsLock) {
                            if (!event.isAutoRepeat) {
                                lockscreenScope.capsLockActive = !lockscreenScope.capsLockActive
                            }
                            event.accepted = true
                            return
                        }

                        // Media keys
                        if (event.key === Qt.Key_MediaPlay || event.key === Qt.Key_MediaTogglePlayPause) {
                            event.accepted = true
                            lockscreenScope.mediaPlayPause()
                            return
                        } else if (event.key === Qt.Key_MediaNext) {
                            event.accepted = true
                            lockscreenScope.mediaNext()
                            return
                        } else if (event.key === Qt.Key_MediaPrevious) {
                            event.accepted = true
                            lockscreenScope.mediaPrevious()
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true
                            lockscreenScope.authenticate(lockscreenScope.currentPassword)
                        } else if (event.key === Qt.Key_Escape) {
                            event.accepted = true
                            lockscreenScope.clearInput()
                        } else if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_U || event.key === Qt.Key_Backspace) {
                                event.accepted = true
                                lockscreenScope.clearInput()
                            }
                        }
                    }
                }

                // Background click catcher (Only active on secondary blackout displays)
                MouseArea {
                    anchors.fill: parent
                    visible: !surfaceRoot.isTargetScreen
                    acceptedButtons: Qt.AllButtons
                    hoverEnabled: true
                    onPressed: globalScreenInput.forceActiveFocus()
                    onClicked: globalScreenInput.forceActiveFocus()
                }

                // ========================================================
                // UI Container (Only visible on the designated target monitor)
                // ========================================================
                Item {
                    anchors.fill: parent
                    visible: surfaceRoot.isTargetScreen

                    // 1. WALLPAPER BACKGROUND + BLUR
                    Item {
                        anchors.fill: parent

                        Image {
                            id: bgImage
                            anchors.fill: parent
                            source: Config.activeWallpaperPath ? "file://" + Config.activeWallpaperPath : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                        }

                        FastBlur {
                            id: blurredBg
                            anchors.fill: bgImage
                            source: bgImage
                            radius: (Config.lockscreenBlurRadius !== undefined ? Config.lockscreenBlurRadius : 36)
                            transparentBorder: false
                            visible: bgImage.status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: bgImage.status !== Image.Ready
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.darker(Config.bgBase, 1.3) }
                                GradientStop { position: 1.0; color: Qt.darker(Config.bgPanel, 1.8) }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 0.58)
                        }

                        RadialGradient {
                            anchors.centerIn: parent
                            width: parent.width * 1.2
                            height: parent.height * 1.2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12) }
                                GradientStop { position: 0.45; color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.03) }
                                GradientStop { position: 0.8; color: "transparent" }
                            }
                        }
                    }

                    // 2. TOP STATUS BAR
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24

                            RowLayout {
                                spacing: 16

                                RowLayout {
                                    spacing: 6
                                    visible: lockscreenScope.shellRef ? lockscreenScope.shellRef.hasBattery : false

                                    Text {
                                        text: {
                                            if (!lockscreenScope.shellRef) return "battery_android_frame_full"
                                            let cap = lockscreenScope.shellRef.battCapacity
                                            let status = lockscreenScope.shellRef.battStatus
                                            if (status === "Charging") return "battery_android_frame_bolt"
                                            if (cap <= 10) return "battery_android_0"
                                            if (cap <= 25) return "battery_android_frame_1"
                                            if (cap <= 40) return "battery_android_frame_2"
                                            if (cap <= 60) return "battery_android_frame_3"
                                            if (cap <= 75) return "battery_android_frame_4"
                                            if (cap <= 90) return "battery_android_frame_5"
                                            if (cap < 100) return "battery_android_frame_6"
                                            return "battery_android_frame_full"
                                        }
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: (lockscreenScope.shellRef && lockscreenScope.shellRef.battCapacity <= 20) ? "#ef4444" : Config.accent
                                    }

                                    Text {
                                        text: (lockscreenScope.shellRef ? lockscreenScope.shellRef.battCapacity : 100) + "%"
                                        color: Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            RowLayout {
                                spacing: 12

                                Rectangle {
                                    implicitWidth: hostRow.implicitWidth + 14
                                    implicitHeight: 24
                                    radius: 12
                                    color: Qt.rgba(255, 255, 255, 0.08)

                                    RowLayout {
                                        id: hostRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "lock"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 12
                                            color: Config.accent
                                        }

                                        Text {
                                            text: "SYNOPTIK"
                                            font.family: Config.sysFont
                                            font.pixelSize: 9
                                            font.bold: true
                                            font.letterSpacing: 1
                                            color: Config.textMuted
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. MAIN CENTER AUTHENTICATION CARD
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 24
                        width: Math.min(520, surfaceRoot.width - 48)

                        // CLOCK SECTION
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                Item {
                                    implicitWidth: lockTimeText.implicitWidth
                                    implicitHeight: lockTimeText.implicitHeight

                                    Glow {
                                        anchors.fill: lockTimeText
                                        source: lockTimeText
                                        radius: 18
                                        samples: 24
                                        color: Config.accent
                                        spread: 0.28
                                        transparentBorder: true
                                        visible: Config.clockShowGlow !== false
                                    }

                                    Text {
                                        id: lockTimeText
                                        text: {
                                            let d = surfaceRoot.currentTime
                                            let use12 = Config.lockscreenUse12Hour !== false
                                            let showSec = Config.lockscreenShowSeconds === true
                                            let min = Qt.formatTime(d, "mm")
                                            let sec = Qt.formatTime(d, "ss")
                                            let rawHours = d.getHours()
                                            let hour = ""
                                            if (use12) {
                                                let h12 = rawHours % 12
                                                hour = (h12 === 0 ? 12 : h12).toString()
                                            } else {
                                                hour = rawHours < 10 ? ("0" + rawHours) : rawHours.toString()
                                            }
                                            return showSec ? (hour + ":" + min + ":" + sec) : (hour + ":" + min)
                                        }
                                        color: Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.lockscreenClockSize || 96
                                        font.weight: Font.ExtraBold
                                        font.letterSpacing: -2
                                    }
                                }

                                Rectangle {
                                    visible: (Config.lockscreenUse12Hour !== false) && (Config.lockscreenShowAmPm !== false)
                                    implicitWidth: amPmText.implicitWidth + 14
                                    implicitHeight: 28
                                    radius: 14
                                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                                    border.width: 1
                                    border.color: Config.accent
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: amPmText
                                        anchors.centerIn: parent
                                        text: surfaceRoot.currentTime.getHours() >= 12 ? "PM" : "AM"
                                        font.family: Config.sysFont
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 1
                                        color: Config.accent
                                    }
                                }
                            }

                            Text {
                                id: lockDateText
                                Layout.alignment: Qt.AlignHCenter
                                text: {
                                    let d = surfaceRoot.currentTime
                                    let mode = Config.lockscreenDateFormat || "long"
                                    if (mode === "standard") return Qt.formatDate(d, "ddd, MMM d, yyyy")
                                    if (mode === "iso") return Qt.formatDate(d, "yyyy-MM-dd")
                                    if (mode === "dayFirst") return Qt.formatDate(d, "d MMMM yyyy")
                                    return Qt.formatDate(d, "dddd, MMMM d, yyyy")
                                }
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontTitle)
                                font.weight: Font.Medium
                            }
                        }

                        // USER AVATAR (200px)
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 14

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 200
                                implicitHeight: 200

                                RectangularGlow {
                                    anchors.fill: avatarRing
                                    glowRadius: 16
                                    spread: 0.22
                                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.5)
                                    cornerRadius: 100
                                    visible: Config.clockShowGlow !== false
                                }

                                Rectangle {
                                    id: avatarRing
                                    anchors.fill: parent
                                    radius: 100
                                    color: Qt.rgba(Config.bgPanel.r, Config.bgPanel.g, Config.bgPanel.b, 0.8)
                                    border.width: 3
                                    border.color: Config.accent

                                    Image {
                                        id: avatarImg
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        source: lockscreenScope.userAvatarPath ? "file://" + lockscreenScope.userAvatarPath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: avatarImg.width
                                                height: avatarImg.height
                                                radius: width / 2
                                            }
                                        }
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: avatarImg.status !== Image.Ready
                                        text: "person"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 104
                                        color: Config.accent
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: lockscreenScope.realName
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontTitle)
                                font.bold: true
                            }

                            Text {
                                id: statusLabel
                                Layout.alignment: Qt.AlignHCenter
                                text: lockscreenScope.authStatus
                                color: lockscreenScope.authStatus.includes("Incorrect") 
                                    ? "#ef4444" 
                                    : (lockscreenScope.authStatus.includes("Unlocked") ? "#10b981" : Config.textMuted)
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.italic: true

                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        // 4. THE PASSWORD BAR
                        LockscreenPasswordBar {
                            id: passBar
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            password: lockscreenScope.currentPassword
                            shapeItems: lockscreenScope.shapeItems
                            isAuthenticating: lockscreenScope.isAuthenticating
                            isError: lockscreenScope.isError
                            isSuccess: lockscreenScope.isSuccess
                            capsLockActive: lockscreenScope.capsLockActive
                            maskStyle: Config.lockscreenMaskStyle || "shapes"
                            paletteMode: Config.lockscreenShapePalette || "vibrant"

                            onSubmitPassword: (pass) => {
                                lockscreenScope.authenticate(pass)
                            }

                            onClearRequested: {
                                lockscreenScope.clearInput()
                            }
                        }

                        // 5. MPRIS MINI CONTROLLER
                        Rectangle {
                            id: mediaCard
                            visible: (Config.lockscreenShowMedia !== false) && lockscreenScope.hasActiveMedia
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: Math.min(380, parent.width - 20)
                            implicitHeight: 52
                            radius: 26
                            color: Qt.rgba(Config.bgPanel.r, Config.bgPanel.g, Config.bgPanel.b, 0.6)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.1)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10

                                Rectangle {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    radius: 16
                                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "music_note"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: Config.accent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: lockscreenScope.currentTrackTitle || "Unknown Track"
                                        color: Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: lockscreenScope.currentTrackArtist || "Unknown Artist"
                                        color: Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    spacing: 4

                                    Rectangle {
                                        implicitWidth: 28; implicitHeight: 28; radius: 14
                                        color: prevHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                                        Text { anchors.centerIn: parent; text: "skip_previous"; font.family: "Material Symbols Outlined"; font.pixelSize: 18; color: Config.textMain }
                                        HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: lockscreenScope.mediaPrevious() }
                                    }

                                    Rectangle {
                                        implicitWidth: 32; implicitHeight: 32; radius: 16
                                        color: playHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                                        Text {
                                            anchors.centerIn: parent
                                            text: lockscreenScope.currentTrackStatus === "Playing" ? "pause" : "play_arrow"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 20
                                            color: playHover.hovered ? Config.bgBase : Config.textMain
                                        }
                                        HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: lockscreenScope.mediaPlayPause() }
                                    }

                                    Rectangle {
                                        implicitWidth: 28; implicitHeight: 28; radius: 14
                                        color: nextHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                                        Text { anchors.centerIn: parent; text: "skip_next"; font.family: "Material Symbols Outlined"; font.pixelSize: 18; color: Config.textMain }
                                        HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { onTapped: lockscreenScope.mediaNext() }
                                    }
                                }
                            }
                        }
                    }

                    // 6. BOTTOM POWER CONTROLS
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: powerRow.implicitWidth + 24
                        implicitHeight: 48
                        radius: 24
                        color: Qt.rgba(Config.bgPanel.r, Config.bgPanel.g, Config.bgPanel.b, 0.65)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.12)
                        visible: Config.lockscreenShowPower !== false

                        RowLayout {
                            id: powerRow
                            anchors.centerIn: parent
                            spacing: 12

                            Repeater {
                                model: [
                                    { icon: "bedtime", label: "Suspend", cmd: ["systemctl", "suspend"] },
                                    { icon: "restart_alt", label: "Reboot", cmd: ["systemctl", "reboot"] },
                                    { icon: "power_settings_new", label: "Power Off", cmd: ["systemctl", "poweroff"] }
                                ]

                                delegate: Rectangle {
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    radius: 18
                                    color: pwrHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 20
                                        color: pwrHover.hovered ? Config.accent : Config.textMuted
                                    }

                                    HoverHandler { id: pwrHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: Quickshell.execDetached(modelData.cmd)
                                    }
                                }
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    globalScreenInput.forceActiveFocus()
                }
            }
        }
    }
}