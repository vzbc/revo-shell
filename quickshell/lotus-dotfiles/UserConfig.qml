import QtQuick
import Quickshell

QtObject {
    readonly property string launcherScript: Quickshell.env("HOME") + "/.config/rofi/rofi.sh"
    readonly property string brightnessScript: Quickshell.env("HOME") + "/.config/hypr/scripts/brightnesscontrol.sh"
    readonly property var terminalCommand: ["ghostty", "-e"]
    readonly property bool clipboardCaptureEnabled: Quickshell.env("LOTUS_DISABLE_CLIPBOARD_CAPTURE") !== "1"
    readonly property bool nativeNotificationsEnabled: Quickshell.env("LOTUS_NOTIFICATION_SERVER") === "1"
    readonly property bool notificationFixturesEnabled: Quickshell.env("LOTUS_NOTIFICATION_FIXTURES") === "1"
}
