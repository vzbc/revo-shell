pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.commons
import qs.utils
import qs.services

Singleton {
    id: root

    readonly property ListModel fillModeModel: ListModel {}
    readonly property string defaultDirectory: Settings.wallpaper.directory

    readonly property ListModel transitionsModel: ListModel {}

    property var wallpaperLists: ({})
    property int scanningCount: 0
    readonly property bool scanning: (scanningCount > 0)
    property var currentWallpapers: ({})
    property bool isInitialized: false

    // Thư mục cache thumbnail cố định
    readonly property string wallpaperThumbsDir: "/home/long/.cache/quickshell/wallpapers_thumbs"

    signal wallpaperChanged(string screenName, string path)
    signal wallpaperDirectoryChanged(string screenName, string directory)
    signal wallpaperListChanged(string screenName, int count)

    Connections {
        target: Settings.wallpaper

        function onDirectoryChanged() {
            root.refreshWallpapersList();
            if (!Settings.wallpaper.enableMultiMonitorDirectories) {
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    root.wallpaperDirectoryChanged(Quickshell.screens[i].name, root.defaultDirectory);
                }
            } else {
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    const screenName = Quickshell.screens[i].name;
                    const monitor = root.getMonitorConfig(screenName);
                    if (!monitor || !monitor.directory) {
                        root.wallpaperDirectoryChanged(screenName, root.defaultDirectory);
                    }
                }
            }
        }

        function onEnableMultiMonitorDirectoriesChanged() {
            root.refreshWallpapersList();
            for (let i = 0; i < Quickshell.screens.length; i++) {
                var screenName = Quickshell.screens[i].name;
                root.wallpaperDirectoryChanged(screenName, root.getMonitorDirectory(screenName));
            }
        }

        function onRecursiveSearchChanged() {
            root.refreshWallpapersList();
        }
    }

    function init() {
        // Tạo thư mục cache nếu chưa tồn tại
        var mkdirCmd = `mkdir -p "${root.wallpaperThumbsDir}"`;
        var mkdirProc = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            Process {
                command: ["bash", "-c", "${mkdirCmd.replace(/"/g, '\\"')}"]
                onExited: destroy()
            }
        `, root, "MkdirCacheProc");
        mkdirProc.running = true;

        currentWallpapers = ({});
        const monitors = Settings.wallpaper.monitors || [];
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name && monitors[i].wallpaper) {
                currentWallpapers[monitors[i].name] = monitors[i].wallpaper;
            }
        }

        isInitialized = true;
        Qt.callLater(refreshWallpapersList);
    }

    function getFillModeUniform() {
        for (let i = 0; i < fillModeModel.count; i++) {
            const mode = fillModeModel.get(i);
            if (mode.key === Settings.wallpaper.fillMode) {
                return mode.uniform;
            }
        }
        return 1.0;
    }

    function getMonitorConfig(screenName) {
        var monitors = Settings.wallpaper.monitors;
        if (monitors !== undefined) {
            for (let i = 0; i < monitors.length; i++) {
                if (monitors[i].name === screenName) {
                    return monitors[i];
                }
            }
        }
    }

    function getMonitorDirectory(screenName) {
        if (!Settings.wallpaper.enableMultiMonitorDirectories) {
            return root.defaultDirectory;
        }

        var monitor = getMonitorConfig(screenName);
        if (monitor && monitor.directory !== undefined) {
            return FileUtils.trimFileProtocol(monitor.directory);
        }

        return root.defaultDirectory;
    }

    function setMonitorDirectory(screenName, directory) {
        var monitors = Settings.wallpaper.monitors || [];
        var found = false;

        var newMonitors = monitors.map(function (monitor) {
            if (monitor.name === screenName) {
                found = true;
                return {
                    "name": screenName,
                    "directory": directory,
                    "wallpaper": monitor.wallpaper || ""
                };
            }
            return monitor;
        });

        if (!found) {
            newMonitors.push({
                "name": screenName,
                "directory": directory,
                "wallpaper": ""
            });
        }

        Settings.wallpaper.monitors = newMonitors.slice();
        root.wallpaperDirectoryChanged(screenName, FileUtils.trimFileProtocol(directory));
    }

    function getWallpaper(screenName) {
        return currentWallpapers[screenName] || Settings.wallpaper.defaultWallpaper;
    }

    // Lấy đường dẫn thumbnail trong cache
    function getCacheThumbnailPath(wallpaperPath) {
        if (!wallpaperPath || wallpaperPath === "")
            return "";

        var filename = wallpaperPath.split('/').pop();
        var nameWithoutExt = filename.substring(0, filename.lastIndexOf('.')) || filename;
        return root.wallpaperThumbsDir + "/" + nameWithoutExt + ".png";
    }

    function isVideoFile(path) {
        if (!path)
            return false;
        const videoExtensions = ["mp4", "webm", "mkv", "avi", "mov", "flv", "wmv", "m4v", "mpg", "mpeg"];
        const pathStr = path.toString();
        const extension = pathStr.split('.').pop().toLowerCase();
        return videoExtensions.includes(extension);
    }

    // Tạo thumbnail trong thư mục cache với chất lượng thấp
    function generateVideoThumbnail(videoPath, callback) {
        if (!videoPath) {
            if (callback)
                callback("");
            return;
        }

        var thumbPath = getCacheThumbnailPath(videoPath);

        // Đảm bảo thư mục cache tồn tại
        var mkdirCmd = `mkdir -p "${root.wallpaperThumbsDir}"`;
        var ffmpegCmd = `ffmpeg -y -i "${videoPath}" -vframes 1 -vf "scale=320:-1" -sws_flags fast_bilinear -q:v 10 "${thumbPath}" 2>/dev/null`;
        var fullCmd = `${mkdirCmd} && ${ffmpegCmd}`;

        try {
            var extractProcess = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                Process {
                    id: extractProc
                    property var callbackFn: null
                    property string thumbPath: ""

                    command: ["bash", "-c", "${fullCmd.replace(/"/g, '\\"')}"]
                    onExited: function(exitCode) {
                        if (exitCode === 0) {
                            console.log("Thumbnail created in cache:", thumbPath);
                            if (callbackFn) callbackFn(thumbPath);
                        } else {
                            console.error("Failed to create thumbnail:", stderr.text);
                            if (callbackFn) callbackFn("");
                        }
                        extractProc.destroy();
                    }
                    stdout: StdioCollector {}
                    stderr: StdioCollector {}
                }
            `, root, "GenerateThumbnail");

            extractProcess.callbackFn = callback;
            extractProcess.thumbPath = thumbPath;
            extractProcess.running = true;
        } catch (e) {
            console.error("Error generating thumbnail:", e);
            if (callback)
                callback("");
        }
    }

    function changeWallpaper(path, screenName) {
        if (screenName !== undefined) {
            _setWallpaper(screenName, path);
        } else {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                _setWallpaper(Quickshell.screens[i].name, path);
            }
        }
    }

    function _setWallpaper(screenName, path) {
        if (!path)
            return;
        var oldPath = currentWallpapers[screenName] || "";
        if (oldPath === path)
            return;
        currentWallpapers[screenName] = path;

        var monitors = Settings.wallpaper.monitors || [];
        var found = false;

        var newMonitors = monitors.map(function (monitor) {
            if (monitor.name === screenName) {
                found = true;
                return {
                    "name": screenName,
                    "directory": FileUtils.trimFileProtocol(monitor.directory) || getMonitorDirectory(screenName),
                    "wallpaper": path
                };
            }
            return monitor;
        });

        if (!found) {
            newMonitors.push({
                "name": screenName,
                "directory": getMonitorDirectory(screenName),
                "wallpaper": path
            });
        }

        Settings.wallpaper.monitors = newMonitors.slice();
        root.wallpaperChanged(screenName, path);

        // Xử lý Matugen - tạo thumbnail cho video
        if (Settings.appearance && Settings.appearance.theme === "matugen") {
            const isVideo = isVideoFile(path);

            if (isVideo) {
                // Tạo thumbnail trong cache và trigger Matugen với thumbnail path
                generateVideoThumbnail(path, function (thumbnailPath) {
                    if (thumbnailPath && thumbnailPath !== "") {
                        console.log("Video thumbnail ready for matugen:", thumbnailPath);
                        if (typeof ThemeService !== 'undefined' && ThemeService.triggerMatugenOnWallpaperChange) {
                            ThemeService.triggerMatugenOnWallpaperChange(thumbnailPath);
                        }
                    } else {
                        console.warn("Matugen skipped: Could not generate thumbnail from video:", path);
                        // Fallback: sử dụng video path nhưng matugen sẽ báo lỗi
                        if (typeof ThemeService !== 'undefined' && ThemeService.triggerMatugenOnWallpaperChange) {
                            ThemeService.triggerMatugenOnWallpaperChange(path);
                        }
                    }
                });
            } else {
                Qt.callLater(function () {
                    if (typeof ThemeService !== 'undefined' && ThemeService.triggerMatugenOnWallpaperChange) {
                        ThemeService.triggerMatugenOnWallpaperChange(path);
                    }
                });
            }
        }
    }

    function restartRandomWallpaperTimer() {
        if (Settings.wallpaper.isRandom) {
            randomWallpaperTimer.restart();
        }
    }

    function getWallpapersList(screenName) {
        if (screenName && wallpaperLists[screenName]) {
            return wallpaperLists[screenName];
        }
        return [];
    }

    function refreshWallpapersList() {
        scanningCount = 0;

        if (Settings.wallpaper.recursiveSearch) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                var screenName = Quickshell.screens[i].name;
                var directory = getMonitorDirectory(screenName);
                scanDirectoryRecursive(screenName, directory);
            }
        } else {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                var screenName = Quickshell.screens[i].name;
                var directory = getMonitorDirectory(screenName);
                root.wallpaperDirectoryChanged(screenName, directory);
            }
        }
    }

    property var recursiveProcesses: ({})

    function scanDirectoryRecursive(screenName, directory) {
        if (!directory) {
            wallpaperLists[screenName] = [];
            wallpaperListChanged(screenName, 0);
            return;
        }

        if (recursiveProcesses[screenName]) {
            recursiveProcesses[screenName].running = false;
            recursiveProcesses[screenName].destroy();
            delete recursiveProcesses[screenName];
            if (scanningCount > 0)
                scanningCount--;
        }

        scanningCount++;

        try {
            var processObject = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                Process {
                    id: process
                    stdout: StdioCollector {}
                    stderr: StdioCollector {}
                }
            `, root, "RecursiveScan_" + screenName);

            processObject.command = ["find", directory, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.gif", "-o", "-iname", "*.pnm", "-o", "-iname", "*.bmp", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm", "-o", "-iname", "*.mkv", "-o", "-iname", "*.avi", "-o", "-iname", "*.mov", "-o", "-iname", "*.flv", "-o", "-iname", "*.wmv", "-o", "-iname", "*.m4v", "-o", "-iname", "*.mpg", "-o", "-iname", "*.mpeg", ")"];

            recursiveProcesses[screenName] = processObject;

            processObject.exited.connect(function (exitCode) {
                if (scanningCount > 0)
                    scanningCount--;

                if (exitCode === 0 && processObject.stdout) {
                    var lines = processObject.stdout.text.split("\n");
                    var files = [];
                    for (let i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line !== "")
                            files.push(line);
                    }

                    files.sort();
                    wallpaperLists[screenName] = files;
                    wallpaperListChanged(screenName, files.length);
                } else {
                    wallpaperLists[screenName] = [];
                    wallpaperListChanged(screenName, 0);
                }

                delete recursiveProcesses[screenName];
                processObject.destroy();
            });

            processObject.running = true;
        } catch (e) {
            console.error("Error in scanDirectoryRecursive:", e);
            if (scanningCount > 0)
                scanningCount--;
        }
    }

    Instantiator {
        id: wallpaperScanners
        model: Quickshell.screens

        delegate: Item {
            id: scannerItem
            property string screenName: modelData.name
            property string targetDirectory: root.getMonitorDirectory(screenName)
            property var folderModel: null
            property bool isLoading: false

            function createModel() {
                if (folderModel) {
                    if (isLoading) {
                        isLoading = false;
                        if (root.scanningCount > 0)
                            root.scanningCount--;
                    }
                    folderModel.destroy();
                    folderModel = null;
                }

                var component = Qt.createQmlObject(`
                    import QtQuick
                    import Qt.labs.folderlistmodel
                    FolderListModel {
                        id: model
                        folder: "file://${targetDirectory}"
                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp",
                                      "*.mp4", "*.webm", "*.mkv", "*.avi", "*.mov", "*.flv",
                                      "*.wmv", "*.m4v", "*.mpg", "*.mpeg"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }
                `, scannerItem, "FolderModel_" + screenName);

                component.statusChanged.connect(function () {
                    if (component.status === FolderListModel.Null) {
                        root.wallpaperLists[screenName] = [];
                        root.wallpaperListChanged(screenName, 0);
                    } else if (component.status === FolderListModel.Loading) {
                        if (!isLoading) {
                            isLoading = true;
                            root.scanningCount++;
                        }
                        root.wallpaperLists[screenName] = [];
                    } else if (component.status === FolderListModel.Ready) {
                        if (isLoading) {
                            isLoading = false;
                            if (root.scanningCount > 0)
                                root.scanningCount--;
                        }
                        var files = [];
                        for (let i = 0; i < component.count; i++) {
                            var filepath = targetDirectory + "/" + component.get(i, "fileName");
                            files.push(filepath);
                        }
                        root.wallpaperLists[screenName] = files;
                        root.wallpaperListChanged(screenName, files.length);
                    }
                });

                folderModel = component;
            }

            Connections {
                target: root
                function onWallpaperDirectoryChanged(screen, directory) {
                    if (screen === scannerItem.screenName) {
                        scannerItem.targetDirectory = directory;
                        scannerItem.createModel();
                    }
                }
            }

            Component.onCompleted: {
                createModel();
            }

            Component.onDestruction: {
                if (isLoading && root.scanningCount > 0) {
                    root.scanningCount--;
                }
                if (folderModel) {
                    folderModel.destroy();
                }
            }
        }
    }
}
