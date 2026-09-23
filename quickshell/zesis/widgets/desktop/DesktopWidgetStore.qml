pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool configMode: false

    // Ordered list of active widget keys, Instantiator in shell.qml watches this.
    property var enabledKeys: []

    // { "key": { nx: 0.0-1.0, ny: 0.0-1.0, bg: BgConfig } }
    property var _positions: ({})

    // [{ key: string, component: Component }] fed to DesktopConfigOverlay's Repeater
    property var _widgets: []

    function register(key, component) {
        var arr = _widgets.filter(w => w.key !== key);
        arr.push({
            key: key,
            component: component
        });
        _widgets = arr;
    }

    function unregister(key) {
        _widgets = _widgets.filter(w => w.key !== key);
    }

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _path: _configDir + "/desktop-widgets.json"
    readonly property string _bgCacheDir: _configDir + "/bg"

    function getPos(key) {
        var p = _positions[key];
        return {
            nx: (p?.nx ?? 0.5),
            ny: (p?.ny ?? 0.5)
        };
    }

    function setPos(key, nx, ny) {
        var copy = Object.assign({}, _positions);
        copy[key] = Object.assign({}, copy[key] || {}, {
            nx: Math.max(0.0, Math.min(1.0, nx)),
            ny: Math.max(0.0, Math.min(1.0, ny))
        });
        _positions = copy;
        _save();
    }

    // 0 means "auto" (use the content's own implicit size) for that axis independently
    function getSize(key) {
        var s = _positions[key]?.size;
        return {
            w: s?.w ?? 0,
            h: s?.h ?? 0
        };
    }

    function setSize(key, w, h) {
        var copy = Object.assign({}, _positions);
        copy[key] = Object.assign({}, copy[key] || {
            nx: 0.5,
            ny: 0.5
        }, {
            size: {
                w: Math.max(0, Math.round(w || 0)),
                h: Math.max(0, Math.round(h || 0))
            }
        });
        _positions = copy;
        _save();
    }

    function _defaultBgConfig() {
        return {
            enabled: false,
            type: "color",
            color: "",
            overlayOpacity: 0.4,
            imagePath: "",
            cachedImagePath: "",
            maskPath: ""
        };
    }

    function getBgConfig(key) {
        var bg = _positions[key]?.bg;
        if (!bg || typeof bg === 'boolean')
            return Object.assign(_defaultBgConfig(), {
                enabled: bg === true
            });
        return Object.assign(_defaultBgConfig(), bg);
    }

    // targetW/H are physical pixels (logical by devicePixelRatio) of the widget
    // background area, used to produce a tight-fit cached image. Omit (or pass 0)
    // when not changing the image path.
    function setBgConfig(key, config, targetW, targetH) {
        var oldConfig = getBgConfig(key);
        var imageChanged = config.imagePath !== oldConfig.imagePath;
        // Clear the cache pointer when the source path changes so the widget
        // falls back to the original while the new cached copy is being generated.
        if (imageChanged)
            config = Object.assign({}, config, {
                cachedImagePath: ""
            });
        var copy = Object.assign({}, _positions);
        copy[key] = Object.assign({}, copy[key] || {
            nx: 0.5,
            ny: 0.5
        }, {
            bg: config
        });
        _positions = copy;
        _save();
        if (imageChanged && config.imagePath)
            _processBackground(key, config.imagePath, targetW || 0, targetH || 0);
    }

    property bool _magickAvailable: false
    property string _pendingBgKey: ""

    Process {
        id: magickCheck
        command: ["sh", "-c", "which magick >/dev/null 2>&1"]
        running: true
        onExited: code => {
            root._magickAvailable = (code === 0);
        }
    }

    Process {
        id: mkdirBgCache
        command: ["mkdir", "-p", root._bgCacheDir]
        running: true
    }

    // Resizes the chosen image to a display-appropriate size and saves to the
    // bg cache dir. The "> " geometry flag means "only shrink, never enlarge".
    Process {
        id: magickProc
        onExited: code => {
            if (code === 0 && root._pendingBgKey !== "") {
                var key = root._pendingBgKey;
                var cachedPath = root._bgCacheDir + "/" + key + ".png";
                var copy = Object.assign({}, root._positions);
                if (copy[key]?.bg && typeof copy[key].bg === 'object') {
                    copy[key] = Object.assign({}, copy[key]);
                    copy[key].bg = Object.assign({}, copy[key].bg, {
                        cachedImagePath: cachedPath
                    });
                    root._positions = copy;
                    root._save();
                }
            }
            root._pendingBgKey = "";
        }
    }

    function _processBackground(key, imagePath, targetW, targetH) {
        if (!root._magickAvailable || !imagePath)
            return;
        // Use the widget's physical pixel dimensions (cover-fit geometry "WxH^").
        // Falls back to 1920x1080 if no size hint was supplied.
        var w = (targetW > 0) ? Math.round(targetW) : 1920;
        var h = (targetH > 0) ? Math.round(targetH) : 1080;
        root._pendingBgKey = key;
        magickProc.command = ["magick", imagePath, "-resize", w + "x" + h + "^", root._bgCacheDir + "/" + key + ".png"];
        magickProc.running = false;
        magickProc.running = true;
    }

    function enableWidget(key) {
        if (enabledKeys.indexOf(key) !== -1)
            return;
        enabledKeys = enabledKeys.concat([key]);
        _save();
    }

    function disableWidget(key) {
        enabledKeys = enabledKeys.filter(k => k !== key);
        _save();
    }

    function isEnabled(key) {
        return enabledKeys.indexOf(key) !== -1;
    }

    function _save() {
        posFile.setText(JSON.stringify({
            enabled: enabledKeys,
            positions: _positions
        }));
    }

    function _load(text) {
        if (!text)
            return;
        try {
            var obj = JSON.parse(text) || {};
            var positions = obj.positions || {};
            // Migrate old boolean bg to config object
            Object.keys(positions).forEach(function (k) {
                var p = positions[k];
                if (p && typeof p.bg === 'boolean')
                    p.bg = Object.assign(root._defaultBgConfig(), {
                        enabled: p.bg
                    });
            });
            root._positions = positions;
            root.enabledKeys = obj.enabled || [];
        } catch (_) {}
    }

    FileView {
        id: posFile
        path: root._path
        blockLoading: true
        printErrors: false
        onLoaded: root._load(posFile.text())
    }

    Component.onCompleted: {
        _load(posFile.text());
    }
}
