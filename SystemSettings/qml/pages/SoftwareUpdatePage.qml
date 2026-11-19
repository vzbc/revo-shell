import QtQuick
import ".."

// General › Software Update (macOS 27, SoftwareUpdateSettingsExtension.appex).
// "Updates" are this system's real ones: pacman (checkupdates) + AUR (yay/paru -Qua).
// Update Now opens a terminal that runs the upgrade.
Column {
    id: page

    property string pageId: "gen.softwareUpdate"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    property int rev: 0
    function ug(k, d) { bumpU; rev; return Shell.uget(k, d) }
    function us(k, v) { Shell.uset(k, v); rev++ }

    width: parent ? parent.width : 640
    spacing: 12

    property string state: "checking"      // checking | uptodate | available | error
    property var updates: []
    property bool showList: false
    property var info: ({})
    readonly property string osName: "macOS " + String(info.os || "Tahoe 26").split(" ")[0]
    readonly property string osVersion: String(info.os || "Tahoe 26").split(" ")[1] || "26"

    readonly property bool autoOn: ug("updates.download", true) === true
    readonly property string autoLabel: !autoOn ? "Off"
        : (ug("updates.installMacOS", false) === true ? "On" : "Only Download")

    function check() {
        state = "checking"
        Shell.run("{ checkupdates 2>/dev/null; command -v yay >/dev/null && yay -Qua 2>/dev/null || { command -v paru >/dev/null && paru -Qua 2>/dev/null; }; } | awk 'NF' ; echo __END__$?")
    }
    Connections {
        target: Shell
        function onRunFinished(output, code) {
            if (output.indexOf("__END__") < 0) return
            const lines = output.split("\n").filter(l => l.trim() && l.indexOf("__END__") < 0)
            page.updates = lines.map(l => { const p = l.trim().split(/\s+/); return { name: p[0], from: p[1] || "", to: p[3] || "" } })
            page.state = page.updates.length ? "available" : "uptodate"
        }
    }
    Component.onCompleted: {
        try { info = JSON.parse(Shell.execOut(HOME_DIR + "/.config/quickshell/macos/scripts/mac-tahoe-about-info", 4000) || "{}") } catch (e) {}
        check()
    }

    Item { width: 1; height: 4 }

    GroupCard {
        DetailRow {
            title: "Automatic Updates"
            value: page.autoLabel
            showInfo: true
            onInfoClicked: page.navigate("gen.softwareUpdate.auto")
            onClicked: page.navigate("gen.softwareUpdate.auto")
        }
        DetailRow {
            separator: true
            title: "Beta Updates"
            value: "Off"
            showInfo: true
        }
    }

    // ------------------------------------------------------------- status
    GroupCard {
        Item {
            width: parent ? parent.width : 100
            height: page.state === "available" ? 84 : 72

            Image {
                id: osIcon
                x: 16; anchors.verticalCenter: parent.verticalCenter
                width: 44; height: 44; mipmap: true
                source: Theme.dark ? "qrc:/icons/about_macos_dark.png" : "qrc:/icons/about_macos_light.png"
            }
            Column {
                anchors.left: osIcon.right; anchors.leftMargin: 12
                anchors.right: actions.left; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: page.state === "checking" ? "Checking for updates…"
                        : page.state === "available" ? "Updates are available for your Mac"
                        : "Your Mac is up to date."
                    font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textPrimary
                }
                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: page.state === "available"
                        ? page.updates.length + " update" + (page.updates.length === 1 ? "" : "s") + " — " + page.updates.slice(0, 2).map(u => u.name).join(", ") + (page.updates.length > 2 ? ", and " + (page.updates.length - 2) + " more…" : "")
                        : page.osName + " " + page.osVersion
                    font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
                }
                BlueLink {
                    visible: page.state === "available"
                    label: page.showList ? "Hide Details" : "More Info…"
                    onClicked: page.showList = !page.showList
                }
            }
            Row {
                id: actions
                anchors.right: parent.right; anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                MacButton {
                    visible: page.state === "available"
                    text: "Update Now"
                    primary: true
                    onClicked: Shell.run("kitty --title 'Software Update' -e sh -c '" + (Shell.execOut("command -v yay || command -v paru", 1000) ? Shell.execOut("command -v yay || command -v paru", 1000).trim() + " -Syu" : "sudo pacman -Syu") + "; printf \"\\nPress Enter to close\"; read _' >/dev/null 2>&1 &")
                }
                MacButton {
                    visible: page.state !== "checking"
                    text: page.state === "available" ? "Check Again" : "Check for Updates"
                    onClicked: page.check()
                }
            }
        }
        Repeater {
            model: page.showList ? page.updates : []
            delegate: DetailRow {
                required property var modelData
                separator: true
                title: modelData.name
                value: modelData.from && modelData.to ? modelData.from + " → " + modelData.to : ""
            }
        }
    }

    Text {
        x: Theme.cardMargin + 4
        width: page.width - 2 * (Theme.cardMargin + 4)
        wrapMode: Text.WordWrap
        textFormat: Text.RichText
        text: "Use of this software is subject to the <a style='text-decoration:none' href='sla'>original license agreement</a> that accompanied the software being updated."
        linkColor: Theme.link
        font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
    }

    Item { width: 1; height: 6 }
}
