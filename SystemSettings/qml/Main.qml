import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import QtCore
import "Pages.js" as Pages
import "PagesContent.js" as Content

ApplicationWindow {
    id: root

    width: 715
    // --shot-height=N: taller window for --shot renders of long pages
    height: {
        var a = Qt.application.arguments
        for (var i = 0; i < a.length; i++)
            if (a[i].indexOf("--shot-height=") === 0) return parseInt(a[i].substring(14))
        return 700
    }
    minimumWidth: 640
    minimumHeight: 480
    visible: true
    title: "System Settings"
    // Transparent: the frame below is drawn by us so the sidebar can be real
    // glass (the compositor blur shows through it) and corners match Tahoe.
    color: "transparent"

    property string selectedId: lastPane.id.length > 0 ? lastPane.id : "general"
    // hardware presence decides which panes macOS shows (Battery vs Energy,
    // Mouse, Trackpad) — same predicates as the representations in the
    // extensions' Info.plist (powersource.battery, device.mouse, device.trackpad)
    readonly property bool hasBattery: Shell.execOut("ls /sys/class/power_supply 2>/dev/null | grep -c '^BAT'", 800) !== "0"
    readonly property bool hasTrackpad: Shell.execOut("grep -ci touchpad /proc/bus/input/devices", 800) !== "0"
    readonly property bool hasMouse: Shell.execOut("hyprctl devices -j 2>/dev/null | python3 -c \"import json,sys,re;d=json.load(sys.stdin);print(sum(1 for m in d.get('mice',[]) if not re.search('touchpad|consumer-control|syna|elan|trackpoint|ps/2',m['name'],re.I)))\"", 1500) !== "0"
    onSelectedIdChanged: if (shotIds.length === 0 && !testMode) lastPane.id = selectedId

    // --test-pages: cycle through every page and print QML errors, then exit
    readonly property bool testMode: Qt.application.arguments.join(" ").indexOf("--test-pages") >= 0
    property var testList: []
    property int testIdx: 0

    // --shot=<id[>sub],...> --shot-dir=<dir>: render each page to <dir>/<id>.png and exit
    readonly property var shotIds: {
        var a = Qt.application.arguments
        for (var i = 0; i < a.length; i++)
            if (a[i].indexOf("--shot=") === 0)
                return a[i].substring(7).split(",")
        return []
    }
    readonly property string shotDir: {
        var a = Qt.application.arguments
        for (var i = 0; i < a.length; i++)
            if (a[i].indexOf("--shot-dir=") === 0)
                return a[i].substring(11)
        return "/tmp"
    }
    property int shotIdx: 0

    function openShot(spec) {
        var parts = spec.split(">")
        root.selectedId = parts[0]
        if (parts.length > 1)
            detailPane.open(parts[1])
    }

    Timer {
        id: shotTimer
        interval: 1400
        repeat: false
        onTriggered: {
            var id = root.shotIds[root.shotIdx].replace(/>/g, "_")
            shotRoot.grabToImage(function (r) {
                r.saveToFile(root.shotDir + "/" + id + ".png")
                console.log("SHOT", id)
                root.shotIdx++
                if (root.shotIdx >= root.shotIds.length) {
                    Qt.quit()
                    return
                }
                root.openShot(root.shotIds[root.shotIdx])
                shotTimer.start()
            })
        }
    }

    Component.onCompleted: {
        if (shotIds.length > 0) {
            openShot(shotIds[0])
            shotTimer.start()
            return
        }
        if (!testMode)
            return
        var all = Pages.roots.slice()
        for (var k in Content.content)
            if (all.indexOf(k) < 0)
                all.push(k)
        testList = all
        testTimer.start()
    }

    Timer {
        id: testTimer
        interval: 650
        repeat: true
        onTriggered: {
            if (root.testIdx >= root.testList.length) {
                console.log("TEST_PAGES_DONE", root.testList.length)
                Qt.quit()
                return
            }
            var id = root.testList[root.testIdx++]
            console.log("TEST_PAGE_BEGIN", id)
            root.selectedId = id
        }
    }

    Settings {
        id: accountStore
        category: "account"
        property string email: ""
        property string name: ""
    }

    Settings {
        id: lastPane
        category: "window"
        property string id: ""
    }

    font.family: Theme.fontText
    font.pixelSize: 13

    Item {
        id: shotRoot
        anchors.fill: parent

        // screenshot mode only: emulate the compositor blur behind the window
        Image {
            id: shotWall
            anchors.fill: parent
            visible: false
            fillMode: Image.PreserveAspectCrop
            source: root.shotIds.length > 0 ? "file://" + String(Shell.eget("wallpaper.path", "")) : ""
        }
        MultiEffect {
            anchors.fill: parent
            visible: root.shotIds.length > 0
            source: shotWall
            blurEnabled: true
            blur: 1.0
            blurMax: 64
        }

        // ---- Window frame: rounded window minus the floating sidebar -------
        Shape {
            id: frame
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            readonly property real wr: Theme.windowRadius
            readonly property real sx: Theme.sidebarInset
            readonly property real sy: Theme.sidebarInset
            readonly property real sw: sidebar.width
            readonly property real sh: height - 2 * Theme.sidebarInset
            readonly property real sr: Theme.sidebarRadius

            ShapePath {
                fillColor: Theme.windowBg
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill

                // outer window outline
                PathRectangle {
                    x: 0; y: 0
                    width: frame.width; height: frame.height
                    radius: frame.wr
                }
                // hole for the glass sidebar
                PathRectangle {
                    x: frame.sx; y: frame.sy
                    width: frame.sw; height: frame.sh
                    radius: frame.sr
                }
            }
        }

        // hairline window stroke (Tahoe windows have a faint 1px rim)
        Rectangle {
            anchors.fill: parent
            radius: Theme.windowRadius
            color: "transparent"
            border.width: 1
            border.color: Theme.windowStroke
        }

        // ---- Floating Liquid Glass sidebar --------------------------------
        Sidebar {
            id: sidebar
            x: Theme.sidebarInset
            y: Theme.sidebarInset
            width: Theme.sidebarWidth - Theme.sidebarInset
            height: parent.height - 2 * Theme.sidebarInset
            selectedId: root.selectedId
            hasBattery: root.hasBattery
            hasMouse: root.hasMouse
            hasTrackpad: root.hasTrackpad
            signedIn: accountStore.email.length > 0
            accountName: accountStore.name
            onSelect: (id) => root.selectedId = id
            onSignIn: root.selectedId = "appleId"
            onDragWindow: root.startSystemMove()
        }

        DetailPane {
            id: detailPane
            x: Theme.sidebarWidth
            y: 0
            width: parent.width - Theme.sidebarWidth
            height: parent.height
            selectedId: root.selectedId
            accountName: accountStore.name
            accountEmail: accountStore.email
            onSignedIn: (email, name) => {
                accountStore.email = email
                accountStore.name = name
            }
            onSignedOut: {
                accountStore.email = ""
                accountStore.name = ""
            }
            onDragWindow: root.startSystemMove()
        }

        // ---- Traffic lights (inside the sidebar, Tahoe placement) ---------
        Row {
            id: lights
            x: Theme.sidebarInset + 12
            y: Theme.sidebarInset + 12
            spacing: 8
            z: 10

            property bool hovered: lightsHover.hovered
            HoverHandler { id: lightsHover }

            Repeater {
                model: [
                    { c: "#FF5F57", ring: "#E0443E", glyph: "close" },
                    { c: "#FEBC2E", ring: "#DEA123", glyph: "min" },
                    { c: "#28C840", ring: "#1AAB29", glyph: "zoom" }
                ]

                delegate: Rectangle {
                    id: light
                    required property var modelData
                    required property int index
                    width: 14
                    height: 14
                    radius: 7
                    color: root.active || lights.hovered ? modelData.c : (Theme.dark ? "#4A4A4C" : "#D4D4D6")
                    border.color: root.active || lights.hovered ? modelData.ring : (Theme.dark ? "#555557" : "#C6C6C8")
                    border.width: 0.5

                    Canvas {
                        anchors.fill: parent
                        visible: lights.hovered
                        onVisibleChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = "rgba(0,0,0,0.55)"
                            ctx.fillStyle = "rgba(0,0,0,0.55)"
                            ctx.lineWidth = 1.2
                            ctx.lineCap = "round"
                            var g = light.modelData.glyph
                            if (g === "close") {
                                ctx.beginPath(); ctx.moveTo(4.5, 4.5); ctx.lineTo(9.5, 9.5)
                                ctx.moveTo(9.5, 4.5); ctx.lineTo(4.5, 9.5); ctx.stroke()
                            } else if (g === "min") {
                                ctx.beginPath(); ctx.moveTo(3.8, 7); ctx.lineTo(10.2, 7); ctx.stroke()
                            } else {
                                ctx.beginPath(); ctx.moveTo(4, 4); ctx.lineTo(8.6, 4); ctx.lineTo(4, 8.6); ctx.closePath(); ctx.fill()
                                ctx.beginPath(); ctx.moveTo(10, 10); ctx.lineTo(5.4, 10); ctx.lineTo(10, 5.4); ctx.closePath(); ctx.fill()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (light.index === 0)
                                Qt.quit()
                            else if (light.index === 1)
                                Shell.run("/usr/bin/python3 " + HOME_DIR + "/.config/hypr/scripts/minimize_window.py min >/dev/null 2>&1")
                            else
                                Shell.run("hyprctl dispatch fullscreen 1 >/dev/null 2>&1")
                        }
                    }
                }
            }
        }
    }
}
