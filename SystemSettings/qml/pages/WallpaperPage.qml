import QtQuick
import QtQuick.Effects
import ".."

// Wallpaper (macOS 27, Wallpaper.appex). The desktop picture is drawn by
// awww: the current one comes from `awww query`, a click applies it with a
// fade and also tells the shell (eqsh wallpaper IPC) and the config.
Column {
    id: page

    property string pageId: "wallpaper"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0
    function ug(k, d) { bumpU; rev; return Shell.uget(k, d) }
    function us(k, v) { Shell.uset(k, v); rev++ }

    width: parent ? parent.width : 640
    spacing: 12

    property string current: ""
    property var groups: []          // [{ title, dir, items }]
    property var expanded: ({})
    readonly property var colors: ["#1C1C1E", "#3A3A3C", "#8E8E93", "#E5E5EA", "#0A84FF", "#5E5CE6",
                                   "#BF5AF2", "#FF375F", "#FF453A", "#FF9F0A", "#FFD60A", "#30D158",
                                   "#64D2FF", "#2C3E50", "#7D5A50"]

    function load() {
        const q = Shell.execOut("awww query 2>/dev/null | head -1", 2000)
        const m = q.match(/image:\s*(.+)$/)
        current = m ? m[1].trim() : String(Shell.eget("wallpaper.path", ""))
        const dirs = [{ title: "Wallpapers", dir: HOME_DIR + "/.config/wallpapers" },
                      { title: "Pictures", dir: HOME_DIR + "/Pictures/Wallpapers" }]
        const extra = ug("wallpaper.folders", [])
        for (let i = 0; i < (extra || []).length; i++)
            dirs.push({ title: String(extra[i]).split("/").pop(), dir: extra[i] })
        const out = []
        for (const d of dirs) {
            const items = Shell.listImages(d.dir).filter(x => !x.animated)
            if (items.length) out.push({ title: d.title, dir: d.dir, items: items })
        }
        groups = out
    }
    Component.onCompleted: load()

    function apply(path) {
        Shell.run("awww img --transition-type fade --transition-duration 0.8 " + JSON.stringify(path) + " >/dev/null 2>&1")
        Shell.eset("wallpaper.path", path)
        Shell.ipc("wallpaper", "change", [path])
        current = path
    }
    function applyColor(c) {
        Shell.run("awww clear " + c.replace("#", "") + " >/dev/null 2>&1")
        Shell.eset("wallpaper.color", c)
        current = c
    }
    function nameOf(p) {
        if (!p) return "Wallpaper"
        if (p.charAt(0) === "#") return "Color"
        return p.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
    }

    component Thumb: Item {
        id: th
        property string src: ""
        property bool selected: false
        signal picked
        width: 80; height: 50
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 10
            color: "transparent"
            border.width: 2.5
            border.color: Theme.accent
            visible: th.selected
        }
        Image {
            id: img
            anchors.fill: parent
            source: th.src ? "file://" + th.src : ""
            sourceSize.width: 200
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        Rectangle { id: mask; anchors.fill: parent; radius: 7; visible: false; layer.enabled: true }
        MultiEffect {
            anchors.fill: img
            source: img
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
        Rectangle {
            anchors.fill: parent; radius: 7; color: "transparent"
            border.width: 1; border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)
        }
        MouseArea { anchors.fill: parent; onClicked: th.picked() }
    }

    // -------------------------------------------------------- current
    Rectangle {
        x: Theme.cardMargin
        width: parent.width - 2 * Theme.cardMargin
        height: 132
        radius: Theme.cardRadius
        color: Theme.cardBg
        border.width: 1
        border.color: Theme.cardStroke

        Item {
            id: big
            x: 16; anchors.verticalCenter: parent.verticalCenter
            width: 160; height: 100
            Rectangle {
                anchors.fill: parent; radius: 9
                color: page.current.charAt(0) === "#" ? page.current : "transparent"
            }
            Image {
                id: bigImg
                anchors.fill: parent
                source: page.current && page.current.charAt(0) !== "#" ? "file://" + page.current : ""
                sourceSize.width: 400
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            Rectangle { id: bigMask; anchors.fill: parent; radius: 9; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: bigImg; source: bigImg
                maskEnabled: true; maskSource: bigMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
            }
            // the large lock-screen clock, as previewed on macOS 27
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14
                visible: String(page.ug("wallpaper.largeClock", "On Screen Saver and Lock Screen")) !== "Never"
                text: Qt.formatTime(new Date(), "h:mm")
                font.family: Theme.fontDisplay; font.pixelSize: 26; font.weight: Font.DemiBold
                color: "white"; opacity: 0.92
                style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.25)
            }
        }
        Column {
            anchors.left: big.right; anchors.leftMargin: 16
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
                width: parent.width; elide: Text.ElideRight
                text: page.nameOf(page.current)
                font.family: Theme.fontText; font.pixelSize: 15; font.weight: Font.DemiBold; color: Theme.textPrimary
            }
            Text {
                text: page.current.charAt(0) === "#" ? "Color" : "Picture"
                font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
            }
        }
    }

    GroupCard {
        DetailRow {
            title: "Show on all Spaces"
            showSwitch: true
            switchOn: page.ug("wallpaper.allSpaces", true) === true
            onToggled: (c) => page.us("wallpaper.allSpaces", c)
        }
        DetailRow {
            separator: true
            title: "Show large clock"
            pickerOptions: ["On Screen Saver and Lock Screen", "On Lock Screen", "Never"]
            value: String(page.ug("wallpaper.largeClock", "On Screen Saver and Lock Screen"))
            onPicked: (v) => page.us("wallpaper.largeClock", v)
        }
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.cardMargin
        spacing: 8
        MacButton { text: "Clock Appearance…"; onClicked: page.navigate("lockScreen") }
        MacButton { text: "Screen Saver…"; onClicked: page.navigate("lockScreen") }
    }

    // --------------------------------------------------------- groups
    Repeater {
        model: page.groups
        delegate: Column {
            id: grp
            required property var modelData
            readonly property bool open: page.expanded[modelData.dir] === true
            readonly property int cols: 5
            width: page.width
            spacing: 8

            Item {
                width: parent.width; height: 26
                Text {
                    x: Theme.cardMargin + 4; anchors.verticalCenter: parent.verticalCenter
                    text: grp.modelData.title
                    font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.textPrimary
                }
                MacButton {
                    anchors.right: parent.right; anchors.rightMargin: Theme.cardMargin
                    anchors.verticalCenter: parent.verticalCenter
                    visible: grp.modelData.items.length > grp.cols
                    text: grp.open ? "Show Less" : "Show All (" + grp.modelData.items.length + ")"
                    onClicked: { const e = Object.assign({}, page.expanded); e[grp.modelData.dir] = !grp.open; page.expanded = e }
                }
            }
            Grid {
                x: Theme.cardMargin + 4
                columns: grp.cols
                readonly property real cellW: (page.width - 2 * (Theme.cardMargin + 4) - (grp.cols - 1) * 12) / grp.cols
                columnSpacing: 12; rowSpacing: 12
                Repeater {
                    model: grp.open ? grp.modelData.items : grp.modelData.items.slice(0, grp.cols)
                    delegate: Thumb {
                        required property var modelData
                        width: parent.cellW
                        height: Math.round(parent.cellW * 10 / 16)
                        src: modelData.path
                        selected: modelData.path === page.current
                        onPicked: page.apply(modelData.path)
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- colors
    Item {
        width: parent.width; height: 26
        Text {
            x: Theme.cardMargin + 4; anchors.verticalCenter: parent.verticalCenter
            text: "Colors"
            font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.textPrimary
        }
    }
    Grid {
        x: Theme.cardMargin + 4
        columns: 5
        readonly property real cellW: (page.width - 2 * (Theme.cardMargin + 4) - 4 * 12) / 5
        columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: page.colors
            delegate: Item {
                required property var modelData
                width: parent.cellW; height: Math.round(parent.cellW * 10 / 16)
                Rectangle {
                    anchors.fill: parent; anchors.margins: -3; radius: 10; color: "transparent"
                    border.width: 2.5; border.color: Theme.accent
                    visible: page.current.toUpperCase() === modelData.toUpperCase()
                }
                Rectangle {
                    anchors.fill: parent; radius: 7; color: modelData
                    border.width: 1; border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)
                }
                MouseArea { anchors.fill: parent; onClicked: page.applyColor(modelData) }
            }
        }
    }

    Item { width: 1; height: 2 }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.cardMargin
        spacing: 8
        MacButton {
            text: "Add Photo…"
            onClicked: {
                const f = Shell.execOut("zenity --file-selection --title='Add Photo' --file-filter='Images | *.png *.jpg *.jpeg *.webp *.heic' 2>/dev/null", 600000).trim()
                if (f) page.apply(f)
            }
        }
        MacButton {
            text: "Choose Folder…"
            onClicked: {
                const d = Shell.execOut("zenity --file-selection --directory --title='Choose Folder' 2>/dev/null", 600000).trim()
                if (d) {
                    const list = (page.ug("wallpaper.folders", []) || []).slice()
                    if (list.indexOf(d) < 0) list.push(d)
                    page.us("wallpaper.folders", list)
                    page.load()
                }
            }
        }
    }
    Item { width: 1; height: 6 }
}
