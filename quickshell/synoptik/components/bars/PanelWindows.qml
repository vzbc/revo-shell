import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../osds"

PanelWindow {
    id: root

    default property alias content: contentContainer.data
    property alias surfaceBackground: backgroundSlot.data
    property alias mainContainer: mainContainer

    property bool isOpen: false
    property bool isPeeking: false
    readonly property real peekThickness: 8
    
    readonly property real actualScreenWidth: screen ? screen.width : 1920
    readonly property real actualScreenHeight: screen ? screen.height : 1080

    property real popoutXOffset: actualScreenWidth / 2.0
    property real popoutYOffset: actualScreenHeight / 2.0
    property bool isCentered: false

    function startPeek(item) {
        if (root.isOpen) return
        setPopoutPos(item)
        root.isPeeking = true
    }

    function stopPeek() {
        root.isPeeking = false
    }

    readonly property real shadowPadding: 16

    readonly property string barPosition: Config.barPosition || "top"
    readonly property bool isHorizontal: barPosition === "top" || barPosition === "bottom"
    readonly property bool isBottom: barPosition === "bottom"
    readonly property bool isRight: barPosition === "right"

    readonly property bool isIsland: Config.barFrameStyle === "island"
    readonly property bool isFloatingStyle: Config.barFrameStyle === "floating" || isIsland

    property real currentMargin: isFloatingStyle ? (Config.barMargin || 4) : 0
    Behavior on currentMargin {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    property real barRadius: isFloatingStyle ? (Config.cornerRadius || 12) : 0
    Behavior on barRadius {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    readonly property bool isScreenFrame: Config.barFrameStyle === "screen"
    readonly property real framePadding: isScreenFrame ? 8 : 0
    readonly property real frameRadius: isScreenFrame ? (Config.surfaceRadius || 18) : 0

    readonly property real padL: barPosition === "left" ? barH + framePadding : framePadding
    readonly property real padR: barPosition === "right" ? barH + framePadding : framePadding
    readonly property real padT: barPosition === "top" ? barH + framePadding : framePadding
    readonly property real padB: barPosition === "bottom" ? barH + framePadding : framePadding

    readonly property real inX: padL
    readonly property real inY: padT
    readonly property real inW: actualScreenWidth - padL - padR
    readonly property real inH: actualScreenHeight - padT - padB
    readonly property real inRadi: Math.max(0.1, frameRadius)

    readonly property real outerPadding: 16
    readonly property real barSidePadding: 0

    readonly property real rawChildWidth: {
        let baseW = 420
        if (root.activeView === "osd") {
            baseW = volumeOsdModule.implicitWidth
        } else if (root.activeView === "notifOsd") {
            baseW = notifOsdModule.implicitWidth
        } else {
            for (let i = 0; i < contentContainer.children.length; i++) {
                let child = contentContainer.children[i]
                if (child.objectName !== "internalOsd" && child.objectName !== "internalNotifOsd") {
                    if (child.item && child.item.implicitWidth > 0) baseW = child.item.implicitWidth
                    else if (child.implicitWidth > 0) baseW = child.implicitWidth
                    break
                }
            }
        }
        return baseW
    }

    readonly property real rawChildHeight: {
        let baseH = 480
        if (root.activeView === "osd") {
            baseH = volumeOsdModule.implicitHeight
        } else if (root.activeView === "notifOsd") {
            baseH = notifOsdModule.implicitHeight
        } else {
            for (let i = 0; i < contentContainer.children.length; i++) {
                let child = contentContainer.children[i]
                if (child.objectName !== "internalOsd" && child.objectName !== "internalNotifOsd") {
                    if (child.item && child.item.implicitHeight > 0) baseH = child.item.implicitHeight
                    else if (child.implicitHeight > 0) baseH = child.implicitHeight
                    break
                }
            }
        }
        return baseH
    }

    property real lastOpenWidth: rawChildWidth
    property real lastOpenHeight: rawChildHeight

    onIsOpenChanged: {
        if (isOpen) {
            root.isPeeking = false
        } else {
            lastOpenWidth = rawChildWidth
            lastOpenHeight = rawChildHeight
        }
    }

    property real targetWidth: {
        if (root.isOpen) return rawChildWidth
        if (root.isPeeking) return isHorizontal ? Math.max(48, lastOpenWidth * 0.35) : peekThickness
        return isHorizontal ? (lastOpenWidth * 0.33) : (lastOpenWidth * 1.10)
    }

    property real targetHeight: {
        if (root.isOpen) return rawChildHeight
        if (root.isPeeking) return isHorizontal ? peekThickness : Math.max(48, lastOpenHeight * 0.35)
        return isHorizontal ? (lastOpenHeight * 1.10) : (lastOpenHeight * 0.33)
    }

    Behavior on targetWidth { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on targetHeight { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }

    property real progress: 0.0
    readonly property real animScale: Math.max(0.0, progress)
    readonly property real closeFactor: root.isOpen ? progress : Math.pow(progress, 1.2)

    readonly property real currentHeight: targetHeight * Math.pow(closeFactor, 1.8)
    readonly property real squishRatio: targetHeight > 0 ? (1.0 - (currentHeight / targetHeight)) : 0.0
    readonly property real currentWidth: root.isOpen ? (targetWidth * animScale) : (targetWidth * (closeFactor + (0.3 * squishRatio * closeFactor)))

    readonly property real wingW: (Config.surfaceRadius || 18) * animScale
    readonly property real wingH: (Config.surfaceRadius || 18) * animScale
    readonly property real radius: Math.max(0.1, (Config.surfaceRadius || 18) * animScale)

    readonly property real borderWidth: (Config.borderThickness !== undefined && Config.borderThickness !== null) ? Number(Config.borderThickness) : 0.0
    readonly property real halfB: borderWidth / 2.0

    readonly property real leftBarRx: inX + currentWidth
    readonly property real rightBarPopL: inX + inW - currentWidth
    readonly property real topBarPopB: inY + currentHeight
    readonly property real bottomBarPopT: inY + inH - currentHeight

    anchors {
        top: barPosition === "top" || !isHorizontal
        bottom: barPosition === "bottom" || !isHorizontal
        left: barPosition === "left" || isHorizontal
        right: barPosition === "right" || isHorizontal
    }

    margins {
        top: barPosition === "bottom" ? 0 : (currentMargin - shadowPadding)
        bottom: barPosition === "top" ? 0 : (currentMargin - shadowPadding)
        left: barPosition === "right" ? 0 : (currentMargin - shadowPadding)
        right: barPosition === "left" ? 0 : (currentMargin - shadowPadding)
    }

    readonly property real baseBarHeight: Config.barHeight || 54
    readonly property real barH: isScreenFrame ? (baseBarHeight - 8) : baseBarHeight
    readonly property real barBottomY: barH - halfB

    implicitHeight: actualScreenHeight + (shadowPadding * 2)
    implicitWidth: actualScreenWidth + (shadowPadding * 2)

    color: "transparent"
    visible: true

    mask: Region {
        Region { item: barContent }
        Region { item: (root.isOpen && root.progress > 0.01) ? contentContainer : null }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: Config.isBarEnabledForScreen(screen ? screen.name : "") ? (isScreenFrame ? (barH + (framePadding * 2)) : (barH + (currentMargin > 0 ? currentMargin : (Config.barMargin || 4)))) : 0
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "synoptik-shell"

    Shortcut {
        sequences: ["Escape"]
        enabled: root.isOpen
        onActivated: {
            root.closeOthers("none")
            root.isCentered = false
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.isOpen && root.activeView !== "osd" && root.activeView !== "notifOsd" && (!screen || screen.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""))
        windows: [root]
        onCleared: {
            root.closeOthers("none")
            root.isCentered = false
        }
    }

    readonly property real minPossibleLeft: isScreenFrame ? ((isHorizontal ? inX : inY) + halfB) : halfB
    readonly property real maxPossibleRight: isScreenFrame ? ((isHorizontal ? inX + inW : inY + inH) - halfB) : ((isHorizontal ? mainContainer.width : mainContainer.height) - halfB)

    readonly property bool isLeftFlush: !isCentered && (
        (isHorizontal ? (popoutXOffset - (targetWidth / 2.0)) : (popoutYOffset - (targetHeight / 2.0))) < (minPossibleLeft + root.barRadius + root.wingW + (root.isScreenFrame ? root.inRadi : root.radius))
    )

    readonly property bool isRightFlush: !isCentered && (
        (isHorizontal ? (popoutXOffset + (targetWidth / 2.0)) : (popoutYOffset + (targetHeight / 2.0))) > (maxPossibleRight - root.barRadius - root.wingW - (root.isScreenFrame ? root.inRadi : root.radius))
    )

    readonly property real targetCenteredLeft: Math.max(minPossibleLeft + 16, Math.min(maxPossibleRight - (isHorizontal ? targetWidth : targetHeight) - 16, ((isHorizontal ? mainContainer.width : mainContainer.height) - (isHorizontal ? targetWidth : targetHeight)) / 2.0))

    readonly property real staticLeft: {
        let span = isHorizontal ? targetWidth : targetHeight
        let offset = isHorizontal ? popoutXOffset : popoutYOffset
        if (isCentered) return targetCenteredLeft
        if (isLeftFlush) return minPossibleLeft
        if (isRightFlush) return maxPossibleRight - span
        return Math.max(minPossibleLeft + 16, Math.min(maxPossibleRight - span - 16, offset - (span / 2.0)))
    }

    readonly property real staticRight: staticLeft + (isHorizontal ? targetWidth : targetHeight)

    readonly property real pLeft: staticLeft
    readonly property real pRight: staticRight

    property string activeView: "none"

    function updateActiveView() {
        let nextView = "none"
        let isFocused = !screen || screen.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")

        if (isFocused) {
            if (typeof Config.showOSD !== "undefined" && Config.showOSD) nextView = "osd"
            else if (typeof Config.showNotificationOsd !== "undefined" && Config.showNotificationOsd) nextView = "notifOsd"
            else if (Config.showWorkspacePreview) nextView = "workspacePreview"
            else if (Config.showPower) nextView = "power"
            else if (Config.showWallpaper) nextView = "wallpaper"
            else if (Config.showAppLauncher) nextView = "appLauncher"
            else if (Config.showCalendar) nextView = "calendar"
            else if (Config.showNotifications) nextView = "notifications"
            else if (Config.showAudio) nextView = "audio"
            else if (Config.showNetwork) nextView = "network"
            else if (Config.showSystemMonitor) nextView = "systemMonitor"
            else if (Config.showBattery) nextView = "battery"
            else if (Config.showClipboard) nextView = "clipboard"
            else if (Config.showMirror && !Config.mirrorPinned) nextView = "mirror"
            else if (Config.showControlCenter) nextView = "controlCenter"
            else if (Config.showMirror && Config.mirrorPinned) nextView = "mirror"
        }

        if (nextView === "none") {
            root.isOpen = false
            activeView = "none"
        } else {
            activeView = nextView
            root.isOpen = true
        }
    }

    function setPopoutPos(item) {
        if (!item) return
        root.isCentered = false
        if (isHorizontal) {
            root.popoutXOffset = item.mapToItem(mainContainer, item.width / 2, 0).x
        } else {
            root.popoutYOffset = item.mapToItem(mainContainer, 0, item.height / 2).y
        }
    }

    function closeOthers(except) {
        if (except !== "osd" && typeof Config.showOSD !== "undefined") Config.showOSD = false
        if (except !== "notifOsd" && typeof Config.showNotificationOsd !== "undefined") Config.showNotificationOsd = false
        if (except !== "workspacePreview") Config.showWorkspacePreview = false
        if (except !== "power") Config.showPower = false
        if (except !== "wallpaper") Config.showWallpaper = false
        if (except !== "appLauncher") Config.showAppLauncher = false
        if (except !== "calendar") Config.showCalendar = false
        if (except !== "notifications") Config.showNotifications = false
        if (except !== "audio") Config.showAudio = false
        if (except !== "network") Config.showNetwork = false
        if (except !== "systemMonitor") Config.showSystemMonitor = false
        if (except !== "battery") Config.showBattery = false
        if (except !== "clipboard") Config.showClipboard = false
        if (except !== "screenRecorder") Config.showScreenRecorder = false
        if (except !== "mirror" && !Config.mirrorPinned) Config.showMirror = false
        if (except !== "controlCenter") Config.showControlCenter = false
    }

    Connections {
        target: Config
        ignoreUnknownSignals: true
        function onShowOSDChanged() {
            if (Config.showOSD) {
                closeOthers("osd")
                root.isCentered = false
                if (root.isIsland) {
                    if (root.isHorizontal) root.popoutXOffset = root.islandX + (root.animatedIslandWidth / 2.0)
                    else root.popoutYOffset = root.islandY + (root.animatedIslandHeight / 2.0)
                } else {
                    if (root.isHorizontal) root.popoutXOffset = mainContainer.width
                    else root.popoutYOffset = mainContainer.height
                }
            }
            updateActiveView()
        }
        function onShowNotificationOsdChanged() {
            if (Config.showNotificationOsd) {
                closeOthers("notifOsd")
                root.isCentered = false
                if (root.isIsland) {
                    if (root.isHorizontal) root.popoutXOffset = root.islandX + (root.animatedIslandWidth / 2.0)
                    else root.popoutYOffset = root.islandY + (root.animatedIslandHeight / 2.0)
                } else {
                    root.popoutXOffset = 0
                    root.popoutYOffset = 0
                }
            }
            updateActiveView()
        }
        function onShowWorkspacePreviewChanged() {
            if (Config.showWorkspacePreview) {
                closeOthers("workspacePreview")
                setPopoutPos(rightCard ? rightCard.getButton("overview") : null)
            }
            updateActiveView()
        }
        function onShowAppLauncherChanged() { if (Config.showAppLauncher) { closeOthers("appLauncher"); setPopoutPos(leftCard ? leftCard.getButton("launcher") : null); } updateActiveView() }
        function onShowPowerChanged() { if (Config.showPower) { closeOthers("power"); setPopoutPos(leftCard ? leftCard.getButton("power") : null); } updateActiveView() }
        function onShowWallpaperChanged() { if (Config.showWallpaper) { closeOthers("wallpaper"); setPopoutPos(leftCard ? leftCard.getButton("wallpaper") : null); } updateActiveView() }
        function onShowCalendarChanged() { if (Config.showCalendar) { closeOthers("calendar"); setPopoutPos(rightCard ? rightCard.getButton("clock") : null); } updateActiveView() }
        function onShowNotificationsChanged() { if (Config.showNotifications) { closeOthers("notifications"); setPopoutPos(leftCard ? leftCard.getButton("notifications") : null); } updateActiveView() }
        function onShowAudioChanged() { if (Config.showAudio) { closeOthers("audio"); setPopoutPos(leftCard ? leftCard.getButton("audio") : null); } updateActiveView() }
        function onShowNetworkChanged() { if (Config.showNetwork) { closeOthers("network"); setPopoutPos(leftCard ? leftCard.getButton("network") : null); } updateActiveView() }
        function onShowBatteryChanged() { if (Config.showBattery) { closeOthers("battery"); setPopoutPos(leftCard ? leftCard.getButton("batt") : null); } updateActiveView() }
        function onShowClipboardChanged() { if (Config.showClipboard) { closeOthers("clipboard"); setPopoutPos(leftCard ? leftCard.getButton("clipboard") : null); } updateActiveView() }
        function onShowScreenRecorderChanged() { if (Config.showScreenRecorder) { closeOthers("screenRecorder"); setPopoutPos(leftCard ? leftCard.getButton("recorder") : null); } updateActiveView() }
        function onShowMirrorChanged() { if (Config.showMirror) { closeOthers("mirror"); setPopoutPos(leftCard ? leftCard.getButton("mirror") : null); } updateActiveView() }
        function onShowControlCenterChanged() { if (Config.showControlCenter) { closeOthers("controlCenter"); setPopoutPos(rightCard ? rightCard.getButton("cc") : null); } updateActiveView() }
        function onShowTaskOverflowChanged() { if (Config.showTaskOverflow) { closeOthers("taskOverflow"); setPopoutPos(activeWindowCard); } updateActiveView() }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: shadowPadding

        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: {
                root.closeOthers("none")
                root.isCentered = false
            }
        }

        states: [
            State { 
                name: "open"
                when: root.isOpen
                PropertyChanges { target: root; progress: 1.0 } 
            },
            State { 
                name: "peek"
                when: !root.isOpen && root.isPeeking
                PropertyChanges { target: root; progress: 0.25 } 
            },
            State { 
                name: "closed"
                when: !root.isOpen && !root.isPeeking
                PropertyChanges { target: root; progress: 0.0 } 
            }
        ]

        transitions: [
            Transition {
                from: "*"; to: "open"
                NumberAnimation { target: root; property: "progress"; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
            },
            Transition {
                from: "closed"; to: "peek"
                NumberAnimation { target: root; property: "progress"; duration: 220; easing.type: Easing.OutCubic }
            },
            Transition {
                from: "*"; to: "closed"
                NumberAnimation { target: root; property: "progress"; duration: 500; easing.type: Easing.InBack; easing.overshoot: 1.6 }
            }
        ]

        Item {
            id: backgroundSlot
            anchors.fill: parent
        }

        Item {
            id: barContent
            x: root.isRight ? (mainContainer.width - root.barH + Math.floor(root.halfB)) : Math.floor(root.halfB)
            y: root.isBottom ? (mainContainer.height - root.barH + Math.floor(root.halfB)) : Math.floor(root.halfB)
            
            transform: Translate {
                x: root.isScreenFrame ? (root.barPosition === "left" ? root.framePadding / 2 : (root.barPosition === "right" ? -root.framePadding / 2 : 0)) : 0
                y: root.isScreenFrame ? (root.barPosition === "top" ? root.framePadding / 2 : (root.barPosition === "bottom" ? -root.framePadding / 2 : 0)) : 0
            }

            width: root.isHorizontal ? (mainContainer.width - Math.ceil(root.borderWidth)) : (root.barH - Math.ceil(root.borderWidth))
            height: root.isHorizontal ? (root.barH - Math.ceil(root.borderWidth)) : (mainContainer.height - Math.ceil(root.borderWidth))

            LeftModules {
                id: leftCard
                rootRef: root
                onPopoutRequested: item => root.setPopoutPos(item)
            }
            ActiveWindowCard {
                id: activeWindowCard
                rootRef: root
                maxAvailableSpan: root.isHorizontal
                    ? Math.max(36, Math.min(190, mainContainer.width - (leftCard ? leftCard.width : 0) - (rightCard ? rightCard.width : 0) - 48))
                    : Math.max(36, Math.min(190, mainContainer.height - (leftCard ? leftCard.height : 0) - (rightCard ? rightCard.height : 0) - 48))

                x: root.isHorizontal
                    ? Math.max(leftCard.x + leftCard.width + 12, Math.min(rightCard.x - activeWindowCard.width - 12, (parent.width - activeWindowCard.width) / 2))
                    : (parent.width - activeWindowCard.width) / 2

                y: root.isHorizontal
                    ? (parent.height - activeWindowCard.height) / 2
                    : Math.max(leftCard.y + leftCard.height + 12, Math.min(rightCard.y - activeWindowCard.height - 12, (parent.height - activeWindowCard.height) / 2))
            }
            RightModules {
                id: rightCard
                rootRef: root
                onPopoutRequested: item => root.setPopoutPos(item)
            }
        }

        Item {
            id: contentContainer
            
            x: {
                if (isHorizontal) {
                    return root.pLeft
                } else {
                    if (isRight) {
                        return isScreenFrame 
                            ? root.rightBarPopL 
                            : (mainContainer.width - root.barH - root.currentWidth)
                    } else {
                        return isScreenFrame 
                            ? root.inX 
                            : root.barH
                    }
                }
            }

            y: {
                if (isHorizontal) {
                    if (isBottom) {
                        return isScreenFrame 
                            ? root.bottomBarPopT 
                            : (mainContainer.height - root.barH - root.currentHeight)
                    } else {
                        return isScreenFrame 
                            ? root.inY 
                            : root.barH
                    }
                } else {
                    return root.pLeft
                }
            }

            width: root.currentWidth
            height: root.currentHeight
            
            clip: true
            visible: root.isOpen && root.progress > 0.05
            focus: true

            TapHandler { onTapped: {} }

            VolumeOSD {
                id: volumeOsdModule
                objectName: "internalOsd"
                anchors.fill: parent
                visible: root.activeView === "osd"
            }

            NotificationOSD {
                id: notifOsdModule
                objectName: "internalNotifOsd"
                anchors.fill: parent
                visible: root.activeView === "notifOsd"
            }
        }
    }
}