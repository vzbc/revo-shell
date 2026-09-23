import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Effects

import qs.components
import qs.modules.dialogs
import qs.modules.panels
import qs.modules.bar
import qs.modules.background
import qs.services
import qs.modules.lockscreen
import qs.commons

ShellRoot {
    id: root
    ConfirmDialog {
        id: confirmDialog
    }
    LoaderService {
        id: loaderService
    }
    property var theme: ThemeService.theme
    property var lang: LanguageService.translations

    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

    function showConfirmDialog(action, actionLabel) {
        confirmDialog.show(action, actionLabel);
    }

    property bool settingsLoaded: false

    PanelWindow {
        visible: VisibleService.hasPanel
        color: "transparent"

        implicitWidth: (Settings.bar.position === "left" || Settings.bar.position === "right") ? Screen.width - 40 : Screen.width
        implicitHeight: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? Screen.height - 50 : Screen.height

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                VisibleService.closeAllPanels();
            }
        }
    }
    Connections {
        target: Settings ? Settings : null
        function onSettingsLoaded() {
            root.settingsLoaded = true;
        }
    }
    Lock {}

    Loader {
        active: root.settingsLoaded && Directories.ready
        sourceComponent: Item {
            Component.onCompleted: {
                ThemeService.init();
                WallpaperService.init();
                ProgramCheckerService.init();
                LanguageService.init();
            }

            Background {}
            Bar {}
            NotificationPopup {}
            VolumeOsd {}
            BrightnessOsd {}
        }
    }
}
