import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray
import "../../components"
import "../../windows"
import "../../"

RowLayout {
    id: root

    RowLayout {
        id: trayRow
        Layout.alignment: Qt.AlignVCenter
        
        // Custom state for toggling
        property bool isOpen: false

        // UX: Smooth fade and slide animation instead of abruptly disappearing
        visible: opacity > 0
        opacity: isOpen ? 1 : 0
        Layout.preferredWidth: isOpen ? implicitWidth : 0
        clip: true

        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                // UX: Larger 28x28 hit-box makes it easier to click than a 16x16 icon
                width: 26
                height: 26
                radius: 6
                color: trayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent" // Subtle hover effect
                
                Image {
                    width: 16
                    height: 16
                    anchors.centerIn: parent
                    source: modelData.icon
                    smooth: true
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor // Visual cue that it's clickable
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                            // Support for native context menus if Quickshell exposes it
                            if (typeof modelData.contextMenu === "function") {
                                modelData.contextMenu() 
                            }
                        }
                    }
                }
            }
        }
    }

    // Tray Toggle Button
    IconBtn {
        Layout.alignment: Qt.AlignVCenter
        text: trayRow.isOpen ? "" : ""
        onClicked: trayRow.isOpen = !trayRow.isOpen
    }
}