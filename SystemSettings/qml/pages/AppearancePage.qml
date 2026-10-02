import QtQuick
import QtQuick.Dialogs
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "appearance"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var meta: Pages.info[pageId] || {}

    width: parent ? parent.width : 560
    spacing: 12

    property int rev: 0

    // reactive config readers: touching Shell.userCfg / Shell.eqCfg makes every
    // binding using them re-evaluate when the settings app writes either file.
    function ucfg(k, d) {
        var m = Shell.userCfg
        if (m === null || m === undefined) m = {}
        return Shell.uget(k, d)
    }
    function ecfg(k, d) {
        var m = Shell.eqCfg
        if (m === null || m === undefined) m = {}
        return Shell.eget(k, d)
    }

    function hexOf(c) {
        function h(v) {
            var x = Math.max(0, Math.min(255, Math.round(v * 255))).toString(16)
            return x.length < 2 ? "0" + x : x
        }
        return ("#" + h(c.r) + h(c.g) + h(c.b)).toUpperCase()
    }

    ColorDialog {
        id: tintDlg
        title: "Icon, widget and folder colour"
        selectedColor: String(ucfg("iconTint", "#8E8E93"))
        onAccepted: {
            Shell.uset("iconTint", hexOf(selectedColor))
            rev++
        }
    }

    ColorDialog {
        id: folderDlg
        title: "Folder colour"
        selectedColor: String(ucfg("folderColor", "#3E7CB1"))
        onAccepted: {
            Shell.uset("folderColor", hexOf(selectedColor))
            rev++
        }
    }

    readonly property bool isDark: Theme.dark
    readonly property bool isAuto: ecfg("general.autoDarkMode", false) === true
    readonly property string mode: isAuto ? "auto" : (isDark ? "dark" : "light")
    readonly property string liquidGlass: { rev; return String(ucfg("liquidGlass", "Clear")) }
    readonly property real liquidGlassIntensity: {
        rev;
        var v = Number(ucfg("liquidGlassIntensity", 0.30))
        if (isNaN(v)) v = 0.30
        return Math.max(0, Math.min(1, v))
    }
    readonly property string iconStyle: { rev; return String(ucfg("iconStyle", "Default")) }

    // shell artwork for the Icon & Widget Style thumbnails
    readonly property string qsIcons: "file://" + Shell.shellDir + "/assets/icons/"
    readonly property string weatherTintSlug: {
        rev
        return String(ucfg("iconTint", "#8E8E93")).replace("#", "").toLowerCase()
    }

    function weatherSrc(style) {
        if (style === "Tinted" && weatherTintSlug.length > 0)
            return qsIcons + "tinted/" + weatherTintSlug + "/Weather.png"
        if (style === "Dark")
            return qsIcons + "dark/Weather.png"
        return qsIcons + "light/Weather.png"
    }

    // live value while the Liquid Glass slider is dragged
    property real lgIntensity: liquidGlassIntensity
    onLiquidGlassIntensityChanged: lgIntensity = liquidGlassIntensity

    property string lgWallpaper: ""
    property bool lgWallpaperDone: false

    function lgFill(mode) {
        var i = lgIntensity
        if (mode === "Tinted") {
            var a = Math.min(0.9, 0.34 + i * 0.5)
            return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, a)
        }
        return Qt.rgba(0.07, 0.07, 0.09, Math.min(0.85, 0.06 + i * 0.7))
    }

    function lgApplyIntensity() {
        Shell.uset("liquidGlassIntensity", Number(lgIntensity.toFixed(3)))
    }

    function modeFromNow() {
        var h = new Date().getHours()
        return h >= 19 || h < 7
    }

    function setMode(m) {
        var dark = m === "dark" || (m === "auto" && modeFromNow())
        Shell.uset("darkMode", dark)
        Shell.eset("general.darkMode", dark)
        Shell.eset("general.autoDarkMode", m === "auto")
        Shell.eset("general.reduceMotion", ecfg("general.reduceMotion", false))
    }

    function setAccent(name, hex) {
        Shell.uset("accentColor", hex)
        Shell.eset("appearance.accentColor", hex)
        Shell.eset("appearance.dynamicAccentColor", name === "multicolour")
        Shell.eset("appearance.multiAccentColor", name === "multicolour")
        Shell.uset("appearance.accentName", name)
    }

    function setHighlight(hex) {
        Shell.uset("highlightColor", hex)
        Shell.uset("appearance.highlightName", hex)
    }

    readonly property var accents: [
        { name: "multicolour", label: "Multicolour", hex: "" },
        { name: "blue", label: "Blue", hex: "#0A6CFF" },
        { name: "purple", label: "Purple", hex: "#A550DE" },
        { name: "pink", label: "Pink", hex: "#F43EA5" },
        { name: "orange", label: "Orange", hex: "#F56300" },
        { name: "yellow", label: "Yellow", hex: "#FFCC00" },
        { name: "green", label: "Green", hex: "#62BA46" },
        { name: "red", label: "Red", hex: "#FF3B30" },
        { name: "graphite", label: "Graphite", hex: "#6E6E73" }
    ]

    function currentAccent() {
        return String(ucfg("accentColor", "#0A84FF")).toLowerCase()
    }

    function accentSelected(hex) {
        if (hex.length === 0) {
            var n = String(ucfg("appearance.accentName", ""))
            return n === "multicolour" || (n.length === 0 && currentAccent() === "#0a6cff")
        }
        return currentAccent() === hex.toLowerCase()
    }

    function highlightSelected(hex) {
        return String(ucfg("highlightColor", "#0A6CFF")).toLowerCase() === hex.toLowerCase()
    }

    Timer {
        interval: 60000
        running: page.isAuto
        repeat: true
        onTriggered: page.setMode("auto")
    }

    Component.onCompleted: {
        var p = String(ecfg("wallpaper.path", "") || "")
        if (p.length > 0 && !p.startsWith("file://"))
            p = "file://" + p
        if (p.length > 0) {
            lgWallpaper = p
        } else {
            var folder = String(ecfg("wallpaper.folder", "")).replace(/^file:\/\//, "").replace(/\/$/, "")
            var imgs = Shell.listImages(folder)
            if (imgs.length > 0)
                lgWallpaper = "file://" + imgs[0].path
        }
        lgWallpaperDone = lgWallpaper.length > 0
    }

    Placard {
        iconFile: "sb_dark-mode"
        title: "Appearance"
    }

    // ---------------- appearance thumbnails ----------------
    SectionHeader { text: "Appearance" }

    GroupCard {
        height: thumbRow.implicitHeight + 40

        Row {
            id: thumbRow
            x: (parent.width - width) / 2
            y: 20
            spacing: 26

            Repeater {
                model: [
                    { label: "Light", mode: "light" },
                    { label: "Dark", mode: "dark" },
                    { label: "Auto", mode: "auto" }
                ]

                delegate: Item {
                    id: tile
                    required property var modelData
                    width: 132
                    height: 114

                    Column {
                        width: parent.width
                        spacing: 8

                    Rectangle {
                        id: plate
                        width: 132
                        height: 84
                        radius: 10
                        clip: true
                        color: Theme.dark ? "#151517" : "#ffffff"
                        border.width: page.mode === tile.modelData.mode ? 3 : 1
                        border.color: page.mode === tile.modelData.mode ? Theme.accent : Theme.separator

                        // light half
                        Rectangle {
                            anchors.left: parent.left
                            width: parent.width / 2
                            height: parent.height
                            color: "#F2F2F7"
                            visible: tile.modelData.mode !== "dark"
                        }
                        // dark half
                        Rectangle {
                            anchors.right: parent.right
                            width: parent.width / 2
                            height: parent.height
                            color: "#1C1C1E"
                            visible: tile.modelData.mode !== "light"
                        }

                        // mini window preview
                        Rectangle {
                            anchors.centerIn: parent
                            width: 74
                            height: 50
                            radius: 5
                            color: tile.modelData.mode === "dark" ? "#2C2C2E"
                                 : tile.modelData.mode === "light" ? "#FFFFFF"
                                 : "#8E8E93"
                            border.width: 1
                            border.color: Qt.rgba(0, 0, 0, 0.12)

                            Rectangle {
                                anchors.top: parent.top
                                width: parent.width
                                height: 12
                                color: Qt.rgba(0, 0, 0, 0.08)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Repeater {
                                        model: 3
                                        delegate: Rectangle {
                                            required property int index
                                            width: 5
                                            height: 5
                                            radius: 2.5
                                            color: ["#FF5F57", "#FEBC2E", "#28C840"][index]
                                        }
                                    }
                                }
                            }
                        }

                        // selection badge
                        Rectangle {
                            visible: page.mode === tile.modelData.mode
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            width: 18
                            height: 18
                            radius: 9
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "\u2713"
                                font.pixelSize: 11
                                font.bold: true
                                color: "white"
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: tile.modelData.label
                        font { family: Theme.fontText; pixelSize: 12 }
                        color: Theme.textPrimary
                    }

                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.setMode(tile.modelData.mode)
                    }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    // ---------------- accent colour ----------------
    SectionHeader { text: "Accent Colour" }

    GroupCard {
        height: accRow.implicitHeight + 40

        Row {
            id: accRow
            x: (parent.width - width) / 2
            y: 20
            spacing: 14

            Repeater {
                model: page.accents

                delegate: Item {
                    id: sw
                    required property var modelData
                    width: 34
                    height: 54

                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 34
                        height: 34
                        radius: 17
                        color: sw.modelData.hex.length > 0 ? sw.modelData.hex : "transparent"
                        border.width: 2
                        border.color: sw.modelData.hex.length > 0
                                      ? (page.accentSelected(sw.modelData.hex) ? Theme.accent : Qt.rgba(1,1,1,0.14))
                                      : "transparent"

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: sw.modelData.hex.length === 0
                            source: Theme.icon("dt_accent-" + sw.modelData.name, 32)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Rectangle {
                            visible: page.accentSelected(sw.modelData.hex)
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.accent
                            border.width: 2
                            border.color: Theme.dark ? "#2C2C2E" : "#FFFFFF"

                            Text {
                                anchors.centerIn: parent
                                text: "\u2713"
                                font.pixelSize: 8
                                font.bold: true
                                color: "white"
                            }
                        }
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 38
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: sw.modelData.label
                        font { family: Theme.fontText; pixelSize: 9 }
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.setAccent(sw.modelData.name, sw.modelData.hex.length > 0 ? sw.modelData.hex : "#315BDC")
                    }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    // ---------------- highlight colour ----------------
    SectionHeader { text: "Text Highlight Colour" }

    GroupCard {
        height: hlRow.implicitHeight + 40

        Row {
            id: hlRow
            x: (parent.width - width) / 2
            y: 20
            spacing: 14

            Repeater {
                model: page.accents

                delegate: Item {
                    id: hl
                    required property var modelData
                    width: 34
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: 17
                        color: hl.modelData.hex.length > 0 ? hl.modelData.hex : "transparent"
                        border.width: page.highlightSelected(hl.modelData.hex) && hl.modelData.hex.length > 0 ? 3 : 1
                        border.color: page.highlightSelected(hl.modelData.hex) && hl.modelData.hex.length > 0
                                      ? Theme.textPrimary : Qt.rgba(1, 1, 1, 0.14)

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: hl.modelData.hex.length === 0
                            source: Theme.icon("dt_accent-" + hl.modelData.name, 32)
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (hl.modelData.hex.length > 0)
                                page.setHighlight(hl.modelData.hex)
                        }
                    }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    // ---------------- liquid glass ----------------
    SectionHeader { text: "Liquid Glass" }

    GroupCard {
        height: lgBox.height + 24

        Item {
            id: lgBox
            x: 12
            y: 12
            width: parent.width - 24
            height: 206

            // ---- live preview: wallpaper with liquid-glass widgets ----
            Item {
                id: lgPreview
                x: 6
                y: 6
                width: 248
                height: 156

                Rectangle {
                    id: lgPlate
                    anchors.fill: parent
                    radius: 14
                    clip: true
                    color: "#0d0d10"

                    Image {
                        anchors.fill: parent
                        source: page.lgWallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    // caption
                    Column {
                        x: 14
                        y: parent.height - 44
                        spacing: 2

                        Text {
                            text: "Apple Park"
                            font { family: Theme.fontText; pixelSize: 13; bold: true }
                            color: "#ffffff"
                        }
                        Text {
                            text: "احصل على دليل الزائر"
                            font { family: Theme.fontText; pixelSize: 10 }
                            color: Qt.rgba(1, 1, 1, 0.75)
                        }
                    }

                    // glass search pill (follows the Liquid Glass setting)
                    Rectangle {
                        id: lgPill
                        x: 14
                        y: 14
                        width: 104
                        height: 30
                        radius: 15
                        color: page.lgFill(page.liquidGlass)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.35)

                        Text {
                            x: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: "بحث"
                            font { family: Theme.fontText; pixelSize: 12 }
                            color: "#ffffff"
                        }

                        Rectangle {
                            x: parent.width - 27
                            y: 8
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "transparent"
                            border.width: 2
                            border.color: Qt.rgba(1, 1, 1, 0.9)
                        }
                        Rectangle {
                            x: parent.width - 15
                            y: 20
                            width: 8
                            height: 2
                            radius: 1
                            color: Qt.rgba(1, 1, 1, 0.9)
                            rotation: 45
                        }
                    }

                    // glass capsule with round buttons
                    Rectangle {
                        id: lgCap
                        x: 128
                        y: 14
                        width: 106
                        height: 30
                        radius: 15
                        color: page.lgFill(page.liquidGlass)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.35)

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Repeater {
                                model: 3

                                delegate: Rectangle {
                                    id: glassBtn
                                    required property int index
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.30)

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: glassBtn.index === 0
                                        width: 12
                                        height: 10
                                        radius: 2
                                        color: Qt.rgba(1, 1, 1, 0.92)
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: glassBtn.index === 1
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Qt.rgba(1, 1, 1, 0.92)
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: glassBtn.index === 2
                                        width: 10
                                        height: 9
                                        radius: 2
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Qt.rgba(1, 1, 1, 0.92)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- intensity slider (left glyph, track, right glyph) ----
            Item {
                id: lgSliderRow
                x: 6
                y: lgPreview.y + lgPreview.height + 10
                width: 248
                height: 24

                Rectangle {
                    x: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 13
                    radius: 6.5
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.textSecondary
                }

                MacSlider {
                    id: lgSlider
                    x: 26
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 52
                    from: 0
                    to: 1
                    value: page.lgIntensity
                    onMoved: (v) => {
                        page.lgIntensity = v
                        lgWrite.restart()
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 16
                    radius: 3
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.textSecondary
                }

                Timer {
                    id: lgWrite
                    interval: 260
                    onTriggered: page.lgApplyIntensity()
                }
            }

            // ---- title + description + Clear / Tinted ----
            Text {
                x: 272
                y: 8
                text: "Liquid Glass"
                font { family: Theme.fontText; pixelSize: 14; bold: true }
                color: Theme.textPrimary
            }

            Text {
                id: lgDesc
                x: 272
                y: 32
                width: Math.max(140, lgBox.width - 276)
                wrapMode: Text.WordWrap
                text: page.liquidGlass === "Tinted"
                      ? "Tinted: Liquid Glass surfaces take on your accent colour."
                      : "Clear: the default Liquid Glass material. Drag the slider to change how solid the glass is."
                font { family: Theme.fontText; pixelSize: 12 }
                color: Theme.textSecondary
            }

            Row {
                id: lgCards
                x: 272
                y: 96
                spacing: 10

                Repeater {
                    model: [
                        { label: "Clear", hint: "Translucent" },
                        { label: "Tinted", hint: "Accent" }
                    ]

                    delegate: Rectangle {
                        id: glass
                        required property var modelData
                        width: 140
                        height: 76
                        radius: 10
                        clip: true
                        color: Theme.dark ? "#1c1c20" : "#f2f3f6"
                        border.width: page.liquidGlass === glass.modelData.label ? 3 : 1
                        border.color: page.liquidGlass === glass.modelData.label ? Theme.accent : Theme.separator

                        Rectangle {
                            x: 10
                            y: 8
                            width: parent.width - 20
                            height: 38
                            radius: 7
                            color: glass.modelData.label === "Tinted"
                                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b,
                                             Theme.dark ? 0.75 : 0.45)
                                   : Qt.rgba(0, 0, 0, Theme.dark ? 0.40 : 0.10)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, Theme.dark ? 0.22 : 0.6)

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 26
                                height: 15
                                radius: 7.5
                                color: Qt.rgba(1, 1, 1, glass.modelData.label === "Tinted" ? 0.22 : 0.5)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.55)
                            }
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 7
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: glass.modelData.label
                            font { family: Theme.fontText; pixelSize: 11; bold: true }
                            color: Theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Shell.uset("liquidGlass", glass.modelData.label)
                                rev++
                            }
                        }
                    }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    // ---------------- icon & widget style ----------------
    SectionHeader { text: "Icon & Widget Style" }

    GroupCard {
        height: styleBox.height + 24

        Item {
            id: styleBox
            x: 12
            y: 12
            width: parent.width - 24
            height: 104

            Row {
                x: 4
                y: 4
                spacing: 16

                Repeater {
                    model: [
                        { label: "Default", hint: "Original icon artwork." },
                        { label: "Dark", hint: "Dark icon backgrounds." },
                        { label: "Clear", hint: "Translucent liquid-glass icons." },
                        { label: "Tinted", hint: "Icons use one colour." }
                    ]

                    delegate: Item {
                        id: st
                        required property var modelData
                        width: 78
                        height: 104

                        Column {
                            width: parent.width
                            spacing: 6

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 62
                            height: 62
                            radius: 15
                            color: st.modelData.label === "Default"
                                   ? Qt.rgba(0.16, 0.48, 0.95, 1)
                                   : st.modelData.label === "Dark"
                                   ? (Theme.dark ? "#2c2c2e" : "#1c1c1e")
                                   : st.modelData.label === "Clear"
                                   ? Qt.rgba(Theme.dark ? 1 : 0, Theme.dark ? 1 : 0, Theme.dark ? 1 : 0, 0.14)
                                   : (String(ucfg("iconTint", "#8E8E93")))
                            border.width: page.iconStyle === st.modelData.label ? 3 : 1
                            border.color: page.iconStyle === st.modelData.label ? Theme.accent
                                          : Qt.rgba(1, 1, 1, Theme.dark ? 0.22 : 0.45)
                            opacity: st.modelData.label === "Clear" ? 0.9 : 1

                            // same artwork in every style: the Weather icon,
                            // rendered the way the chosen style renders it
                            Image {
                                anchors.centerIn: parent
                                width: 46
                                height: 46
                                property string baseSrc: page.qsIcons + "light/Weather.png"
                                property string effSrc: page.weatherSrc(st.modelData.label)
                                source: effSrc
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                opacity: st.modelData.label === "Clear" ? 0.55 : 1
                                onStatusChanged: {
                                    if (status === Image.Error && effSrc !== baseSrc)
                                        effSrc = baseSrc
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: st.modelData.label
                            font { family: Theme.fontText; pixelSize: 11 }
                            color: Theme.textPrimary
                        }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Shell.uset("iconStyle", st.modelData.label)
                                rev++
                            }
                        }
                    }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    GroupCard {
        DetailRow {
            title: "Always / Auto"
            subtitle: "Auto follows the light appearance for Dark style."
            pickerOptions: ["Always", "Auto"]
            value: String(ucfg("iconStyleMode", "Always"))
            onPicked: (v) => { Shell.uset("iconStyleMode", v); rev++ }
        }
        DetailRow {
            separator: true
            visible: page.iconStyle === "Tinted"
            title: "Icon, widget and folder colour"
            value: String(ucfg("iconTint", "#8E8E93"))
            pickerOptions: ["#8E8E93", "#0A6CFF", "#A550DE", "#F43EA5", "#F56300",
                            "#FFCC00", "#62BA46", "#FF3B30", "#315BDC", "Custom Colour\u2026"]
            onPicked: (v) => {
                if (v.indexOf("Custom") === 0)
                    tintDlg.open()
                else
                    Shell.uset("iconTint", v)
                rev++
            }
        }
        DetailRow {
            separator: true
            visible: page.iconStyle !== "Tinted"
            title: "Folder colour"
            value: String(ucfg("folderColor", ""))
            pickerOptions: ["", "#3E7CB1", "#62BA46", "#F56300", "#FF3B30",
                            "#A550DE", "#F43EA5", "#6E6E73", "Custom Colour\u2026"]
            onPicked: (v) => {
                if (v.indexOf("Custom") === 0)
                    folderDlg.open()
                else
                    Shell.uset("folderColor", v)
                rev++
            }
        }
    }

    Item { width: 1; height: 4 }

    // ---------------- sidebar ----------------
    SectionHeader { text: "Sidebar" }

    GroupCard {
        DetailRow {
            title: "Sidebar icon size"
            pickerOptions: ["Small", "Medium", "Large"]
            value: String(ucfg("appearance.sidebarIconSize", "Medium"))
            onPicked: (v) => { Shell.uset("appearance.sidebarIconSize", v); Shell.eset("appearance.sidebarIconSize", v) }
        }
        DetailRow {
            separator: true
            title: "Allow wallpaper tinting in windows"
            showSwitch: true
            switchOn: ucfg("appearance.wallpaperTinting", true) === true
            onToggled: (c) => { Shell.uset("appearance.wallpaperTinting", c); Shell.eset("appearance.wallpaperTinting", c) }
        }
    }

    Item { width: 1; height: 4 }

    // ---------------- scroll bars ----------------
    SectionHeader { text: "Scroll Bars" }

    GroupCard {
        DetailRow {
            title: "Show scroll bars"
            pickerOptions: ["Automatically based on mouse or trackpad", "When scrolling", "Always"]
            value: String(ucfg("appearance.scrollBars", "Automatically based on mouse or trackpad"))
            onPicked: (v) => { Shell.uset("appearance.scrollBars", v); Shell.eset("appearance.scrollBars", v) }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Reduce Motion" }

    GroupCard {
        DetailRow {
            title: "Reduce motion"
            subtitle: "Reduce the motion of the user interface"
            showSwitch: true
            switchOn: ecfg("general.reduceMotion", false) === true
            onToggled: (c) => { Shell.eset("general.reduceMotion", c); Shell.uset("reduceMotion", c) }
        }
    }

    Item { width: 1; height: 6 }
}
