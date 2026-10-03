import QtQuick
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "spotlight"
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

    readonly property var categories: [
        { k: "applications", t: "Applications" },
        { k: "calculator", t: "Calculator" },
        { k: "calendar", t: "Calendar" },
        { k: "contacts", t: "Contacts" },
        { k: "definition", t: "Definition" },
        { k: "developer", t: "Developer" },
        { k: "directories", t: "Directories" },
        { k: "documents", t: "Documents" },
        { k: "events", t: "Events" },
        { k: "fonts", t: "Fonts" },
        { k: "images", t: "Images" },
        { k: "mail", t: "Mail" },
        { k: "messages", t: "Messages" },
        { k: "movies", t: "Movies" },
        { k: "music", t: "Music" },
        { k: "notes", t: "Notes" },
        { k: "pdf", t: "PDF" },
        { k: "presentations", t: "Presentations" },
        { k: "spelling", t: "Spelling" },
        { k: "systemSettings", t: "System Settings" },
        { k: "todolist", t: "To Do" },
        { k: "websites", t: "Websites" }
    ]

    readonly property var exclusions: [
        { p: HOME_DIR + "/Downloads", t: "Downloads" },
        { p: HOME_DIR + "/.cache", t: "Cache" },
        { p: HOME_DIR + "/.local/share/Trash", t: "Bin" },
        { p: HOME_DIR + "/Documents", t: "Documents" },
        { p: HOME_DIR + "/.config", t: "Configuration" }
    ]

    function keyFor(p) { return p.replace(/[^A-Za-z0-9]+/g, "_") }

    Placard {
        iconFile: "sb_spotlight"
        title: "Spotlight"
    }

    GroupCard {
        DetailRow {
            title: "Enable Spotlight"
            subtitle: "Press the shortcut, or use the menu bar icon, to search."
            showSwitch: true
            switchOn: eget("spotlight.enable", true) === true
            onToggled: (c) => {
                Shell.eset("spotlight.enable", c)
                Shell.uset("spotlightEnable", c)
                rev++
            }
        }
        DetailRow {
            separator: true
            title: "Keyboard shortcut"
            pickerOptions: ["\u2318Space", "\u2318\u2325Space", "\u2318\u2318Space", "Off"]
            value: String(eget("spotlight.hotkey", "\u2318Space"))
            onPicked: (v) => { Shell.eset("spotlight.hotkey", v); rev++ }
        }
        DetailRow {
            title: "Allow Spotlight in System Settings"
            showSwitch: true
            switchOn: eget("spotlight.inSettings", true) === true
            onToggled: (c) => { Shell.eset("spotlight.inSettings", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    GroupCard {
        DetailRow {
            title: "Open Spotlight"
            subtitle: "Try the search window right now."
            chevron: true
            onClicked: Shell.ipc("spotlight", "toggle", [])
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Search Results" }

    GroupCard {
        Repeater {
            model: page.categories

            delegate: DetailRow {
                required property var modelData
                required property int index
                separator: index > 0
                title: modelData.t
                showSwitch: true
                switchOn: page.eget("spotlight.categories." + modelData.k, true) === true
                onToggled: (c) => { Shell.eset("spotlight.categories." + modelData.k, c); rev++ }
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Privacy" }

    GroupCard {
        Repeater {
            model: page.exclusions

            delegate: DetailRow {
                required property var modelData
                required property int index
                separator: index > 0
                iconFile: "dt_privacy2"
                title: modelData.t
                subtitle: modelData.p
                showSwitch: true
                switchOn: page.eget("spotlight.exclude." + page.keyFor(modelData.p), false) === true
                onToggled: (c) => { Shell.eset("spotlight.exclude." + page.keyFor(modelData.p), c); rev++ }
            }
        }
    }

    Item { width: 1; height: 2 }
}
