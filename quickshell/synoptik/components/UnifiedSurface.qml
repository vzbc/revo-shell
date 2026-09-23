import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "bars"
import "osds"

PanelWindow {
    id: root

    default property alias content: contentContainer.data

    property bool isOpen: false

    // --- Hover Peek State & Math ---
    property bool isPeeking: false
    property var peekTargetItem: null
    property real peekProgress: isPeeking ? 1.0 : 0.0
    Behavior on peekProgress { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    readonly property real peekSpan: 50      // Increased default length
    readonly property real peekDepth: 6      // Depth extending into the screen
    readonly property real peekRadius: 4     // Increased for much rounder corners
    readonly property real peekWing: 2

    readonly property real pkSpan: {
        let flushExtra = (isScreenFrame && (isPeekLeftFlush || isPeekRightFlush)) ? 12 : 0
        return basePeekSpan + flushExtra
    }
    readonly property real pkDepth: peekDepth * (peekProgress || 0)
    readonly property real pkWing: peekWing * (peekProgress || 0)
    readonly property real pkRad: Math.max(0.1, peekRadius * (peekProgress || 0))

    readonly property real pkCenter: (isHorizontal ? (popoutXOffset || 0) : (popoutYOffset || 0)) || 0
    readonly property real pkLeft: {
        let center = pkCenter
        let safeMargin = isScreenFrame ? ((inRadi || 0) + pkWing) : ((barRadius || 0) + pkWing)
        let minL = isScreenFrame ? ((isHorizontal ? (inX || 0) : (inY || 0)) + (halfB || 0)) : (halfB || 0)
        let maxR = isScreenFrame ? ((isHorizontal ? ((inX || 0) + (inW || 0)) : ((inY || 0) + (inH || 0))) - (halfB || 0)) : ((isHorizontal ? (mainContainer ? mainContainer.width : 0) : (mainContainer ? mainContainer.height : 0)) - (halfB || 0))
        
        if (root.isIsland) {
            let barOrigin = isHorizontal ? (islandX || 0) : (islandY || 0)
            let barEnd = isHorizontal ? ((islandX || 0) + (animatedIslandWidth || 0)) : ((islandY || 0) + (animatedIslandHeight || 0))
            return Math.max(barOrigin + safeMargin, Math.min(barEnd - safeMargin - pkSpan, center - (pkSpan / 2.0))) || 0
        }

        // In screen frame mode flush states, snap to exact screen frame edge boundaries
        if (root.isScreenFrame && root.isPeekLeftFlush) return minL
        if (root.isScreenFrame && root.isPeekRightFlush) return maxR - pkSpan
        return Math.max(minL + safeMargin, Math.min(maxR - safeMargin - pkSpan, center - (pkSpan / 2.0))) || 0
    }
    readonly property real pkRight: (pkLeft + pkSpan) || 0

    // Peek-specific flush helpers (no circular dependency — use raw center/span, not pLeft)
    readonly property real _pkSafeMargin: isScreenFrame ? ((inRadi || 0) + pkWing) : ((barRadius || 0) + pkWing)
    
    readonly property bool isPeekLeftFlush: root.isScreenFrame && (
        (pkCenter - (basePeekSpan / 2.0)) <= (minPossibleLeft + _pkSafeMargin + 8)
    )
    readonly property bool isPeekRightFlush: root.isScreenFrame && (
        (pkCenter + (basePeekSpan / 2.0)) >= (maxPossibleRight - _pkSafeMargin - 8)
    )

    readonly property real basePeekSpan: {
        let span = 32
        if (peekTargetItem) {
            span = isHorizontal 
                ? (peekTargetItem.width || peekTargetItem.implicitWidth || 32) 
                : (peekTargetItem.height || peekTargetItem.implicitHeight || 32)
        }
        return (span || 32) + 20
    }

    function startPeek(item) {
        if (!Config.enableHoverPeek || !item || root.isOpen || !item.visible) return
        setPopoutPos(item)
        root.peekTargetItem = item
        root.isPeeking = true
    }

    function stopPeek() {
        root.isPeeking = false
    }
    
    readonly property real actualScreenWidth: screen ? screen.width : 1920
    readonly property real actualScreenHeight: screen ? screen.height : 1080

    property real popoutXOffset: actualScreenWidth / 2.0
    property real popoutYOffset: actualScreenHeight / 2.0
    property bool isCentered: false

    property Timer mirrorReopenTimer: Timer {
        id: mirrorReopenTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (Config.showMirror) {
                updateMirrorPopoutPos()
                root.isOpen = true
            }
        }
    }

    property Timer barLayoutReopenTimer: Timer {
        id: barLayoutReopenTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (root.activeView !== "none") {
                root.refreshPopoutPos()
                root.isOpen = true
            }
        }
    }

    function updateMirrorPopoutPos() {
        if (root.activeView !== "mirror") return

        let screenCenter = isHorizontal 
            ? (inX + (inW / 2.0)) 
            : (inY + (inH / 2.0))

        if (Config.mirrorAnchorPos === "top") {
            if (isHorizontal) root.popoutXOffset = inX + (rawChildWidth / 2.0) + 12
            else root.popoutYOffset = inY + (rawChildHeight / 2.0) + 12
        } else if (Config.mirrorAnchorPos === "bottom") {
            if (isHorizontal) root.popoutXOffset = (inX + inW) - (rawChildWidth / 2.0) - 12
            else root.popoutYOffset = (inY + inH) - (rawChildHeight / 2.0) - 12
        } else {
            if (isHorizontal) root.popoutXOffset = screenCenter
            else root.popoutYOffset = screenCenter
        }
    }

    readonly property real shadowPadding: 16

    readonly property string barPosition: Config.barPosition || "top"
    readonly property bool isHorizontal: barPosition === "top" || barPosition === "bottom"
    readonly property bool isBottom: barPosition === "bottom"
    readonly property bool isRight: barPosition === "right"

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

    readonly property real activeBarSideThickness: isScreenFrame
        ? (framePadding + (barH * autoHideProgress))
        : barH

    readonly property real padL: barPosition === "left" ? activeBarSideThickness : framePadding
    readonly property real padR: barPosition === "right" ? activeBarSideThickness : framePadding
    readonly property real padT: barPosition === "top" ? activeBarSideThickness : framePadding
    readonly property real padB: barPosition === "bottom" ? activeBarSideThickness : framePadding

    readonly property real inX: padL
    readonly property real inY: padT
    readonly property real inW: actualScreenWidth - padL - padR
    readonly property real inH: actualScreenHeight - padT - padB
    readonly property real inRadi: Math.max(0.1, frameRadius)

    // --- Dynamic Child Measurement Engine ---
    property Item activeDrawerItem: null

    readonly property real rawChildWidth: {
        if (root.activeView === "osd") return volumeOsdModule.implicitWidth
        if (root.activeView === "notifOsd") return notifOsdModule.implicitWidth
        if (root.activeView === "taskOverflow") return taskOverflowModule.implicitWidth
        if (root.activeDrawerItem && root.activeDrawerItem.implicitWidth > 0) {
            return root.activeDrawerItem.implicitWidth
        }

        // Direct O(1) dimension fallback lookup table
        switch (root.activeView) {
            case "calendar":      return 680
            case "settings":      return 620
            case "systemMonitor": return 540
            default:              return 340
        }
    }

    readonly property real rawChildHeight: {
        if (root.activeView === "osd") return volumeOsdModule.implicitHeight
        if (root.activeView === "notifOsd") return notifOsdModule.implicitHeight
        if (root.activeView === "taskOverflow") return taskOverflowModule.implicitHeight
        if (root.activeDrawerItem && root.activeDrawerItem.implicitHeight > 0) {
            return root.activeDrawerItem.implicitHeight
        }

        switch (root.activeView) {
            case "calendar":         return 460
            case "settings":         return 520
            case "systemMonitor":    return 500
            case "workspacePreview": return 260
            case "controlCenter":    return 480
            default:                 return 480
        }
    }

    // Explicit state variables declared in scope
    property real lastOpenWidth: rawChildWidth
    property real lastOpenHeight: rawChildHeight

    onRawChildWidthChanged: {
        if (activeView === "mirror") updateMirrorPopoutPos()
    }

    onRawChildHeightChanged: {
        if (activeView === "mirror") updateMirrorPopoutPos()
    }

    SoundEffect {
        id: openSoundPlayer
        volume: Config.windowSoundVolume !== undefined ? Config.windowSoundVolume : 0.25
        source: {
            let baseDir = Quickshell.shellDir.toString()
            if (!baseDir.endsWith("/")) baseDir += "/"
            let file = Config.windowSoundPath || "sound1.wav"
            return Qt.resolvedUrl(baseDir + "assets/" + file)
        }
    }

    function playOpenSound() {
        if (!Config.playWindowSounds || root.activeView === "notifOsd" || root.activeView === "osd") return
        openSoundPlayer.stop()
        openSoundPlayer.play()
    }

    onIsOpenChanged: {
        if (isOpen) {
            root.playOpenSound()
            root.isBarRevealedByUser = true
            root.isPeeking = false
            autoHideTimer.stop()
        } else {
            lastOpenWidth = rawChildWidth
            lastOpenHeight = rawChildHeight
            if (Config.autoHideBar) {
                root.isBarRevealedByUser = true
                autoHideTimer.restart()
            }
        }
    }

    property real targetWidth: isOpen ? rawChildWidth : (isHorizontal ? (lastOpenWidth * 0.33) : (lastOpenWidth * 1.10))
    property real targetHeight: isOpen ? rawChildHeight : (isHorizontal ? (lastOpenHeight * 1.10) : (lastOpenHeight * 0.33))

    Behavior on targetWidth {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
    }

    Behavior on targetHeight {
        NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
    }

    property real progress: 0.0
    readonly property real animScale: Math.max(0.0, progress)
    readonly property real closeFactor: root.isOpen ? progress : Math.pow(progress, 1.2)

    // Unmodified popout squish math
    readonly property real popoutHeight: targetHeight * Math.pow(closeFactor, 1.8)
    readonly property real squishRatio: targetHeight > 0 ? (1.0 - (popoutHeight / targetHeight)) : 0.0
    readonly property real popoutWidth: root.isOpen ? (targetWidth * animScale) : (targetWidth * (closeFactor + (0.33 * squishRatio * closeFactor)))

    // Dynamic switch to peek geometry without polluting the squish lifecycle
    readonly property bool peekActive: root.isPeeking && !root.isOpen && root.progress <= 0.005
    readonly property real currentWidth: peekActive ? (isHorizontal ? pkSpan : pkDepth) : popoutWidth
    readonly property real currentHeight: peekActive ? (isHorizontal ? pkDepth : pkSpan) : popoutHeight

    readonly property real wingW: peekActive ? pkWing : ((Config.surfaceRadius || 18) * animScale)
    readonly property real wingH: peekActive ? pkWing : ((Config.surfaceRadius || 18) * animScale)
    readonly property real radius: Math.max(0.1, peekActive ? pkRad : ((Config.surfaceRadius || 18) * animScale))

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

    // --- AUTO-HIDE ENGINE ---
    property bool isBarHovered: false
    property bool isBarRevealedByUser: false
    readonly property bool isBarRevealed: !Config.autoHideBar || root.isOpen || (root.progress > 0.005) || isBarHovered || isBarRevealedByUser || (root.activeView !== "none")

    Timer {
        id: autoHideTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!barContentHover.hovered && !edgeHover.hovered && !root.isOpen && root.activeView === "none") {
                root.isBarRevealedByUser = false
                root.isBarHovered = false
            }
        }
    }

    property real autoHideProgress: isBarRevealed ? 1.0 : 0.0
    Behavior on autoHideProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    readonly property real autoHideDist: barH + currentMargin + 32
    readonly property real autoHideShiftDist: isScreenFrame ? barH : autoHideDist
    readonly property real autoHideXOffset: {
        if (!Config.autoHideBar) return 0
        if (barPosition === "left") return (1.0 - autoHideProgress) * -autoHideShiftDist
        if (barPosition === "right") return (1.0 - autoHideProgress) * autoHideShiftDist
        return 0
    }
    readonly property real autoHideYOffset: {
        if (!Config.autoHideBar) return 0
        if (barPosition === "top") return (1.0 - autoHideProgress) * -autoHideShiftDist
        if (barPosition === "bottom") return (1.0 - autoHideProgress) * autoHideShiftDist
        return 0
    }

    mask: Region {
        Region { item: isBarRevealed ? barContent : null }
        Region { item: root.progress > 0.01 ? contentContainer : null }
        Region { item: (Config.autoHideBar && !isBarRevealed) ? edgeTrigger : null }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: (Config.isBarEnabledForScreen(screen ? screen.name : "") && !Config.autoHideBar)
        ? (isScreenFrame ? (barH + (framePadding * 2)) : (barH + (currentMargin > 0 ? currentMargin : (Config.barMargin || 4))))
        : 0
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
        active: root.isOpen && root.activeView !== "osd" && root.activeView !== "notifOsd" && !(root.activeView === "mirror" && Config.mirrorPinned) && (!screen || screen.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""))
        windows: [root]
        onCleared: {
            root.closeOthers("none")
            root.isCentered = false
        }
    }

    readonly property bool isIsland: Config.barFrameStyle === "island"
    readonly property bool isFloatingStyle: Config.barFrameStyle === "floating" || isIsland
    readonly property real leftCardTargetWidth: leftCard ? (root.isHorizontal ? (leftCard.contentTargetWidth || leftCard.width) : 36) : 0
    readonly property real leftCardTargetHeight: leftCard ? (!root.isHorizontal ? (leftCard.contentTargetHeight || leftCard.height) : 36) : 0
    readonly property real rightCardTargetWidth: rightCard ? (root.isHorizontal ? (rightCard.contentTargetWidth || rightCard.width) : 36) : 0
    readonly property real rightCardTargetHeight: rightCard ? (!root.isHorizontal ? (rightCard.contentTargetHeight || rightCard.height) : 36) : 0

    readonly property real islandContentWidth: (root.isHorizontal ? leftCardTargetWidth : (leftCard ? leftCard.width : 0)) 
        + (activeWindowCard && activeWindowCard.visible ? 190 : 0) 
        + (root.isHorizontal ? rightCardTargetWidth : (rightCard ? rightCard.width : 0)) 
        + 64
    readonly property real islandTargetWidth: Math.min(
        mainContainer.width - (root.currentMargin * 2),
        Math.max(200, (root.isOpen && root.isHorizontal) ? Math.max(islandContentWidth, root.targetWidth) : islandContentWidth)
    )

    property real animatedIslandWidth: isIsland ? islandTargetWidth : (mainContainer.width - Math.ceil(root.borderWidth))
    Behavior on animatedIslandWidth {
        NumberAnimation { id: islandWidthAnim; duration: 250; easing.type: Easing.OutCubic }
    }

    readonly property real islandContentHeight: (!root.isHorizontal ? leftCardTargetHeight : (leftCard ? leftCard.height : 0)) 
        + (activeWindowCard && activeWindowCard.visible ? 190 : 0) 
        + (rightCard ? rightCard.height : 0) 
        + 64

    readonly property real islandTargetHeight: Math.min(
        mainContainer.height - (root.currentMargin * 2),
        Math.max(200, (root.isOpen && !root.isHorizontal) ? Math.max(islandContentHeight, root.targetHeight) : islandContentHeight)
    )
    property real animatedIslandHeight: isIsland ? islandTargetHeight : (mainContainer.height - Math.ceil(root.borderWidth))
    Behavior on animatedIslandHeight {
        NumberAnimation { id: islandHeightAnim; duration: 250; easing.type: Easing.OutCubic }
    }

    readonly property bool isIslandResizing: isIsland && (islandWidthAnim.running || islandHeightAnim.running)

    readonly property real islandX: (mainContainer.width - animatedIslandWidth) / 2
    readonly property real islandY: (mainContainer.height - animatedIslandHeight) / 2

    readonly property bool isOsdView: activeView === "osd" || activeView === "notifOsd"

    readonly property real minPossibleLeft: isScreenFrame ? ((isHorizontal ? inX : inY) + halfB) : halfB
    readonly property real maxPossibleRight: isScreenFrame ? ((isHorizontal ? inX + inW : inY + inH) - halfB) : ((isHorizontal ? mainContainer.width : mainContainer.height) - halfB)

    readonly property bool isIslandBothFlush: root.isIsland && root.isOpen && (
        (root.isHorizontal ? root.targetWidth : root.targetHeight) >= (root.isHorizontal ? (root.islandContentWidth - 16) : (root.islandContentHeight - 16))
    )
    
    readonly property real islandBarL: root.isIsland ? Math.min(root.islandX, root.pLeft) : root.halfB
    readonly property real islandBarR: root.isIsland ? Math.max(root.islandX + root.animatedIslandWidth, root.pRight) : (mainContainer.width - root.halfB)
    readonly property real islandBarT: root.isIsland ? Math.min(root.islandY, root.pLeft) : root.halfB
    readonly property real islandBarB: root.isIsland ? Math.max(root.islandY + root.animatedIslandHeight, root.pRight) : (mainContainer.height - root.halfB)

    readonly property real safeCornerMargin: isScreenFrame ? (root.inRadi + root.wingW) : (root.barRadius + root.wingW)

    readonly property bool isPanelActive: root.isOpen || root.progress > 0.005

    readonly property bool isLeftFlush: isPanelActive && !peekActive && (root.isIsland
        ? (root.isHorizontal 
            ? (staticLeft <= (root.islandX + safeCornerMargin)) 
            : (staticLeft <= (root.islandY + safeCornerMargin)))
        : (root.isScreenFrame && !isCentered && (
            (isHorizontal ? (popoutXOffset - targetWidth / 2.0) : (popoutYOffset - targetHeight / 2.0)) <= minPossibleLeft
        )))

    readonly property bool isRightFlush: isPanelActive && !peekActive && (root.isIsland
        ? (root.isHorizontal 
            ? ((staticLeft + targetWidth) >= (root.islandX + root.animatedIslandWidth - safeCornerMargin)) 
            : ((staticLeft + targetHeight) >= (root.islandY + root.animatedIslandHeight - safeCornerMargin)))
        : (root.isScreenFrame && !isCentered && (
            (isHorizontal ? (popoutXOffset + targetWidth / 2.0) : (popoutYOffset + targetHeight / 2.0)) >= maxPossibleRight
        )))

    readonly property real targetCenteredLeft: Math.max(
        minPossibleLeft + safeCornerMargin,
        Math.min(
            maxPossibleRight - (isHorizontal ? targetWidth : targetHeight) - safeCornerMargin,
            ((isHorizontal ? mainContainer.width : mainContainer.height) - (isHorizontal ? targetWidth : targetHeight)) / 2.0
        )
    )

    readonly property real staticLeft: {
        let span = isHorizontal ? targetWidth : targetHeight
        let offset = isHorizontal ? popoutXOffset : popoutYOffset
        let safeMargin = root.safeCornerMargin
        if (isCentered) return targetCenteredLeft

        if (root.isIsland) {
            let barOrigin = isHorizontal ? root.islandX : root.islandY
            let barEnd = isHorizontal ? (root.islandX + root.animatedIslandWidth) : (root.islandY + root.animatedIslandHeight)
            let barSpan = barEnd - barOrigin
            let rawLeft = offset - (span / 2.0)
            let rawRight = offset + (span / 2.0)

            if (span >= barSpan - safeMargin) {
                return barOrigin + ((barSpan - span) / 2.0)
            }
            if (rawLeft <= barOrigin + safeMargin) return barOrigin
            if (rawRight >= barEnd - safeMargin) return barEnd - span
            return Math.max(barOrigin + safeMargin, Math.min(barEnd - safeMargin - span, rawLeft))
        }

        let rawLeft = offset - (span / 2.0)
        let rawRight = offset + (span / 2.0)
        if (root.isScreenFrame && !isCentered && rawLeft <= minPossibleLeft) return minPossibleLeft
        if (root.isScreenFrame && !isCentered && rawRight >= maxPossibleRight) return maxPossibleRight - span
        return Math.max(minPossibleLeft + safeMargin, Math.min(maxPossibleRight - span - safeMargin, rawLeft))
    }

    readonly property real staticRight: staticLeft + (isHorizontal ? targetWidth : targetHeight)

    readonly property real pLeft: peekActive ? pkLeft : staticLeft
    readonly property real pRight: peekActive ? pkRight : staticRight

    property string activeView: "none"

    function refreshPopoutPos() {
        if (activeView === "none" || activeView === "workspacePreview") return

        // 1. Edge OSDs: Snap coordinates to screen boundaries or center on Island bar
        if (activeView === "osd" || activeView === "notifOsd") {
            root.isCentered = false
            if (root.isIsland) {
                if (root.isHorizontal) root.popoutXOffset = root.islandX + (root.animatedIslandWidth / 2.0)
                else root.popoutYOffset = root.islandY + (root.animatedIslandHeight / 2.0)
            } else {
                if (activeView === "osd") {
                    if (root.isHorizontal) root.popoutXOffset = mainContainer.width
                    else root.popoutYOffset = mainContainer.height
                } else {
                    root.popoutXOffset = 0
                    root.popoutYOffset = 0
                }
            }
            return
        }

        // 2. Bar Panel Modules: Map view IDs to button handles
        let btn = null

        switch (activeView) {
            // Left Card Modules
            case "settings":       btn = leftCard ? (leftCard.getButton("settings") || leftCard) : null; break
            case "appLauncher":    btn = leftCard ? (leftCard.getButton("launcher") || leftCard) : null; break
            case "power":          btn = leftCard ? (leftCard.getButton("power") || leftCard) : null; break
            case "wallpaper":      btn = leftCard ? (leftCard.getButton("wallpaper") || leftCard) : null; break
            case "notifications":  btn = leftCard ? (leftCard.getButton("notifications") || leftCard) : null; break
            case "screenRecorder": btn = leftCard ? (leftCard.getButton("recorder") || leftCard) : null; break
            case "mirror":         btn = leftCard ? (leftCard.getButton("mirror") || leftCard) : null; break
            case "audio":          btn = leftCard ? (leftCard.getButton("audio") || leftCard) : null; break
            case "network":        btn = leftCard ? (leftCard.getButton("network") || leftCard) : null; break
            case "battery":        btn = leftCard ? (leftCard.getButton("batt") || leftCard) : null; break
            case "clipboard":      btn = leftCard ? (leftCard.getButton("clipboard") || leftCard) : null; break

            // Right Card & Center Modules
            case "workspacePreview": btn = rightCard ? (rightCard.getButton("overview") || rightCard) : null; break
            case "taskOverflow":     btn = activeWindowCard; break
            case "controlCenter":    btn = rightCard ? (rightCard.getButton("cc") || rightCard) : null; break
            case "calendar":         btn = rightCard ? (rightCard.getButton("clock") || rightCard) : null; break
        }

        // Snap popout offset to the active button position or anchor mode
        if (activeView === "mirror") {
            updateMirrorPopoutPos()
        } else if (btn) {
            setPopoutPos(btn)
        }
    }

    // Unified popout re-anchoring engine for ALL views
    onActiveViewChanged: {
        refreshPopoutPos()
    }

    function updateActiveView() {
        let nextView = "none"
        let isFocused = !screen || screen.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")

        if (isFocused) {
            // High Priority OSD Takeover (Preserves underlying panel state)
            if (typeof Config.showOSD !== "undefined" && Config.showOSD) nextView = "osd"
            else if (typeof Config.showNotificationOsd !== "undefined" && Config.showNotificationOsd) nextView = "notifOsd"

            // Standard Module Panels (Unpinned active modules take priority)
            else if (Config.showSettings) nextView = "settings"
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
            else if (Config.showScreenRecorder) nextView = "screenRecorder"
            else if (Config.showControlCenter) nextView = "controlCenter"
            else if (Config.showMirror && !Config.mirrorPinned) nextView = "mirror"
            else if (typeof Config.showTaskOverflow !== "undefined" && Config.showTaskOverflow) nextView = "taskOverflow"

            // Pinned Fallback Panels (Active when no temporary unpinned panel is open)
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
        let isOsdTrigger = (except === "osd" || except === "notifOsd")

        if (except !== "osd" && typeof Config.showOSD !== "undefined") Config.showOSD = false
        if (except !== "notifOsd" && typeof Config.showNotificationOsd !== "undefined") Config.showNotificationOsd = false

        if (!isOsdTrigger) {
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
            if (except !== "settings") Config.showSettings = false
            if (except !== "taskOverflow" && typeof Config.showTaskOverflow !== "undefined") Config.showTaskOverflow = false
        }
    }

    Connections {
        target: Config
        ignoreUnknownSignals: true

        function onEnableHoverPeekChanged() {
            if (!Config.enableHoverPeek && root.isPeeking) {
                root.stopPeek()
            }
        }

        function onBarPositionChanged() {
            if (root.isOpen && root.activeView !== "none") {
                root.isOpen = false
                barLayoutReopenTimer.restart()
            }
        }

        function onBarFrameStyleChanged() {
            if (root.isOpen && root.activeView !== "none") {
                root.isOpen = false
                barLayoutReopenTimer.restart()
            }
        }

        function onShowOSDChanged() {
            updateActiveView()
        }

        function onShowNotificationOsdChanged() {
            updateActiveView()
        }
        
        function onShowWorkspacePreviewChanged() {
            if (Config.showWorkspacePreview) {
                closeOthers("workspacePreview")
                let btn = rightCard ? rightCard.getButton("overview") : null
                if (btn) setPopoutPos(btn)
            }
            updateActiveView()
        }
        function onShowSettingsChanged() {
            if (Config.showSettings) {
                closeOthers("settings")
                let btn = leftCard ? leftCard.getButton("settings") : null
                if (btn) setPopoutPos(btn)
            }
            updateActiveView()
        }
        function onShowTaskOverflowChanged() {
            if (Config.showTaskOverflow) {
                closeOthers("taskOverflow")
                if (activeWindowCard) setPopoutPos(activeWindowCard)
            }
            updateActiveView()
        }
        function onShowAppLauncherChanged() { if (Config.showAppLauncher) { closeOthers("appLauncher"); let btn = leftCard ? leftCard.getButton("launcher") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowPowerChanged() { if (Config.showPower) { closeOthers("power"); let btn = leftCard ? leftCard.getButton("power") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowWallpaperChanged() { if (Config.showWallpaper) { closeOthers("wallpaper"); let btn = leftCard ? leftCard.getButton("wallpaper") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowCalendarChanged() { if (Config.showCalendar) { closeOthers("calendar"); let btn = rightCard ? rightCard.getButton("clock") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowNotificationsChanged() { if (Config.showNotifications) { closeOthers("notifications"); let btn = leftCard ? leftCard.getButton("notifications") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowAudioChanged() { if (Config.showAudio) { closeOthers("audio"); let btn = leftCard ? leftCard.getButton("audio") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowNetworkChanged() { if (Config.showNetwork) { closeOthers("network"); let btn = leftCard ? leftCard.getButton("network") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowBatteryChanged() { if (Config.showBattery) { closeOthers("battery"); let btn = leftCard ? leftCard.getButton("batt") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowClipboardChanged() { if (Config.showClipboard) { closeOthers("clipboard"); let btn = leftCard ? leftCard.getButton("clipboard") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowScreenRecorderChanged() { if (Config.showScreenRecorder) { closeOthers("screenRecorder"); let btn = leftCard ? leftCard.getButton("recorder") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
        function onShowMirrorChanged() {
            if (Config.showMirror) {
                closeOthers("mirror")
            }
            updateActiveView()
            if (Config.showMirror) {
                updateMirrorPopoutPos()
            }
        }
        function onMirrorAnchorPosChanged() {
            if (activeView === "mirror") {
                root.isOpen = false
                mirrorReopenTimer.restart()
            }
        }
        function onShowControlCenterChanged() { if (Config.showControlCenter) { closeOthers("controlCenter"); let btn = rightCard ? rightCard.getButton("cc") : null; if (btn) setPopoutPos(btn); } updateActiveView() }
    }

    // --- AUTO-HIDE EDGE TRIGGER ---
    Item {
        id: edgeTrigger
        z: 999
        visible: Config.autoHideBar && !root.isBarRevealed

        x: root.shadowPadding + (isHorizontal ? (root.isIsland ? root.islandX : 0) : (barPosition === "right" ? (root.actualScreenWidth - 16) : 0))
        y: root.shadowPadding + (isHorizontal ? (barPosition === "bottom" ? (root.actualScreenHeight - 16) : 0) : (root.isIsland ? root.islandY : 0))
        width: isHorizontal ? (root.isIsland ? root.animatedIslandWidth : root.actualScreenWidth) : 16
        height: !isHorizontal ? (root.isIsland ? root.animatedIslandHeight : root.actualScreenHeight) : 16

        HoverHandler {
            id: edgeHover
            onHoveredChanged: {
                if (hovered) {
                    root.isBarRevealedByUser = true
                    autoHideTimer.restart()
                }
            }
        }
    }

    Item {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: shadowPadding

        opacity: root.isScreenFrame ? 1.0 : (Config.autoHideBar ? root.autoHideProgress : 1.0)
        visible: root.isScreenFrame || !Config.autoHideBar || root.autoHideProgress > 0.001

        MouseArea {
            anchors.fill: parent
            enabled: root.isOpen
            onClicked: {
                root.closeOthers("none")
                root.isCentered = false
            }
        }

        states: [
            State { name: "open"; when: root.isOpen; PropertyChanges { target: root; progress: 1.0 } },
            State { name: "closed"; when: !root.isOpen; PropertyChanges { target: root; progress: 0.0 } }
        ]

        transitions: [
            Transition {
                from: "closed"; to: "open"
                NumberAnimation { target: root; property: "progress"; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
            },
            Transition {
                from: "open"; to: "closed"
                NumberAnimation { target: root; property: "progress"; duration: 300; easing.type: Easing.InBack; easing.overshoot: 1.6 }
            }
        ]

        Item {
            id: shadowWrapper
            anchors.fill: parent

            layer.enabled: true
            layer.samples: 4
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#D0000000"
                shadowBlur: 0.7
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            Component {
                id: screenFrameCorners
                Shape {
                    anchors.fill: parent
                    readonly property bool popupActive: root.progress > 0.005 || root.peekActive
                    readonly property bool hideTL: popupActive && ((root.barPosition === "left" && (root.isLeftFlush || (root.peekActive && root.isPeekLeftFlush))) || (root.barPosition === "top" && (root.isLeftFlush || (root.peekActive && root.isPeekLeftFlush))))
                    readonly property bool hideTR: popupActive && ((root.barPosition === "right" && (root.isLeftFlush || (root.peekActive && root.isPeekLeftFlush))) || (root.barPosition === "top" && (root.isRightFlush || (root.peekActive && root.isPeekRightFlush))))
                    readonly property bool hideBL: popupActive && ((root.barPosition === "left" && (root.isRightFlush || (root.peekActive && root.isPeekRightFlush))) || (root.barPosition === "bottom" && (root.isLeftFlush || (root.peekActive && root.isPeekLeftFlush))))
                    readonly property bool hideBR: popupActive && ((root.barPosition === "right" && (root.isRightFlush || (root.peekActive && root.isPeekRightFlush))) || (root.barPosition === "bottom" && (root.isRightFlush || (root.peekActive && root.isPeekRightFlush))))

                    ShapePath {
                        fillColor: hideTL ? "transparent" : Config.bgPanel; strokeWidth: 0
                        startX: root.inX; startY: root.inY
                        PathLine { x: root.inX + root.inRadi; y: root.inY }
                        PathArc { x: root.inX; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX; y: root.inY }
                    }
                    ShapePath {
                        fillColor: hideTR ? "transparent" : Config.bgPanel; strokeWidth: 0
                        startX: root.inX + root.inW; startY: root.inY
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY }
                        PathArc { x: root.inX + root.inW; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW; y: root.inY }
                    }
                    ShapePath {
                        fillColor: hideBL ? "transparent" : Config.bgPanel; strokeWidth: 0
                        startX: root.inX; startY: root.inY + root.inH
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH }
                        PathArc { x: root.inX; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX; y: root.inY }
                    }
                    ShapePath {
                        fillColor: hideBR ? "transparent" : Config.bgPanel; strokeWidth: 0
                        startX: root.inX + root.inW; startY: root.inY + root.inH
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH }
                        PathArc { x: root.inX + root.inW; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX + root.inW; y: root.inY + root.inH }
                    }
                }
            }

            Shape {
                id: closedShape
                anchors.fill: parent
                visible: root.progress <= 0.005 && !root.isPeeking && !root.isScreenFrame

                readonly property real bX: (root.isIsland 
                    ? (root.isHorizontal ? root.islandX : (root.isRight ? (mainContainer.width - root.barH + root.halfB) : root.halfB))
                    : (root.isRight ? (mainContainer.width - root.barH + root.halfB) : root.halfB)) + root.autoHideXOffset

                readonly property real bY: (root.isIsland
                    ? (root.isHorizontal ? (root.isBottom ? (mainContainer.height - root.barH + root.halfB) : root.halfB) : root.islandY)
                    : (root.isBottom ? (mainContainer.height - root.barH + root.halfB) : root.halfB)) + root.autoHideYOffset

                readonly property real bW: (root.isIsland
                    ? (root.isHorizontal ? (root.islandX + root.animatedIslandWidth) : (root.isRight ? (mainContainer.width - root.halfB) : (root.barH - root.halfB)))
                    : (root.isHorizontal ? (mainContainer.width - root.halfB) : (root.isRight ? (mainContainer.width - root.halfB) : (root.barH - root.halfB)))) + root.autoHideXOffset

                readonly property real bH: (root.isIsland
                    ? (root.isHorizontal ? (root.isBottom ? (mainContainer.height - root.halfB) : (root.barH - root.halfB)) : (root.islandY + root.animatedIslandHeight))
                    : (root.isHorizontal ? (root.isBottom ? (mainContainer.height - root.halfB) : (root.barH - root.halfB)) : (mainContainer.height - root.halfB))) + root.autoHideYOffset

                ShapePath {
                    fillColor: Config.bgPanel
                    strokeWidth: root.borderWidth
                    strokeColor: shellRoot.currentBorderColor
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: closedShape.bX + root.barRadius
                    startY: closedShape.bY

                    PathLine { x: closedShape.bW - root.barRadius; y: closedShape.bY }
                    PathArc { x: closedShape.bW; y: closedShape.bY + root.barRadius; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                    PathLine { x: closedShape.bW; y: closedShape.bH - root.barRadius }
                    PathArc { x: closedShape.bW - root.barRadius; y: closedShape.bH; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                    PathLine { x: closedShape.bX + root.barRadius; y: closedShape.bH }
                    PathArc { x: closedShape.bX; y: closedShape.bH - root.barRadius; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                    PathLine { x: closedShape.bX; y: closedShape.bY + root.barRadius }
                    PathArc { x: closedShape.bX + root.barRadius; y: closedShape.bY; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                }
            }

            Shape {
                id: openShapeLeftFloating
                anchors.fill: parent
                visible: root.barPosition === "left" && !root.isScreenFrame && (root.progress > 0 || root.isPeeking)

                ShapePath {
                    fillColor: Config.bgPanel
                    strokeWidth: root.borderWidth
                    strokeColor: shellRoot.currentBorderColor
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: root.halfB + root.barRadius
                    startY: root.islandBarT

                    // Top horizontal segment towards popup/bar outer edge
                    PathLine { 
                        x: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth - root.radius) 
                            : (root.barH - root.halfB - root.barRadius)
                        y: root.islandBarT 
                    }
                    PathArc { 
                        x: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth) 
                            : (root.barH - root.halfB)
                        y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : (root.islandBarT + root.barRadius)
                        radiusX: root.isLeftFlush ? Math.max(0.1, root.radius) : root.barRadius
                        radiusY: root.isLeftFlush ? Math.max(0.1, root.radius) : root.barRadius
                        direction: PathArc.Clockwise 
                    }

                    // Upper wing transition into the popout
                    PathLine { 
                        x: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth) 
                            : (root.barH - root.halfB)
                        y: root.isLeftFlush 
                            ? (root.isRightFlush ? (root.islandBarB - root.radius) : (root.pRight - root.radius)) 
                            : (root.pLeft - root.wingW) 
                    }
                    PathCubic { 
                        x: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth) 
                            : (root.barH - root.halfB + root.wingW)
                        y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : root.pLeft
                        control1X: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth) 
                            : (root.barH - root.halfB)
                        control1Y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : (root.pLeft - (root.wingW * 0.5))
                        control2X: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth) 
                            : (root.barH - root.halfB + (root.wingW * 0.5))
                        control2Y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : root.pLeft 
                    }

                    // Popout outer top-right edge & curve
                    PathLine { 
                        x: root.isLeftFlush 
                            ? (root.barH - root.halfB + root.currentWidth) 
                            : (root.barH - root.halfB + root.currentWidth - root.radius)
                        y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : root.pLeft 
                    }
                    PathArc { 
                        x: root.barH - root.halfB + root.currentWidth
                        y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : (root.pLeft + root.radius)
                        radiusX: root.isLeftFlush ? 0 : Math.max(0.1, root.radius)
                        radiusY: root.isLeftFlush ? 0 : Math.max(0.1, root.radius)
                        direction: PathArc.Clockwise 
                    }

                    // Popout outer edge down to bottom-right corner
                    PathLine { 
                        x: root.barH - root.halfB + root.currentWidth
                        y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : (root.pRight - root.radius) 
                    }
                    PathArc { 
                        x: root.barH - root.halfB + root.currentWidth - root.radius
                        y: root.isRightFlush 
                            ? root.islandBarB 
                            : root.pRight
                        radiusX: Math.max(0.1, root.radius)
                        radiusY: Math.max(0.1, root.radius)
                        direction: PathArc.Clockwise 
                    }

                    // Lower wing transition back into the bar
                    PathLine { 
                        x: root.isRightFlush 
                            ? (root.halfB + root.barRadius) 
                            : (root.barH - root.halfB + root.wingW)
                        y: root.isRightFlush 
                            ? root.islandBarB 
                            : root.pRight 
                    }
                    PathCubic { 
                        x: root.isRightFlush 
                            ? (root.halfB + root.barRadius) 
                            : (root.barH - root.halfB)
                        y: root.isRightFlush 
                            ? root.islandBarB 
                            : (root.pRight + root.wingW)
                        control1X: root.isRightFlush 
                            ? (root.halfB + root.barRadius) 
                            : (root.barH - root.halfB + (root.wingW * 0.5))
                        control1Y: root.isRightFlush 
                            ? root.islandBarB 
                            : root.pRight
                        control2X: root.isRightFlush 
                            ? (root.halfB + root.barRadius) 
                            : (root.barH - root.halfB)
                        control2Y: root.isRightFlush 
                            ? root.islandBarB 
                            : (root.pRight + (root.wingW * 0.5)) 
                    }

                    // Bottom bar return line and inner corner arcs
                    PathLine { 
                        x: root.isRightFlush 
                            ? (root.halfB + root.barRadius) 
                            : (root.barH - root.halfB)
                        y: root.isRightFlush 
                            ? root.islandBarB 
                            : (root.islandBarB - root.barRadius) 
                    }
                    PathArc { 
                        x: root.isRightFlush 
                            ? (root.halfB + root.barRadius) 
                            : (root.barH - root.halfB - root.barRadius)
                        y: root.islandBarB
                        radiusX: root.isRightFlush ? 0 : root.barRadius
                        radiusY: root.isRightFlush ? 0 : root.barRadius
                        direction: PathArc.Clockwise 
                    }
                    PathLine { 
                        x: root.halfB + root.barRadius
                        y: root.islandBarB 
                    }
                    PathArc { 
                        x: root.halfB
                        y: root.islandBarB - root.barRadius
                        radiusX: root.barRadius
                        radiusY: root.barRadius
                        direction: PathArc.Clockwise 
                    }
                    PathLine { 
                        x: root.halfB
                        y: root.islandBarT + root.barRadius 
                    }
                    PathArc { 
                        x: root.halfB + root.barRadius
                        y: root.islandBarT
                        radiusX: root.barRadius
                        radiusY: root.barRadius
                        direction: PathArc.Clockwise 
                    }
                }
            }

            Shape {
                id: openShapeTopFloating
                anchors.fill: parent
                visible: root.barPosition === "top" && !root.isScreenFrame && (root.progress > 0 || root.isPeeking)

                ShapePath {
                    fillColor: Config.bgPanel
                    strokeWidth: root.borderWidth
                    strokeColor: shellRoot.currentBorderColor
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: root.islandBarL + root.barRadius
                    startY: root.halfB
                    PathLine { x: root.islandBarR - root.barRadius; y: root.halfB }
                    PathArc { x: root.islandBarR; y: root.halfB + root.barRadius; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                    PathLine { x: root.islandBarR; y: root.isRightFlush ? (root.barBottomY + root.currentHeight - root.radius) : (root.barBottomY - root.barRadius) }
                    PathArc { x: root.isRightFlush ? root.islandBarR : (root.islandBarR - root.barRadius); y: root.isRightFlush ? (root.barBottomY + root.currentHeight - root.radius) : root.barBottomY; radiusX: root.isRightFlush ? 0 : root.barRadius; radiusY: root.isRightFlush ? 0 : root.barRadius; direction: PathArc.Clockwise }
                    PathLine { x: root.isRightFlush ? root.islandBarR : (root.pRight + root.wingW); y: root.isRightFlush ? (root.barBottomY + root.currentHeight - root.radius) : root.barBottomY }
                    PathCubic { x: root.isRightFlush ? root.islandBarR : root.pRight; y: root.isRightFlush ? (root.barBottomY + root.currentHeight - root.radius) : (root.barBottomY + root.wingH); control1X: root.isRightFlush ? root.islandBarR : (root.pRight + (root.wingW * 0.5)); control1Y: root.isRightFlush ? (root.barBottomY + root.currentHeight - root.radius) : root.barBottomY; control2X: root.isRightFlush ? root.islandBarR : root.pRight; control2Y: root.isRightFlush ? (root.barBottomY + root.currentHeight - root.radius) : (root.barBottomY + (root.wingH * 0.5)) }
                    PathLine { x: root.isRightFlush ? root.islandBarR : root.pRight; y: root.barBottomY + root.currentHeight - root.radius }
                    PathArc { x: root.isRightFlush ? (root.islandBarR - root.radius) : (root.pRight - root.radius); y: root.barBottomY + root.currentHeight; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Clockwise }
                    PathLine { x: root.isLeftFlush ? (root.islandBarL + root.radius) : (root.pLeft + root.radius); y: root.barBottomY + root.currentHeight }
                    PathArc { x: root.isLeftFlush ? root.islandBarL : root.pLeft; y: root.barBottomY + root.currentHeight - root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Clockwise }
                    PathLine { x: root.isLeftFlush ? root.islandBarL : root.pLeft; y: root.isLeftFlush ? (root.halfB + root.barRadius) : (root.barBottomY + root.wingH) }
                    PathCubic { x: root.isLeftFlush ? root.islandBarL : (root.pLeft - root.wingW); y: root.isLeftFlush ? (root.halfB + root.barRadius) : root.barBottomY; control1X: root.isLeftFlush ? root.islandBarL : root.pLeft; control1Y: root.isLeftFlush ? (root.halfB + root.barRadius) : (root.barBottomY + (root.wingH * 0.5)); control2X: root.isLeftFlush ? root.islandBarL : (root.pLeft - (root.wingW * 0.5)); control2Y: root.isLeftFlush ? (root.halfB + root.barRadius) : root.barBottomY }
                    PathLine { x: root.isLeftFlush ? root.islandBarL : (root.islandBarL + root.barRadius); y: root.isLeftFlush ? (root.halfB + root.barRadius) : root.barBottomY }
                    PathArc { x: root.islandBarL; y: root.isLeftFlush ? (root.halfB + root.barRadius) : (root.barBottomY - root.barRadius); radiusX: root.isLeftFlush ? 0 : root.barRadius; radiusY: root.isLeftFlush ? 0 : root.barRadius; direction: PathArc.Clockwise }
                    PathLine { x: root.islandBarL; y: root.halfB + root.barRadius }
                    PathArc { x: root.islandBarL + root.barRadius; y: root.halfB; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                }
            }

            Shape {
                id: openShapeBottomFloating
                anchors.fill: parent
                visible: root.barPosition === "bottom" && !root.isScreenFrame && (root.progress > 0 || root.isPeeking)
                readonly property real barTopY: mainContainer.height - root.barH + root.halfB

                ShapePath {
                    fillColor: Config.bgPanel
                    strokeWidth: root.borderWidth
                    strokeColor: shellRoot.currentBorderColor
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: root.islandBarL + root.barRadius
                    startY: mainContainer.height - root.halfB

                    // Bottom horizontal line (left to right)
                    PathLine { x: root.islandBarR - root.barRadius; y: mainContainer.height - root.halfB }
                    PathArc { x: root.islandBarR; y: mainContainer.height - root.halfB - root.barRadius; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Counterclockwise }

                    // Right side going up to the bar top edge
                    PathLine { x: root.islandBarR; y: root.isRightFlush ? (openShapeBottomFloating.barTopY - root.currentHeight + root.radius) : (openShapeBottomFloating.barTopY + root.barRadius) }
                    PathArc { x: root.isRightFlush ? root.islandBarR : (root.islandBarR - root.barRadius); y: root.isRightFlush ? (openShapeBottomFloating.barTopY - root.currentHeight + root.radius) : openShapeBottomFloating.barTopY; radiusX: root.isRightFlush ? 0 : root.barRadius; radiusY: root.isRightFlush ? 0 : root.barRadius; direction: PathArc.Counterclockwise }

                    // Right transition into popout
                    PathLine { x: root.isRightFlush ? root.islandBarR : (root.pRight + root.wingW); y: root.isRightFlush ? (openShapeBottomFloating.barTopY - root.currentHeight + root.radius) : openShapeBottomFloating.barTopY }
                    PathCubic { 
                        x: root.isRightFlush ? root.islandBarR : root.pRight; 
                        y: root.isRightFlush ? (openShapeBottomFloating.barTopY - root.currentHeight + root.radius) : (openShapeBottomFloating.barTopY - root.wingH); 
                        control1X: root.isRightFlush ? root.islandBarR : (root.pRight + (root.wingW * 0.5)); 
                        control1Y: root.isRightFlush ? (openShapeBottomFloating.barTopY - root.currentHeight + root.radius) : openShapeBottomFloating.barTopY; 
                        control2X: root.isRightFlush ? root.islandBarR : root.pRight; 
                        control2Y: root.isRightFlush ? (openShapeBottomFloating.barTopY - root.currentHeight + root.radius) : (openShapeBottomFloating.barTopY - (root.wingH * 0.5)) 
                    }

                    // Popout Top-Right Corner
                    PathLine { x: root.isRightFlush ? root.islandBarR : root.pRight; y: openShapeBottomFloating.barTopY - root.currentHeight + root.radius }
                    PathArc { x: root.isRightFlush ? (root.islandBarR - root.radius) : (root.pRight - root.radius); y: openShapeBottomFloating.barTopY - root.currentHeight; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }

                    // Popout Top edge (Right to Left)
                    PathLine { x: root.isLeftFlush ? (root.islandBarL + root.radius) : (root.pLeft + root.radius); y: openShapeBottomFloating.barTopY - root.currentHeight }
                    PathArc { x: root.isLeftFlush ? root.islandBarL : root.pLeft; y: openShapeBottomFloating.barTopY - root.currentHeight + root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }

                    // Popout Left side going down into bar
                    PathLine { x: root.isLeftFlush ? root.islandBarL : root.pLeft; y: root.isLeftFlush ? (mainContainer.height - root.halfB - root.barRadius) : (openShapeBottomFloating.barTopY - root.wingH) }
                    PathCubic { 
                        x: root.isLeftFlush ? root.islandBarL : (root.pLeft - root.wingW); 
                        y: root.isLeftFlush ? (mainContainer.height - root.halfB - root.barRadius) : openShapeBottomFloating.barTopY; 
                        control1X: root.isLeftFlush ? root.islandBarL : root.pLeft; 
                        control1Y: root.isLeftFlush ? (mainContainer.height - root.halfB - root.barRadius) : (openShapeBottomFloating.barTopY - (root.wingH * 0.5)); 
                        control2X: root.isLeftFlush ? root.islandBarL : (root.pLeft - (root.wingW * 0.5)); 
                        control2Y: root.isLeftFlush ? (mainContainer.height - root.halfB - root.barRadius) : openShapeBottomFloating.barTopY 
                    }

                    // Left outer transition down to the bottom corner
                    PathLine { x: root.isLeftFlush ? root.islandBarL : (root.islandBarL + root.barRadius); y: root.isLeftFlush ? (mainContainer.height - root.halfB - root.barRadius) : openShapeBottomFloating.barTopY }
                    PathArc { x: root.islandBarL; y: root.isLeftFlush ? (mainContainer.height - root.halfB - root.barRadius) : (openShapeBottomFloating.barTopY + root.barRadius); radiusX: root.isLeftFlush ? 0 : root.barRadius; radiusY: root.isLeftFlush ? 0 : root.barRadius; direction: PathArc.Counterclockwise }
                    PathLine { x: root.islandBarL; y: mainContainer.height - root.halfB - root.barRadius }
                    PathArc { x: root.islandBarL + root.barRadius; y: mainContainer.height - root.halfB; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Counterclockwise }
                }
            }

            Shape {
                id: openShapeRightFloating
                anchors.fill: parent
                visible: root.barPosition === "right" && !root.isScreenFrame && (root.progress > 0 || root.isPeeking)
                readonly property real rX: mainContainer.width - root.barH

                ShapePath {
                    fillColor: Config.bgPanel
                    strokeWidth: root.borderWidth
                    strokeColor: shellRoot.currentBorderColor
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: openShapeRightFloating.rX + root.halfB + (root.isLeftFlush ? 0 : root.barRadius)
                    startY: root.islandBarT

                    PathLine { x: mainContainer.width - root.halfB - root.barRadius; y: root.islandBarT }
                    PathArc { x: mainContainer.width - root.halfB; y: root.islandBarT + root.barRadius; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                    
                    PathLine { x: mainContainer.width - root.halfB; y: root.islandBarB - root.barRadius }
                    PathArc { x: mainContainer.width - root.halfB - root.barRadius; y: root.islandBarB; radiusX: root.barRadius; radiusY: root.barRadius; direction: PathArc.Clockwise }
                    
                    // Bottom edge transition into outer popup boundary
                    PathLine { 
                        x: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth + root.radius) 
                            : (openShapeRightFloating.rX + root.halfB + root.barRadius)
                        y: root.islandBarB 
                    }
                    PathArc { 
                        x: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth) 
                            : (openShapeRightFloating.rX + root.halfB)
                        y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : (root.islandBarB - root.barRadius)
                        radiusX: root.isRightFlush ? Math.max(0.1, root.radius) : root.barRadius
                        radiusY: root.isRightFlush ? Math.max(0.1, root.radius) : root.barRadius
                        direction: PathArc.Clockwise 
                    }
                    
                    // Bottom wing curve into popout
                    PathLine { 
                        x: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth) 
                            : (openShapeRightFloating.rX + root.halfB)
                        y: root.isRightFlush 
                            ? (root.isLeftFlush ? (root.islandBarT + root.radius) : (root.pLeft + root.radius)) 
                            : (root.pRight + root.wingW) 
                    }
                    PathCubic { 
                        x: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth) 
                            : (openShapeRightFloating.rX + root.halfB - root.wingW)
                        y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : root.pRight
                        control1X: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth) 
                            : (openShapeRightFloating.rX + root.halfB)
                        control1Y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : (root.pRight + (root.wingW * 0.5))
                        control2X: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth) 
                            : (openShapeRightFloating.rX + root.halfB - (root.wingW * 0.5))
                        control2Y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : root.pRight 
                    }

                    // Popout outer edge & corners
                    PathLine { 
                        x: root.isRightFlush 
                            ? (openShapeRightFloating.rX + root.halfB - root.currentWidth) 
                            : (openShapeRightFloating.rX + root.halfB - root.currentWidth + root.radius)
                        y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : root.pRight 
                    }
                    PathArc { 
                        x: openShapeRightFloating.rX + root.halfB - root.currentWidth
                        y: root.isRightFlush 
                            ? (root.islandBarB - root.radius) 
                            : (root.pRight - root.radius)
                        radiusX: root.isRightFlush ? 0 : Math.max(0.1, root.radius)
                        radiusY: root.isRightFlush ? 0 : Math.max(0.1, root.radius)
                        direction: PathArc.Clockwise 
                    }

                    PathLine { 
                        x: openShapeRightFloating.rX + root.halfB - root.currentWidth
                        y: root.isLeftFlush 
                            ? (root.islandBarT + root.radius) 
                            : (root.pLeft + root.radius) 
                    }
                    PathArc { 
                        x: openShapeRightFloating.rX + root.halfB - root.currentWidth + root.radius
                        y: root.isLeftFlush 
                            ? root.islandBarT 
                            : root.pLeft
                        radiusX: Math.max(0.1, root.radius)
                        radiusY: Math.max(0.1, root.radius)
                        direction: PathArc.Clockwise 
                    }

                    // Top wing curve return to bar
                    PathLine { 
                        x: root.isLeftFlush 
                            ? (mainContainer.width - root.halfB - root.barRadius) 
                            : (openShapeRightFloating.rX + root.halfB - root.wingW)
                        y: root.isLeftFlush 
                            ? root.islandBarT 
                            : root.pLeft 
                    }
                    PathCubic { 
                        x: root.isLeftFlush 
                            ? (mainContainer.width - root.halfB - root.barRadius) 
                            : (openShapeRightFloating.rX + root.halfB)
                        y: root.isLeftFlush 
                            ? root.islandBarT 
                            : (root.pLeft - root.wingW)
                        control1X: root.isLeftFlush 
                            ? (mainContainer.width - root.halfB - root.barRadius) 
                            : (openShapeRightFloating.rX + root.halfB - (root.wingW * 0.5))
                        control1Y: root.isLeftFlush 
                            ? root.islandBarT 
                            : root.pLeft
                        control2X: root.isLeftFlush 
                            ? (mainContainer.width - root.halfB - root.barRadius) 
                            : (openShapeRightFloating.rX + root.halfB)
                        control2Y: root.isLeftFlush 
                            ? root.islandBarT 
                            : (root.pLeft - (root.wingW * 0.5)) 
                    }

                    PathLine { 
                        x: root.isLeftFlush 
                            ? (mainContainer.width - root.halfB - root.barRadius) 
                            : (openShapeRightFloating.rX + root.halfB)
                        y: root.isLeftFlush 
                            ? root.islandBarT 
                            : (root.islandBarT + root.barRadius) 
                    }
                    PathArc { 
                        x: root.isLeftFlush 
                            ? (mainContainer.width - root.halfB - root.barRadius) 
                            : (openShapeRightFloating.rX + root.halfB + root.barRadius)
                        y: root.islandBarT
                        radiusX: root.isLeftFlush ? 0 : root.barRadius
                        radiusY: root.isLeftFlush ? 0 : root.barRadius
                        direction: PathArc.Clockwise 
                    }
                }
            }

            Item {
                id: sfClosedGroup
                anchors.fill: parent
                visible: root.progress === 0 && !root.isPeeking && root.isScreenFrame

                Rectangle { x: 0; y: 0; width: mainContainer.width; height: root.inY; color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY + root.inH; width: mainContainer.width; height: mainContainer.height - (root.inY + root.inH); color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY; width: root.inX; height: root.inH; color: Config.bgPanel }
                Rectangle { x: root.inX + root.inW; y: root.inY; width: mainContainer.width - (root.inX + root.inW); height: root.inH; color: Config.bgPanel }

                Loader { anchors.fill: parent; sourceComponent: screenFrameCorners }

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        fillColor: "transparent"
                        strokeWidth: root.borderWidth
                        strokeColor: shellRoot.currentBorderColor
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap

                        startX: root.inX + root.inRadi
                        startY: root.inY + root.halfB

                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
            }

            Item {
                id: sfOpenGroupLeft
                anchors.fill: parent
                visible: root.barPosition === "left" && root.isScreenFrame && (root.progress > 0 || root.isPeeking)

                Rectangle { x: 0; y: 0; width: mainContainer.width; height: root.inY; color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY + root.inH; width: mainContainer.width; height: mainContainer.height - (root.inY + root.inH); color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY; width: root.inX; height: root.inH; color: Config.bgPanel }
                Rectangle { x: root.inX + root.inW; y: root.inY; width: mainContainer.width - (root.inX + root.inW); height: root.inH; color: Config.bgPanel }

                Loader { anchors.fill: parent; sourceComponent: screenFrameCorners }

                // --- Center Floating Surface ---
                Shape {
                    anchors.fill: parent
                    visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel
                        strokeWidth: 0
                        startX: root.inX
                        startY: root.pLeft - root.wingW
                        PathCubic { x: root.inX + root.wingW; y: root.pLeft; control1X: root.inX; control1Y: root.pLeft - root.wingW * 0.5; control2X: root.inX + root.wingW * 0.5; control2Y: root.pLeft }
                        PathLine { x: root.leftBarRx - root.radius; y: root.pLeft }
                        PathArc { x: root.leftBarRx; y: root.pLeft + root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise }
                        PathLine { x: root.leftBarRx; y: root.pRight - root.radius }
                        PathArc { x: root.leftBarRx - root.radius; y: root.pRight; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.wingW; y: root.pRight }
                        PathCubic { x: root.inX; y: root.pRight + root.wingW; control1X: root.inX + root.wingW * 0.5; control1Y: root.pRight; control2X: root.inX; control2Y: root.pRight + root.wingW * 0.5 }
                        PathLine { x: root.inX; y: root.pLeft - root.wingW }
                    }
                }
                Shape {
                    anchors.fill: parent
                    visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: Config.bgPanel
                        strokeWidth: 0
                        startX: root.inX
                        startY: root.inY
                        PathLine { x: root.leftBarRx + root.wingW; y: root.inY }
                        PathCubic { x: root.leftBarRx; y: root.inY + root.wingW; control1X: root.leftBarRx + root.wingW * 0.5; control1Y: root.inY; control2X: root.leftBarRx; control2Y: root.inY + root.wingW * 0.5 }
                        PathLine { x: root.leftBarRx; y: root.pRight - root.radius }
                        PathArc { x: root.leftBarRx - root.radius; y: root.pRight; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.wingW; y: root.pRight }
                        PathCubic { x: root.inX; y: root.pRight + root.wingW; control1X: root.inX + root.wingW * 0.5; control1Y: root.pRight; control2X: root.inX; control2Y: root.pRight + root.wingW * 0.5 }
                        PathLine { x: root.inX; y: root.inY }
                    }
                }
                Shape {
                    anchors.fill: parent
                    visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel
                        strokeWidth: 0
                        startX: root.inX
                        startY: root.pLeft - root.wingW
                        PathCubic { x: root.inX + root.wingW; y: root.pLeft; control1X: root.inX; control1Y: root.pLeft - root.wingW * 0.5; control2X: root.inX + root.wingW * 0.5; control2Y: root.pLeft }
                        PathLine { x: root.leftBarRx - root.radius; y: root.pLeft }
                        PathArc { x: root.leftBarRx; y: root.pLeft + root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise }
                        PathLine { x: root.leftBarRx; y: root.inY + root.inH - root.wingW }
                        PathCubic { x: root.leftBarRx + root.wingW; y: root.inY + root.inH; control1X: root.leftBarRx; control1Y: root.inY + root.inH - root.wingW * 0.5; control2X: root.leftBarRx + root.wingW * 0.5; control2Y: root.inY + root.inH }
                        PathLine { x: root.inX; y: root.inY + root.inH }
                        PathLine { x: root.inX; y: root.pLeft - root.wingW }
                    }
                }

                // --- Inner Border Lines ---
                Shape {
                    anchors.fill: parent
                    visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"
                        strokeWidth: root.borderWidth
                        strokeColor: shellRoot.currentBorderColor
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap

                        startX: root.inX + root.inW - root.inRadi
                        startY: root.inY + root.halfB
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.pRight + root.wingW }
                        PathCubic { x: root.inX + root.wingW; y: root.pRight; control1X: root.inX + root.halfB; control1Y: root.pRight + root.wingW * 0.5; control2X: root.inX + root.wingW * 0.5; control2Y: root.pRight }
                        PathLine { x: root.leftBarRx - root.radius; y: root.pRight }
                        PathArc { x: root.leftBarRx; y: root.pRight - root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.leftBarRx; y: root.pLeft + root.radius }
                        PathArc { x: root.leftBarRx - root.radius; y: root.pLeft; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX + root.wingW; y: root.pLeft }
                        PathCubic { x: root.inX + root.halfB; y: root.pLeft - root.wingW; control1X: root.inX + root.wingW * 0.5; control1Y: root.pLeft; control2X: root.inX + root.halfB; control2Y: root.pLeft - root.wingW * 0.5 }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                    }
                }
                Shape {
                    anchors.fill: parent
                    visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: "transparent"
                        strokeWidth: root.borderWidth
                        strokeColor: shellRoot.currentBorderColor
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap

                        startX: root.inX + root.inW - root.inRadi
                        startY: root.inY + root.halfB
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.pRight + root.wingW }
                        PathCubic { x: root.inX + root.wingW; y: root.pRight; control1X: root.inX + root.halfB; control1Y: root.pRight + root.wingW * 0.5; control2X: root.inX + root.wingW * 0.5; control2Y: root.pRight }
                        PathLine { x: root.leftBarRx - root.radius; y: root.pRight }
                        PathArc { x: root.leftBarRx; y: root.pRight - root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.leftBarRx; y: root.inY + root.halfB + root.wingW }
                        PathCubic { x: root.leftBarRx + root.wingW; y: root.inY + root.halfB; control1X: root.leftBarRx; control1Y: root.inY + root.halfB + root.wingW * 0.5; control2X: root.leftBarRx + root.wingW * 0.5; control2Y: root.inY + root.halfB }
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                    }
                }
                Shape {
                    anchors.fill: parent
                    visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"
                        strokeWidth: root.borderWidth
                        strokeColor: shellRoot.currentBorderColor
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap

                        startX: root.inX + root.inRadi
                        startY: root.inY + root.halfB
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.leftBarRx + root.wingW; y: root.inY + root.inH - root.halfB }
                        PathCubic { x: root.leftBarRx; y: root.inY + root.inH - root.halfB - root.wingW; control1X: root.leftBarRx + root.wingW * 0.5; control1Y: root.inY + root.inH - root.halfB; control2X: root.leftBarRx; control2Y: root.inY + root.inH - root.halfB - root.wingW * 0.5 }
                        PathLine { x: root.leftBarRx; y: root.pLeft + root.radius }
                        PathArc { x: root.leftBarRx - root.radius; y: root.pLeft; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX + root.wingW; y: root.pLeft }
                        PathCubic { x: root.inX + root.halfB; y: root.pLeft - root.wingW; control1X: root.inX + root.wingW * 0.5; control1Y: root.pLeft; control2X: root.inX + root.halfB; control2Y: root.pLeft - root.wingW * 0.5 }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
            }

            Item {
                id: sfOpenGroupRight
                anchors.fill: parent
                visible: root.barPosition === "right" && root.isScreenFrame && (root.progress > 0 || root.isPeeking)

                Rectangle { x: 0; y: 0; width: mainContainer.width; height: root.inY; color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY + root.inH; width: mainContainer.width; height: mainContainer.height - (root.inY + root.inH); color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY; width: root.inX; height: root.inH; color: Config.bgPanel }
                Rectangle { x: root.inX + root.inW; y: root.inY; width: mainContainer.width - (root.inX + root.inW); height: root.inH; color: Config.bgPanel }

                Loader { anchors.fill: parent; sourceComponent: screenFrameCorners }

                Shape {
                    anchors.fill: parent; visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.inX + root.inW; startY: root.pRight + root.wingW
                        PathLine { x: root.inX + root.inW; y: root.pLeft - root.wingW }
                        PathCubic { x: root.inX + root.inW - root.wingW; y: root.pLeft; control1X: root.inX + root.inW; control1Y: root.pLeft - root.wingW * 0.5; control2X: root.inX + root.inW - root.wingW * 0.5; control2Y: root.pLeft }
                        PathLine { x: root.rightBarPopL + root.radius; y: root.pLeft }
                        PathArc { x: root.rightBarPopL; y: root.pLeft + root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
                        PathLine { x: root.rightBarPopL; y: root.pRight - root.radius }
                        PathArc { x: root.rightBarPopL + root.radius; y: root.pRight; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX + root.inW - root.wingW; y: root.pRight }
                        PathCubic { x: root.inX + root.inW; y: root.pRight + root.wingW; control1X: root.inX + root.inW - root.wingW * 0.5; control1Y: root.pRight; control2X: root.inX + root.inW; control2Y: root.pRight + root.wingW * 0.5 }
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.inX + root.inW; startY: root.pRight + root.wingW
                        PathLine { x: root.inX + root.inW; y: root.inY }
                        PathLine { x: root.rightBarPopL - root.wingW; y: root.inY }
                        PathCubic { x: root.rightBarPopL; y: root.inY + root.wingW; control1X: root.rightBarPopL - root.wingW * 0.5; control1Y: root.inY; control2X: root.rightBarPopL; control2Y: root.inY + root.wingW * 0.5 }
                        PathLine { x: root.rightBarPopL; y: root.pRight - root.radius }
                        PathArc { x: root.rightBarPopL + root.radius; y: root.pRight; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX + root.inW - root.wingW; y: root.pRight }
                        PathCubic { x: root.inX + root.inW; y: root.pRight + root.wingW; control1X: root.inX + root.inW - root.wingW * 0.5; control1Y: root.pRight; control2X: root.inX + root.inW; control2Y: root.pRight + root.wingW * 0.5 }
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.inX + root.inW; startY: root.inY + root.inH
                        
                        PathLine { x: root.inX + root.inW; y: root.pLeft - root.wingW } 
                        PathCubic { x: root.inX + root.inW - root.wingW; y: root.pLeft; control1X: root.inX + root.inW; control1Y: root.pLeft - root.wingW * 0.5; control2X: root.inX + root.inW - root.wingW * 0.5; control2Y: root.pLeft }
                        
                        PathLine { x: root.rightBarPopL + root.radius; y: root.pLeft } 
                        PathArc { x: root.rightBarPopL; y: root.pLeft + root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise } 
                        
                        PathLine { x: root.rightBarPopL; y: root.inY + root.inH - root.wingW } 
                        PathCubic { x: root.rightBarPopL - root.wingW; y: root.inY + root.inH; control1X: root.rightBarPopL; control1Y: root.inY + root.inH - root.wingW * 0.5; control2X: root.rightBarPopL - root.wingW * 0.5; control2Y: root.inY + root.inH } 
                        
                        PathLine { x: root.inX + root.inW; y: root.inY + root.inH } 
                    }
                }

                Shape {
                    anchors.fill: parent; visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.pLeft - root.wingW }
                        PathCubic { x: root.inX + root.inW - root.wingW; y: root.pLeft; control1X: root.inX + root.inW - root.halfB; control1Y: root.pLeft - root.wingW * 0.5; control2X: root.inX + root.inW - root.wingW * 0.5; control2Y: root.pLeft }
                        PathLine { x: root.rightBarPopL + root.radius; y: root.pLeft }
                        PathArc { x: root.rightBarPopL; y: root.pLeft + root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.rightBarPopL; y: root.pRight - root.radius }
                        PathArc { x: root.rightBarPopL + root.radius; y: root.pRight; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.inX + root.inW - root.wingW; y: root.pRight }
                        PathCubic { x: root.inX + root.inW - root.halfB; y: root.pRight + root.wingW; control1X: root.inX + root.inW - root.wingW * 0.5; control1Y: root.pRight; control2X: root.inX + root.inW - root.halfB; control2Y: root.pRight + root.wingW * 0.5 }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        
                        PathLine { x: root.rightBarPopL - root.wingW; y: root.inY + root.halfB }
                        PathCubic { x: root.rightBarPopL; y: root.inY + root.halfB + root.wingW; control1X: root.rightBarPopL - root.wingW * 0.5; control1Y: root.inY + root.halfB; control2X: root.rightBarPopL; control2Y: root.inY + root.halfB + root.wingW * 0.5 }
                        
                        PathLine { x: root.rightBarPopL; y: root.pRight - root.radius }
                        PathArc { x: root.rightBarPopL + root.radius; y: root.pRight; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        
                        PathLine { x: root.inX + root.inW - root.wingW; y: root.pRight }
                        PathCubic { x: root.inX + root.inW - root.halfB; y: root.pRight + root.wingW; control1X: root.inX + root.inW - root.wingW * 0.5; control1Y: root.pRight; control2X: root.inX + root.inW - root.halfB; control2Y: root.pRight + root.wingW * 0.5 }
                        
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.pLeft - root.wingW } 
                        PathCubic { x: root.inX + root.inW - root.halfB - root.wingW; y: root.pLeft; control1X: root.inX + root.inW - root.halfB; control1Y: root.pLeft - root.wingW * 0.5; control2X: root.inX + root.inW - root.halfB - root.wingW * 0.5; control2Y: root.pLeft }
                        
                        PathLine { x: root.rightBarPopL + root.radius; y: root.pLeft } 
                        PathArc { x: root.rightBarPopL; y: root.pLeft + root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise } 
                        
                        PathLine { x: root.rightBarPopL; y: root.inY + root.inH - root.halfB - root.wingW } 
                        PathCubic { x: root.rightBarPopL - root.wingW; y: root.inY + root.inH - root.halfB; control1X: root.rightBarPopL; control1Y: root.inY + root.inH - root.halfB - root.wingW * 0.5; control2X: root.rightBarPopL - root.wingW * 0.5; control2Y: root.inY + root.inH } 
                        
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB } 
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi } 
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
            }

            Item {
                id: sfOpenGroupTop
                anchors.fill: parent
                visible: root.barPosition === "top" && root.isScreenFrame && (root.progress > 0 || root.isPeeking)

                Rectangle { x: 0; y: 0; width: mainContainer.width; height: root.inY; color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY + root.inH; width: mainContainer.width; height: mainContainer.height - (root.inY + root.inH); color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY; width: root.inX; height: root.inH; color: Config.bgPanel }
                Rectangle { x: root.inX + root.inW; y: root.inY; width: mainContainer.width - (root.inX + root.inW); height: root.inH; color: Config.bgPanel }

                Loader { anchors.fill: parent; sourceComponent: screenFrameCorners }

                Shape {
                    anchors.fill: parent; visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.pLeft - root.wingW; startY: root.inY
                        PathLine { x: root.pRight + root.wingW; y: root.inY }
                        PathCubic { x: root.pRight; y: root.inY + root.wingW; control1X: root.pRight + root.wingW * 0.5; control1Y: root.inY; control2X: root.pRight; control2Y: root.inY + root.wingW * 0.5 }
                        PathLine { x: root.pRight; y: root.topBarPopB - root.radius }
                        PathArc { x: root.pRight - root.radius; y: root.topBarPopB; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise }
                        PathLine { x: root.pLeft + root.radius; y: root.topBarPopB }
                        PathArc { x: root.pLeft; y: root.topBarPopB - root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise }
                        PathLine { x: root.pLeft; y: root.inY + root.wingW }
                        PathCubic { x: root.pLeft - root.wingW; y: root.inY; control1X: root.pLeft; control1Y: root.inY + root.wingW * 0.5; control2X: root.pLeft - root.wingW * 0.5; control2Y: root.inY }
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.inX; startY: root.inY
                        
                        PathLine { x: root.pRight + root.wingW; y: root.inY } 
                        PathCubic { x: root.pRight; y: root.inY + root.wingW; control1X: root.pRight + root.wingW * 0.5; control1Y: root.inY; control2X: root.pRight; control2Y: root.inY + root.wingW * 0.5 }
                        
                        PathLine { x: root.pRight; y: root.topBarPopB - root.radius } 
                        PathArc { x: root.pRight - root.radius; y: root.topBarPopB; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise } 
                        
                        PathLine { x: root.inX + root.wingW; y: root.topBarPopB } 
                        PathCubic { x: root.inX; y: root.topBarPopB + root.wingW; control1X: root.inX + root.wingW * 0.5; control1Y: root.topBarPopB; control2X: root.inX; control2Y: root.topBarPopB + root.wingW * 0.5 } 
                        
                        PathLine { x: root.inX; y: root.inY } 
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.pLeft - root.wingW; startY: root.inY
                        
                        PathLine { x: root.inX + root.inW; y: root.inY } 
                        
                        PathLine { x: root.inX + root.inW; y: root.topBarPopB + root.wingW } 
                        PathCubic { x: root.inX + root.inW - root.wingW; y: root.topBarPopB; control1X: root.inX + root.inW; control1Y: root.topBarPopB + root.wingW * 0.5; control2X: root.inX + root.inW - root.wingW * 0.5; control2Y: root.topBarPopB }
                        
                        PathLine { x: root.pLeft + root.radius; y: root.topBarPopB } 
                        PathArc { x: root.pLeft; y: root.topBarPopB - root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise } 
                        
                        PathLine { x: root.pLeft; y: root.inY + root.wingW } 
                        PathCubic { x: root.pLeft - root.wingW; y: root.inY; control1X: root.pLeft; control1Y: root.inY + root.wingW * 0.5; control2X: root.pLeft - root.wingW * 0.5; control2Y: root.inY } 
                    }
                }

                Shape {
                    anchors.fill: parent; visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inW - root.inRadi; startY: root.inY + root.halfB
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.pLeft - root.wingW; y: root.inY + root.halfB }
                        PathCubic { x: root.pLeft; y: root.inY + root.halfB + root.wingW; control1X: root.pLeft - root.wingW * 0.5; control1Y: root.inY + root.halfB; control2X: root.pLeft; control2Y: root.inY + root.halfB + root.wingW * 0.5 }
                        PathLine { x: root.pLeft; y: root.topBarPopB - root.radius }
                        PathArc { x: root.pLeft + root.radius; y: root.topBarPopB; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.pRight - root.radius; y: root.topBarPopB }
                        PathArc { x: root.pRight; y: root.topBarPopB - root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.pRight; y: root.inY + root.halfB + root.wingW }
                        PathCubic { x: root.pRight + root.wingW; y: root.inY + root.halfB; control1X: root.pRight; control1Y: root.inY + root.halfB + root.wingW * 0.5; control2X: root.pRight + root.wingW * 0.5; control2Y: root.inY + root.halfB }
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inW - root.inRadi; startY: root.inY + root.halfB
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.halfB; y: root.topBarPopB + root.wingW }
                        PathCubic { x: root.inX + root.halfB + root.wingW; y: root.topBarPopB; control1X: root.inX + root.halfB; control1Y: root.topBarPopB + root.wingW * 0.5; control2X: root.inX + root.halfB + root.wingW * 0.5; control2Y: root.topBarPopB }
                        
                        PathLine { x: root.pRight - root.radius; y: root.topBarPopB } 
                        PathArc { x: root.pRight; y: root.topBarPopB - root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        
                        PathLine { x: root.pRight; y: root.inY + root.halfB + root.wingW } 
                        PathCubic { x: root.pRight + root.wingW; y: root.inY + root.halfB; control1X: root.pRight; control1Y: root.inY + root.halfB + root.wingW * 0.5; control2X: root.pRight + root.wingW * 0.5; control2Y: root.inY + root.halfB } 
                        
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB } 
                    }
                }
                Shape {
                    anchors.fill: parent; visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        
                        PathLine { x: root.pLeft - root.wingW; y: root.inY + root.halfB } 
                        PathCubic { x: root.pLeft; y: root.inY + root.halfB + root.wingW; control1X: root.pLeft - root.wingW * 0.5; control1Y: root.inY + root.halfB; control2X: root.pLeft; control2Y: root.inY + root.halfB + root.wingW * 0.5 }
                        
                        PathLine { x: root.pLeft; y: root.topBarPopB - root.radius } 
                        PathArc { x: root.pLeft + root.radius; y: root.topBarPopB; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        
                        PathLine { x: root.inX + root.inW - root.halfB - root.wingW; y: root.topBarPopB }
                        PathCubic { x: root.inX + root.inW - root.halfB; y: root.topBarPopB + root.wingW; control1X: root.inX + root.inW - root.halfB - root.wingW * 0.5; control1Y: root.topBarPopB; control2X: root.inX + root.inW - root.halfB; control2Y: root.topBarPopB + root.wingW * 0.5 }
                        
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
            }

            Item {
                id: sfOpenGroupBottom
                anchors.fill: parent
                visible: root.barPosition === "bottom" && root.isScreenFrame && (root.progress > 0 || root.isPeeking)

                Rectangle { x: 0; y: 0; width: mainContainer.width; height: root.inY; color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY + root.inH; width: mainContainer.width; height: mainContainer.height - (root.inY + root.inH); color: Config.bgPanel }
                Rectangle { x: 0; y: root.inY; width: root.inX; height: root.inH; color: Config.bgPanel }
                Rectangle { x: root.inX + root.inW; y: root.inY; width: mainContainer.width - (root.inX + root.inW); height: root.inH; color: Config.bgPanel }

                Loader { anchors.fill: parent; sourceComponent: screenFrameCorners }

                Shape {
                    anchors.fill: parent; visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.pLeft - root.wingW; startY: root.inY + root.inH
                        PathLine { x: root.pRight + root.wingW; y: root.inY + root.inH }
                        PathCubic { x: root.pRight; y: root.inY + root.inH - root.wingW; control1X: root.pRight + root.wingW * 0.5; control1Y: root.inY + root.inH; control2X: root.pRight; control2Y: root.inY + root.inH - root.wingW * 0.5 }
                        PathLine { x: root.pRight; y: root.bottomBarPopT + root.radius }
                        PathArc { x: root.pRight - root.radius; y: root.bottomBarPopT; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
                        PathLine { x: root.pLeft + root.radius; y: root.bottomBarPopT }
                        PathArc { x: root.pLeft; y: root.bottomBarPopT + root.radius; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise }
                        PathLine { x: root.pLeft; y: root.inY + root.inH - root.wingW }
                        PathCubic { x: root.pLeft - root.wingW; y: root.inY + root.inH; control1X: root.pLeft; control1Y: root.inY + root.inH - root.wingW * 0.5; control2X: root.pLeft - root.wingW * 0.5; control2Y: root.inY + root.inH }
                    }
                }

                Shape {
                    anchors.fill: parent; visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.inX; startY: root.inY + root.inH
                        
                        PathLine { x: root.pRight + root.wingW; y: root.inY + root.inH } 
                        PathCubic { x: root.pRight; y: root.inY + root.inH - root.wingW; control1X: root.pRight + root.wingW * 0.5; control1Y: root.inY + root.inH; control2X: root.pRight; control2Y: root.inY + root.inH - root.wingW * 0.5 }
                        
                        PathLine { x: root.pRight; y: root.bottomBarPopT + root.radius } 
                        PathArc { x: root.pRight - root.radius; y: root.bottomBarPopT; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Counterclockwise } 
                        
                        PathLine { x: root.inX + root.wingW; y: root.bottomBarPopT } 
                        PathCubic { x: root.inX; y: root.bottomBarPopT - root.wingW; control1X: root.inX + root.wingW * 0.5; control1Y: root.bottomBarPopT; control2X: root.inX; control2Y: root.bottomBarPopT - root.wingW * 0.5 }
                        
                        PathLine { x: root.inX; y: root.inY + root.inH } 
                    }
                }

                Shape {
                    anchors.fill: parent; visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: Config.bgPanel; strokeWidth: 0
                        startX: root.inX + root.inW; startY: root.inY + root.inH
                        
                        PathLine { x: root.pLeft - root.wingW; y: root.inY + root.inH } 
                        PathCubic { x: root.pLeft; y: root.inY + root.inH - root.wingW; control1X: root.pLeft; control1Y: root.inY + root.inH - root.wingW * 0.5; control2X: root.pLeft - root.wingW * 0.5; control2Y: root.inY + root.inH }
                        
                        PathLine { x: root.pLeft; y: root.bottomBarPopT + root.radius } 
                        PathArc { x: root.pLeft + root.radius; y: root.bottomBarPopT; radiusX: root.radius; radiusY: root.radius; direction: PathArc.Clockwise } 
                        
                        PathLine { x: root.inX + root.inW - root.wingW; y: root.bottomBarPopT } 
                        PathCubic { x: root.inX + root.inW; y: root.bottomBarPopT - root.wingW; control1X: root.inX + root.inW - root.wingW * 0.5; control1Y: root.bottomBarPopT; control2X: root.inX + root.inW; control2Y: root.bottomBarPopT - root.wingW * 0.5 }
                        
                        PathLine { x: root.inX + root.inW; y: root.inY + root.inH } 
                    }
                }

                Shape {
                    anchors.fill: parent; visible: !root.isLeftFlush && !root.isRightFlush && !(peekActive && root.isPeekLeftFlush) && !(peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.pRight + root.wingW; y: root.inY + root.inH - root.halfB }
                        PathCubic { x: root.pRight; y: root.inY + root.inH - root.halfB - root.wingW; control1X: root.pRight + root.wingW * 0.5; control1Y: root.inY + root.inH - root.halfB; control2X: root.pRight; control2Y: root.inY + root.inH - root.halfB - root.wingW * 0.5 }
                        PathLine { x: root.pRight; y: root.bottomBarPopT + root.radius }
                        PathArc { x: root.pRight - root.radius; y: root.bottomBarPopT; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.pLeft + root.radius; y: root.bottomBarPopT }
                        PathArc { x: root.pLeft; y: root.bottomBarPopT + root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        PathLine { x: root.pLeft; y: root.inY + root.inH - root.halfB - root.wingW }
                        PathCubic { x: root.pLeft - root.wingW; y: root.inY + root.inH - root.halfB; control1X: root.pLeft; control1Y: root.inY + root.inH - root.halfB - root.wingW * 0.5; control2X: root.pLeft - root.wingW * 0.5; control2Y: root.inY + root.inH }
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB }
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi }
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }

                Shape {
                    anchors.fill: parent; visible: root.isLeftFlush || (peekActive && root.isPeekLeftFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.inY + root.inH - root.inRadi }
                        PathArc { x: root.inX + root.inW - root.inRadi; y: root.inY + root.inH - root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.pRight + root.wingW; y: root.inY + root.inH - root.halfB } 
                        PathCubic { x: root.pRight; y: root.inY + root.inH - root.halfB - root.wingW; control1X: root.pRight + root.wingW * 0.5; control1Y: root.inY + root.inH - root.halfB; control2X: root.pRight; control2Y: root.inY + root.inH - root.halfB - root.wingW * 0.5 }
                        
                        PathLine { x: root.pRight; y: root.bottomBarPopT + root.radius } 
                        PathArc { x: root.pRight - root.radius; y: root.bottomBarPopT; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise }
                        
                        PathLine { x: root.inX + root.halfB + root.wingW; y: root.bottomBarPopT }
                        PathCubic { x: root.inX + root.halfB; y: root.bottomBarPopT - root.wingH; control1X: root.inX + root.halfB + root.wingW * 0.5; control1Y: root.bottomBarPopT; control2X: root.inX + root.halfB; control2Y: root.bottomBarPopT - root.wingH * 0.5 }
                        
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi } 
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }

                Shape {
                    anchors.fill: parent; visible: root.isRightFlush || (peekActive && root.isPeekRightFlush)
                    ShapePath {
                        fillColor: "transparent"; strokeWidth: root.borderWidth; strokeColor: shellRoot.currentBorderColor; joinStyle: ShapePath.RoundJoin; capStyle: ShapePath.RoundCap
                        startX: root.inX + root.inRadi; startY: root.inY + root.halfB
                        
                        PathLine { x: root.inX + root.inW - root.inRadi; y: root.inY + root.halfB }
                        PathArc { x: root.inX + root.inW - root.halfB; y: root.inY + root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        
                        PathLine { x: root.inX + root.inW - root.halfB; y: root.bottomBarPopT - root.wingW } 
                        PathCubic { x: root.inX + root.inW - root.halfB - root.wingW; y: root.bottomBarPopT; control1X: root.inX + root.inW - root.halfB; control1Y: root.bottomBarPopT - root.wingW * 0.5; control2X: root.inX + root.inW - root.halfB - root.wingW * 0.5; control2Y: root.bottomBarPopT }
                        
                        PathLine { x: root.pLeft + root.radius; y: root.bottomBarPopT } 
                        PathArc { x: root.pLeft; y: root.bottomBarPopT + root.radius; radiusX: Math.max(0.1, root.radius); radiusY: Math.max(0.1, root.radius); direction: PathArc.Counterclockwise } 
                        
                        PathLine { x: root.pLeft; y: root.inY + root.inH - root.halfB - root.wingW } 
                        PathCubic { x: root.pLeft - root.wingW; y: root.inY + root.inH - root.halfB; control1X: root.pLeft; control1Y: root.inY + root.inH - root.halfB - root.wingW * 0.5; control2X: root.pLeft - root.wingW * 0.5; control2Y: root.inY + root.inH } 
                        
                        PathLine { x: root.inX + root.inRadi; y: root.inY + root.inH - root.halfB } 
                        PathArc { x: root.inX + root.halfB; y: root.inY + root.inH - root.inRadi; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                        PathLine { x: root.inX + root.halfB; y: root.inY + root.inRadi } 
                        PathArc { x: root.inX + root.inRadi; y: root.inY + root.halfB; radiusX: root.inRadi; radiusY: root.inRadi; direction: PathArc.Clockwise }
                    }
                }
            }

            Item {
                id: barContent
                x: (root.isIsland 
                    ? (root.isHorizontal ? root.islandX : (root.isRight ? (mainContainer.width - root.barH + Math.floor(root.halfB)) : Math.floor(root.halfB)))
                    : (root.isRight ? (mainContainer.width - root.barH + Math.floor(root.halfB)) : Math.floor(root.halfB)))
                    + (root.isScreenFrame ? (root.barPosition === "left" ? root.framePadding / 2 : (root.barPosition === "right" ? -root.framePadding / 2 : 0)) : 0)
                    + root.autoHideXOffset

                y: (root.isIsland
                    ? (root.isHorizontal ? (root.isBottom ? (mainContainer.height - root.barH + Math.floor(root.halfB)) : Math.floor(root.halfB)) : root.islandY)
                    : (root.isBottom ? (mainContainer.height - root.barH + Math.floor(root.halfB)) : Math.floor(root.halfB)))
                    + (root.isScreenFrame ? (root.barPosition === "top" ? root.framePadding / 2 : (root.barPosition === "bottom" ? -root.framePadding / 2 : 0)) : 0)
                    + root.autoHideYOffset

                width: root.isHorizontal ? (root.isIsland ? root.animatedIslandWidth : (mainContainer.width - Math.ceil(root.borderWidth))) : (root.barH - Math.ceil(root.borderWidth))
                height: root.isHorizontal ? (root.barH - Math.ceil(root.borderWidth)) : (root.isIsland ? root.animatedIslandHeight : (mainContainer.height - Math.ceil(root.borderWidth)))

                opacity: 1.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                LeftModules {
                    id: leftCard
                    rootRef: root
                    onPopoutRequested: item => root.setPopoutPos(item)
                }
                ActiveWindowCard {
                    id: activeWindowCard
                    rootRef: root
                    onPopoutRequested: item => root.setPopoutPos(item)

                    // Factor in the 30px outer shell margins for both cards
                    readonly property real leftBound: leftCard ? (root.isHorizontal ? (leftCard.width + 30) : (leftCard.height + 30)) : 30
                    readonly property real rightBound: rightCard ? (root.isHorizontal ? (parent.width - rightCard.width - 30) : (parent.height - rightCard.height - 30)) : (root.isHorizontal ? parent.width : parent.height)
                    readonly property real barSpan: root.isHorizontal ? parent.width : parent.height

                    // Real available gap bounded cleanly between the padded card edges
                    readonly property real availableGap: Math.max(36, rightBound - leftBound - 24)

                    // Dynamically scale down width if space gets tight instead of overlapping
                    maxAvailableSpan: Math.max(36, Math.min(190, availableGap))

                    // Clamp position strictly between left and right bounds
                    x: root.isHorizontal
                        ? Math.max(leftBound + 12, Math.min(rightBound - activeWindowCard.width - 12, (barSpan - activeWindowCard.width) / 2))
                        : ((parent.width - activeWindowCard.width) / 2)

                    y: root.isHorizontal
                        ? ((parent.height - activeWindowCard.height) / 2)
                        : Math.max(leftBound + 12, Math.min(rightBound - activeWindowCard.height - 12, (barSpan - activeWindowCard.height) / 2))
                }
                RightModules {
                    id: rightCard
                    rootRef: root
                    onPopoutRequested: item => root.setPopoutPos(item)
                }

                HoverHandler {
                    id: barContentHover
                    onHoveredChanged: {
                        if (hovered) {
                            autoHideTimer.stop()
                            root.isBarHovered = true
                            root.isBarRevealedByUser = true
                        } else {
                            root.isBarHovered = false
                            if (Config.autoHideBar && !root.isOpen) {
                                autoHideTimer.restart()
                            }
                        }
                    }
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
                visible: root.progress > 0.01
                opacity: (root.isOpen && root.progress >= 0.95) ? 1.0 : 0.0
                focus: true

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

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

                TaskOverflow {
                    id: taskOverflowModule
                    objectName: "internalTaskOverflow"
                    anchors.fill: parent
                    activeScreenName: screen ? screen.name : ""
                    visible: root.activeView === "taskOverflow"
                }
            }
        }
    }
}
