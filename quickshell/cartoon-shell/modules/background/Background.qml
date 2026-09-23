pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtMultimedia
import qs.commons
import qs.services

Variants {
    id: backgroundVariants
    model: Quickshell.screens

    delegate: Loader {
        id: loader
        required property ShellScreen modelData

        active: modelData && Settings.wallpaper.enabled

        sourceComponent: PanelWindow {
            id: root

            // Internal state management
            property string transitionType: "fade"
            property real transitionProgress: 0

            readonly property real edgeSmoothness: Settings.wallpaper.transitionEdgeSmoothness
            readonly property bool transitioning: transitionAnimation.running

            Loader {
                active: VisibleService.shortcutMenu
                source: "../panels/shortcutMenu/ShortcutMenuPanel.qml"
                onLoaded: {
                    item.visible = VisibleService.shortcutMenu;
                    item.xMargins = root.xMargins;
                    item.yMargins = root.yMargins;
                }
            }
            property real xMargins: 0
            property real yMargins: 0
            // Wipe direction: 0=left, 1=right, 2=up, 3=down
            property real wipeDirection: 0

            // Disc
            property real discCenterX: 0.5
            property real discCenterY: 0.5

            // Stripe
            property real stripesCount: 16
            property real stripesAngle: 0
            property var shaders: ["/shaders/qsb/wp_disc.frag.qsb", "/shaders/qsb/wp_stripes.frag.qsb", "/shaders/qsb/wp_fade.frag.qsb", "/shaders/qsb/wp_wipe.frag.qsb"]

            // Used to debounce wallpaper changes
            property string futureWallpaper: ""
            readonly property var heightBar: ({
                    "style1": 50,
                    "style2": 40,
                    "style3": 50
                })

            // Fillmode default is "crop"
            property real fillMode: WallpaperService.getFillModeUniform()
            property vector4d fillColor: Qt.vector4d(Settings.wallpaper.fillColor.r, Settings.wallpaper.fillColor.g, Settings.wallpaper.fillColor.b, 1.0)

            // Video properties from Settings
            readonly property bool videoMuted: Settings.wallpaper.videoMuted !== undefined ? Settings.wallpaper.videoMuted : true
            readonly property bool videoLoop: Settings.wallpaper.videoLoop !== undefined ? Settings.wallpaper.videoLoop : true
            readonly property real videoPlaybackRate: Settings.wallpaper.videoPlaybackRate !== undefined ? Settings.wallpaper.videoPlaybackRate : 1.0

            color: "transparent"
            screen: loader.modelData
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaper-" + (screen?.name || "unknown")

            anchors {
                bottom: true
                top: true
                right: true
                left: true
            }

            Timer {
                id: debounceTimer
                interval: 333
                running: false
                repeat: false
                onTriggered: {
                    root.changeWallpaper();
                }
            }

            Component.onCompleted: setWallpaperInitial()

            Component.onDestruction: {
                transitionAnimation.stop();
                debounceTimer.stop();
                shaderLoader.active = false;
                currentWallpaper.source = "";
                nextWallpaper.source = "";
            }

            Connections {
                target: WallpaperService
                function onWallpaperChanged(screenName, path) {
                    if (screenName === loader.modelData.name) {
                        root.futureWallpaper = path;
                        debounceTimer.restart();
                    }
                }
            }

            Connections {
                target: CompositorService
                function onDisplayScalesChanged() {
                    root.setWallpaperInitial();
                }
            }
            Item {
                anchors.fill: parent
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    z: 1

                    onClicked: mouse => {
                        let isVisible = VisibleService.getPanelVisible("shortcutMenu");
                        if (mouse.button === Qt.RightButton) {
                            if (mouse.x > Number(parent.width) - ScalerService.s(250)) {
                                root.xMargins = mouse.x - ScalerService.s(250);
                            } else {
                                root.xMargins = mouse.x;
                            }
                            if (mouse.y > Number(parent.height - ScalerService.s(heightBar[Settings.bar.style])) - ScalerService.s(400)) {
                                root.yMargins = mouse.y - ScalerService.s(heightBar[Settings.bar.style]) - ScalerService.s(400);
                            } else {
                                root.yMargins = mouse.y - ScalerService.s(heightBar[Settings.bar.style]);
                            }
                            VisibleService.togglePanel("shortcutMenu");
                            if (isVisible)
                                VisibleService.togglePanel("shortcutMenu");
                        } else if (isVisible) {
                            VisibleService.togglePanel("shortcutMenu");
                        }
                    }
                }
            }

            // Current wallpaper - can be Image or Video
            Item {
                id: currentWallpaperContainer
                anchors.fill: parent
                visible: !root.transitioning || root.transitionProgress === 0

                Image {
                    id: currentImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    cache: false
                    asynchronous: true
                    sourceSize: root.calculateOptimalWallpaperSize(implicitWidth, implicitHeight)
                    visible: root.currentWallpaperType === "image"

                    property bool dimensionsCalculated: false

                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Current wallpaper failed to load:", source);
                        } else if (status === Image.Ready && !dimensionsCalculated) {
                            dimensionsCalculated = true;
                            const optimalSize = root.calculateOptimalWallpaperSize(implicitWidth, implicitHeight);
                            if (optimalSize !== false) {
                                sourceSize = optimalSize;
                            }
                        }
                    }
                    onSourceChanged: {
                        dimensionsCalculated = false;
                        sourceSize = undefined;
                    }
                }

                // Video for video wallpapers
                Video {
                    id: currentVideo
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    muted: root.videoMuted
                    loops: root.videoLoop ? MediaPlayer.Infinite : 1
                    autoPlay: true
                    playbackRate: root.videoPlaybackRate
                    visible: root.currentWallpaperType === "video"

                    onErrorOccurred: function (error, errorString) {
                        console.error("Video error:", error, errorString);
                        // Fallback to default wallpaper if video fails
                        if (WallpaperService && WallpaperService.isInitialized) {
                            const defaultWallpaper = WallpaperService.getWallpaper(loader.modelData.name);
                            if (defaultWallpaper) {
                                root.setWallpaperImmediate(defaultWallpaper);
                            }
                        }
                    }

                    onPlaying: {
                        console.log("Current video started playing:", source);
                    }

                    onStopped: {
                        console.log("Current video stopped");
                    }

                    Component.onDestruction: {
                        if (playbackState === MediaPlayer.PlayingState) {
                            stop();
                        }
                    }
                }
            }

            // Next wallpaper - for transitions
            Item {
                id: nextWallpaperContainer
                anchors.fill: parent
                visible: root.transitioning && root.transitionProgress > 0

                // Image for image wallpapers
                Image {
                    id: nextImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    cache: false
                    asynchronous: true
                    sourceSize: root.calculateOptimalWallpaperSize(implicitWidth, implicitHeight)
                    visible: root.nextWallpaperType === "image"

                    property bool dimensionsCalculated: false

                    onStatusChanged: {
                        if (status === Image.Error) {} else if (status === Image.Ready && !dimensionsCalculated) {
                            dimensionsCalculated = true;
                            const optimalSize = root.calculateOptimalWallpaperSize(implicitWidth, implicitHeight);
                            if (optimalSize !== false) {
                                sourceSize = optimalSize;
                            }
                        }
                    }
                    onSourceChanged: {
                        dimensionsCalculated = false;
                        sourceSize = undefined;
                    }
                }

                // Video for video wallpapers
                Video {
                    id: nextVideo
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectCrop
                    autoPlay: true
                    loops: MediaPlayer.Infinite
                    muted: true
                    playbackRate: root.videoPlaybackRate
                    visible: root.nextWallpaperType === "video"

                    onErrorOccurred: function (error, errorString) {
                        console.error("Next video error:", error, errorString);
                    }

                    onPlaying: {
                        console.log("Next video started playing:", source);
                    }

                    onStopped: {
                        console.log("Next video stopped");
                    }

                    Component.onDestruction: {
                        if (playbackState === MediaPlayer.PlayingState) {
                            stop();
                        }
                    }
                }
            }

            // Track current and next wallpaper types
            property string currentWallpaperType: "image" // "image" or "video"
            property string nextWallpaperType: "image" // "image" or "video"

            // Track current and next sources
            property string currentSource: ""
            property string nextSource: ""

            Loader {
                id: shaderLoader
                anchors.fill: parent
                active: true
                sourceComponent: ShaderEffect {
                    anchors.fill: parent

                    property variant source1: currentWallpaperContainer.children[0]
                    property variant source2: nextWallpaperContainer.children[0]
                    property real progress: root.transitionProgress
                    property real smoothness: root.edgeSmoothness
                    property real aspectRatio: root.width / root.height
                    property real stripeCount: root.stripesCount
                    property real angle: root.stripesAngle

                    // Fill mode properties
                    property real fillMode: root.fillMode
                    property vector4d fillColor: root.fillColor
                    property real imageWidth1: currentImage.sourceSize.width
                    property real imageHeight1: currentImage.sourceSize.height
                    property real imageWidth2: nextImage.sourceSize.width
                    property real imageHeight2: nextImage.sourceSize.height
                    property real screenWidth: width
                    property real screenHeight: height

                    fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + shaders[0])
                }
            }

            NumberAnimation {
                id: transitionAnimation
                target: root
                property: "transitionProgress"
                from: 0.0
                to: 1.0
                // The stripes shader feels faster visually, we make it a bit slower here.
                duration: 1500
                easing.type: Easing.InOutCubic
                onFinished: {
                    // Assign new wallpaper to current BEFORE clearing to prevent flicker
                    const tempSource = root.nextSource;
                    const tempType = root.nextWallpaperType;

                    // Stop current video if it's playing
                    if (root.currentWallpaperType === "video" && currentVideo.playbackState === MediaPlayer.PlayingState) {
                        currentVideo.stop();
                    }

                    // Clear current
                    if (root.currentWallpaperType === "image") {
                        currentImage.source = "";
                    } else {
                        currentVideo.source = "";
                    }

                    // Set current to new wallpaper
                    root.currentSource = tempSource;
                    root.currentWallpaperType = tempType;

                    if (tempType === "image") {
                        currentImage.source = tempSource;
                    } else {
                        currentVideo.source = tempSource;
                    }

                    root.transitionProgress = 0.0;

                    // Now clear next wallpaper
                    root.nextSource = "";
                    if (root.nextWallpaperType === "image") {
                        nextImage.source = "";
                        nextImage.sourceSize = undefined;
                    } else {
                        nextVideo.source = "";
                        if (nextVideo.playbackState === MediaPlayer.PlayingState) {
                            nextVideo.stop();
                        }
                    }
                    root.nextWallpaperType = "image";
                }
            }

            function setWallpaperInitial() {
                // On startup, defer assigning wallpaper until the service cache is ready, retries every tick
                if (!WallpaperService || !WallpaperService.isInitialized) {
                    Qt.callLater(setWallpaperInitial);
                    return;
                }

                setWallpaperImmediate(WallpaperService.getWallpaper(loader.modelData.name));
            }

            function setWallpaperImmediate(source) {
                transitionAnimation.stop();
                transitionProgress = 0.0;

                // Clear next wallpaper completely
                root.nextSource = "";
                if (root.nextWallpaperType === "image") {
                    nextImage.source = "";
                    nextImage.sourceSize = undefined;
                } else {
                    nextVideo.source = "";
                    if (nextVideo.playbackState === MediaPlayer.PlayingState) {
                        nextVideo.stop();
                    }
                }
                root.nextWallpaperType = "image";

                // Set current wallpaper
                if (source) {
                    root.currentSource = source;
                    const isVideo = isVideoFile(source);
                    root.currentWallpaperType = isVideo ? "video" : "image";

                    if (isVideo) {
                        currentVideo.source = "file://" + source;
                        currentImage.source = "";
                    } else {
                        currentImage.source = source;
                        currentVideo.source = "";
                        if (currentVideo.playbackState === MediaPlayer.PlayingState) {
                            currentVideo.stop();
                        }
                    }
                }
            }

            function calculateOptimalWallpaperSize(wpWidth, wpHeight) {
                const compositorScale = CompositorService.getDisplayScale(loader.modelData.name);
                const screenWidth = loader.modelData.width * compositorScale;
                const screenHeight = loader.modelData.height * compositorScale;

                if (wpWidth <= screenWidth || wpHeight <= screenHeight || wpWidth <= 0 || wpHeight <= 0) {
                    return;
                }

                const imageAspectRatio = wpWidth / wpHeight;
                var dim = Qt.size(0, 0);
                if (screenWidth >= screenHeight) {
                    const w = Math.min(screenWidth, wpWidth);
                    dim = Qt.size(w, w / imageAspectRatio);
                } else {
                    const h = Math.min(screenHeight, wpHeight);
                    dim = Qt.size(h * imageAspectRatio, h);
                }

                return dim;
            }

            function setWallpaperWithTransition(source) {
                if (!source || source === root.currentSource) {
                    return;
                }

                // Determine file type
                const isVideo = isVideoFile(source);
                const newType = isVideo ? "video" : "image";

                if (transitioning) {
                    // If already transitioning, complete current transition first
                    transitionAnimation.stop();
                    transitionProgress = 0;

                    // Set current to whatever was in next
                    root.currentSource = root.nextSource;
                    root.currentWallpaperType = root.nextWallpaperType;

                    if (root.currentWallpaperType === "image") {
                        currentImage.source = root.currentSource;
                        currentVideo.source = "";
                        if (currentVideo.playbackState === MediaPlayer.PlayingState) {
                            currentVideo.stop();
                        }
                    } else {
                        currentVideo.source = root.currentSource;
                        currentImage.source = "";
                    }

                    // Now set next to new source
                    root.nextSource = source;
                    root.nextWallpaperType = newType;

                    if (newType === "image") {
                        nextImage.source = source;
                        nextVideo.source = "";
                        if (nextVideo.playbackState === MediaPlayer.PlayingState) {
                            nextVideo.stop();
                        }
                    } else {
                        nextVideo.source = source;
                        nextImage.source = "";
                    }

                    currentImage.asynchronous = false;
                    transitionAnimation.start();
                    return;
                }

                // Set next wallpaper
                root.nextSource = source;
                root.nextWallpaperType = newType;

                if (newType === "image") {
                    nextImage.source = source;
                    nextVideo.source = "";
                    if (nextVideo.playbackState === MediaPlayer.PlayingState) {
                        nextVideo.stop();
                    }
                } else {
                    nextVideo.source = source;
                    nextImage.source = "";
                }

                currentImage.asynchronous = false;
                transitionAnimation.start();
            }

            function changeWallpaper() {
                stripesCount = Math.round(Math.random() * 20 + 4);
                stripesAngle = Math.random() * 360;
                setWallpaperWithTransition(futureWallpaper);
                futureWallpaper = "";
            }

            function isVideoFile(source) {
                if (!source)
                    return false;
                const videoExtensions = ["mp4", "webm", "mkv", "avi", "mov", "flv", "wmv", "m4v", "mpg", "mpeg"];
                const sourceStr = source.toString();
                const extension = sourceStr.split('.').pop().toLowerCase();
                return videoExtensions.includes(extension);
            }
        }
    }
}
