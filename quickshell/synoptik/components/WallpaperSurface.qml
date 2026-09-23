import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: parallaxScope

    property real globalCursorX: -1
    property real globalCursorY: -1

    Process {
        id: cursorTrackerProc
        running: Config.enableWallpaperParallax && Config.wallpaperCursorParallax
        command: [
            "python3", "-u", "-c",
            "import socket, os, time\n" +
            "sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')\n" +
            "path = f'/run/user/{os.getuid()}/hypr/{sig}/.socket.sock'\n" +
            "while True:\n" +
            "    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)\n" +
            "    try:\n" +
            "        s.connect(path)\n" +
            "        s.sendall(b'cursorpos')\n" +
            "        data = b''\n" +
            "        while True:\n" +
            "            c = s.recv(256)\n" +
            "            if not c: break\n" +
            "            data += c\n" +
            "        print(data.decode('utf-8', errors='ignore').strip(), flush=True)\n" +
            "    except Exception: pass\n" +
            "    finally: s.close()\n" +
            "    time.sleep(0.1)\n"
        ]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(",")
                if (parts.length >= 2) {
                    let cx = parseFloat(parts[0].trim())
                    let cy = parseFloat(parts[1].trim())
                    if (!isNaN(cx) && !isNaN(cy)) {
                        parallaxScope.globalCursorX = cx
                        parallaxScope.globalCursorY = cy
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: wpWindow
            required property var modelData

            screen: modelData

            readonly property string currentWpPath: {
                let monName = modelData ? modelData.name : ""
                let wp = Config.activeWallpaperPath || ""
                if (Config.activeMonitorWallpapers && Config.activeMonitorWallpapers[monName]) {
                    wp = Config.activeMonitorWallpapers[monName]
                }
                return wp.replace(/^file:\/\//, "")
            }

            readonly property bool isVideo: {
                let ext = currentWpPath.split('.').pop().toLowerCase()
                return ext === "mp4" || ext === "webm"
            }

            readonly property string displayWallpaper: {
                if (!currentWpPath || isVideo) return ""
                return currentWpPath.startsWith("file://") ? currentWpPath : ("file://" + currentWpPath)
            }

            visible: Config.enableWallpaperParallax && 
                     (Config.wallpaperWorkspaceParallax || Config.wallpaperCursorParallax) && 
                     !isVideo && 
                     currentWpPath !== ""

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell-wallpaper-parallax"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusiveZone: -1

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            mask: Region {}

            readonly property real intensity: Math.max(0.1, Config.wallpaperParallaxIntensity)
            readonly property real overscanX: (width * 0.16) * intensity
            readonly property real overscanY: (height * 0.10) * intensity

            readonly property int activeWsId: {
                if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace) {
                    return Math.max(1, Hyprland.focusedMonitor.activeWorkspace.id)
                }
                return 1
            }

            readonly property int maxTrackedWorkspaces: 10

            readonly property real wsPanProgress: {
                if (!Config.wallpaperWorkspaceParallax) return 0.5
                let clampedWs = Math.min(maxTrackedWorkspaces, Math.max(1, activeWsId))
                return (clampedWs - 1) / (maxTrackedWorkspaces - 1)
            }

            readonly property real targetWsOffsetX: Config.wallpaperWorkspaceParallax ? (wsPanProgress - 0.5) * -overscanX : 0.0
            property real smoothWsOffsetX: targetWsOffsetX

            Behavior on smoothWsOffsetX {
                NumberAnimation { duration: 450; easing.type: Easing.OutCubic }
            }

            readonly property real cursorNormX: {
                if (parallaxScope.globalCursorX < 0 || !modelData) return 0.5
                let hMon = Hyprland.monitorFor(modelData)
                let monX = hMon ? hMon.x : 0
                let sw = (hMon && hMon.width) ? hMon.width : (modelData.width || 1920)
                return Math.max(0.0, Math.min(1.0, (parallaxScope.globalCursorX - monX) / sw))
            }
            readonly property real cursorNormY: {
                if (parallaxScope.globalCursorY < 0 || !modelData) return 0.5
                let hMon = Hyprland.monitorFor(modelData)
                let monY = hMon ? hMon.y : 0
                let sh = (hMon && hMon.height) ? hMon.height : (modelData.height || 1080)
                return Math.max(0.0, Math.min(1.0, (parallaxScope.globalCursorY - monY) / sh))
            }

            readonly property real targetCursorOffsetX: Config.wallpaperCursorParallax ? (cursorNormX - 0.5) * (-overscanX * 0.35) : 0.0
            readonly property real targetCursorOffsetY: Config.wallpaperCursorParallax ? (cursorNormY - 0.5) * (-overscanY * 0.45) : 0.0

            property real smoothCursorOffsetX: targetCursorOffsetX
            property real smoothCursorOffsetY: targetCursorOffsetY

            Behavior on smoothCursorOffsetX { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }
            Behavior on smoothCursorOffsetY { NumberAnimation { duration: 260; easing.type: Easing.OutQuad } }

            Item {
                id: wallpaperCanvas
                anchors.centerIn: parent

                width: parent.width + (overscanX * 1.5)
                height: parent.height + overscanY

                transform: Translate {
                    x: wpWindow.smoothWsOffsetX + wpWindow.smoothCursorOffsetX
                    y: wpWindow.smoothCursorOffsetY
                }

                // Cross-fade support between wallpaper transitions
                Image {
                    id: imgBackdrop
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true
                }

                Image {
                    id: imgPrimary
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: wpWindow.displayWallpaper
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true

                    onSourceChanged: {
                        // Only trigger cross-fade if transitioning to a valid image
                        if (imgPrimary.source.toString() !== "") {
                            crossFadeAnim.restart()
                        } else {
                            imgBackdrop.source = ""
                        }
                    }

                    SequentialAnimation {
                        id: crossFadeAnim
                        ScriptAction {
                            script: {
                                if (imgPrimary.source.toString() !== "") {
                                    imgBackdrop.source = imgPrimary.source
                                }
                            }
                        }
                        NumberAnimation { 
                            target: imgPrimary
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad 
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.06
                }
            }
        }
    }
}