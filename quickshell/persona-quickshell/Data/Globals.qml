pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // Shared mouse position for parallax (set by WallpaperEngine's MouseArea)
    property real mouseOffsetX: 0.0
    property real mouseOffsetY: 0.0

    Behavior on mouseOffsetX {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutQuart
        }
    }
    Behavior on mouseOffsetY {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutQuart
        }
    }
}
