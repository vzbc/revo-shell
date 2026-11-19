import QtQuick
import ".."

// Game Center (macOS 27; strings from GameCenterSettings*Extension). On this
// Mac the player profile is the signed-in Steam account (name, avatar and
// friends come from Steam's local data); the Friends rows open Steam.
Column {
    id: page

    property string pageId: "gameCenter"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    property int rev: 0
    function ug(k, d) { bumpU; rev; return Shell.uget(k, d) }
    function us(k, v) { Shell.uset(k, v); rev++ }

    width: parent ? parent.width : 640
    spacing: 12

    property var steam: ({ id: "", name: "", account: "", friends: 0 })
    readonly property string steamDir: HOME_DIR + "/.local/share/Steam"

    function load() {
        const script = HOME_DIR + "/.cache/systemsettings/steam_profile.py"
        Shell.execOut("mkdir -p " + HOME_DIR + "/.cache/systemsettings", 1000)
        Shell.writeFile(script, Shell.readFile(":/scripts/steam_profile.py"))
        try { steam = JSON.parse(Shell.execOut("python3 -I " + script, 4000) || "{}") } catch (e) { steam = {} }
    }
    Component.onCompleted: load()
    readonly property bool signedIn: !!steam.id

    component Note: Text {
        x: Theme.cardMargin + 4
        width: page.width - 2 * (Theme.cardMargin + 4)
        wrapMode: Text.WordWrap
        font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
    }

    // ---------------------------------------------------------- profile
    Rectangle {
        x: Theme.cardMargin
        width: parent.width - 2 * Theme.cardMargin
        height: prof.implicitHeight + 40
        radius: Theme.cardRadius
        color: Theme.cardBg
        border.width: 1
        border.color: Theme.cardStroke

        Column {
            id: prof
            anchors.horizontalCenter: parent.horizontalCenter
            y: 20
            spacing: 6
            Avatar {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 84
                avatarPath: page.signedIn ? page.steamDir + "/config/avatarcache/" + page.steam.id + ".png" : ""
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.signedIn ? page.steam.name : "Game Center"
                font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.textDetail
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.signedIn ? "Steam Account: " + page.steam.name : "Sign in to play with friends and compare scores."
                font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
            }
            Item { width: 1; height: 4 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                MacButton {
                    text: page.signedIn ? "Customize Profile..." : "Sign In"
                    onClicked: Shell.run("steam " + (page.signedIn ? "steam://url/SteamIDEditPage" : "") + " >/dev/null 2>&1 &")
                }
                MacButton {
                    visible: page.signedIn
                    text: "Invite Friends..."
                    onClicked: Shell.run("steam steam://open/friends/add >/dev/null 2>&1 &")
                }
            }
        }
    }

    GroupCard {
        DetailRow {
            title: "Game Center"
            showSwitch: true
            switchOn: page.ug("gamecenter.enabled", true) === true
            onToggled: (c) => page.us("gamecenter.enabled", c)
        }
    }

    SectionHeader { text: "Friends" }
    GroupCard {
        DetailRow {
            title: "Friends"
            value: page.steam.friends + (page.steam.friends === 1 ? " Friend" : " Friends")
            chevron: true
            onClicked: Shell.run("steam steam://open/friends >/dev/null 2>&1 &")
        }
        DetailRow {
            separator: true
            title: "Friend Requests"
            chevron: true
            onClicked: Shell.run("steam steam://open/friends/pendinginvites >/dev/null 2>&1 &")
        }
    }

    SectionHeader { text: "Profile Privacy" }
    GroupCard {
        DetailRow {
            title: "Profile Privacy"
            pickerOptions: ["Everyone", "Friends Only", "Only You"]
            value: String(page.ug("gamecenter.privacy", "Friends Only"))
            onPicked: (v) => page.us("gamecenter.privacy", v)
        }
    }
    Note { text: "Choose who can see your activity. Your game activity includes your achievements and recently played games." }

    SectionHeader { text: "Help Friends Find You" }
    GroupCard {
        DetailRow {
            title: "Allow Finding by Friends"
            showSwitch: true
            switchOn: page.ug("gamecenter.findable", true) === true
            onToggled: (c) => page.us("gamecenter.findable", c)
        }
    }
    Note { text: "Help your Game Center friends find you more easily based on the name they have for you in their contacts." }

    SectionHeader { text: "Friend Requests" }
    GroupCard {
        DetailRow {
            title: "Requests from Contacts Only"
            showSwitch: true
            switchOn: page.ug("gamecenter.contactsOnly", false) === true
            onToggled: (c) => page.us("gamecenter.contactsOnly", c)
        }
    }
    Note { text: "Allow only people from your contacts to send you friend requests." }

    SectionHeader { text: "Multiplayer" }
    GroupCard {
        DetailRow {
            title: "Nearby Players"
            showSwitch: true
            switchOn: page.ug("gamecenter.nearby", true) === true
            onToggled: (c) => page.us("gamecenter.nearby", c)
        }
    }
    Note { text: "Allow nearby Game Center players in the same game to invite you to a multiplayer game over Wi-Fi or Bluetooth." }

    SectionHeader { text: "Connect with Friends" }
    GroupCard {
        DetailRow {
            title: "Allow connections with friends"
            showSwitch: true
            switchOn: page.ug("gamecenter.connect", true) === true
            onToggled: (c) => page.us("gamecenter.connect", c)
        }
        DetailRow {
            separator: true
            title: "Applications"
            buttonLabel: "Show Applications\u2026"
            onClicked: Shell.run("steam steam://open/games >/dev/null 2>&1 &")
        }
    }
    Note { text: "Turning off Connect with Friends prevents applications from asking if they can connect you with your Game Center friends." }

    Item { width: 1; height: 6 }
}
