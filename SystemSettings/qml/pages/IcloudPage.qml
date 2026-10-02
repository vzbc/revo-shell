import QtQuick
import ".."

Column {
    id: page

    property string pageId: "icloud"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    width: parent ? parent.width : 640
    spacing: 12

    property real used: SysInfo.usedBytes
    property real total: SysInfo.totalBytes

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }
    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function pct() { return total > 0 ? Math.round(used / total * 100) : 0 }

    Placard {
        iconFile: "sb_icloud"
        title: "iCloud"
        subtitle: page.accountEmail.length > 0 ? page.accountEmail : ""
    }

    // ---- storage ----
    Rectangle {
        x: 12
        width: parent.width - 24
        height: stCol.implicitHeight + 36
        radius: 10
        color: Theme.cardBg

        Column {
            id: stCol
            width: parent.width - 32
            x: 16
            y: 18
            spacing: 0

            Text {
                text: "Storage"
                font { family: Theme.fontText; pixelSize: 13; weight: Font.DemiBold }
                color: Theme.textPrimary
            }

            Item { width: 1; height: 10 }

            Row {
                width: parent.width
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SysInfo.fmt(used)
                    font { family: Theme.fontDisplay; pixelSize: 26; weight: Font.Bold }
                    color: Theme.textPrimary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "of " + SysInfo.fmt(total) + " used"
                    font { family: Theme.fontText; pixelSize: 13 }
                    color: Theme.textSecondary
                }
            }

            Item { width: 1; height: 12 }

            Rectangle {
                width: parent.width
                height: 10
                radius: 5
                color: Theme.dark ? "#2a2a2f" : "#e6e7ec"

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, page.used / Math.max(1, page.total)))
                    height: parent.height
                    radius: 5
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }

            Item { width: 1; height: 6 }

            Text {
                text: page.pct() + "% used \u00B7 " + SysInfo.fmt(page.total - page.used) + " available"
                font { family: Theme.fontText; pixelSize: 12 }
                color: Theme.textSecondary
            }
        }
    }

    Item { width: 1; height: 4 }

    GroupCard {
        DetailRow {
            title: "Account"
            subtitle: page.accountEmail
            chevron: true
            onClicked: page.navigate("acct.personalInfo")
        }
        DetailRow {
            separator: true
            title: "iCloud+"
            subtitle: "Upgrade for more storage, Private Relay, and more"
            chevron: true
            onClicked: Shell.run("xdg-open 'https://www.icloud.com' >/dev/null 2>&1 &")
        }
        DetailRow {
            separator: true
            title: "Manage Storage\u2026"
            chevron: true
            onClicked: page.navigate("gen.storage")
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Apps Using iCloud" }

    GroupCard {
        DetailRow {
            title: "iCloud Drive"
            subtitle: "Sync Desktop & Documents folders"
            showSwitch: true
            switchOn: Shell.eget("icloud.drive", true) === true
            onToggled: (c) => { Shell.eset("icloud.drive", c); rev++ }
            chevron: false
        }
        DetailRow {
            separator: true
            title: "Photos"
            showSwitch: true
            switchOn: Shell.eget("icloud.photos", true) === true
            onToggled: (c) => { Shell.eset("icloud.photos", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Mail"
            showSwitch: true
            switchOn: Shell.eget("icloud.mail", true) === true
            onToggled: (c) => { Shell.eset("icloud.mail", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Notes"
            showSwitch: true
            switchOn: Shell.eget("icloud.notes", true) === true
            onToggled: (c) => { Shell.eset("icloud.notes", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Passwords & Keychain"
            showSwitch: true
            switchOn: Shell.eget("icloud.keychain", true) === true
            onToggled: (c) => { Shell.eset("icloud.keychain", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Find My Mac"
            showSwitch: true
            switchOn: Shell.eget("findmy.mac", true) === true
            onToggled: (c) => { Shell.eset("findmy.mac", c); rev++ }
            chevron: true
            onClicked: page.navigate("acct.findMy")
        }
        DetailRow {
            separator: true
            title: "iCloud Web"
            chevron: true
            onClicked: Shell.run("xdg-open 'https://www.icloud.com' >/dev/null 2>&1 &")
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Storage shown is this Mac\u2019s local capacity. iCloud+ plans are managed on icloud.com."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 6 }
}
