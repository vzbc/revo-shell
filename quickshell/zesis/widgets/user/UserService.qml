pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/user.json"

    property string name: userData.name
    property string avatarPath: userData.avatarPath
    property string heroImage: userData.heroImage
    property bool heroFollowWallpaper: userData.heroFollowWallpaper

    function setName(n) {
        _write(n, root.avatarPath, root.heroImage, root.heroFollowWallpaper);
    }
    function setAvatarPath(p) {
        _write(root.name, p, root.heroImage, root.heroFollowWallpaper);
    }
    function setHeroImage(p) {
        _write(root.name, root.avatarPath, p, root.heroFollowWallpaper);
    }
    function setHeroFollowWallpaper(v) {
        _write(root.name, root.avatarPath, root.heroImage, v);
    }

    function _write(n, p, hi, hfw) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && " + "printf '%s' '{\"name\":\"" + n + "\",\"avatarPath\":\"" + p + "\",\"heroImage\":\"" + hi + "\",\"heroFollowWallpaper\":" + hfw + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: userData
        property string name: ""
        property string avatarPath: ""
        property string heroImage: ""
        property bool heroFollowWallpaper: true
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: userData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }
}
