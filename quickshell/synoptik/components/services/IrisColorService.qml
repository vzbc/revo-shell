import QtQuick
import Quickshell
import Quickshell.Io
import ".."

QtObject {
    id: irisService

    property var configRef: null

    property Process irisRunner: Process {
        id: runner
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let text = this.text ? this.text.trim() : ""
                    if (text.length > 0 && configRef) {
                        let match = text.match(/\{[\s\S]*\}/)
                        if (match) {
                            let jsonStr = match[0]

                            if (jsonStr.includes('"bg"') || jsonStr.includes('"surface"') || jsonStr.includes('"accent"')) {
                                let parsed = JSON.parse(jsonStr)

                                let baseCol = parsed.bg || "#12131a"
                                let panelCol = parsed.surface || "#1e202b"
                                let accentCol = parsed.accent || "#94a3b8"

                                configRef.customBgBase = baseCol
                                configRef.customBgPanel = panelCol
                                configRef.customAccent = accentCol

                                configRef.bgBase = Qt.rgba(Qt.color(baseCol).r, Qt.color(baseCol).g, Qt.color(baseCol).b, configRef.shellOpacity)
                                configRef.bgPanel = Qt.rgba(Qt.color(panelCol).r, Qt.color(panelCol).g, Qt.color(panelCol).b, configRef.shellOpacity)
                                configRef.accent = accentCol

                                configRef.syncHyprlandBorders()
                            }
                        }
                    }
                } catch (e) {
                    console.error("Failed to parse Iris JSON colors:", e)
                }
            }
        }
    }

    function applyIrisColors(filePath) {
        if (!configRef || !configRef.enableIris) return

        let rawPath = filePath || configRef.activeWallpaperPath

        if (!rawPath && configRef.wallpapers && configRef.wallpapers.length > 0) {
            rawPath = configRef.wallpapers[0]
        }

        if (!rawPath || rawPath === "") return

        let cleanPath = rawPath.replace(/^file:\/\//, "")
        let ext = cleanPath.split('.').pop().toLowerCase()
        let targetPath = cleanPath

        if (ext === "mp4" || ext === "webm") {
            let fileName = cleanPath.split('/').pop()
            let thumbName = fileName.replace(/[^a-zA-Z0-9]/g, "_") + ".png"
            targetPath = Quickshell.env("HOME") + "/.cache/wallpaper-thumbs/" + thumbName
        }

        let cmd = "if not test -f '" + targetPath + "'; ffmpeg -y -ss 00:00:00 -i '" + cleanPath + "' -vframes 1 -vf 'scale=600:-1' '" + targetPath + "' >/dev/null 2>&1; end; "
        cmd += "if test -f '" + targetPath + "'; iris --json-only '" + targetPath + "' 2>/dev/null; end"

        runner.command = ["fish", "-c", cmd]
        runner.running = false
        runner.running = true
    }
}
