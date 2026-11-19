import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common"

// Hot Corners (System Settings › Desktop & Dock › Hot Corners…).
// userconfig.json: hotCorners { tl, tr, bl, br } = one of the macOS actions.
// Each corner is a 2×2 px overlay surface; pushing the pointer into it runs
// the action (once, until the pointer leaves the corner).
Scope {
    id: root

    readonly property var cfg: (Appearance.userCfg || {}).hotCorners || ({})
    readonly property string shellDir: Quickshell.env("HOME") + "/.config/quickshell/macos"
    readonly property string hyprScripts: Quickshell.env("HOME") + "/.config/hypr/scripts"

    function run(action) {
        const ipc = (t, f) => Quickshell.execDetached(["qs", "-p", root.shellDir, "ipc", "call", t, f]);
        switch (action) {
        case "Desktop":
            Quickshell.execDetached(["bash", root.hyprScripts + "/show_desktop.sh"]); break;
        case "Notification Center":
            ipc("notificationCenter", "toggle"); break;
        case "Apps":
        case "Launchpad":
            ipc("launchpad", "toggle"); break;
        case "Lock Screen":
        case "Start Screen Saver":
            Quickshell.execDetached(["bash", root.hyprScripts + "/macos_lock.sh"]); break;
        case "Put Display to Sleep":
            Quickshell.execDetached(["sh", "-c", "sleep 0.5; hyprctl dispatch dpms off"]); break;
        default:
            break;  // "-", and macOS-only actions with no counterpart here
        }
    }

    Variants {
        model: [
            { key: "tl", top: true,  left: true  },
            { key: "tr", top: true,  left: false },
            { key: "bl", top: false, left: true  },
            { key: "br", top: false, left: false }
        ]

        delegate: PanelWindow {
            id: corner
            required property var modelData
            readonly property string action: String(root.cfg[modelData.key] || "-")

            visible: action !== "-" && action !== ""
            screen: Quickshell.screens[0]
            anchors {
                top: modelData.top
                bottom: !modelData.top
                left: modelData.left
                right: !modelData.left
            }
            implicitWidth: 2
            implicitHeight: 2
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "macos:hotcorner"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                property bool armed: true
                onEntered: if (armed) { armed = false; root.run(corner.action) }
                onExited: rearm.restart()
                Timer { id: rearm; interval: 600; onTriggered: parent.armed = true }
            }
        }
    }
}
