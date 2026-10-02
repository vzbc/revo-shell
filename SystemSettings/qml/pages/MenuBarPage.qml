import QtQuick
import ".."

Column {
    id: page

    property string pageId: "menuBar"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }
    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }

    // flat keys are consumed live by the shell TopBar; nested menubar.* keeps history
    property var keyMap: ({
        autoHide: "bar.autohideMode",
        showBackground: "bar.showBackground",
        recentDocs: "bar.recentDocs",
        siri: "menubar.siri",
        spotlight: "menubarSpotlight",
        wifi: "menubarWifi",
        bluetooth: "menubarBluetooth",
        battery: "menubarBattery",
        focus: "menubar.focus",
        mirror: "menubar.mirror",
        display: "menubar.display",
        sound: "menubarSound",
        nowPlaying: "menubar.nowPlaying",
        timeMachine: "menubar.timeMachine",
        weather: "menubar.weather",
        tray: "menubarTray",
        controlCenter: "menubarControlCenter",
        clock: "menubarClock"
    })

    property var eqKeyMap: ({
        focusShow: "bar.focusShow",
        mirrorShow: "bar.mirrorShow",
        displayShow: "bar.displayShow",
        soundShow: "bar.soundShow",
        playingShow: "bar.playingShow"
    })

    function eg(name, def) {
        bumpU; bumpE
        var k = eqKeyMap[name]
        return k === undefined ? def : Shell.eget(k, def)
    }

    function set(name, value) {
        var ek = eqKeyMap[name]
        if (ek !== undefined) {
            Shell.eset(ek, value)
            rev++
            return
        }
        var k = keyMap[name]
        if (k === undefined)
            return
        Shell.uset(k, value)
        if (name === "autoHide")
            Shell.eset("bar.autohideMode", value)
        if (name === "wifi") Shell.uset("menubar.wifi", value)
        if (name === "bluetooth") Shell.uset("menubar.bluetooth", value)
        if (name === "battery") Shell.uset("menubar.battery", value)
        if (name === "sound") Shell.uset("menubar.sound", value)
        if (name === "spotlight") Shell.uset("menubar.spotlight", value)
        if (name === "clock") Shell.uset("menubar.clock", value)
        if (name === "tray") Shell.uset("menubar.tray", value)
        rev++
    }

    function g(name, def) {
        bumpU; bumpE
        var k = keyMap[name]
        if (k === undefined)
            return def
        return Shell.uget(k, def)
    }

    QtObject {
        id: mb
        property string autoHide: String(page.g("autoHide", "In Full Screen Only"))
        property bool showBackground: page.g("showBackground", false) === true
        property string recentDocs: String(page.g("recentDocs", "10"))
        property bool siri: page.g("siri", false) === true
        property bool spotlight: page.g("spotlight", true) === true
        property bool wifi: page.g("wifi", true) === true
        property bool bluetooth: page.g("bluetooth", true) === true
        property bool battery: page.g("battery", true) === true
        property bool focus: page.g("focus", true) === true
        property string focusShow: String(page.eg("focusShow", "Show When Active"))
        property bool mirror: page.g("mirror", true) === true
        property string mirrorShow: String(page.eg("mirrorShow", "Show When Active"))
        property bool display: page.g("display", true) === true
        property string displayShow: String(page.eg("displayShow", "Show When Active"))
        property bool sound: page.g("sound", true) === true
        property string soundShow: String(page.eg("soundShow", "Show When Active"))
        property bool nowPlaying: page.g("nowPlaying", true) === true
        property string playingShow: String(page.eg("playingShow", "Show When Active"))
        property bool timeMachine: page.g("timeMachine", false) === true
        property bool weather: page.g("weather", false) === true
        property string enabledApps: String(page.g("enabledApps",
            "ChatGPTHelper|DockFlow|Elgato Stream Deck|LookAway|Notion Calendar|PastePal|Rize|Substage|Umbra"))
    }

    function appEnabled(name) {
        bumpU; bumpE
        if (mb.enabledApps.length === 0)
            return false
        return mb.enabledApps.split("|").indexOf(name) !== -1
    }

    function toggleApp(name) {
        var list = mb.enabledApps.length > 0 ? mb.enabledApps.split("|") : []
        var i = list.indexOf(name)
        if (i >= 0)
            list.splice(i, 1)
        else
            list.push(name)
        Shell.uset("menubar.enabledApps", list.join("|"))
        rev++
    }

    Placard {
        iconFile: "sb_controlcenter.settings"
        title: "Menu Bar"
    }

    GroupCard {
        MenuControlRow {
            title: "Automatically hide and show the menu bar"
            showPicker: true
            pickerValue: mb.autoHide
            pickerOptions: ["Always", "On Desktop Only", "In Full Screen Only", "Never"]
            onPickerAccepted: (v) => page.set("autoHide", v)
        }
        MenuControlRow {
            separator: true
            title: "Show menu bar background"
            showSwitch: true
            switchOn: mb.showBackground
            onToggled: page.set("showBackground", checked)
        }
        MenuControlRow {
            separator: true
            title: "Recent documents, applications, and servers"
            showPicker: true
            pickerValue: mb.recentDocs
            pickerOptions: ["None", "5", "10", "15", "20", "30", "50"]
            onPickerAccepted: (v) => page.set("recentDocs", v)
        }
    }

    Item { width: 1; height: 8 }

    SectionHeader { text: "Menu Bar Controls" }

    Text {
        x: 16
        width: parent.width - 32
        wrapMode: Text.WordWrap
        text: "System and app controls can be configured to appear in both Control Center and the menu bar."
        font { family: Theme.fontText; pixelSize: 11 }
        color: Theme.textSecondary
    }

    BlueLink {
        x: 16
        label: "Add Controls…"
        onClicked: console.log("Add Controls window — TODO")
    }

    Item { width: 1; height: 4 }

    GroupCard {
        MenuControlRow {
            iconFile: "mc_clock"
            title: "Clock"
            showButton: true
            buttonLabel: "Clock Options…"
            onButtonClicked: console.log("Clock Options — TODO")
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_apple-intelligence"
            title: "Siri"
            showSwitch: true
            switchOn: mb.siri
            onToggled: page.set("siri", checked)
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_spotlight"
            title: "Spotlight"
            showSwitch: true
            switchOn: mb.spotlight
            onToggled: page.set("spotlight", checked)
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_wifi"
            title: "Wi-Fi"
            showSwitch: true
            switchOn: mb.wifi
            onToggled: page.set("wifi", checked)
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_bluetooth"
            title: "Bluetooth"
            showSwitch: true
            switchOn: mb.bluetooth
            onToggled: page.set("bluetooth", checked)
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_battery"
            title: "Battery"
            showSwitch: true
            switchOn: mb.battery
            onToggled: page.set("battery", checked)
            showButton: true
            buttonLabel: "Battery Options…"
            onButtonClicked: console.log("Battery Options — TODO")
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_focus"
            title: "Focus"
            showSwitch: true
            switchOn: mb.focus
            onToggled: page.set("focus", checked)
            showPicker: true
            pickerValue: mb.focusShow
            pickerOptions: ["Always Show", "Show When Active"]
            onPickerAccepted: (v) => page.set("focusShow", v)
        }
        MenuControlRow {
            separator: true
            iconFile: "mc_mirroring"
            title: "Screen Mirroring"
            showSwitch: true
            switchOn: mb.mirror
            onToggled: page.set("mirror", checked)
            showPicker: true
            pickerValue: mb.mirrorShow
            pickerOptions: ["Always Show", "Show When Active"]
            onPickerAccepted: (v) => page.set("mirrorShow", v)
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_display"
            title: "Display"
            showSwitch: true
            switchOn: mb.display
            onToggled: page.set("display", checked)
            showPicker: true
            pickerValue: mb.displayShow
            pickerOptions: ["Always Show", "Show When Active"]
            onPickerAccepted: (v) => page.set("displayShow", v)
        }
        MenuControlRow {
            separator: true
            iconFile: "sb_sound"
            title: "Sound"
            showSwitch: true
            switchOn: mb.sound
            onToggled: page.set("sound", checked)
            showPicker: true
            pickerValue: mb.soundShow
            pickerOptions: ["Always Show", "Show When Active"]
            onPickerAccepted: (v) => page.set("soundShow", v)
        }
        MenuControlRow {
            separator: true
            iconFile: "mc_nowplaying"
            title: "Now Playing"
            showSwitch: true
            switchOn: mb.nowPlaying
            onToggled: page.set("nowPlaying", checked)
            showPicker: true
            pickerValue: mb.playingShow
            pickerOptions: ["Always Show", "Show When Active"]
            onPickerAccepted: (v) => page.set("playingShow", v)
        }
        MenuControlRow {
            separator: true
            iconFile: "mc_timemachine"
            title: "Time Machine"
            showSwitch: true
            switchOn: mb.timeMachine
            onToggled: page.set("timeMachine", checked)
        }
        MenuControlRow {
            separator: true
            iconFile: "mc_weather"
            title: "Weather"
            showSwitch: true
            switchOn: mb.weather
            onToggled: page.set("weather", checked)
        }
    }

    Item { width: 1; height: 8 }

    SectionHeader { text: "Allow in the Menu Bar" }

    Text {
        x: 16
        width: parent.width - 32
        wrapMode: Text.WordWrap
        text: "Applications can add menu bar items to provide extra functionality such as launching a utility or performing tasks when the application isn't open. Turning off a menu bar item will prevent it from ever appearing in the menu bar."
        font { family: Theme.fontText; pixelSize: 11 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 4 }

    GroupCard {
        Repeater {
            model: [
                "ChatGPTHelper", "CleanMyMac Menu", "CleanShot X", "Clop",
                "Creative Cloud", "DockFlow", "Elgato Stream Deck", "Google Drive",
                "Imaging Edge Desktop", "Insta360 Link Controller", "iZotope Product Portal",
                "Logi Options+", "LookAway", "mInstaller", "Monocle", "Notion Calendar",
                "PasswordsMenuBarExtra", "PastePal", "Rize", "Rocket", "Screen Studio",
                "Sidebar Calendar", "Substage", "Umbra", "VLC", "Wispr Flow"
            ]

            delegate: MenuControlRow {
                required property string modelData
                required property int index
                separator: index > 0
                appName: modelData
                showSwitch: true
                switchOn: page.appEnabled(modelData)
                onToggled: page.toggleApp(modelData)
            }
        }
    }

    Item { width: 1; height: 4 }

    Row {
        width: parent.width
        layoutDirection: Qt.RightToLeft
        spacing: 8

        HelpCircle { anchors.verticalCenter: parent.verticalCenter; onClicked: {} }
        MacButton {
            anchors.verticalCenter: parent.verticalCenter
            text: "Reset Control Center…"
            onClicked: console.log("Reset Control Center — TODO")
        }
    }

    Item { width: 1; height: 2 }
}
