import QtQuick
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "desktopDock"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }
    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    Placard {
        iconFile: "sb_desktop"
        title: "Desktop & Dock"
    }

    DockPreview {
        id: preview
        width: parent.width
        position: String(uget("dockPosition", eget("dock.position", "bottom"))).toLowerCase()
        iconSize: Number(uget("dockIconSize", 52))
        magnify: uget("dockMagnification", true) === true
        autohide: uget("dockAutohide", false) === true
        indicators: uget("dockIndicators", true) === true
        animateOpen: uget("dockShowAnimation", true) === true
    }

    // ============================ Dock ============================
    SectionHeader { text: "Dock" }

    GroupCard {
        DetailRow {
            title: "Size"
            isSlider: true
            sliderValue: Math.max(0, Math.min(1, (Number(uget("dockIconSize", 52)) - 16) / 112))
            value: String(uget("dockIconSize", 52))
            onMoved: (r) => {
                var v = Math.round((16 + r * 112) / 2) * 2
                Shell.uset("dockIconSize", v)
                rev++
            }
        }

        DetailRow {
            separator: true
            title: "Magnification"
            showSwitch: true
            switchOn: uget("dockMagnification", true) === true
            onToggled: (c) => { Shell.uset("dockMagnification", c); Shell.eset("dock.magnify", c); rev++ }
        }

        DetailRow {
            separator: true
            visible: uget("dockMagnification", true) === true
            title: "Magnification size"
            isSlider: true
            sliderValue: Math.max(0, Math.min(1, (Number(uget("dockZoom", 55)) - 20) / 100))
            value: String(uget("dockZoom", 55))
            onMoved: (r) => {
                var v = Math.round(20 + r * 100)
                Shell.uset("dockZoom", v)
                rev++
            }
        }

        DetailRow {
            separator: true
            title: "Position on screen"
            pickerOptions: ["Left", "Bottom", "Right"]
            value: {
                bumpU
                var p = String(uget("dockPosition", eget("dock.position", "bottom")))
                return p.length > 0 ? p.charAt(0).toUpperCase() + p.slice(1) : "Bottom"
            }
            onPicked: (v) => {
                Shell.uset("dockPosition", v.toLowerCase())
                Shell.eset("dock.position", v.toLowerCase())
                rev++
            }
        }

        DetailRow {
            separator: true
            title: "Minimize windows using"
            pickerOptions: ["Genie", "Scale"]
            value: String(eget("dock.minimizeEffect", "Genie"))
            onPicked: (v) => { Shell.eset("dock.minimizeEffect", v.toLowerCase()); rev++ }
        }

        DetailRow {
            separator: true
            title: "Double-click a window's title bar to"
            pickerOptions: ["Zoom", "Minimize", "Do Nothing"]
            value: String(uget("dock.titleBarAction", "Zoom"))
            onPicked: (v) => { Shell.uset("dock.titleBarAction", v); rev++ }
        }

        DetailRow {
            separator: true
            title: "Minimize windows into application icon"
            showSwitch: true
            switchOn: eget("dock.minimizeIntoIcon", false) === true
            onToggled: (c) => { Shell.eset("dock.minimizeIntoIcon", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    GroupCard {
        DetailRow {
            title: "Automatically hide and show the Dock"
            showSwitch: true
            switchOn: uget("dockAutohide", false) === true
            onToggled: (c) => { Shell.uset("dockAutohide", c); Shell.eset("dock.autohide", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Animate opening applications"
            showSwitch: true
            switchOn: uget("dockShowAnimation", true) === true
            onToggled: (c) => { Shell.uset("dockShowAnimation", c); Shell.eset("dock.showAnimation", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Animate hiding and showing the Dock"
            showSwitch: true
            switchOn: uget("dockAnimateHide", true) === true
            onToggled: (c) => { Shell.uset("dockAnimateHide", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show indicators for open applications"
            showSwitch: true
            switchOn: uget("dockIndicators", true) === true
            onToggled: (c) => { Shell.uset("dockIndicators", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show recent applications in Dock"
            showSwitch: true
            switchOn: eget("dock.recent", true) === true
            onToggled: (c) => { Shell.eset("dock.recent", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show suggested and recent apps in Dock"
            showSwitch: true
            switchOn: eget("dock.suggested", true) === true
            onToggled: (c) => { Shell.eset("dock.suggested", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show File Provider documents in Dock"
            showSwitch: true
            switchOn: eget("dock.fileProvider", false) === true
            onToggled: (c) => { Shell.eset("dock.fileProvider", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    // ============================ Desktop & Stage Manager ============================
    SectionHeader { text: "Desktop & Stage Manager" }

    GroupCard {
        DetailRow {
            title: "Show Items"
            pickerOptions: ["Desktop", "Stage Manager"]
            value: String(eget("stage.showItems", "Desktop"))
            onPicked: (v) => { Shell.eset("stage.showItems", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show items on Desktop"
            pickerOptions: ["Always", "Only in Stage Manager", "Never"]
            value: String(eget("stage.itemsOnDesktop", "Always"))
            onPicked: (v) => { Shell.eset("stage.itemsOnDesktop", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show Desktop Items"
            showSwitch: true
            switchOn: eget("wallpaper.desktopEnable", true) === true
            onToggled: (c) => { Shell.eset("wallpaper.desktopEnable", c); Shell.eset("desktopEnable", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show windows from an application"
            showSwitch: true
            switchOn: eget("stage.windowsFromApp", true) === true
            onToggled: (c) => { Shell.eset("stage.windowsFromApp", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Click wallpaper to reveal desktop"
            pickerOptions: ["Always", "Only in Stage Manager"]
            value: String(eget("dock.clickWallpaper", "Always"))
            onPicked: (v) => { Shell.eset("dock.clickWallpaper", v); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    // ============================ Windows ============================
    SectionHeader { text: "Windows" }

    GroupCard {
        DetailRow {
            title: "Tiled windows have margins"
            showSwitch: true
            switchOn: eget("windows.tileMargins", true) === true
            onToggled: (c) => { Shell.eset("windows.tileMargins", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Drag windows to screen edges to tile"
            showSwitch: true
            switchOn: eget("windows.edgeTile", true) === true
            onToggled: (c) => { Shell.eset("windows.edgeTile", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Hold Option key while dragging windows to tile"
            showSwitch: true
            switchOn: eget("windows.optionTile", true) === true
            onToggled: (c) => { Shell.eset("windows.optionTile", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Drag windows to menu bar to fill screen"
            showSwitch: true
            switchOn: eget("windows.menuTile", true) === true
            onToggled: (c) => { Shell.eset("windows.menuTile", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Prefer tabs when opening documents"
            pickerOptions: ["Never", "In Full Screen", "Always"]
            value: String(eget("windows.preferTabs", "Never"))
            onPicked: (v) => { Shell.eset("windows.preferTabs", v); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    // ============================ Mission Control ============================
    SectionHeader { text: "Mission Control" }

    GroupCard {
        DetailRow {
            title: "Automatically rearrange Spaces based on most recent use"
            showSwitch: true
            switchOn: eget("spaces.autoRearrange", true) === true
            onToggled: (c) => { Shell.eset("spaces.autoRearrange", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "When switching to an application, switch to a Space with open windows"
            showSwitch: true
            switchOn: eget("spaces.switchToSpace", true) === true
            onToggled: (c) => { Shell.eset("spaces.switchToSpace", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Group windows by application"
            showSwitch: true
            switchOn: eget("spaces.groupByApp", true) === true
            onToggled: (c) => { Shell.eset("spaces.groupByApp", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Displays have separate Spaces"
            showSwitch: true
            switchOn: eget("spaces.separateDisplays", true) === true
            onToggled: (c) => { Shell.eset("spaces.separateDisplays", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Shortcut"
            pickerOptions: ["F1", "F2", "F3", "F4", "None"]
            value: String(eget("spaces.shortcut", "F3"))
            onPicked: (v) => { Shell.eset("spaces.shortcut", v); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    // ============================ Widgets ============================
    SectionHeader { text: "Widgets" }

    GroupCard {
        DetailRow {
            title: "Show Widgets"
            showSwitch: true
            switchOn: eget("widgets.enable", true) === true
            onToggled: (c) => { Shell.eset("widgets.enable", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Widget size"
            pickerOptions: ["Small", "Medium", "Large"]
            value: String(eget("widgets.size", "Medium"))
            onPicked: (v) => { Shell.eset("widgets.size", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Widget style"
            pickerOptions: ["Automatic", "Monochrome"]
            value: String(eget("widgets.style", "Automatic"))
            onPicked: (v) => { Shell.eset("widgets.style", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show widgets on all Spaces"
            showSwitch: true
            switchOn: eget("widgets.allSpaces", true) === true
            onToggled: (c) => { Shell.eset("widgets.allSpaces", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    // ============================ Menu Bar ============================
    SectionHeader { text: "Menu Bar" }

    GroupCard {
        DetailRow {
            title: "Automatically hide and show the menu bar"
            pickerOptions: ["Never", "On Desktop Only", "In Full Screen", "Always"]
            value: String(eget("bar.autohideMode", "On Desktop Only"))
            onPicked: (v) => { Shell.eset("bar.autohideMode", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show menu bar in full screen"
            showSwitch: true
            switchOn: eget("bar.fullscreenShow", true) === true
            onToggled: (c) => { Shell.eset("bar.fullscreenShow", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Menu bar size"
            pickerOptions: ["Auto", "Compact", "Full Size"]
            value: String(eget("bar.size", "Auto"))
            onPicked: (v) => { Shell.eset("bar.size", v); rev++ }
        }
    }

    Item { width: 1; height: 6 }
}
