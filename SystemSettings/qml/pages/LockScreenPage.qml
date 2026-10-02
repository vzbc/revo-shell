import QtQuick
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "lockScreen"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0
    property bool locking: false

    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    readonly property string idlePath: "/home/revo/.config/hypr/hypridle.conf"
    readonly property string lockPath: "/home/revo/.config/hypr/hyprlock.conf"

    function secs(v) {
        var m = { "Never": 0, "Immediately": 0, "5 seconds": 5, "1 minute": 60,
                  "2 minutes": 120, "5 minutes": 300, "10 minutes": 600,
                  "15 minutes": 900, "20 minutes": 1200, "1 hour": 3600 }
        return m[v] !== undefined ? m[v] : 0
    }

    function backup(path) {
        if (Shell.readFile(path + ".settings-backup").length === 0) {
            var t = Shell.readFile(path)
            if (t.length > 0)
                Shell.writeFile(path + ".settings-backup", t)
        }
    }

    function applySystem() {
        backup(idlePath)
        backup(lockPath)

        var enabled = eget("lockScreen.enable", true) === true
        var ss = enabled ? secs(String(eget("lockScreen.startAfter", "Never"))) : 0
        var off = secs(String(eget("lockScreen.displayOffAfter", "10 minutes")))

        var L = []
        L.push("general {")
        L.push("    lock_cmd = bash ~/.config/hypr/scripts/macos_lock.sh 'pidof hyprlock || hyprlock'")
        L.push("    before_sleep_cmd = bash ~/.config/hypr/scripts/macos_lock.sh 'loginctl lock-session'")
        L.push("    after_sleep_cmd = hyprctl dispatch dpms on")
        L.push("}")
        if (ss > 0) {
            L.push("")
            L.push("listener {")
            L.push("    timeout = " + ss)
            L.push("    on-timeout = pidof hyprlock >/dev/null || hyprlock")
            L.push("}")
        }
        if (off > 0 && off !== ss) {
            L.push("")
            L.push("listener {")
            L.push("    timeout = " + off)
            L.push("    on-timeout = hyprctl dispatch dpms off")
            L.push("    on-resume = hyprctl dispatch dpms on")
            L.push("}")
        }
        Shell.writeFile(idlePath, L.join("\n") + "\n")

        var ht = Shell.readFile(lockPath)
        if (ht.length > 0) {
            var delay = eget("lockScreen.requirePassword", true) === true
                        ? secs(String(eget("lockScreen.passwordDelay", "Immediately"))) : 0
            ht = ht.replace(/grace = \d+/, "grace = " + delay)
            var msg = eget("lockScreen.showMessage", false) === true
                      ? String(eget("lockScreen.userNote", "")) : ""
            msg = msg.replace(/["\\\n]/g, " ").replace(/^\s+|\s+$/g, "")
            var line = msg.length > 0 ? "text = " + msg
                       : "text = cmd[update:0] echo \"Wellcome, $USER!\""
            ht = ht.replace(/text = cmd\[update:0\] echo "[^"]*"/, line)
            ht = ht.replace(/text = cmd\[update:0\] echo "Wellcome, \$USER!"/, line)
            Shell.writeFile(lockPath, ht)
        }

        Shell.run("pkill hypridle; sleep 0.2; hypridle >/dev/null 2>&1 &")
        rev++
    }

    Timer {
        id: idleApply
        interval: 350
        onTriggered: page.applySystem()
    }
    function scheduleApply() { idleApply.restart() }

    Timer {
        id: unlockTimer
        interval: 1400
        onTriggered: page.locking = false
    }

    Placard {
        iconFile: "sb_lockscreen"
        title: "Lock Screen"
    }

    GroupCard {
        height: previewBox.height + 20

        Rectangle {
            id: previewBox
            x: 12
            y: 10
            width: parent.width - 24
            height: Math.round(width * 0.36)
            radius: 10
            clip: true
            color: Theme.dark ? "#0c0c10" : "#1b1b1f"

            Image {
                anchors.fill: parent
                source: "file://" + String(Shell.eget("lockScreen.customWallpaperPath", "")).replace(/^file:\/\//, "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
                opacity: 0.75
            }
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: Number(Shell.eget("lockScreen.dimOpacity", 0.1))
            }

            Column {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "HH:mm")
                    visible: String(eget("lockScreen.largeClock", "Digital")) !== "Off"
                    font.family: Theme.fontText
                    font.pixelSize: 44
                    font.weight: Font.Light
                    color: "white"

                    Timer {
                        interval: 10000
                        running: page.visible
                        repeat: true
                        onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm")
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                    font.family: Theme.fontText
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.85)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: text.length > 0
                    text: eget("lockScreen.showMessage", false) === true
                          ? String(eget("lockScreen.userNote", ""))
                          : String(Shell.eget("lockScreen.usageInfo", ""))
                    font.family: Theme.fontText
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                text: page.locking ? "Locked" : ""
                font { family: Theme.fontText; pixelSize: 12; bold: true }
                color: Qt.rgba(1, 1, 1, 0.75)
            }
        }
    }

    SectionHeader { text: "Display" }

    GroupCard {
        DetailRow {
            title: "Start Screen Saver when inactive"
            subtitle: "Locks the screen after this amount of time."
            pickerOptions: ["Never", "1 minute", "2 minutes", "5 minutes", "10 minutes", "20 minutes", "1 hour"]
            value: String(eget("lockScreen.startAfter", "Never"))
            onPicked: (v) => { Shell.eset("lockScreen.startAfter", v); page.scheduleApply() }
        }
        DetailRow {
            separator: true
            title: "Turn display off when inactive"
            pickerOptions: ["Never", "1 minute", "2 minutes", "5 minutes", "10 minutes", "20 minutes", "1 hour"]
            value: String(eget("lockScreen.displayOffAfter", "10 minutes"))
            onPicked: (v) => { Shell.eset("lockScreen.displayOffAfter", v); page.scheduleApply() }
        }
        DetailRow {
            separator: true
            title: "Require password after screen saver begins"
            showSwitch: true
            switchOn: eget("lockScreen.requirePassword", true) === true
            onToggled: (c) => { Shell.eset("lockScreen.requirePassword", c); page.scheduleApply() }
        }
        DetailRow {
            visible: eget("lockScreen.requirePassword", true) === true
            title: "Delay"
            pickerOptions: ["Immediately", "5 seconds", "1 minute", "5 minutes", "15 minutes", "1 hour"]
            value: String(eget("lockScreen.passwordDelay", "Immediately"))
            onPicked: (v) => { Shell.eset("lockScreen.passwordDelay", v); page.scheduleApply() }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Clock & Message" }

    GroupCard {
        DetailRow {
            title: "Show large clock"
            pickerOptions: ["Off", "Analog", "Digital"]
            value: String(eget("lockScreen.largeClock", "Digital"))
            onPicked: (v) => { Shell.eset("lockScreen.largeClock", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show message with clock"
            showSwitch: true
            switchOn: eget("lockScreen.showMessage", false) === true
            onToggled: (c) => { Shell.eset("lockScreen.showMessage", c); page.scheduleApply() }
        }
        DetailRow {
            visible: eget("lockScreen.showMessage", false) === true
            title: "Message"
            value: String(eget("lockScreen.userNote", ""))
            pickerOptions: ["", "Hello", "Do not disturb", "Back soon"]
            onPicked: (v) => { Shell.eset("lockScreen.userNote", v); page.scheduleApply() }
        }
        DetailRow {
            separator: true
            title: "Show user name and photo"
            showSwitch: true
            switchOn: eget("lockScreen.showAvatar", true) === true && eget("lockScreen.showName", true) === true
            onToggled: (c) => { Shell.eset("lockScreen.showAvatar", c); Shell.eset("lockScreen.showName", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Screen Saver" }

    GroupCard {
        DetailRow {
            title: "Show as wallpaper"
            showSwitch: true
            switchOn: eget("lockScreen.useAsWallpaper", true) === true
            onToggled: (c) => { Shell.eset("lockScreen.useAsWallpaper", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Blur strength"
            isSlider: true
            sliderValue: {
                bumpE
                return Math.max(0, Math.min(1, Number(Shell.eget("lockScreen.blurStrength", 1)) / 4))
            }
            onMoved: (r) => { Shell.eset("lockScreen.blurStrength", Math.round(r * 4)); rev++ }
        }
        DetailRow {
            separator: true
            title: "Fade duration (ms)"
            isSlider: true
            sliderValue: {
                bumpE
                return Math.max(0, Math.min(1, Number(Shell.eget("lockScreen.fadeDuration", 500)) / 2000))
            }
            onMoved: (r) => { Shell.eset("lockScreen.fadeDuration", Math.round(r * 2000 / 50) * 50); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Locking" }

    GroupCard {
        DetailRow {
            title: "Lock Screen Now"
            subtitle: "Immediately shows the lock screen."
            chevron: true
            onClicked: {
                page.locking = true
                unlockTimer.restart()
                Shell.ipc("lock", "lock", [])
            }
        }
        DetailRow {
            separator: true
            title: "Enable lock screen"
            subtitle: "Used by the shell and hypridle."
            showSwitch: true
            switchOn: eget("lockScreen.enable", true) === true
            onToggled: (c) => { Shell.eset("lockScreen.enable", c); page.scheduleApply() }
        }
        DetailRow {
            separator: true
            title: "Test display off now"
            subtitle: "Turns the monitor off; move the mouse to wake it."
            chevron: true
            onClicked: Shell.run("hyprctl dispatch dpms off >/dev/null 2>&1")
        }
    }

    Item { width: 1; height: 6 }

    Component.onCompleted: scheduleApply()
}
