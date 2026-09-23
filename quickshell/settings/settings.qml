import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Io

Window {
    id: win
    visible: true
    width: 1010
    height: 720
    minimumWidth: 780
    minimumHeight: 540
    title: "System Settings"
    color: bg

    FontLoader { id: sf; source: "file:///home/revo/.config/quickshell/settings/assets/fonts/SFNS.ttf" }
    FontLoader { id: sfr; source: "file:///home/revo/.config/quickshell/settings/assets/fonts/SFNSRounded.ttf" }
    readonly property string fnt: sf.name
    readonly property string fntR: sfr.name

    // ---- live config (shared with the macos shell) ----
    property var cfg: ({})
    FileView {
        id: cfgFile
        path: "file:///home/revo/.config/quickshell/macos/userconfig.json"
        onLoaded: (file) => { try { cfg = JSON.parse(file.text) } catch (e) { cfg = {} } }
    }
    Process { id: writer; running: false }
    function set(k, v) {
        writer.command = ["python3", "/home/revo/.config/quickshell/macos/scripts/setcfg.py", k, JSON.stringify(v)]
        writer.running = true
    }
    function val(key) {
        if (!cfg) return undefined
        var parts = String(key).split("."); var cur = cfg
        for (var i = 0; i < parts.length; i++) { if (cur === undefined || cur === null) return undefined; cur = cur[parts[i]] }
        return cur
    }

    // ---- palette (macOS system colors) ----
    readonly property bool isDark: cfg && cfg.darkMode === true
    readonly property color bg: isDark ? "#1e1e1e" : "#ffffff"
    readonly property color sideBg: isDark ? "#2a2a2e" : "#f5f5f7"
    readonly property color text: isDark ? "#f5f5f7" : "#1d1d1f"
    readonly property color sub: isDark ? "#98989d" : "#86868b"
    readonly property color cardBg: isDark ? "#2c2c2e" : "#ffffff"
    readonly property color cardBorder: isDark ? "#3a3a3c" : "#e3e3e8"
    readonly property color sep: isDark ? "#3a3a3c" : "#d2d2d7"
    readonly property color hover: isDark ? "#3a3a3e" : "#e8e8ed"
    readonly property color toggleOn: "#34c759"
    readonly property color accentCol: (cfg && cfg.accentColor) ? cfg.accentColor : (isDark ? "#0a84ff" : "#007aff")
    readonly property string icondir: "file:///home/revo/.config/quickshell/settings/assets/icons/"

    property var iconPool: [
        "icon__0109_0_512.png","icon_2x.png_0109_4_32.png","icon_2x.png_0109_5_256.png",
        "icon_2x.png_0109_6_256.png","icon_2x.png_0109_7_256.png","icon_2x.png_0109_20_256.png",
        "icon_icon_256x256.png_0109_8_64.png","icon_icon_256x256.png_0109_9_64.png",
        "icon_icon_256x256.png_0109_10_64.png","icon_icon_256x256.png_0109_14_128.png",
        "icon_icon_256x256.png_0109_15_128.png","icon_icon_256x256.png_0109_16_128.png",
        "icon__0109_21_256.png","icon__0109_24_256.png","icon__0110_16_512.png",
        "icon__0059_4_32.png","icon__0063_3_256.png",
        "icon_NSAppearanceNameAqua_0059_1_64.png","icon_NSAppearanceNameAqua_0059_2_32.png",
        "icon_NSAppearanceNameAqua_0059_3_32.png","icon_dlg_icloud_0063_6_32.png",
        "icon_dlg_icloud_0063_7_32.png","icon_dlg_icloud_0063_8_64.png",
        "icon_dlg_icloud_0083_12_64.png","icon_SystemSettings1024x1024_NSAppearanceName_0109_29_128.png",
        "icon_SystemSettings1024x1024_NSAppearanceName_0109_30_512.png"
    ]
    function iconFor(id) {
        var aa = { appleid:1, family:1, wifi:1, bluetooth:1, network:1, vpn:1, general:1,
                   notifications:1, sound:1, lockscreen:1, privacy:1, touchid:1, users:1,
                   internet:1, gamecenter:1, icloud:1, wallet:1, passwords:1, keyboard:1,
                   sirispotlight:1, appearance:1, lockdown:1, energy:1 }
        if (aa[id]) return icondir + "aa_" + id + ".png"
        var h = 0; for (var i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) >>> 0
        return icondir + iconPool[h % iconPool.length]
    }

    // ---- sidebar model (real macOS grouping) ----
    readonly property var groups: [
        { items:[ {id:"appleid", label:"Apple ID", special:true}, {id:"family", label:"Family"} ]},
        { items:[ {id:"wifi", label:"Wi‑Fi"}, {id:"bluetooth", label:"Bluetooth"}, {id:"network", label:"Network"}, {id:"vpn", label:"VPN"} ]},
        { items:[ {id:"general", label:"General"} ]},
        { items:[ {id:"notifications", label:"Notifications"}, {id:"sound", label:"Sound"}, {id:"focus", label:"Focus"}, {id:"screentime", label:"Screen Time"} ]},
        { items:[ {id:"lockscreen", label:"Lock Screen"}, {id:"privacy", label:"Privacy & Security"}, {id:"touchid", label:"Touch ID & Password"}, {id:"users", label:"Users & Groups"} ]},
        { items:[ {id:"internet", label:"Internet Accounts"}, {id:"gamecenter", label:"Game Center"}, {id:"icloud", label:"iCloud"}, {id:"wallet", label:"Wallet"}, {id:"passwords", label:"Passwords"} ]},
        { items:[ {id:"keyboard", label:"Keyboard"}, {id:"mouse", label:"Mouse"}, {id:"trackpad", label:"Trackpad"}, {id:"printers", label:"Printers & Scanners"} ]},
        { items:[ {id:"dock", label:"Dock"}, {id:"menubar", label:"Menu Bar"}, {id:"controlcenter", label:"Control Center"}, {id:"sirispotlight", label:"Siri & Spotlight"}, {id:"appearance", label:"Appearance"} ]},
        { items:[ {id:"lockdown", label:"Lockdown Mode"}, {id:"energy", label:"Energy"}, {id:"softwareupdate", label:"Software Update"} ]}
    ]
    property string current: "dock"
    readonly property var masters: ({ wifi:"wifiPower", bluetooth:"btPower" })

    function titleFor(id) {
        for (var g = 0; g < groups.length; g++)
            for (var i = 0; i < groups[g].items.length; i++)
                if (groups[g].items[i].id === id) return groups[g].items[i].label
        return "Settings"
    }
    function filt(items) {
        if (search === "") return items
        var s = search.toLowerCase(); var out = []
        for (var i = 0; i < items.length; i++)
            if (items[i].label.toLowerCase().indexOf(s) >= 0) out.push(items[i])
        return out
    }

    // ---- pane definitions (authentic content; functional keys write userconfig.json) ----
    readonly property var panes: ({
        dock: [ { title:"", rows:[
            { kind:"slider", key:"dockIconSize", label:"Size", min:32, max:96, step:4 },
            { kind:"toggle", key:"dockMagnification", label:"Magnification" },
            { kind:"segmented", key:"dockPosition", options:["Left","Bottom","Right"], current:1, label:"Position on screen" },
            { kind:"segmented", key:"minimizeStyle", options:["Genie effect","Scale effect"], current:0, label:"Minimize windows using" },
            { kind:"popup", key:"preferTabs", value:"In Full Screen Only", label:"Prefer tabs when opening documents" },
            { kind:"popup", key:"dblClickTitle", value:"Zoom", label:"Double-click a window's title bar to" },
            { kind:"toggle", key:"closeOnQuit", label:"Close windows when quitting an app" },
            { kind:"toggle", key:"showRecents", label:"Show suggested and recent apps in Dock" }
        ]} ],
        menubar: [ { title:"", rows:[
            { kind:"toggle", key:"menubar.wifi", label:"Wi‑Fi" },
            { kind:"toggle", key:"menubar.bluetooth", label:"Bluetooth" },
            { kind:"toggle", key:"menubar.battery", label:"Battery" },
            { kind:"toggle", key:"menubar.sound", label:"Sound" },
            { kind:"toggle", key:"menubar.controlcenter", label:"Control Center" },
            { kind:"toggle", key:"menubar.spotlight", label:"Spotlight" },
            { kind:"toggle", key:"menubar.clock", label:"Clock" },
            { kind:"toggle", key:"menubar.tray", label:"Menu Bar Items" }
        ]} ],
        appearance: [ { title:"", rows:[
            { kind:"appearance", label:"Appearance" },
            { kind:"color", key:"accentColor", label:"Accent color", swatches:["#ff453a","#ff9f0a","#ffd60a","#30d158","#007aff","#bf5af2","#ff375f","#64d2ff","#ffffff"] },
            { kind:"popup", key:"highlightColor", value:"Accent color", label:"Highlight color" }
        ]} ],
        wifi: [ { title:"", rows:[
            { kind:"nav", label:"Known Networks", value:"" },
            { kind:"nav", label:"Other Network…", value:"" },
            { kind:"nav", label:"Join Other Network…", value:"" },
            { kind:"nav", label:"Ask to Join Hotspots", value:"Ask" }
        ]} ],
        bluetooth: [ { title:"", rows:[
            { kind:"nav", label:"My Devices", value:"" },
            { kind:"nav", label:"Magic Keyboard", value:"Connected" },
            { kind:"nav", label:"Magic Mouse", value:"Connected" },
            { kind:"nav", label:"Magic Trackpad", value:"Not Connected" }
        ]} ],
        network: [ { title:"", rows:[
            { kind:"nav", label:"Wi‑Fi", value:"Connected" },
            { kind:"nav", label:"Ethernet", value:"Connected" },
            { kind:"nav", label:"Thunderbolt Bridge", value:"Not Connected" },
            { kind:"nav", label:"VPN", value:"" },
            { kind:"toggle", key:"firewallOn", label:"Firewall" }
        ]} ],
        general: [ { title:"", rows:[
            { kind:"nav", label:"About", value:"" },
            { kind:"nav", label:"Software Update", value:"" },
            { kind:"nav", label:"Storage", value:"" },
            { kind:"nav", label:"AirDrop & Handoff", value:"" },
            { kind:"nav", label:"Language & Region", value:"" },
            { kind:"nav", label:"Date & Time", value:"" },
            { kind:"nav", label:"Sharing", value:"" },
            { kind:"nav", label:"Time Machine", value:"" },
            { kind:"nav", label:"Transfer or Reset", value:"" },
            { kind:"nav", label:"Startup Disk", value:"" }
        ]} ],
        notifications: [ { title:"", rows:[
            { kind:"toggle", key:"notifPreviews", label:"Show previews" },
            { kind:"nav", label:"Do Not Disturb", value:"" },
            { kind:"nav", label:"Allow notifications", value:"" },
            { kind:"nav", label:"Scheduled summary", value:"" }
        ]} ],
        sound: [ { title:"", rows:[
            { kind:"nav", label:"Output", value:"MacBook Pro Speakers" },
            { kind:"nav", label:"Input", value:"MacBook Pro Microphone" },
            { kind:"nav", label:"Alert sound", value:"Ping" },
            { kind:"nav", label:"Balance", value:"Center" },
            { kind:"toggle", key:"soundOnStartup", label:"Play sound on startup" },
            { kind:"toggle", key:"uiSounds", label:"Play user interface sound effects" }
        ]} ],
        focus: [ { title:"", rows:[ { kind:"nav", label:"Focus", value:"" }, { kind:"nav", label:"Do Not Disturb", value:"" }, { kind:"nav", label:"Sleep", value:"" } ]} ],
        screentime: [ { title:"", rows:[ { kind:"nav", label:"App Usage", value:"" }, { kind:"nav", label:"Downtime", value:"" }, { kind:"nav", label:"App Limits", value:"" }, { kind:"nav", label:"Always Allowed", value:"" } ]} ],
        lockscreen: [ { title:"", rows:[
            { kind:"popup", key:"screenSaver", value:"After 5 minutes", label:"Start Screen Saver when inactive" },
            { kind:"popup", key:"turnOff", value:"After 10 minutes", label:"Turn display off on battery when inactive" },
            { kind:"toggle", key:"reqPassword", label:"Require password after screen saver begins" }
        ]} ],
        privacy: [ { title:"", rows:[
            { kind:"nav", label:"Location Services", value:"" },
            { kind:"nav", label:"Contacts", value:"" },
            { kind:"nav", label:"Photos", value:"" },
            { kind:"nav", label:"Camera", value:"" },
            { kind:"nav", label:"Microphone", value:"" },
            { kind:"nav", label:"Full Disk Access", value:"" },
            { kind:"nav", label:"FileVault", value:"Off" },
            { kind:"nav", label:"Firewall", value:"On" },
            { kind:"nav", label:"Lockdown Mode", value:"" }
        ]} ],
        touchid: [ { title:"", rows:[
            { kind:"nav", label:"Fingerprints", value:"" },
            { kind:"nav", label:"Apple ID Password", value:"" },
            { kind:"toggle", key:"touchIdUnlock", label:"Use Touch ID to unlock" },
            { kind:"toggle", key:"touchIdPay", label:"Apple Pay" }
        ]} ],
        users: [ { title:"", rows:[ { kind:"nav", label:"Password", value:"" }, { kind:"nav", label:"Guest User", value:"Off" }, { kind:"nav", label:"Login Items", value:"" }, { kind:"nav", label:"Add Account", value:"" } ]} ],
        internet: [ { title:"", rows:[ { kind:"nav", label:"iCloud", value:"" }, { kind:"nav", label:"Google", value:"" }, { kind:"nav", label:"Add Account", value:"" } ]} ],
        gamecenter: [ { title:"", rows:[ { kind:"nav", label:"Profile", value:"" }, { kind:"toggle", key:"gcInvite", label:"Allow Friends to Invite" }, { kind:"toggle", key:"gcNearby", label:"Nearby Players" } ]} ],
        icloud: [ { title:"", rows:[ { kind:"nav", label:"Account Details", value:"" }, { kind:"nav", label:"iCloud Drive", value:"On" }, { kind:"nav", label:"Photos", value:"On" }, { kind:"nav", label:"Mail", value:"On" }, { kind:"nav", label:"Contacts", value:"On" } ]} ],
        wallet: [ { title:"", rows:[ { kind:"nav", label:"Apple Account", value:"" }, { kind:"nav", label:"Cards", value:"" }, { kind:"nav", label:"Keys", value:"" } ]} ],
        passwords: [ { title:"", rows:[ { kind:"nav", label:"All", value:"" }, { kind:"nav", label:"Security Recommendations", value:"" } ]} ],
        keyboard: [ { title:"", rows:[
            { kind:"slider", key:"keyRepeat", label:"Key Repeat", min:1, max:4, step:1 },
            { kind:"slider", key:"delayRepeat", label:"Delay Until Repeat", min:1, max:4, step:1 },
            { kind:"toggle", key:"kbBrightness", label:"Adjust keyboard brightness in low light" },
            { kind:"nav", label:"Keyboard Shortcuts", value:"" },
            { kind:"nav", label:"Text Replacements", value:"" },
            { kind:"nav", label:"Input Sources", value:"" }
        ]} ],
        mouse: [ { title:"", rows:[
            { kind:"slider", key:"mouseSpeed", label:"Tracking speed", min:1, max:4, step:1 },
            { kind:"toggle", key:"mouseNatural", label:"Scroll direction: Natural" },
            { kind:"popup", key:"mouseButton", value:"Left", label:"Primary mouse button" }
        ]} ],
        trackpad: [ { title:"", rows:[
            { kind:"slider", key:"trackSpeed", label:"Tracking speed", min:1, max:4, step:1 },
            { kind:"toggle", key:"trackTap", label:"Tap to click" },
            { kind:"toggle", key:"trackNatural", label:"Scroll direction: Natural" },
            { kind:"nav", label:"More Gestures", value:"" }
        ]} ],
        printers: [ { title:"", rows:[ { kind:"nav", label:"Add Printer, Scanner, or Fax", value:"" }, { kind:"nav", label:"Default Printer", value:"Last Printer Used" }, { kind:"nav", label:"Default Paper Size", value:"A4" } ]} ],
        controlcenter: [ { title:"", rows:[
            { kind:"toggle", key:"ccWifi", label:"Wi‑Fi" },
            { kind:"toggle", key:"ccBt", label:"Bluetooth" },
            { kind:"toggle", key:"ccAirDrop", label:"AirDrop" },
            { kind:"toggle", key:"ccBattery", label:"Battery" },
            { kind:"toggle", key:"ccMirror", label:"Screen Mirroring" },
            { kind:"toggle", key:"ccFocus", label:"Focus" },
            { kind:"toggle", key:"ccNowPlaying", label:"Now Playing" },
            { kind:"toggle", key:"ccSound", label:"Sound" }
        ]} ],
        sirispotlight: [ { title:"", rows:[ { kind:"toggle", key:"siriEnabled", label:"Enable Ask Siri" }, { kind:"nav", label:"Siri & Spotlight", value:"" }, { kind:"nav", label:"Search Privacy", value:"" }, { kind:"nav", label:"Search Results", value:"" } ]} ],
        softwareupdate: [ { title:"", rows:[ { kind:"toggle", key:"autoUpdate", label:"Automatic Updates" }, { kind:"nav", label:"Advanced", value:"" } ]} ],
        energy: [ { title:"", rows:[ { kind:"toggle", key:"lowPower", label:"Low Power Mode" }, { kind:"popup", key:"energyDisplay", value:"After 10 minutes", label:"Turn display off after" } ]} ],
        lockdown: [ { title:"", rows:[ { kind:"toggle", key:"lockdown", label:"Lockdown Mode" } ]} ]
    })

    // ================= LAYOUT =================
    Column {
        anchors.fill: parent
        spacing: 0
        // ---- TITLE BAR (traffic lights + centered title) ----
        Item {
            width: parent.width; height: 30
            Rectangle { anchors.fill: parent; color: bg
                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: cardBorder } }
            Row {
                spacing: 8; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 16
                Repeater { model: [ {c:"#ff5f57"}, {c:"#febc2e"}, {c:"#28c840"} ]
                    delegate: Rectangle { width: 12; height: 12; radius: 6; color: modelData.c } }
            }
            Text { anchors.centerIn: parent; text: "System Settings"; color: text; font { family: fnt; pointSize: 13; bold: true } }
        }
        // ---- BODY: sidebar | content ----
        Row {
            width: parent.width; height: parent.height - 30
            spacing: 0
            // ---- SIDEBAR ----
            Item {
                id: sidebar
                width: 250; height: parent.height
                Rectangle { anchors.fill: parent; color: sideBg
                    Rectangle { anchors { right: parent.right; top: parent.top; bottom: parent.bottom } width: 1; color: cardBorder } }
                Column {
                    id: sbCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 10 }
                    spacing: 2
                    Item { width: parent.width; height: 30
                        Rectangle { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } radius: 7; color: isDark ? "#3a3a3c" : "#e8e8ed"; border.color: isDark ? "#4a4a4e" : "#d2d2d7"; border.width: 1
                            Canvas { width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                onPaint: { var c = getContext("2d"); c.strokeStyle = isDark ? "#8e8e93" : "#86868b"; c.lineWidth = 1.5; c.beginPath(); c.arc(5,5,4,0,Math.PI*2); c.stroke(); c.beginPath(); c.moveTo(8,8); c.lineTo(12,12); c.stroke() } }
                            TextInput { id: si; anchors { left: parent.left; leftMargin: 28; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } color: sub; font { family: fnt; pointSize: 12 } text: "Search"; onActiveFocusChanged: { if (activeFocus && text === "Search") text = ""; if (!activeFocus && text === "") text = "Search" } onTextChanged: search = text } } }
                    Item { width: parent.width; height: 6 }
                    Repeater {
                        model: groups
                        delegate: Column {
                            width: sbCol.width; spacing: 2
                            visible: filt(modelData.items).length > 0
                            Repeater {
                                model: filt(modelData.items)
                                delegate: Item {
                                    id: srow
                                    width: sbCol.width; height: modelData.special ? 52 : 30
                                    property bool selected: current === modelData.id
                                    Rectangle { anchors { fill: parent; leftMargin: 8; rightMargin: 8 } radius: 6; color: srow.selected ? accentCol : (srowHover.containsMouse ? hover : "transparent"); Behavior on color { ColorAnimation { duration: 90 } } }
                                    MouseArea { id: srowHover; anchors.fill: parent; hoverEnabled: true; onClicked: current = modelData.id }
                                    Row { anchors.fill: parent; anchors.leftMargin: 14; spacing: 10
                                        Item { width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                                            Image { anchors.centerIn: parent; source: iconFor(modelData.id); sourceSize.width: 22; sourceSize.height: 22; fillMode: Image.PreserveAspectFit; visible: modelData.special !== true }
                                            Rectangle { visible: modelData.special === true; width: 24; height: 24; radius: 12; color: "#c7c7cc"; Text { anchors.centerIn: parent; text: "ID"; color: "#fff"; font { family: fnt; pointSize: 9; bold: true } } } }
                                        Column { anchors.verticalCenter: parent.verticalCenter; spacing: 0
                                            Text { text: modelData.label; color: srow.selected ? "#ffffff" : text; font { family: fnt; pointSize: 13; bold: modelData.special === true } visible: modelData.special !== true }
                                            Text { text: modelData.label; color: srow.selected ? "#ffffff" : text; font { family: fnt; pointSize: 13; bold: true } visible: modelData.special === true }
                                            Text { text: "Apple Account, iCloud, Media & Purchases"; color: srow.selected ? "#ffffff" : sub; font { family: fnt; pointSize: 11 } visible: modelData.special === true } } }
                                }
                            }
                        }
                    }
                }
            }
            // ---- CONTENT ----
            Item {
                width: parent.width - sidebar.width; height: parent.height
                Rectangle { anchors.fill: parent; color: bg }
                Flickable {
                    anchors.fill: parent; contentHeight: contentCol.height; boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: contentCol; width: parent.width; spacing: 0
                        Item { width: parent.width; height: 18 }
                        Item { width: parent.width; height: 56
                            Row { anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter } spacing: 14
                                Image { source: iconFor(current); sourceSize.width: 38; sourceSize.height: 38; fillMode: Image.PreserveAspectFit; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: titleFor(current); color: text; font { family: fntR; pointSize: 22; bold: true } anchors.verticalCenter: parent.verticalCenter } }
                            Item { anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                                visible: masters[current] !== undefined
                                Toggle { id: hdrToggle; checked: mkeyVal(); function mkeyVal(){ return masters[current] !== undefined ? (val(masters[current]) === true) : true }
                                    onCheckedChanged: { if (masters[current] !== undefined) set(masters[current], checked) } } } }
                        Repeater {
                            model: panes[current] || []
                            delegate: Column {
                                width: contentCol.width; topPadding: 14; spacing: 0
                                Text { text: modelData.title ? modelData.title.toUpperCase() : ""; visible: modelData.title; leftPadding: 22; color: sub; font { family: fnt; pointSize: 11; bold: true } height: modelData.title ? 20 : 0 }
                                FormSection { width: parent.width - 44; anchors.horizontalCenter: parent.horizontalCenter; title: modelData.title; rows: modelData.rows }
                            }
                        }
                        Item { width: parent.width; height: 24 }
                    }
                }
            }
        }
    }

    // ================= COMPONENTS =================
    component Toggle : Rectangle {
        id: tg
        property bool checked: true
        width: 38; height: 22; radius: 11
        color: tg.checked ? toggleOn : (isDark ? "#48484a" : "#e3e3e8")
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle { width: 18; height: 18; radius: 9; color: "#ffffff"; anchors.verticalCenter: parent.verticalCenter; x: tg.checked ? 18 : 2; Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
        MouseArea { anchors.fill: parent; onClicked: tg.checked = !tg.checked }
    }

    component SegmentedControl : Item {
        id: sc
        property var options: []
        property int current: 0
        signal selected(int i)
        height: 26
        Rectangle { anchors.fill: parent; radius: 7; color: isDark ? "#3a3a3c" : "#e6e6ea" }
        Row {
            id: segs
            anchors { fill: parent; margins: 2 }
            spacing: 0
            Repeater {
                model: sc.options
                delegate: Rectangle {
                    width: (sc.options.length > 0) ? (sc.width - 4) / sc.options.length : sc.width
                    height: 22; radius: 6
                    color: sc.current === index ? (isDark ? "#636366" : "#ffffff") : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: modelData; color: sc.current === index ? (isDark ? "#ffffff" : "#1d1d1f") : (isDark ? "#d4d4d8" : "#57575b"); font { family: fnt; pointSize: 12; bold: true } }
                    MouseArea { anchors.fill: parent; onClicked: { sc.current = index; sc.selected(index) } }
                }
            }
        }
    }

    component PopupButton : Rectangle {
        id: pb
        property string label: ""
        width: 180; height: 24; radius: 6
        color: isDark ? "#3a3a3c" : "#f1f1f4"
        border.color: isDark ? "#4a4a4e" : "#d2d2d7"; border.width: 1
        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: pb.label; color: text; font { family: fnt; pointSize: 12 } }
        Canvas { width: 10; height: 6; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
            onPaint: { var c = getContext("2d"); c.strokeStyle = sub; c.lineWidth = 1.5; c.lineCap = "round"; c.beginPath(); c.moveTo(1,1); c.lineTo(5,5); c.lineTo(9,1); c.stroke() } }
    }

    component HSlider : Item {
        id: sl
        property real from: 0; property real to: 100; property real step: 1; property real value: 0
        signal moved(real v)
        height: 20; width: 200
        Rectangle { anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right } height: 3; radius: 1.5; color: isDark ? "#5a5a5e" : "#d2d2d7" }
        Rectangle { id: fill; anchors { verticalCenter: parent.verticalCenter; left: parent.left } height: 3; radius: 1.5; color: accentCol; width: ((sl.value - sl.from) / (sl.to - sl.from)) * sl.width }
        Rectangle { id: knob; width: 18; height: 18; radius: 9; color: "#ffffff"; border.color: "#c4c4c8"; border.width: 0.5; x: fill.width - 9; anchors.verticalCenter: parent.verticalCenter }
        MouseArea { anchors.fill: parent; onPositionChanged: (m) => { if (pressed) { var r = Math.min(1, Math.max(0, m.x / width)); var v = from + r * (to - from); v = Math.round(v / step) * step; if (v !== value) { value = v; moved(v) } } } }
    }

    component ColorSwatches : Item {
        id: cs; property var swatches: []; property string current: ""
        signal picked(string c)
        height: 22; width: 210
        Row { spacing: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            Repeater { model: cs.swatches
                delegate: Rectangle { width: 18; height: 18; radius: 9; color: modelData; border.color: cs.current === modelData ? (isDark ? "#ffffff" : "#1d1d1f") : "transparent"; border.width: 2.5; MouseArea { anchors.fill: parent; onClicked: cs.picked(modelData) } } } }
    }

    component FormControl : Item {
        property var row
        height: 26
        Toggle { visible: row.kind === "toggle"; checked: row.key ? (val(row.key) === true) : (row.value === true); onCheckedChanged: { if (row.key) set(row.key, checked) } }
        HSlider { visible: row.kind === "slider"; from: row.kind === "slider" ? row.min : 0; to: row.kind === "slider" ? row.max : 0; step: row.kind === "slider" ? row.step : 1; value: row.kind === "slider" ? (row.key ? (val(row.key) !== undefined ? val(row.key) : row.min) : (row.value !== undefined ? row.value : row.min)) : 0; onMoved: (v) => { if (row.key) set(row.key, v) } }
        SegmentedControl { visible: row.kind === "segmented"; width: 220; options: row.options || []; current: row.key !== undefined ? (val(row.key) !== undefined ? val(row.key) : (row.current || 0)) : (row.current || 0); onSelected: (i) => { if (row.key) set(row.key, i) } }
        PopupButton { visible: row.kind === "popup"; label: row.key !== undefined ? (val(row.key) || row.value || "") : (row.value || "") }
        ColorSwatches { visible: row.kind === "color"; swatches: row.swatches; current: row.key ? (val(row.key) || "") : ""; onPicked: (c) => { if (row.key) set(row.key, c) } }
        Item { visible: row.kind === "appearance"; width: 230; height: 26
            SegmentedControl { anchors.fill: parent; options: ["Light","Dark","Auto"]; current: val("darkMode") === true ? 1 : 0; onSelected: (i) => { set("darkMode", i === 1) } } }
        Text { visible: row.kind === "nav"; text: row.value || ""; color: sub; font { family: fnt; pointSize: 13 } horizontalAlignment: Text.AlignRight }
        Canvas { visible: row.kind === "nav"; width: 12; height: 18; onPaint: { var c = getContext("2d"); c.clearRect(0,0,width,height); c.strokeStyle = isDark ? "#8e8e93" : "#b0b0b5"; c.lineWidth = 2; c.lineCap = "round"; c.beginPath(); c.moveTo(3,4); c.lineTo(9,9); c.lineTo(3,14); c.stroke() } }
        Text { visible: row.kind === "text"; text: row.value || ""; color: text; font { family: fnt; pointSize: 13 } horizontalAlignment: Text.AlignRight }
    }

    component FormSection : Rectangle {
        id: fs
        property string title: ""
        property var rows: []
        color: cardBg; radius: 11; border.color: cardBorder; border.width: 1
        readonly property int rowH: 46
        height: rows.length * rowH + 14
        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 7; bottomMargin: 7 }
            Repeater {
                model: fs.rows
                delegate: Item {
                    width: parent.width; height: fs.rowH
                    Rectangle { visible: index > 0; anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16; bottom: parent.bottom } height: 1; color: sep }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                        Text { text: modelData.label; color: text; font { family: fnt; pointSize: 13 } Layout.fillWidth: true; elide: Text.ElideRight }
                        FormControl { row: modelData }
                    }
                }
            }
        }
    }

    property string search: ""
}
