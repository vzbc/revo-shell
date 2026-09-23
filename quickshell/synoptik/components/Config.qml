pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import "settings"
import "services"

QtObject {
    id: root

    // --- WALLHAVEN INTEGRATION ---
    property string wallhavenUsername: ""
    property string wallhavenApiKey: ""

    onWallhavenUsernameChanged: { if (isLoaded) saveSettings() }
    onWallhavenApiKeyChanged: { if (isLoaded) saveSettings() }

    // --- RETRO SCREEN SHADER STATE & PERSISTENCE ---
    property bool pixelShaderEnabled: false
    property string pixelShaderMode: "pixelate"
    property real pixelShaderSize: 2.0
    property real pixelShaderLevels: 32.0
    property string pixelShaderPalette: "default"
    property bool pixelShaderDither: true
    property bool pixelShaderGrid: false
    property bool pixelShaderBoost: true

    onPixelShaderEnabledChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderModeChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderSizeChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderLevelsChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderPaletteChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderDitherChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderGridChanged: { if (isLoaded) { saveSettings(); updateShader() } }
    onPixelShaderBoostChanged: { if (isLoaded) { saveSettings(); updateShader() } }

    // --- EXTRACTED BACKGROUND SERVICES ---
    property WallpaperService wallpaperService: WallpaperService { configRef: root }
    property QuoteService quoteService: QuoteService { configRef: root }
    property IrisColorService irisService: IrisColorService { configRef: root }
    property ShaderService shaderService: ShaderService { configRef: root }

    // --- RETRO SHADER IPC HANDLER ---
    property IpcHandler shaderIpc: IpcHandler {
        target: "shader"

        function toggle() {
            root.pixelShaderEnabled = !root.pixelShaderEnabled
            root.updateShader()
        }
    }

    // Debounce timer for shader updates
    property Timer shaderDebounce: Timer {
        interval: 200
        repeat: false
        onTriggered: shaderService.updateShader()
    }

    function updateShader() {
        if (!isLoaded) return
        saveSettings()
        shaderDebounce.restart()
    }

    property bool showTaskOverflow: false

    // --- CAMERA / MIRROR (LAZY LOADED) ---
    property bool showMirror: false
    property bool mirrorShowPanel: true
    property bool mirrorMirrored: true
    property bool mirrorKeepAspect: true
    property bool mirrorExpanded: false
    property bool mirrorPinned: false
    property string mirrorAnchorPos: "center"
    property bool mirrorLoading: false
    property string mirrorError: ""

    // Lazy load the QtMultimedia backend only when mirror is visible
    property Loader mirrorLoader: Loader {
        id: mirrorLoader
        active: root.showMirror

        sourceComponent: Component {
            QtObject {
                id: mirrorBackend

                property MediaDevices mediaDevices: MediaDevices {}

                property CaptureSession captureSession: CaptureSession {
                    id: globalMirrorCaptureSession
                    camera: Camera {
                        id: globalMirrorCamera
                        cameraDevice: mirrorBackend.mediaDevices.defaultVideoInput
                        active: true

                        onActiveChanged: {
                            if (active) {
                                root.mirrorLoading = false
                                root.mirrorError = ""
                            }
                        }

                        function applyRawFormat() {
                            if (!cameraDevice) {
                                root.mirrorLoading = false
                                root.mirrorError = "No camera device found"
                                return
                            }
                            let formats = cameraDevice.videoFormats
                            if (formats && formats.length > 0) {
                                let bestFormat = undefined
                                let bestScore = -1
                                for (let i = 0; i < formats.length; ++i) {
                                    let f = formats[i]
                                    let fpsTarget = Math.min(f.maxFrameRate, 30)
                                    let width = f.resolution.width
                                    let widthScore = width <= 1280 ? width : (1280 - (width - 1280)) 
                                    let score = (fpsTarget * 10000) + widthScore
                                    if (score > bestScore) {
                                        bestScore = score
                                        bestFormat = f
                                    }
                                }
                                if (bestFormat) cameraFormat = bestFormat
                            }
                        }

                        Component.onCompleted: applyRawFormat()
                    }
                }

                property Connections deviceWatcher: Connections {
                    target: mirrorBackend.mediaDevices
                    function onDefaultVideoInputChanged() {
                        if (mirrorBackend.mediaDevices.defaultVideoInput) {
                            root.mirrorError = ""
                            mirrorBackend.captureSession.camera.applyRawFormat()
                        } else {
                            root.mirrorLoading = false
                            root.mirrorError = "No camera device found"
                        }
                    }
                }
            }
        }

        onActiveChanged: {
            if (active) {
                root.mirrorLoading = true
                root.mirrorError = ""
            } else {
                root.mirrorLoading = false
                root.mirrorError = ""
            }
        }
    }

    // Accessors for external consumers
    readonly property CaptureSession mirrorCaptureSession: mirrorLoader.item ? mirrorLoader.item.captureSession : null
    readonly property MediaDevices mirrorMediaDevices: mirrorLoader.item ? mirrorLoader.item.mediaDevices : null

    function cycleMirrorAnchor(direction) {
        if (direction === "up" || direction === "left" || direction === "prev") {
            if (mirrorAnchorPos === "bottom") mirrorAnchorPos = "center"
            else if (mirrorAnchorPos === "center") mirrorAnchorPos = "top"
            else mirrorAnchorPos = "bottom"
        } else if (direction === "down" || direction === "right" || direction === "next") {
            if (mirrorAnchorPos === "top") mirrorAnchorPos = "center"
            else if (mirrorAnchorPos === "center") mirrorAnchorPos = "bottom"
            else mirrorAnchorPos = "top"
        }
    }

    onShowMirrorChanged: { if (isLoaded) saveSettings() }
    onMirrorShowPanelChanged: { if (isLoaded) saveSettings() }
    onMirrorMirroredChanged: { if (isLoaded) saveSettings() }
    onMirrorKeepAspectChanged: { if (isLoaded) saveSettings() }
    onMirrorExpandedChanged: { if (isLoaded) saveSettings() }
    onMirrorPinnedChanged: { if (isLoaded) saveSettings() }
    onMirrorAnchorPosChanged: { if (isLoaded) saveSettings() }

    // --- INITIALIZATION GUARD ---
    property bool isLoaded: false

    // UI Toggle States
    property bool showSettings: false
    property bool showCalendar: false
    property bool showWallpaper: false
    property bool showAppLauncher: false
    property bool showNetwork: false
    property bool showAudio: false
    property bool showBluetooth: false
    property bool showWifi: false
    property bool showOSD: false
    property bool showWorkspacePreview: false
    property bool showNotificationOsd: false
    property bool showControlCenter: false
    property bool showBattery: false
    property bool showPower: false
    property bool showClipboard: false
    property bool showScreenRecorder: false

    // --- NAVIGATION PERSISTENCE ---
    property int lastSettingsSection: 0
    onLastSettingsSectionChanged: { if (isLoaded) saveSettings() }

    // --- SHELL KEYBIND CUSTOMIZATION (SUPER EXCLUSIVE) ---
    readonly property var defaultKeybinds: ({
        "wallpaper":         { mod: "SUPER",         key: "B",     cmd: "qs -c Synoptik ipc call wallpaper toggle" },
        "launcher":          { mod: "SUPER",         key: "A",     cmd: "qs -c Synoptik ipc call launcher toggle" },
        "settings":          { mod: "SUPER",         key: "Space", cmd: "qs -c Synoptik ipc call settings toggle" },
        "workspaceoverview": { mod: "SUPER",         key: "TAB",   cmd: "qs -c Synoptik ipc call workspaceoverview toggle" },
        "clipboard":         { mod: "SUPER + SHIFT", key: "V",     cmd: "qs -c Synoptik ipc call clipboard toggle" },
        "lockscreen":        { mod: "SUPER",         key: "L",     cmd: "qs -c Synoptik ipc call lockscreen toggle" },
        "shader":            { mod: "CTRL + ALT",    key: "P",     cmd: "qs -c Synoptik ipc call shader toggle" }
    })

    property var keybinds: Object.assign({}, defaultKeybinds)

    function updateKeybind(action, mod, key) {
        let current = Object.assign({}, keybinds)
        let defaultCmd = defaultKeybinds[action] ? defaultKeybinds[action].cmd : ""
        let existingCmd = current[action] ? current[action].cmd : defaultCmd

        current[action] = { 
            mod: mod, 
            key: key, 
            cmd: existingCmd 
        }
        
        keybinds = current
        syncHyprlandBorders()
        saveSettings()
    }

    function resetKeybinds() {
        keybinds = Object.assign({}, defaultKeybinds)
        syncHyprlandBorders()
        saveSettings()
    }

    // --- SYSTEM SOUNDS CONFIGURATION ---
    property bool playWindowSounds: true
    property bool playNotificationSounds: true
    property string windowSoundPath: "sound1.wav"
    property string notificationSoundPath: "sound1.wav"
    property real windowSoundVolume: 0.25

    onPlayWindowSoundsChanged: { if (isLoaded) saveSettings() }
    onPlayNotificationSoundsChanged: { if (isLoaded) saveSettings() }
    onWindowSoundPathChanged: { if (isLoaded) saveSettings() }
    onNotificationSoundPathChanged: { if (isLoaded) saveSettings() }
    onWindowSoundVolumeChanged: { if (isLoaded) saveSettings() }

    // --- LOCKSCREEN CONFIGURATION ---
    property bool sessionLocked: false
    property real lockscreenBlurRadius: 36
    property bool lockscreenShowMedia: true
    property bool lockscreenShowPower: true
    property string lockscreenMaskStyle: "shapes"
    property string lockscreenShapePalette: "vibrant"
    property bool lockscreenUse12Hour: true
    property bool lockscreenShowSeconds: false
    property bool lockscreenShowAmPm: true
    property string lockscreenDateFormat: "long"
    property int lockscreenClockSize: 150
    property string lockscreenTargetMonitor: "focused"

    onLockscreenBlurRadiusChanged: { if (isLoaded) saveSettings() }
    onLockscreenShowMediaChanged: { if (isLoaded) saveSettings() }
    onLockscreenShowPowerChanged: { if (isLoaded) saveSettings() }
    onLockscreenMaskStyleChanged: { if (isLoaded) saveSettings() }
    onLockscreenShapePaletteChanged: { if (isLoaded) saveSettings() }
    onLockscreenUse12HourChanged: { if (isLoaded) saveSettings() }
    onLockscreenShowSecondsChanged: { if (isLoaded) saveSettings() }
    onLockscreenShowAmPmChanged: { if (isLoaded) saveSettings() }
    onLockscreenDateFormatChanged: { if (isLoaded) saveSettings() }
    onLockscreenClockSizeChanged: { if (isLoaded) saveSettings() }
    onLockscreenTargetMonitorChanged: { if (isLoaded) saveSettings() }

    // --- WORKSPACES CONFIGURATION ---
    property string workspaceStyle: "pill"
    property bool workspaceGlow: true
    property bool workspaceScroll: true
    property bool workspaceTooltips: true
    property bool workspaceShowAddBtn: true
    property bool workspaceShowOverviewBtn: true
    property bool workspaceShowSpecial: true
    property string workspaceContainerStyle: "plain"

    onWorkspaceStyleChanged: { if (isLoaded) saveSettings() }
    onWorkspaceGlowChanged: { if (isLoaded) saveSettings() }
    onWorkspaceScrollChanged: { if (isLoaded) saveSettings() }
    onWorkspaceTooltipsChanged: { if (isLoaded) saveSettings() }
    onWorkspaceShowAddBtnChanged: { if (isLoaded) saveSettings() }
    onWorkspaceShowOverviewBtnChanged: { if (isLoaded) saveSettings() }
    onWorkspaceShowSpecialChanged: { if (isLoaded) saveSettings() }
    onWorkspaceContainerStyleChanged: { if (isLoaded) saveSettings() }

    // --- CAFFEINE STATE & TIMER ---
    property bool caffeineHasHypridle: false
    property int caffeineState: 0
    property double caffeineTimerEndTime: 0
    property string caffeineRemainingTimeString: ""

    property Process caffeineCheckBinaryProc: Process {
        id: caffeineCheckBinaryProc
        command: ["fish", "-c", "which hypridle"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.caffeineHasHypridle = this.text.trim().length > 0
                if (root.caffeineHasHypridle) root.caffeineCheckStatusProc.running = true
            }
        }
    }

    property Process caffeineCheckStatusProc: Process {
        id: caffeineCheckStatusProc
        command: ["fish", "-c", "pgrep -x hypridle"]
        running: false
        stdout: StdioCollector { id: caffeineStatusOutput }

        onExited: (exitCode, exitStatus) => {
            let isRunning = (exitCode === 0 && caffeineStatusOutput.text.trim().length > 0)
            if (!isRunning) {
                if (root.caffeineState === 0) root.caffeineState = 1
            } else {
                if (root.caffeineState !== 0) {
                    root.caffeineState = 0
                    root.caffeineTimerEndTime = 0
                }
            }
        }
    }

    property Process caffeineExecProc: Process {
        id: caffeineExecProc
        running: false
        onExited: root.caffeineCheckStatusProc.running = true
    }

    // Only polls when hypridle is present and caffeine override is active
    property Timer caffeinePoller: Timer {
        interval: 5000
        running: root.caffeineHasHypridle && root.caffeineState !== 0
        repeat: true
        onTriggered: {
            if (!root.caffeineExecProc.running && !root.caffeineCheckStatusProc.running) {
                root.caffeineCheckStatusProc.running = true
            }
        }
    }

    property Timer caffeineCountdownTicker: Timer {
        id: caffeineCountdownTicker
        interval: 1000
        repeat: true
        running: root.caffeineState === 2
        onTriggered: root.updateCaffeineCountdown()
    }

    function updateCaffeineCountdown() {
        if (root.caffeineState !== 2) return
        let now = Date.now()
        let diffMs = root.caffeineTimerEndTime - now

        if (diffMs <= 0) {
            root.caffeineState = 0
            root.caffeineTimerEndTime = 0
            setHypridleRunning(true)
            return
        }

        let totalSeconds = Math.round(diffMs / 1000)
        let mins = Math.floor(totalSeconds / 60)
        let secs = totalSeconds % 60
        root.caffeineRemainingTimeString = `${mins}:${secs < 10 ? '0' : ''}${secs}`
    }

    function setHypridleRunning(enable) {
        let cmd = enable
            ? "systemctl --user start hypridle.service"
            : "pkill -x hypridle; and systemctl --user stop hypridle.service; and systemctl --user reset-failed hypridle.service"

        caffeineExecProc.command = ["fish", "-c", cmd]
        caffeineExecProc.running = true
    }

    function addCaffeineMinutes(minutes) {
        if (caffeineState !== 2) return
        let msToAdd = minutes * 60 * 1000
        let now = Date.now()
        let baseTime = Math.max(now, caffeineTimerEndTime)
        let newEndTime = baseTime + msToAdd

        if (newEndTime <= now) {
            caffeineState = 0
            caffeineTimerEndTime = 0
            setHypridleRunning(true)
        } else {
            caffeineTimerEndTime = newEndTime
            updateCaffeineCountdown()
        }
    }

    function cycleCaffeine() {
        if (!caffeineHasHypridle) return
        let nextState = (caffeineState + 1) % 3

        if (nextState === 1) {
            caffeineTimerEndTime = 0
            setHypridleRunning(false)
        } else if (nextState === 2) {
            let roundedNow = Math.floor(Date.now() / 1000) * 1000
            caffeineTimerEndTime = roundedNow + 900000
            updateCaffeineCountdown()
            setHypridleRunning(false)
        } else {
            caffeineTimerEndTime = 0
            setHypridleRunning(true)
        }

        caffeineState = nextState
    }

    function startCaffeineTimer(minutes) {
        if (!caffeineHasHypridle) return
        if (minutes <= 0) {
            caffeineState = 0
            caffeineTimerEndTime = 0
            setHypridleRunning(true)
            return
        }
        let roundedNow = Math.floor(Date.now() / 1000) * 1000
        caffeineTimerEndTime = roundedNow + (minutes * 60 * 1000)
        caffeineState = 2
        updateCaffeineCountdown()
        setHypridleRunning(false)
    }

    function setIndefiniteCaffeine() {
        if (!caffeineHasHypridle) return
        caffeineState = 1
        caffeineTimerEndTime = 0
        setHypridleRunning(false)
    }

    // --- ICON MAP & OVERRIDES ---
    property var iconOverrides: ({})

    readonly property var defaultIcons: ({
        "power": "electrical_services",
        "recorder": "videocam",
        "mirror": "photo_camera",
        "screenshot": "crop",
        "wallpaper": "wall_art",
        "settings": "build",
        "launcher": "terminal_2",
        "audio": "ear_sound",
        "sys": "neurology",
        "batt": "battery_android_frame_full",
        "cc": "widgets",
        "network": "lan",
        "notifications": "inbox",
        "clipboard": "content_paste",
        "clock": "calendar_month",
        "overview": "select_window_2",
        "apps": "view_apps",
        "magic": "kid_star",
        "magic_active": "family_star",
        "music": "music_note",
        "music_active": "genres",
        "private": "lock",
        "private_active": "lock_open"
    })

    function getIcon(iconId) {
        if (iconOverrides && iconOverrides[iconId]) {
            return iconOverrides[iconId]
        }
        return defaultIcons[iconId] || "help_outline"
    }

    function setIconOverride(iconId, glyphName) {
        let current = Object.assign({}, iconOverrides)
        current[iconId] = glyphName
        iconOverrides = current
        saveSettings()
    }

    function resetIcons() {
        iconOverrides = {}
        saveSettings()
    }

    // --- ICON GROUPS COLLAPSE & PINNING STATE ---
    property bool leftCardCollapsed: false
    property bool rightCardCollapsed: false
    property var pinnedIcons: ({})

    function togglePin(iconId) {
        let temp = Object.assign({}, pinnedIcons)
        temp[iconId] = !temp[iconId]
        pinnedIcons = temp
        saveSettings()
    }

    function isPinned(iconId) {
        return !!pinnedIcons[iconId]
    }

    onLeftCardCollapsedChanged: { if (isLoaded) saveSettings() }
    onRightCardCollapsedChanged: { if (isLoaded) saveSettings() }

    // --- DYNAMIC MODULE ORDERING ---
    property var leftCardOrder: ["power", "settings", "wallpaper", "launcher", "recorder", "mirror", "audio", "batt", "network", "clipboard", "screenshot"]
    property var rightCardOrder: ["clock", "cc"]

    function moveModule(cardKey, iconId, direction) {
        let list = (cardKey === "left" ? leftCardOrder : rightCardOrder).slice()
        let idx = list.indexOf(iconId)
        if (idx === -1) return

        let targetIdx = idx + direction
        if (targetIdx < 0 || targetIdx >= list.length) return

        let item = list.splice(idx, 1)[0]
        list.splice(targetIdx, 0, item)

        if (cardKey === "left") leftCardOrder = list
        else rightCardOrder = list

        saveSettings()
    }

    // --- UNIFIED SURFACE GEOMETRY ---
    property real surfaceRadius: 18.0
    property int borderThickness: 3
    property real cardMargin: 12.0

    readonly property bool showBorders: borderThickness > 0

    onSurfaceRadiusChanged: { 
        if (isLoaded) {
            syncHyprlandBorders()
            saveSettings()
        }
    }

    onBorderThicknessChanged: {
        if (isLoaded) {
            syncHyprlandBorders()
            saveSettings()
        }
    }
    onCardMarginChanged: { if (isLoaded) saveSettings() }

    readonly property real cornerRadius: surfaceRadius
    readonly property real surfaceWingSize: surfaceRadius

    // --- DESKTOP CLOCK STATE & PERSISTENCE ---
    property bool showDesktopClock: true
    property string clockStyle: "digital"
    property real clockScale: 1.0
    property bool clockShowSeconds: false
    property bool clockUse12Hour: true
    property bool clockShowAmPm: true
    property bool clockShowBorder: true
    property bool clockShowBackground: true
    property bool clockShowGlow: true

    property var clockPositions: ({})
    property var clockScales: ({})
    property var enabledClockScreens: []

    function getClockPosition(screenName, defaultX, defaultY) {
        if (clockPositions && clockPositions[screenName]) {
            return clockPositions[screenName]
        }
        return { x: defaultX, y: defaultY }
    }

    function saveClockPosition(screenName, x, y) {
        let current = Object.assign({}, clockPositions)
        current[screenName] = { x: x, y: y }
        clockPositions = current
        saveSettings()
    }

    function getClockScale(screenName) {
        if (clockScales && clockScales[screenName] !== undefined) {
            return clockScales[screenName]
        }
        return 1.0
    }

    function saveClockScale(screenName, scale) {
        let current = Object.assign({}, clockScales)
        current[screenName] = scale
        clockScales = current
        saveSettings()
    }

    function isClockEnabledForScreen(screenName) {
        if (!enabledClockScreens || enabledClockScreens.length === 0) return true
        return enabledClockScreens.includes(screenName)
    }

    function toggleClockScreen(screenName) {
        let current = (enabledClockScreens || []).slice()
        let idx = current.indexOf(screenName)
        if (idx !== -1) {
            current.splice(idx, 1)
        } else {
            current.push(screenName)
        }
        enabledClockScreens = current
        saveSettings()
    }

    onShowDesktopClockChanged: { if (isLoaded) saveSettings() }
    onClockStyleChanged: { if (isLoaded) saveSettings() }
    onClockScaleChanged: { if (isLoaded) saveSettings() }
    onClockShowSecondsChanged: { if (isLoaded) saveSettings() }
    onClockUse12HourChanged: { if (isLoaded) saveSettings() }
    onClockShowAmPmChanged: { if (isLoaded) saveSettings() }
    onClockShowBorderChanged: { if (isLoaded) saveSettings() }
    onClockShowBackgroundChanged: { if (isLoaded) saveSettings() }
    onClockShowGlowChanged: { if (isLoaded) saveSettings() }

    // --- DESKTOP SYSTEM INFO STATE & PERSISTENCE ---
    property bool showDesktopSysInfo: true
    property real sysInfoScale: 1.0

    // OS & System
    property bool sysInfoShowHost: true
    property bool sysInfoShowOs: true
    property bool sysInfoShowKernel: true
    property bool sysInfoShowUptime: true
    property bool sysInfoShowPackages: true
    property bool sysInfoShowWm: true

    // Hardware
    property bool sysInfoShowBoard: true
    property bool sysInfoShowCpu: true
    property bool sysInfoShowCores: true
    property bool sysInfoShowLoad: true
    property bool sysInfoShowGpu: true

    // Network
    property bool sysInfoShowIp: true
    property bool sysInfoShowGateway: true
    property bool sysInfoShowDns: true

    // Gauges & Styling
    property bool sysInfoShowRam: true
    property bool sysInfoShowSwap: true
    property bool sysInfoShowDisk: true
    property bool sysInfoShowDiskHome: true
    property bool sysInfoShowBg: true
    property bool sysInfoShowGlow: true
    property int sysInfoRefreshInterval: 3000

    property var sysInfoPositions: ({})
    property var sysInfoScales: ({})
    property var enabledSysInfoScreens: []

    function getSysInfoPosition(screenName, defaultX, defaultY) {
        if (sysInfoPositions && sysInfoPositions[screenName]) {
            return sysInfoPositions[screenName]
        }
        return { x: defaultX, y: defaultY }
    }

    function saveSysInfoPosition(screenName, x, y) {
        let current = Object.assign({}, sysInfoPositions)
        current[screenName] = { x: x, y: y }
        sysInfoPositions = current
        saveSettings()
    }

    function getSysInfoScale(screenName) {
        if (sysInfoScales && sysInfoScales[screenName] !== undefined) {
            return sysInfoScales[screenName]
        }
        return 1.0
    }

    function saveSysInfoScale(screenName, scale) {
        let current = Object.assign({}, sysInfoScales)
        current[screenName] = scale
        sysInfoScales = current
        saveSettings()
    }

    function isSysInfoEnabledForScreen(screenName) {
        if (!enabledSysInfoScreens || enabledSysInfoScreens.length === 0) return true
        return enabledSysInfoScreens.includes(screenName)
    }

    function toggleSysInfoScreen(screenName) {
        let current = (enabledSysInfoScreens || []).slice()
        let idx = current.indexOf(screenName)
        if (idx !== -1) {
            current.splice(idx, 1)
        } else {
            current.push(screenName)
        }
        enabledSysInfoScreens = current
        saveSettings()
    }

    onShowDesktopSysInfoChanged: { if (isLoaded) saveSettings() }
    onSysInfoScaleChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowHostChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowOsChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowKernelChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowUptimeChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowPackagesChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowWmChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowBoardChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowCpuChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowCoresChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowLoadChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowGpuChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowIpChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowGatewayChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowDnsChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowRamChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowSwapChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowDiskChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowDiskHomeChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowBgChanged: { if (isLoaded) saveSettings() }
    onSysInfoShowGlowChanged: { if (isLoaded) saveSettings() }
    onSysInfoRefreshIntervalChanged: { if (isLoaded) saveSettings() }

    // --- WALLPAPER CONFIG STATE & PERSISTENCE ---
    property var selectedWallpaperMonitors: []
    property string wallpaperTransitionType: "wipe"
    property string activeWallpaperPath: ""
    property var activeMonitorWallpapers: ({})
    property bool enableWallpaperParallax: true
    property bool wallpaperWorkspaceParallax: true
    property bool wallpaperCursorParallax: true
    property real wallpaperParallaxIntensity: 1.0

    onEnableWallpaperParallaxChanged: saveSettings()
    onWallpaperWorkspaceParallaxChanged: saveSettings()
    onWallpaperCursorParallaxChanged: saveSettings()
    onWallpaperParallaxIntensityChanged: saveSettings()

    function getMonitorWallpaper(screenName) {
        if (activeMonitorWallpapers && activeMonitorWallpapers[screenName]) {
            return activeMonitorWallpapers[screenName]
        }
        return activeWallpaperPath
    }

    property Process wallpaperQuerier: Process {
        id: wpQuerier
        command: [
            "python3", "-c",
            "import subprocess, json, re; out=subprocess.getoutput('awww query 2>/dev/null || swww query 2>/dev/null'); res={}; [res.update({m.group(1).strip(): m.group(2).strip()}) for m in re.finditer(r':\\s*([^:]+):.*currently displaying:\\s*(?:image|video):\\s*(.*)', out)]; print(json.dumps(res))"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text)
                    if (parsed && typeof parsed === "object") {
                        root.activeMonitorWallpapers = parsed
                        let keys = Object.keys(parsed)
                        if (keys.length > 0 && parsed[keys[0]]) {
                            root.activeWallpaperPath = parsed[keys[0]]
                        }
                    }
                } catch (e) {}
            }
        }
    }

    function refreshActiveWallpapers() {
        wpQuerier.running = false
        wpQuerier.running = true
    }

    // --- BACKGROUND SLIDESHOW TIMER & RUNNER ---
    property bool slideshowActive: false
    property int slideshowMinutes: 5

    onSlideshowActiveChanged: { if (isLoaded) saveSettings() }
    onSlideshowMinutesChanged: { if (isLoaded) saveSettings() }

    property alias slideshowRunner: root.wallpaperService.slideshowRunner
    property alias bgSlideshowTimer: root.wallpaperService.bgSlideshowTimer
    property alias wallpaperApplyRunner: root.wallpaperService.wallpaperApplyRunner

    function triggerRandomWallpaperBackground() {
        wallpaperService.triggerRandomWallpaperBackground()
    }

    function applyWallpaperBackend(filePath, activeOnly) {
        wallpaperService.applyWallpaperBackend(filePath, activeOnly)
        refreshActiveWallpapers()
    }

    function toggleWallpaperMonitor(screenName) {
        wallpaperService.toggleWallpaperMonitor(screenName)
    }

    // --- GLOBAL WEATHER SERVICE ---
    property WeatherService weather: WeatherService {
        id: globalWeather
        zipcode: root.locationQuery
    }

    // Only poll weather if loaded and a valid location query exists
    property Timer weatherTimer: Timer {
        interval: 900000
        running: root.isLoaded && root.locationQuery.trim().length > 0
        repeat: true
        onTriggered: root.weather.fetchWeather(true)
    }

    onSelectedWallpaperMonitorsChanged: { if (isLoaded) saveSettings() }
    onWallpaperTransitionTypeChanged: { if (isLoaded) saveSettings() }

    // --- ON-SCREEN KEYBOARD (OSK) STATE & PERSISTENCE ---
    property bool showOsk: false
    property string oskLayout: "Normal"

    property string barFrameStyle: "floating"
    property bool animateGradient: true
    property bool showScreenFrame: false
    property real shellOpacity: 1.0
    property bool enableBlur: true
    property bool enableXray: true
    property bool enableIris: false
    property bool showWatermarks: true
    property bool bounceWatermarks: true

    onShowWatermarksChanged: saveSettings()
    onBounceWatermarksChanged: saveSettings()

    onEnableIrisChanged: {
        if (!isLoaded) return
        if (enableIris) {
            applyIrisColors()
        } else {
            applyTheme(currentThemeIndex)
        }
        saveSettings()
    }

    onActiveWallpaperPathChanged: {
        if (isLoaded && enableIris && activeWallpaperPath !== "") {
            applyIrisColors(activeWallpaperPath)
        }
    }

    function applyIrisColors(filePath) {
        irisService.applyIrisColors(filePath)
    }

    property bool enableHoverPeek: true
    onEnableHoverPeekChanged: { if (isLoaded) saveSettings() }

    readonly property bool isFloatingBar: barFrameStyle === "floating"

    // --- DESKTOP SCREENSAVER STATE & PERSISTENCE ---
    property bool showScreensaver: false
    property string screensaverText: "SYNOPTIK"
    property string screensaverMode: "text"
    property int screensaverFontSize: 54
    property real screensaverSpeed: 3.5
    property bool screensaverCornerCounter: true

    // --- DESKTOP MASCOT STATE & PERSISTENCE ---
    property bool showMascot: false
    property string mascotPath: ""
    property var mascotPhrases: [
        "I use Arch btw", 
        "Hyprland is so comfy", 
        "Need some coffee?", 
        "Compiling...", 
        "Look at me go!"
    ]

    property bool fetchOnlineQuotes: false
    property string quoteSource: "zenquotes"

    function addMascotPhrase(phrase) {
        if (!phrase) return
        var list = mascotPhrases ? mascotPhrases.slice() : []
        list.push(phrase)
        mascotPhrases = list
        saveSettings()
    }

    function removeMascotPhrase(index) {
        if (!mascotPhrases || index < 0 || index >= mascotPhrases.length) return
        var list = mascotPhrases.slice()
        list.splice(index, 1)
        mascotPhrases = list
        saveSettings()
    }

    property string rssFeedUrl: ""
    property alias quoteFetchQueue: root.quoteService.quoteFetchQueue
    property alias quoteFetcher: root.quoteService.quoteFetcher
    property alias quoteFetchTimer: root.quoteService.quoteFetchTimer

    function processQuoteQueue() {
        quoteService.processQuoteQueue()
    }

    function triggerQuoteFetch() {
        quoteService.triggerQuoteFetch()
    }

    // --- BAR POSITION CONTROL ---
    property string barPosition: "top"
    property bool autoHideBar: false

    onAutoHideBarChanged: {
        if (isLoaded) {
            syncHyprlandBorders()
            saveSettings()
        }
    }

    function syncScreenFrame() {
        if (isLoaded) {
            syncHyprlandBorders()
        }
    }

    onBarFrameStyleChanged: { 
        if (isLoaded) {
            syncHyprlandBorders()
            saveSettings()
        }
    }

    onShowScreenFrameChanged: {
        if (!isLoaded) return
        syncScreenFrame()
        saveSettings()
    }

    onShellOpacityChanged: {
        if (!isLoaded) return
        if (enableIris) {
            applyIrisColors()
        } else {
            applyTheme(currentThemeIndex)
        }
        saveSettings()
    }

    onEnableBlurChanged: {
        if (!isLoaded) return
        syncHyprlandBorders()
        saveSettings()
    }

    onEnableXrayChanged: {
        if (!isLoaded) return
        syncHyprlandBorders()
        saveSettings()
    }

    // Typography
    property string sysFont: ""
    property bool nativeFontRendering: true
    readonly property int textRenderType: nativeFontRendering ? Text.NativeRendering : Text.QtRendering
    property bool fontDropdownOpen: false
    property string fontSearchFilter: ""
    property int fontScaleIndex: 1 

    onNativeFontRenderingChanged: { if (isLoaded) saveSettings() }

    function fontStyle(fontObj) {
        if (!fontObj) return fontObj
        fontObj.hintingPreference = Font.PreferFullHinting
        fontObj.styleName = "Regular"
        return fontObj
    }

    property string locationQuery: ""
    property int currentThemeIndex: 0

    // Custom Colors
    property bool useCustomColors: false
    property string customBgBase: "#12131a"
    property string customBgPanel: "#1e202b"
    property string customAccent: "#94a3b8"

    property color borderStart: accent
    property color borderEnd: Qt.lighter(accent, 1.5)

    property string windowStyle: "rounded"

    onWindowStyleChanged: { if (isLoaded) saveSettings() }
    onShowScreensaverChanged: { if (isLoaded) saveSettings() }
    onScreensaverTextChanged: { if (isLoaded) saveSettings() }
    onScreensaverModeChanged: { if (isLoaded) saveSettings() }
    onScreensaverFontSizeChanged: { if (isLoaded) saveSettings() }
    onScreensaverSpeedChanged: { if (isLoaded) saveSettings() }
    onScreensaverCornerCounterChanged: { if (isLoaded) saveSettings() }
    onShowOskChanged: { if (isLoaded) saveSettings() }
    onOskLayoutChanged: { if (isLoaded) saveSettings() }
    onShowMascotChanged: { if (isLoaded) saveSettings() }
    onMascotPathChanged: { if (isLoaded) saveSettings() }
    onMascotPhrasesChanged: { if (isLoaded) saveSettings() }

    onFetchOnlineQuotesChanged: {
        if (!isLoaded) return
        if (fetchOnlineQuotes) triggerQuoteFetch()
        saveSettings()
    }

    onQuoteSourceChanged: { if (isLoaded) saveSettings() }
    onBarPositionChanged: { if (isLoaded) saveSettings() }
    onSysFontChanged: { if (isLoaded && sysFont !== "") saveSettings() }
    onFontScaleIndexChanged: { if (isLoaded) saveSettings() }
    onLocationQueryChanged: {
        if (root.weather) {
            root.weather.zipcode = root.locationQuery;
            if (root.isLoaded && root.locationQuery.trim().length > 0) {
                root.weather.fetchWeather(true);
                root.saveSettings();
            }
        }
    }

    onAnimateGradientChanged: {
        if (!isLoaded) return
        syncHyprlandBorders()
        saveSettings()
    }

    onCustomBgBaseChanged: {
        if (!isLoaded) return
        if (useCustomColors && !enableIris) applyTheme(currentThemeIndex)
        saveSettings()
    }

    onCustomBgPanelChanged: {
        if (!isLoaded) return
        if (useCustomColors && !enableIris) applyTheme(currentThemeIndex)
        saveSettings()
    }

    onCustomAccentChanged: {
        if (!isLoaded) return
        if (useCustomColors && !enableIris) {
            accent = customAccent
            syncHyprlandBorders()
        }
        saveSettings()
    }

    onUseCustomColorsChanged: {
        if (!isLoaded) return
        if (!enableIris) applyTheme(currentThemeIndex)
        saveSettings()
    }

    // Display Targets
    property var enabledBarScreens: []

    function toggleBarScreen(screenName) {
        let current = (enabledBarScreens.length === 0) 
            ? Quickshell.screens.map(s => s.name) 
            : enabledBarScreens.slice()

        let idx = current.indexOf(screenName)
        if (idx >= 0) {
            if (current.length > 1) current.splice(idx, 1)
        } else {
            current.push(screenName)
        }

        enabledBarScreens = current
        saveSettings()
    }

    function isBarEnabledForScreen(screenName) {
        if (!enabledBarScreens || enabledBarScreens.length === 0) return true
        return enabledBarScreens.includes(screenName)
    }

    // --- MONITOR DETECTOR PROCESS ---
    property var detectedModes: ({})

    property Process monitorDetector: Process {
        id: monDetector
        command: ["fish", "-c", "hyprctl monitors -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    let modesMap = {}
                    data.forEach(m => {
                        if (m.availableModes) {
                            modesMap[m.name] = m.availableModes.map(modeStr => {
                                let parts = modeStr.split("@")
                                let res = parts[0].split("x")
                                let rateStr = parts[1] ? parts[1].replace("Hz", "") : "60.00"
                                return {
                                    text: modeStr,
                                    w: parseInt(res[0]),
                                    h: parseInt(res[1]),
                                    r: parseFloat(rateStr)
                                }
                            })
                        }
                    })
                    root.detectedModes = modesMap
                } catch (e) {
                    console.error("Failed to parse hyprctl monitors output:", e)
                }
            }
        }
        Component.onCompleted: monDetector.running = true
    }

    // --- HYPRLAND SCALE VALIDATION HELPERS ---
    function isScaleValid(width, height, scale) {
        if (scale === "auto" || !scale) return true
        
        let logicalW = width / scale
        let logicalH = height / scale
        
        let isWInt = Math.abs(logicalW - Math.round(logicalW)) < 0.001
        let isHInt = Math.abs(logicalH - Math.round(logicalH)) < 0.001
        
        return isWInt && isHInt
    }

    function getNearestValidScale(width, height, desiredScale) {
        if (desiredScale === "auto" || !desiredScale) return "auto"
        if (isScaleValid(width, height, desiredScale)) return desiredScale
        
        let bestScale = 1.0
        let minDiff = Number.MAX_VALUE
        
        for (let s = 0.5; s <= 3.0; s = Math.round((s + 0.05) * 100) / 100) {
            if (isScaleValid(width, height, s)) {
                let diff = Math.abs(s - desiredScale)
                if (diff < minDiff) {
                    minDiff = diff
                    bestScale = s
                }
            }
        }
        return bestScale
    }

    // --- MONITOR LAYOUT & DRAFT STATE MANAGEMENT ---
    property string selectedScreenConfig: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "DP-1"
    property var monitorConfigs: ({})
    property var draftMonitorConfigs: ({})

    function getMonitorConfig(screenName) {
        let actualScreen = (Quickshell.screens && screenName) ? Quickshell.screens.find(s => s.name === screenName) : null
        let defaultW = actualScreen ? actualScreen.width : 1920
        let defaultH = actualScreen ? actualScreen.height : 1080
        const safeFallback = { width: defaultW, height: defaultH, refreshRate: 60.0, x: 0, y: 0, scale: "auto", transform: 0 }

        if (!screenName) return safeFallback
        
        if (draftMonitorConfigs && draftMonitorConfigs[screenName]) {
            return draftMonitorConfigs[screenName]
        }
        if (monitorConfigs && monitorConfigs[screenName]) {
            return monitorConfigs[screenName]
        }

        return safeFallback
    }

    function normalizeMonitorPositions() {
        let keys = Object.keys(monitorConfigs)
        if (keys.length === 0) return

        let minX = Number.MAX_VALUE
        keys.forEach(k => {
            let cfg = monitorConfigs[k]
            if (cfg && cfg.x < minX) minX = cfg.x
        })

        if (minX !== Number.MAX_VALUE && minX !== 0) {
            let updated = Object.assign({}, monitorConfigs)
            keys.forEach(k => {
                updated[k].x = updated[k].x - minX
            })
            monitorConfigs = updated
        }
    }

    function getOtherMonitorConfig(currentScreenName) {
        let screens = Quickshell.screens
        let otherScreen = screens.find(s => s.name !== currentScreenName)
        if (otherScreen) {
            return getMonitorConfig(otherScreen.name)
        }
        let actualScreen = (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
        let defaultW = actualScreen ? actualScreen.width : 1920
        let defaultH = actualScreen ? actualScreen.height : 1080
        return { width: defaultW, height: defaultH, refreshRate: 60.0, x: 0, y: 0, scale: "auto", transform: 0 }
    }

    function updateDraftMonitorConfig(screenName, newOpts) {
        if (!screenName) return
        let current = Object.assign({}, draftMonitorConfigs)
        let existing = getMonitorConfig(screenName)
        let updated = Object.assign({}, existing, newOpts)

        if (updated.scale && updated.scale !== "auto") {
            updated.scale = getNearestValidScale(updated.width, updated.height, updated.scale)
        }

        current[screenName] = updated
        draftMonitorConfigs = current
    }

    function applyMonitorConfigs() {
        let current = Object.assign({}, monitorConfigs)
        Object.keys(draftMonitorConfigs).forEach(k => {
            current[k] = draftMonitorConfigs[k]
        })
        monitorConfigs = current

        normalizeMonitorPositions()
        saveSettings()

        let monitorLuaBlocks = []
        if (monitorConfigs && Object.keys(monitorConfigs).length > 0) {
            Object.keys(monitorConfigs).forEach(k => {
                let m = monitorConfigs[k]
                if (!m) return
                let safeScale = (m.scale === "auto" || !m.scale) ? "auto" : getNearestValidScale(m.width, m.height, m.scale)
                let scaleVal = (safeScale === "auto") ? '"auto"' : parseFloat(safeScale).toFixed(2)
                let transformLine = (m.transform !== undefined && m.transform !== 0) ? ',\n    transform = ' + m.transform : ''
                
                let luaBlock = 'hl.monitor({\n' +
                    '    output = "' + k + '",\n' +
                    '    mode = "' + m.width + 'x' + m.height + '@' + (m.refreshRate || 60.0) + '",\n' +
                    '    position = "' + m.x + 'x' + m.y + '",\n' +
                    '    scale = ' + scaleVal + transformLine + '\n' +
                    '})'
                monitorLuaBlocks.push(luaBlock)
            })
        }

        let pyScript = "import os, re\n" +
            "path = os.path.expanduser('~/.config/hypr/hypr_style.lua')\n" +
            "content = ''\n" +
            "if os.path.exists(path):\n" +
            "    with open(path, 'r') as f:\n" +
            "        content = f.read()\n" +
            "content = re.sub(r'hl\\.monitor\\(\\{[^}]+\\}\\)\\n*', '', content).strip()\n" +
            "new_monitors = '''" + monitorLuaBlocks.join("\n\n") + "'''\n" +
            "full_content = content + '\\n\\n' + new_monitors + '\\n'\n" +
            "with open(path, 'w') as f:\n" +
            "    f.write(full_content)\n"

        let cmd = "python3 -c \"" + pyScript.replace(/"/g, '\\"') + "\" && hyprctl reload"

        writer.command = ["fish", "-c", cmd]
        writer.running = true
    }

    function resetDraftMonitorConfigs() {
        draftMonitorConfigs = Object.assign({}, monitorConfigs)
    }

    // Hyprland Exporter
    property Process themeWriter: Process { id: writer }
    readonly property string hyprThemePath: Quickshell.env("HOME") + "/.config/hypr/hypr_style.lua"

    function syncHyprlandBorders() {
        if (!isLoaded) return

        function toOpaqueHex(c) {
            let str = Qt.color(c).toString().replace("#", "")
            return str.length === 8 ? str.substring(2) : str
        }

        let hexAccent = toOpaqueHex(root.accent)
        let hexEnd = toOpaqueHex(root.borderEnd)
        let hexInactive = toOpaqueHex(root.bgPanel)

        let colorStart = "rgba(" + hexAccent + "ff)"
        let colorEnd = "rgba(" + hexEnd + "ff)"
        let inactiveStr = "rgba(" + hexInactive + "aa)"

        let activeLua = animateGradient
            ? '{ colors = { "' + colorStart + '", "' + colorEnd + '" }, angle = 45 }'
            : '"' + colorStart + '"'

        let borderSize = root.borderThickness
        let gapsOut = (barFrameStyle === "screen") ? 32 : 20
        let roundingVal = Math.round(surfaceRadius)
        let shaderPath = root.pixelShaderEnabled 
            ? (Quickshell.env("HOME") + "/.config/hypr/shaders/pixelate.frag") 
            : ""

        let bindLines = []
        let bindKeys = ["wallpaper", "launcher", "settings", "workspaceoverview", "clipboard", "lockscreen", "shader"]
        bindKeys.forEach(bk => {
            let b = (root.keybinds && root.keybinds[bk]) ? root.keybinds[bk] : root.defaultKeybinds[bk]
            if (b) {
                let modStr = (b.mod || "SUPER").replace(/mainMod/g, "SUPER").replace(/\.\./g, "").replace(/["']/g, "").trim()
                let keyStr = (b.key || "").trim()
                let combo = modStr.length > 0 ? (modStr + " + " + keyStr) : keyStr
                combo = combo.replace(/\+\s*\+/g, "+").trim()
                bindLines.push('hl.bind("' + combo + '", hl.dsp.exec_cmd("' + b.cmd + '"))')
            }
        })
        let bindsLua = bindLines.join('\n')

        let pyScript = "import os, re\n" +
            "path = os.path.expanduser('~/.config/hypr/hypr_style.lua')\n" +
            "existing_monitors = ''\n" +
            "if os.path.exists(path):\n" +
            "    with open(path, 'r') as f:\n" +
            "        content = f.read()\n" +
            "        mons = re.findall(r'hl\\.monitor\\(\\{[^}]+\\}\\)', content, re.DOTALL)\n" +
            "        if mons:\n" +
            "            existing_monitors = '\\n\\n'.join(mons)\n\n" +
            "new_config = '''hl.config({\n" +
            "    general = {\n" +
            "        gaps_out = " + gapsOut + ",\n" +
            "        border_size = " + borderSize + ",\n" +
            "        col = {\n" +
            "            active_border = " + activeLua + ",\n" +
            "            inactive_border = \"" + inactiveStr + "\"\n" +
            "        }\n" +
            "    },\n" +
            "    decoration = {\n" +
            "        rounding = " + roundingVal + ",\n" +
            "        screen_shader = \"" + shaderPath + "\"\n" +
            "    }\n" +
            "})\n\n" +
            "hl.layer_rule({\n" +
            "    name = \"synoptik-shell\",\n" +
            "    match = { namespace = \"^synoptik-shell.*\" },\n" +
            "    blur = " + (enableBlur ? "true" : "false") + ",\n" +
            "    xray = " + (enableXray ? "true" : "false") + ",\n" +
            "    ignore_alpha = 0.6\n" +
            "})\n\n" +
            bindsLua.replace(/\\/g, '\\\\').replace(/'/g, "\\'") + "\n'''\n\n" +
            "if existing_monitors:\n" +
            "    new_config += '\\n' + existing_monitors + '\\n'\n\n" +
            "with open(path, 'w') as f:\n" +
            "    f.write(new_config)\n"

        let cmd = "python3 -c \"" + pyScript.replace(/"/g, '\\"') + "\" && hyprctl reload"

        writer.command = ["fish", "-c", cmd]
        writer.running = true
    }

    // --- STARTUP WALLPAPER & THUMBNAIL CACHER ---
    property var wallpapers: []
    property var tempPaths: []

    property Process wallpaperScanner: Process {
        id: scanner
        command: [
            "python3", "-c",
            "import os; d=os.path.expanduser('~/Pictures/Wallpapers'); (os.path.isdir(d) and [print(os.path.join(d, f)) for f in os.listdir(d) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.mp4', '.webm'))])"
        ]
        
        stdout: SplitParser {
            onRead: data => {
                var trimmed = data.trim()
                if (trimmed.length > 0) root.tempPaths.push(trimmed)
            }
        }

        onExited: (code, status) => { 
            root.wallpapers = root.tempPaths 
            thumbPreloader.running = true
        }

        Component.onCompleted: {
            root.tempPaths = []
            running = true
        }
    }

    property Process thumbPreloader: Process {
        id: thumbPreloader
        running: false
        command: [
            "fish", "-c",
            "set -l cache_dir $HOME/.cache/wallpaper-thumbs; " +
            "test -d $cache_dir; or mkdir -p $cache_dir; " +
            "for f in ~/Pictures/Wallpapers/*.{png,jpg,jpeg,webp,mp4,webm}; " +
            "    test -f $f; or continue; " +
            "    set -l base_name (string replace -r '\\.[^.]+$' '' (path basename $f)); " +
            "    set -l target \"$cache_dir/$base_name.jpg\"; " +
            "    if not test -f $target; " +
            "        if string match -rq '\\.(mp4|webm)$' $f; " +
            "            nice -n 19 ffmpeg -y -ss 00:00:01 -i $f -vframes 1 -vf 'scale=960:-1:flags=lanczos' -q:v 2 $target >/dev/null 2>&1 &; " +
            "        else; " +
            "            nice -n 19 ffmpeg -y -i $f -vf 'scale=960:-1:flags=lanczos' -q:v 2 $target >/dev/null 2>&1 &; " +
            "        end; " +
            "    end; " +
            "end; " +
            "wait"
        ]
        onExited: {
            if (root.wallpaperService) {
                root.wallpaperService.thumbEpoch++
            }
        }
    }

    function refreshWallpapers() {
        if (!scanner.running) {
            tempPaths = []
            scanner.running = true
        }
    }

    // Persistence
    readonly property string settingsPath: Quickshell.shellDir.toString().replace(/^file:\/\//, "") + "/settings.json"
    property Process saveProcess: Process { id: saver }

    property Timer saveTimer: Timer {
        interval: 400
        repeat: false
        onTriggered: {
            if (saver.running) {
                saveTimer.restart()
                return
            }

            var customPalettes = themes.filter(function(t) { return t.isCustom === true })

            var data = {
                "lastSettingsSection": root.lastSettingsSection,
                "monitorConfigs": root.monitorConfigs,
                "selectedWallpaperMonitors": root.selectedWallpaperMonitors,
                "wallpaperTransitionType": root.wallpaperTransitionType,
                "activeWallpaperPath": root.activeWallpaperPath,
                "enableWallpaperParallax": root.enableWallpaperParallax,
                "wallpaperWorkspaceParallax": root.wallpaperWorkspaceParallax,
                "wallpaperCursorParallax": root.wallpaperCursorParallax,
                "wallpaperParallaxIntensity": root.wallpaperParallaxIntensity,
                "slideshowActive": root.slideshowActive,
                "slideshowMinutes": root.slideshowMinutes,
                "showScreensaver": root.showScreensaver,
                "screensaverText": root.screensaverText,
                "screensaverMode": root.screensaverMode,
                "screensaverFontSize": root.screensaverFontSize,
                "screensaverSpeed": root.screensaverSpeed,
                "screensaverCornerCounter": root.screensaverCornerCounter,
                "showOsk": root.showOsk,
                "oskLayout": root.oskLayout,
                "keybinds": root.keybinds,
                "showMascot": root.showMascot,
                "mascotPath": root.mascotPath,
                "mascotPhrases": root.mascotPhrases,
                "fetchOnlineQuotes": root.fetchOnlineQuotes,
                "quoteSource": root.quoteSource,
                "barFrameStyle": root.barFrameStyle,
                "barPosition": root.barPosition,
                "autoHideBar": root.autoHideBar,
                "showScreenFrame": root.showScreenFrame,
                "sysFont": root.sysFont,
                "nativeFontRendering": root.nativeFontRendering,
                "fontScaleIndex": root.fontScaleIndex,
                "currentThemeIndex": root.currentThemeIndex,
                "locationQuery": root.locationQuery,
                "enabledBarScreens": root.enabledBarScreens,
                "useCustomColors": root.useCustomColors,
                "customBgBase": root.customBgBase.toString(),
                "customBgPanel": root.customBgPanel.toString(),
                "customAccent": root.customAccent.toString(),
                "animateGradient": root.animateGradient,
                "shellOpacity": root.shellOpacity,
                "enableBlur": root.enableBlur,
                "enableXray": root.enableXray,
                "enableIris": root.enableIris,
                "showWatermarks": root.showWatermarks,
                "bounceWatermarks": root.bounceWatermarks,
                "customThemes": customPalettes,
                "windowStyle": root.windowStyle,
                "playWindowSounds": root.playWindowSounds,
                "playNotificationSounds": root.playNotificationSounds,
                "windowSoundPath": root.windowSoundPath,
                "notificationSoundPath": root.notificationSoundPath,
                "windowSoundVolume": root.windowSoundVolume,
                "enableHoverPeek": root.enableHoverPeek,

                "pixelShaderEnabled": root.pixelShaderEnabled,
                "pixelShaderMode": root.pixelShaderMode,
                "pixelShaderSize": root.pixelShaderSize,
                "pixelShaderLevels": root.pixelShaderLevels,
                "pixelShaderPalette": root.pixelShaderPalette,
                "pixelShaderDither": root.pixelShaderDither,
                "pixelShaderGrid": root.pixelShaderGrid,
                "pixelShaderBoost": root.pixelShaderBoost,

                "showMirror": root.showMirror,
                "mirrorShowPanel": root.mirrorShowPanel,
                "mirrorMirrored": root.mirrorMirrored,
                "mirrorKeepAspect": root.mirrorKeepAspect,
                "mirrorExpanded": root.mirrorExpanded,
                "mirrorPinned": root.mirrorPinned,
                "mirrorAnchorPos": root.mirrorAnchorPos,

                "leftCardOrder": root.leftCardOrder,
                "leftCardCollapsed": root.leftCardCollapsed,
                "rightCardCollapsed": root.rightCardCollapsed,
                "pinnedIcons": root.pinnedIcons,
                "iconOverrides": root.iconOverrides,

                "surfaceRadius": root.surfaceRadius,
                "borderThickness": root.borderThickness,
                "cardMargin": root.cardMargin,

                "showDesktopClock": root.showDesktopClock,
                "clockStyle": root.clockStyle,
                "clockScale": root.clockScale,
                "clockShowSeconds": root.clockShowSeconds,
                "clockUse12Hour": root.clockUse12Hour,
                "clockShowAmPm": root.clockShowAmPm,
                "clockShowBorder": root.clockShowBorder,
                "clockShowBackground": root.clockShowBackground,
                "clockShowGlow": root.clockShowGlow,
                "clockPositions": root.clockPositions,
                "clockScales": root.clockScales,
                "enabledClockScreens": root.enabledClockScreens,

                "showDesktopSysInfo": root.showDesktopSysInfo,
                "sysInfoScale": root.sysInfoScale,
                "sysInfoShowHost": root.sysInfoShowHost,
                "sysInfoShowOs": root.sysInfoShowOs,
                "sysInfoShowKernel": root.sysInfoShowKernel,
                "sysInfoShowUptime": root.sysInfoShowUptime,
                "sysInfoShowPackages": root.sysInfoShowPackages,
                "sysInfoShowWm": root.sysInfoShowWm,
                "sysInfoShowBoard": root.sysInfoShowBoard,
                "sysInfoShowCpu": root.sysInfoShowCpu,
                "sysInfoShowCores": root.sysInfoShowCores,
                "sysInfoShowLoad": root.sysInfoShowLoad,
                "sysInfoShowGpu": root.sysInfoShowGpu,
                "sysInfoShowIp": root.sysInfoShowIp,
                "sysInfoShowGateway": root.sysInfoShowGateway,
                "sysInfoShowDns": root.sysInfoShowDns,
                "sysInfoShowRam": root.sysInfoShowRam,
                "sysInfoShowSwap": root.sysInfoShowSwap,
                "sysInfoShowDisk": root.sysInfoShowDisk,
                "sysInfoShowDiskHome": root.sysInfoShowDiskHome,
                "sysInfoShowBg": root.sysInfoShowBg,
                "sysInfoShowGlow": root.sysInfoShowGlow,
                "sysInfoRefreshInterval": root.sysInfoRefreshInterval,
                "sysInfoPositions": root.sysInfoPositions,
                "sysInfoScales": root.sysInfoScales,
                "enabledSysInfoScreens": root.enabledSysInfoScreens,

                "lockscreenBlurRadius": root.lockscreenBlurRadius,
                "lockscreenShowMedia": root.lockscreenShowMedia,
                "lockscreenShowPower": root.lockscreenShowPower,
                "lockscreenMaskStyle": root.lockscreenMaskStyle,
                "lockscreenShapePalette": root.lockscreenShapePalette,
                "lockscreenUse12Hour": root.lockscreenUse12Hour,
                "lockscreenShowSeconds": root.lockscreenShowSeconds,
                "lockscreenShowAmPm": root.lockscreenShowAmPm,
                "lockscreenDateFormat": root.lockscreenDateFormat,
                "lockscreenClockSize": root.lockscreenClockSize,
                "lockscreenTargetMonitor": root.lockscreenTargetMonitor,

                "workspaceStyle": root.workspaceStyle,
                "workspaceGlow": root.workspaceGlow,
                "workspaceScroll": root.workspaceScroll,
                "workspaceTooltips": root.workspaceTooltips,
                "workspaceShowAddBtn": root.workspaceShowAddBtn,
                "workspaceShowOverviewBtn": root.workspaceShowOverviewBtn,
                "workspaceShowSpecial": root.workspaceShowSpecial,
                "workspaceContainerStyle": root.workspaceContainerStyle,

                "wallhavenUsername": root.wallhavenUsername,
                "wallhavenApiKey": root.wallhavenApiKey
            }

            var jsonStr = JSON.stringify(data, null, 2)
            saver.command = ["fish", "-c", "printf '%s' '" + jsonStr.replace(/'/g, "'\\''") + "' > " + settingsPath]
            saver.running = true
        }
    }

    function saveSettings() {
        if (!isLoaded) return
        saveTimer.restart()
    }

    property Process loaderProcess: Process {
        id: loader
        command: ["fish", "-c", "cat " + settingsPath + " 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text ? this.text.trim() : ""
                if (text !== "") {
                    try {
                        var parsed = JSON.parse(text)

                        let props = [
                            "lastSettingsSection",
                            "monitorConfigs", "selectedWallpaperMonitors", "wallpaperTransitionType", "activeWallpaperPath",
                            "enableWallpaperParallax", "wallpaperWorkspaceParallax", "wallpaperCursorParallax", "wallpaperParallaxIntensity",
                            "slideshowActive", "slideshowMinutes",
                            "showScreensaver", "screensaverText", "screensaverMode", "screensaverFontSize", "screensaverSpeed", "screensaverCornerCounter",
                            "showOsk", "oskLayout",
                            "showMascot", "mascotPath", "mascotPhrases", "fetchOnlineQuotes", "quoteSource",
                            "barFrameStyle", "barPosition", "autoHideBar", "showScreenFrame", "sysFont", "nativeFontRendering", "fontScaleIndex", "locationQuery",
                            "enabledBarScreens", "useCustomColors", "customBgBase", "customBgPanel",
                            "customAccent", "animateGradient", "shellOpacity", "enableBlur",
                            "enableXray", "enableIris", "showWatermarks", "bounceWatermarks", "surfaceRadius", "borderThickness", "cardMargin", "showDesktopClock", "clockStyle", "clockScale", 
                            "clockShowSeconds", "clockUse12Hour", "clockShowAmPm", "clockShowBorder", 
                            "clockShowBackground", "clockShowGlow", "clockPositions", "clockScales", "enabledClockScreens",
                            "showDesktopSysInfo", "sysInfoScale",
                            "sysInfoShowHost", "sysInfoShowOs", "sysInfoShowKernel", "sysInfoShowUptime", "sysInfoShowPackages", "sysInfoShowWm",
                            "sysInfoShowBoard", "sysInfoShowCpu", "sysInfoShowCores", "sysInfoShowLoad", "sysInfoShowGpu",
                            "sysInfoShowIp", "sysInfoShowGateway", "sysInfoShowDns",
                            "sysInfoShowRam", "sysInfoShowSwap", "sysInfoShowDisk", "sysInfoShowDiskHome",
                            "sysInfoShowBg", "sysInfoShowGlow", "sysInfoRefreshInterval",
                            "sysInfoPositions", "sysInfoScales", "enabledSysInfoScreens",
                            "lockscreenBlurRadius", "lockscreenShowMedia", "lockscreenShowPower", "lockscreenMaskStyle", "lockscreenShapePalette",
                            "lockscreenUse12Hour", "lockscreenShowSeconds", "lockscreenShowAmPm", "lockscreenDateFormat", "lockscreenClockSize", "lockscreenTargetMonitor",
                            "workspaceStyle", "workspaceGlow", "workspaceScroll", "workspaceTooltips", "workspaceShowAddBtn", "workspaceShowOverviewBtn", "workspaceShowSpecial", "workspaceContainerStyle",
                            "leftCardOrder", "rightCardOrder", "leftCardCollapsed", "rightCardCollapsed", "pinnedIcons", "iconOverrides",
                            "playWindowSounds", "playNotificationSounds", "windowSoundPath", "notificationSoundPath", "windowSoundVolume",
                            "showMirror", "mirrorShowPanel", "mirrorMirrored", "mirrorKeepAspect", "mirrorExpanded", "mirrorPinned", "mirrorAnchorPos",
                            "enableHoverPeek", "wallhavenUsername", "wallhavenApiKey",
                            "pixelShaderEnabled", "pixelShaderMode", "pixelShaderSize", "pixelShaderLevels", 
                            "pixelShaderPalette", "pixelShaderDither", "pixelShaderGrid", "pixelShaderBoost"
                        ]

                        props.forEach(p => {
                            if (parsed[p] !== undefined) root[p] = parsed[p]
                        })

                        if (parsed.keybinds && typeof parsed.keybinds === "object") {
                            let cleaned = {}
                            Object.keys(parsed.keybinds).forEach(k => {
                                let item = parsed.keybinds[k]
                                cleaned[k] = {
                                    mod: (item.mod || "SUPER").replace(/mainMod/g, "SUPER").replace(/\.\./g, "").replace(/["']/g, "").trim(),
                                    key: item.key || "",
                                    cmd: item.cmd || ""
                                }
                            })
                            root.keybinds = cleaned
                        }

                        let defaultLeft = ["power", "recorder", "mirror", "screenshot", "wallpaper", "settings", "launcher", "audio", "batt", "network", "clipboard"]
                        let currentLeft = Array.isArray(root.leftCardOrder) ? root.leftCardOrder.slice() : []
                        defaultLeft.forEach(mod => {
                            if (!currentLeft.includes(mod)) currentLeft.push(mod)
                        })
                        root.leftCardOrder = currentLeft

                        if (parsed.isFloatingBar !== undefined && parsed.barFrameStyle === undefined) {
                            root.barFrameStyle = parsed.isFloatingBar ? "floating" : "edge"
                        }

                        if (parsed.customThemes && Array.isArray(parsed.customThemes)) {
                            var stockList = stockThemes.slice()
                            root.themes = stockList.concat(parsed.customThemes)
                        }

                        if (parsed.currentThemeIndex !== undefined) {
                            root.currentThemeIndex = Math.min(parsed.currentThemeIndex, root.themes.length - 1)
                        }

                        if (root.enableIris) {
                            root.applyIrisColors()
                        } else {
                            root.applyTheme(root.currentThemeIndex)
                        }
                    } catch (e) {
                        console.error("Failed to parse settings JSON:", e)
                    }
                }

                root.normalizeMonitorPositions()
                root.isLoaded = true
                root.resetDraftMonitorConfigs()
                root.syncHyprlandBorders()
                root.syncScreenFrame()

                if (root.pixelShaderEnabled) {
                    root.updateShader()
                }

                if (root.weather && root.locationQuery.trim().length > 0) {
                    root.weather.fetchWeather(true)
                }

                root.refreshActiveWallpapers()
            }
        }
        
        Component.onCompleted: {
            loader.running = true
        }
    }

    // Typography Engine
    function size(preset) { return preset[fontScaleIndex] }

    readonly property var fontMicro:   [8, 11, 14]
    readonly property var fontCaption: [9, 12, 15]
    readonly property var fontBody:    [11, 14, 17]
    readonly property var fontSubhead: [12, 16, 20]
    readonly property var fontTitle:   [16, 21, 26]
    readonly property var fontDisplay: [58, 82, 106]

    // Themes
    property color bgBase: "#12131a"
    property color bgPanel: "#1e202b"
    property color accent: "#94a3b8"
    property color textMain: "#ffffff"
    property color textMuted: "#94a3b8"

    readonly property int barHeight: 54
    readonly property int barMargin: 12

    readonly property var stockThemes: [
        { name: "Monochrome",       bgBase: "#121212", bgPanel: "#1e1e1e", accent: "#e0e0e0" },
        { name: "Classic Red",      bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#ef4444" },
        { name: "Vibrant Orange",   bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#ff7b00" },
        { name: "Amber Yellow",     bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#facc15" },
        { name: "Emerald Green",    bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#10b981" },
        { name: "Cyber Cyan",       bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#06b6d4" },
        { name: "Dodger Blue",      bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#3b82f6" },
        { name: "Deep Purple",      bgBase: "#13141c", bgPanel: "#1a1b26", accent: "#a855f7" },
        { name: "Gruvbox Dark",     bgBase: "#282828", bgPanel: "#3c3836", accent: "#fe8019" },
        { name: "Catppuccin Mocha", bgBase: "#1e1e2e", bgPanel: "#181825", accent: "#f5c2e7" },
        { name: "Nord Slate",       bgBase: "#2e3440", bgPanel: "#3b4252", accent: "#88c0d0" },
        { name: "Tokyo Night",      bgBase: "#1a1b26", bgPanel: "#24283b", accent: "#7aa2f7" },
        { name: "Rosé Pine",        bgBase: "#191724", bgPanel: "#1f1d2e", accent: "#ebbcba" },
        { name: "Everforest",       bgBase: "#2d353b", bgPanel: "#343f44", accent: "#a7c080" },
        { name: "Solarized Dark",   bgBase: "#002b36", bgPanel: "#073642", accent: "#268bd2" },
        { name: "Dracula",          bgBase: "#282a36", bgPanel: "#44475a", accent: "#ff79c6" },
        { name: "Cyberpunk 2077",   bgBase: "#000b1e", bgPanel: "#12002b", accent: "#ff0055" },
        { name: "Catppuccin Latte", bgBase: "#eff1f5", bgPanel: "#e6e9ef", accent: "#8839ef" },
        { name: "Monokai Pro",      bgBase: "#2d2a2e", bgPanel: "#403e41", accent: "#ffd866" },
        { name: "Synthwave '84",    bgBase: "#262335", bgPanel: "#241b2f", accent: "#ff7edb" },
        { name: "Kanagawa",         bgBase: "#1f1f28", bgPanel: "#2a2a37", accent: "#7e9cd8" },
        { name: "Ayu Dark",         bgBase: "#0f1419", bgPanel: "#131721", accent: "#ffb454" },
        { name: "Solarized Light",  bgBase: "#fdf6e3", bgPanel: "#eee8d5", accent: "#b58900" },
        { name: "One Dark",         bgBase: "#282c34", bgPanel: "#21252b", accent: "#61afef" },
        { name: "Neon Red",         bgBase: "#0d0202", bgPanel: "#1a0404", accent: "#ff0055" },
        { name: "Neon Orange",      bgBase: "#0f0800", bgPanel: "#1f1000", accent: "#ff5f00" },
        { name: "Neon Yellow",      bgBase: "#0f0f00", bgPanel: "#1f1f00", accent: "#ccff00" },
        { name: "Neon Lime",        bgBase: "#020f02", bgPanel: "#051f05", accent: "#00ff66" },
        { name: "Neon Cyan",        bgBase: "#000f0f", bgPanel: "#001f1f", accent: "#00f0ff" },
        { name: "Neon Blue",        bgBase: "#00050f", bgPanel: "#000a1f", accent: "#0066ff" },
        { name: "Neon Purple",      bgBase: "#0a000f", bgPanel: "#15001f", accent: "#bf00ff" },
        { name: "Neon Hot Pink",    bgBase: "#0f000a", bgPanel: "#1f0015", accent: "#ff00a0" },
        { name: "Laserwave",        bgBase: "#1b192e", bgPanel: "#272140", accent: "#40e0d0" },
        { name: "Matrix Deep",      bgBase: "#020a02", bgPanel: "#051405", accent: "#00ff41" },
        { name: "Outrun Sunset",    bgBase: "#11001c", bgPanel: "#220038", accent: "#ff2a6d" },
        { name: "Vaporwave Pink",   bgBase: "#1a001a", bgPanel: "#2e002e", accent: "#ff71ce" },
        { name: "Midnight City",    bgBase: "#090a10", bgPanel: "#121420", accent: "#00d2ff" },
        { name: "Toxic Emerald",    bgBase: "#01120a", bgPanel: "#022414", accent: "#00ff87" },
        { name: "Inferno Glow",     bgBase: "#140200", bgPanel: "#260500", accent: "#ff3300" },
        { name: "Ultra Violet",     bgBase: "#0d0614", bgPanel: "#180b26", accent: "#9900ff" }
    ]

    property var themes: stockThemes.slice()

    function addCustomTheme(themeObj) {
        var list = themes.slice()
        list.push(themeObj)
        themes = list
        setTheme(themes.length - 1)
    }

    function removeCustomTheme(index) {
        if (index < 0 || index >= themes.length) return
        if (!themes[index].isCustom) return

        var list = themes.slice()
        list.splice(index, 1)
        themes = list

        if (currentThemeIndex >= themes.length) {
            setTheme(Math.max(0, themes.length - 1))
        } else {
            setTheme(currentThemeIndex)
        }
    }

    function applyTheme(index) {
        if (enableIris) return

        var baseColor = useCustomColors ? customBgBase : (themes[index] || themes[0]).bgBase
        var panelColor = useCustomColors ? customBgPanel : (themes[index] || themes[0]).bgPanel
        var accentColor = useCustomColors ? customAccent : (themes[index] || themes[0]).bgPanel ? (themes[index] || themes[0]).accent : "#94a3b8"

        bgBase = Qt.rgba(Qt.color(baseColor).r, Qt.color(baseColor).g, Qt.color(baseColor).b, shellOpacity)
        bgPanel = Qt.rgba(Qt.color(panelColor).r, Qt.color(panelColor).g, Qt.color(panelColor).b, shellOpacity)
        accent = accentColor

        if (!useCustomColors) {
            var t = themes[index] || themes[0]
            customBgBase = t.bgBase
            customBgPanel = t.bgPanel
            customAccent = t.accent
        }

        syncHyprlandBorders()
    }

    function setTheme(index) {
        if (index < 0 || index >= themes.length) index = 0
        currentThemeIndex = index
        
        var t = themes[index]
        customBgBase = t.bgBase
        customBgPanel = t.bgPanel
        customAccent = t.accent

        applyTheme(index)
        saveSettings()
    }

    Component.onCompleted: {
        if (!enableIris) applyTheme(currentThemeIndex)
    }
}