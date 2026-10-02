import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtMultimedia
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "wallpaper"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    // ---------------------------------------------------------------- library
    property var allImgs: []
    property var dyn: []
    property var photos: []
    property var wide: []
    property var tall: []

    readonly property var folders: {
        var out = []
        var roots = ["/home/revo/Pictures/Wallpapers",
                     "/home/revo/Pictures",
                     Shell.eget("wallpaper.folder", "").toString().replace(/^file:\/\//, "").replace(/\/$/, ""),
                     "/home/revo/.local/share/equora/wallpapers"]
        var seen = {}
        for (var i = 0; i < roots.length; i++) {
            var r = roots[i]
            if (!r || seen[r])
                continue
            seen[r] = true
            var files = Shell.listFiles(r, "")
            if (files.length > 0)
                out.push({ name: r.split("/").filter(Boolean).pop() || r, dir: r, files: files })
        }
        return out
    }

    function build() {
        var roots = ["/home/revo/Pictures/Wallpapers",
                     Shell.eget("wallpaper.folder", "").toString().replace(/^file:\/\//, "").replace(/\/$/, ""),
                     "/home/revo/.local/share/equora/wallpapers"]
        var seen = {}
        var all = []
        for (var i = 0; i < roots.length; i++) {
            var r = roots[i]
            if (!r || seen[r])
                continue
            seen[r] = true
            var imgs = Shell.listImages(r)
            for (var j = 0; j < imgs.length; j++)
                all.push(imgs[j])
        }
        var d = [], p = [], w = [], t = []
        var cap = 400
        for (var k = 0; k < all.length; k++) {
            var m = all[k]
            if (m.animated === true) { if (d.length < cap) d.push(m); continue }
            if (p.length < cap) p.push(m)
            if (m.w > m.h * 1.05) { if (w.length < cap) w.push(m) }
            else if (m.h > m.w * 1.05) { if (t.length < cap) t.push(m) }
        }
        allImgs = all
        dyn = d
        photos = p
        wide = w
        tall = t
        console.log("WALLPAPER_LIB all=" + all.length + " dyn=" + d.length + " photos=" + p.length
                    + " wide=" + w.length + " tall=" + t.length)
    }

    readonly property var sections: {
        var s = [
            { title: "Dynamic Wallpapers", files: dyn, add: false,
              hint: "Dynamic wallpapers (GIF, video) appear here." },
            { title: "Photos", files: photos, add: true, hint: "" },
            { title: "Landscape", files: wide, add: false,
              hint: "Landscape wallpapers appear here." }
        ]
        if (tall.length > 0)
            s.push({ title: "Portraits", files: tall, add: false, hint: "" })
        return s
    }

    readonly property string current: {
        bumpE
        var p = String(eget("wallpaper.path", ""))
        if (p.length > 0)
            return p
        if (photos.length > 0)
            return photos[0].path
        return ""
    }

    function apply(path) {
        Shell.eset("wallpaper.path", path)
        Shell.eset("wallpaper.folder", "file://" + path.split("/").slice(0, -1).join("/") + "/")
        Shell.ipc("wallpaper", "change", [path])
        rev++
        build()
    }

    function applyColor(c) {
        Shell.eset("wallpaper.color", c)
        Shell.eset("wallpaper.path", "")
        Shell.ipc("wallpaper", "change", [c])
        rev++
    }

    function isVideo(p) {
        var e = p.toLowerCase().split("?")[0]
        return e.endsWith(".mp4") || e.endsWith(".webm") || e.endsWith(".mkv") || e.endsWith(".mov")
    }
    function isGif(p) { return p.toLowerCase().split("?")[0].endsWith(".gif") }
    function nameOf(p) { return p.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]/g, " ") }

    function modeOf() { return String(eget("wallpaper.mode", "Still")) }

    Component.onCompleted: {
        build()
        if (Shell.eget("wallpaper.mode", "").toString().length === 0)
            Shell.eset("wallpaper.mode", "Still")
    }

    FileDialog {
        id: addPhotoDlg
        title: "Choose Wallpaper"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.bmp *.gif *.JPG)",
                      "Movies (*.mp4 *.webm *.mov *.mkv)", "All files (*)"]
        onAccepted: {
            var p = selectedFile.toString().replace("file://", "")
            page.apply(p)
        }
    }

    FolderDialog {
        id: addFolderDlg
        title: "Choose Wallpaper Folder"
        onAccepted: {
            var d = selectedFolder.toString().replace("file://", "")
            Shell.eset("wallpaper.folder", d.replace(/\/$/, "") + "/")
            rev++
            page.build()
        }
    }

    Placard {
        iconFile: "sb_wallpaper"
        title: "Wallpaper"
    }

    // ---------------------------------------------------------------- preview
    Item {
        width: parent.width
        height: Math.round(width * 0.44)

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: 12
            color: Theme.dark ? "#101014" : "#e8eaef"
            border.width: 1
            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.12)
            clip: true
        }

        Rectangle {
            anchors.fill: frame
            color: eget("wallpaper.color", "#6967b0")
            opacity: preview.status === Image.Ready || preview.active ? 0
                     : (stillPreview.status === Image.Ready && stillPreview.visible ? 0 : 1)
            Behavior on opacity { NumberAnimation { duration: 260 } }
            HueGradient { anchors.fill: parent }
        }

        AnimatedImage {
            id: preview
            property bool active: page.current.length > 0 && page.isGif(page.current)
            anchors.fill: frame
            anchors.margins: 1
            source: active ? "file://" + page.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: active && status === Image.Ready
            playing: visible
        }

        Video {
            id: vidPreview
            property bool active: page.current.length > 0 && page.isVideo(page.current)
            anchors.fill: frame
            anchors.margins: 1
            source: active ? "file://" + page.current : ""
            fillMode: VideoOutput.PreserveAspectCrop
            visible: active && playbackState === MediaPlayer.PlayingState
            loops: MediaPlayer.Infinite
            autoPlay: active
            muted: true
        }

        Image {
            id: stillPreview
            property bool active: page.current.length > 0 && !page.isGif(page.current) && !page.isVideo(page.current)
            anchors.fill: frame
            anchors.margins: 1
            source: active ? "file://" + page.current : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: active && status === Image.Ready
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 12
            width: nameText.implicitWidth + 20
            height: 24
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.55)

            Text {
                id: nameText
                anchors.centerIn: parent
                text: page.current.length > 0 ? page.nameOf(page.current) : "Choose a Wallpaper"
                font.family: Theme.fontText
                font.pixelSize: 12
                color: "white"
            }
        }
    }

    // ---------------------------------------------------------------- options
    SectionHeader { text: "Wallpaper" }

    Row {
        width: parent.width
        spacing: 12

        GroupCard {
            width: (parent.width - 12) / 2
            height: modeBox.height + 24

            Item {
                id: modeBox
                x: 12
                y: 12
                width: parent.width - 24
                height: 74

                Text {
                    x: 4
                    y: 0
                    text: "Mode"
                    font { family: Theme.fontText; pixelSize: 11 }
                    color: Theme.textSecondary
                }

                Row {
                    x: 4
                    y: 22
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "Dynamic", glyph: "\u25D1" },
                            { label: "Still", glyph: "\u25AD" },
                            { label: "Shuffle", glyph: "\u21C4" },
                            { label: "Video", glyph: "\u25B6" }
                        ]

                        delegate: Rectangle {
                            id: mode
                            required property var modelData
                            width: modeLbl.implicitWidth + 26
                            height: 46
                            radius: 8
                            color: page.modeOf() === mode.modelData.label ? Theme.accent
                                 : Theme.dark ? "#3A3A3C" : "#E9E9EB"
                            border.width: 1
                            border.color: Qt.rgba(0, 0, 0, 0.06)

                            Text {
                                id: modeLbl
                                anchors.centerIn: parent
                                text: mode.modelData.glyph + "  " + mode.modelData.label
                                font { family: Theme.fontText; pixelSize: 12 }
                                color: page.modeOf() === mode.modelData.label ? "white" : Theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Shell.eset("wallpaper.mode", mode.modelData.label)
                                    rev++
                                }
                            }
                        }
                    }
                }
            }
        }

        GroupCard {
            width: (parent.width - 12) / 2
            height: colorBox.height + 24

            Item {
                id: colorBox
                x: 12
                y: 12
                width: parent.width - 24
                height: 74

                Text {
                    x: 4
                    y: 0
                    text: "Colour"
                    font { family: Theme.fontText; pixelSize: 11 }
                    color: Theme.textSecondary
                }

                Flow {
                    x: 4
                    y: 22
                    width: parent.width - 8
                    spacing: 8

                    Repeater {
                        model: {
                            var c = eget("wallpaper.colors", [])
                            var out = []
                            for (var i = 0; i < c.length; i++) {
                                var v = String(c[i])
                                if (v === "add" || v.charAt(0) !== "#")
                                    continue
                                out.push(v)
                            }
                            if (out.length === 0)
                                out = ["#6967B0", "#3E7CB1", "#8AB17D", "#D9A441", "#C46A6A"]
                            return out
                        }

                        delegate: Rectangle {
                            id: swatch
                            required property var modelData
                            width: 34
                            height: 34
                            radius: 17
                            color: modelData
                            border.width: 3
                            border.color: String(eget("wallpaper.path", "")).length === 0
                                          && String(eget("wallpaper.color", "")) === modelData
                                          ? Theme.accent : Qt.rgba(1, 1, 1, 0.30)

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.applyColor(swatch.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    GroupCard {
        DetailRow {
            title: "Show on all Spaces"
            showSwitch: true
            switchOn: eget("wallpaper.allSpaces", true) === true
            onToggled: (c) => { Shell.eset("wallpaper.allSpaces", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show colour on desktop"
            showSwitch: true
            switchOn: eget("wallpaper.desktopEnable", true) === true
            onToggled: (c) => { Shell.eset("wallpaper.desktopEnable", c); Shell.eset("desktopEnable", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Folder"
            pickerOptions: page.folders.map(function (f) { return f.name })
            value: page.folders.length > 0 ? page.folders[Math.min(page.selFolderIdx(), page.folders.length - 1)].name : "\u2014"
            onPicked: (v) => {
                for (var i = 0; i < page.folders.length; i++) {
                    if (page.folders[i].name === v) {
                        Shell.eset("wallpaper.folder", "file://" + page.folders[i].dir + "/")
                        page.build()
                        rev++
                        break
                    }
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8

        MacButton {
            text: "Add Photo\u2026"
            primary: true
            onClicked: addPhotoDlg.open()
        }
        MacButton {
            text: "Add Folder\u2026"
            onClicked: addFolderDlg.open()
        }
    }

    function selFolderIdx() {
        var f = String(eget("wallpaper.folder", "")).replace(/^file:\/\//, "").replace(/\/$/, "")
        for (var i = 0; i < folders.length; i++)
            if (folders[i].dir === f)
                return i
        return 0
    }

    // ---------------------------------------------------------------- strips
    Repeater {
        model: page.sections

        delegate: Column {
            id: sec
            required property var modelData
            required property int index
            width: page.width
            spacing: 6

            Item { width: 1; height: 6 }

            SectionHeader {
                width: parent.width
                suffix: " (" + sec.modelData.files.length + ")"
                buttonLabel: sec.modelData.add ? "Add Photo\u2026" : ""
                onButtonClicked: addPhotoDlg.open()
            }

            GroupCard {
                width: parent.width - 24
                height: sec.modelData.files.length > 0 ? strip.implicitHeight + 24 : 56

                Text {
                    visible: sec.modelData.files.length === 0
                    x: 16
                    y: (parent.height - height) / 2
                    width: parent.width - 32
                    horizontalAlignment: Text.AlignHCenter
                    text: sec.modelData.hint
                    font { family: Theme.fontText; pixelSize: 12 }
                    color: Theme.textSecondary
                }

                Item {
                    id: strip
                    visible: sec.modelData.files.length > 0
                    x: 12
                    y: 12
                    width: parent.width - 24
                    height: 96

                    Flickable {
                        id: flick
                        anchors.fill: parent
                        contentWidth: cells.width
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: cells.width > width
                        flickableDirection: Flickable.HorizontalFlick

                        Row {
                            id: cells
                            spacing: 8
                            height: parent.height

                            Repeater {
                                model: sec.modelData.files

                                delegate: Item {
                                    id: cell
                                    required property var modelData
                                    width: 148
                                    height: 96

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 7
                                        color: Theme.dark ? "#1c1c20" : "#f2f3f6"
                                        clip: true

                                        AnimatedImage {
                                            anchors.fill: parent
                                            source: page.isGif(cell.modelData.path) ? "file://" + cell.modelData.path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(296, 192)
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }
                                        Image {
                                            anchors.fill: parent
                                            source: !page.isGif(cell.modelData.path) && !page.isVideo(cell.modelData.path)
                                                    ? "file://" + cell.modelData.path : ""
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(296, 192)
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }

                                        Rectangle {
                                            visible: page.isVideo(cell.modelData.path)
                                            anchors.centerIn: parent
                                            width: 26
                                            height: 26
                                            radius: 13
                                            color: Qt.rgba(0, 0, 0, 0.55)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "\u25B6"
                                                color: "white"
                                                font.pixelSize: 11
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 7
                                            color: "transparent"
                                            border.width: 2
                                            border.color: page.current === cell.modelData.path
                                                          ? Theme.accent : "transparent"
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: page.apply(cell.modelData.path)
                                    }
                                }
                            }
                        }
                    }

                    Component.onCompleted:
                        console.log("WP_STRIP " + sec.modelData.title
                                   + " files=" + sec.modelData.files.length
                                   + " w=" + width + " h=" + height
                                   + " contentW=" + flick.contentWidth)

                    // right-edge scroll affordance
                    Rectangle {
                        visible: flick.contentWidth > flick.width && flick.atXEnd === false
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 54
                        radius: 13
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                            GradientStop { position: 1.0; color: Theme.dark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.75) }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\u203A"
                            font { pixelSize: 22; bold: true }
                            color: Theme.dark ? "white" : "#333333"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: flick.flick(flick.width, 0)
                        }
                    }
                }
            }
        }
    }

    Item { width: 1; height: 6 }
}
