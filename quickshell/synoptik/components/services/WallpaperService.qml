import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

QtObject {
    id: wallpaperService

    property var configRef: null
    property var onlineResults: []
    property bool isFetchingOnline: false

    property int thumbEpoch: 0

    // Ensure daemon starts silently at shell initialization
    property Process daemonStarter: Process {
        id: daemonStarterProc
        running: true
        command: [
            "fish", "-c",
            "if not pgrep -x 'awww-daemon' > /dev/null; " +
            "    set -l wayland_disp (test -n \"$WAYLAND_DISPLAY\"; and echo \"$WAYLAND_DISPLAY\"; or echo \"wayland-1\"); " +
            "    rm -f /run/user/(id -u)/$wayland_disp-awww-daemon.sock; " +
            "    nohup awww-daemon >/dev/null 2>&1 & disown; " +
            "end"
        ]
    }

    property Process slideshowRunner: Process {
        id: bgSlideshowProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let path = this.text ? this.text.trim() : ""
                if (path.length > 0) {
                    wallpaperService.applyWallpaperBackend(path, false)
                }
            }
        }
    }

    property Timer bgSlideshowTimer: Timer {
        id: bgTimer
        interval: Math.max(1, (configRef ? configRef.slideshowMinutes : 5)) * 60000
        running: (configRef ? (configRef.isLoaded && configRef.slideshowActive) : false)
        repeat: true
        onTriggered: wallpaperService.triggerRandomWallpaperBackground()
    }

    function triggerRandomWallpaperBackground() {
        bgSlideshowProc.command = [
            "fish", "-c",
            "set -l files ~/Pictures/Wallpapers/*.{jpg,jpeg,png,webp,mp4,webm}; " +
            "if test (count $files) -gt 0; " +
            "    random choice $files; " +
            "end"
        ]
        bgSlideshowProc.running = false
        bgSlideshowProc.running = true
    }

    property Process wallpaperApplyRunner: Process {
        id: wpApplyProc
        running: false
        property string pendingIrisPath: ""
        property string pendingWpPath: ""
        property var pendingTargets: []

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && configRef) {
                if (pendingTargets.length > 0) {
                    let updatedMap = Object.assign({}, configRef.activeMonitorWallpapers)
                    for (let i = 0; i < pendingTargets.length; i++) {
                        updatedMap[pendingTargets[i]] = pendingWpPath
                    }
                    configRef.activeMonitorWallpapers = updatedMap
                } else {
                    configRef.activeWallpaperPath = pendingWpPath
                    configRef.activeMonitorWallpapers = ({})
                }

                if (configRef.enableIris && pendingIrisPath !== "") {
                    configRef.applyIrisColors(pendingIrisPath)
                    pendingIrisPath = ""
                }
                configRef.refreshActiveWallpapers()
            }
        }
    }

    function applyWallpaperBackend(filePath, activeOnly) {
        if (!filePath || !configRef) return

        let cleanFilePath = (typeof filePath === "string" ? filePath : filePath.toString()).replace(/^file:\/\//, "")
        let ext = cleanFilePath.split('.').pop().toLowerCase()
        let isVid = (ext === "mp4" || ext === "webm")
        let transition = (configRef.wallpaperTransitionType && configRef.wallpaperTransitionType !== "") ? configRef.wallpaperTransitionType : "fade"

        // Determine targets:
        // 1. activeOnly (Ctrl+Click in Wallpaper.qml) -> Focused Monitor
        // 2. selectedWallpaperMonitors (Target Displays toggle) -> Selected list
        // 3. Otherwise empty -> All monitors
        let targets = []
        if (activeOnly) {
            let focusedMon = (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) ? Hyprland.focusedMonitor.name : ""
            if (focusedMon !== "") {
                targets = [focusedMon]
            }
        } else if (configRef.selectedWallpaperMonitors && configRef.selectedWallpaperMonitors.length > 0) {
            targets = configRef.selectedWallpaperMonitors.slice()
        }

        wpApplyProc.pendingWpPath = cleanFilePath
        wpApplyProc.pendingTargets = targets

        let script = ""

        if (isVid) {
            script += "killall -q -9 awww-daemon awww mpvpaper 2>/dev/null; "
            if (targets.length > 0) {
                for (let i = 0; i < targets.length; i++) {
                    script += "nohup mpvpaper -vs -o 'input-terminal=no loop-file=inf no-audio panscan=1.0 video-unscaled=no' '" + targets[i] + "' '" + cleanFilePath + "' < /dev/null >/dev/null 2>&1 & disown; "
                }
            } else {
                script += "nohup mpvpaper -vs -o 'input-terminal=no loop-file=inf no-audio panscan=1.0 video-unscaled=no' '*' '" + cleanFilePath + "' < /dev/null >/dev/null 2>&1 & disown; "
            }
        } else {
            script += "if pgrep -x 'mpvpaper' > /dev/null; killall -q mpvpaper; end; "
            script += "if not pgrep -x 'awww-daemon' > /dev/null; nohup awww-daemon >/dev/null 2>&1 & disown; sleep 0.1; end; "

            let transArgs = "--transition-type " + transition + " --transition-step 30 --transition-fps 60"

            if (targets.length > 0) {
                for (let i = 0; i < targets.length; i++) {
                    script += "awww img -o \"" + targets[i] + "\" '" + cleanFilePath + "' " + transArgs + "; "
                }
            } else {
                script += "awww img '" + cleanFilePath + "' " + transArgs + "; "
            }
        }

        if (configRef.enableIris) {
            if (isVid) {
                let fileName = cleanFilePath.split('/').pop()
                let baseName = fileName.replace(/\.[^/.]+$/, "")
                let thumbPath = Quickshell.env("HOME") + "/.cache/wallpaper-thumbs/" + baseName + ".jpg"
                wpApplyProc.pendingIrisPath = thumbPath
                script += "nohup fish -c 'test -f \"" + thumbPath + "\"; or ffmpeg -y -ss 00:00:01 -i \"" + cleanFilePath + "\" -vframes 1 -vf scale=600:-1 \"" + thumbPath + "\" >/dev/null 2>&1; iris \"" + thumbPath + "\"' >/dev/null 2>&1 & disown; "
            } else {
                wpApplyProc.pendingIrisPath = cleanFilePath
                script += "nohup iris '" + cleanFilePath + "' >/dev/null 2>&1 & disown; "
            }
        }

        if (wpApplyProc.running) {
            wpApplyProc.running = false
        }

        wpApplyProc.command = ["fish", "-c", script]
        wpApplyProc.running = true
    }

    function toggleWallpaperMonitor(screenName) {
        if (!configRef) return
        let current = configRef.selectedWallpaperMonitors ? configRef.selectedWallpaperMonitors.slice() : []
        let idx = current.indexOf(screenName)
        if (idx >= 0) {
            current.splice(idx, 1)
        } else {
            current.push(screenName)
        }
        configRef.selectedWallpaperMonitors = current
        configRef.saveSettings()
    }
}