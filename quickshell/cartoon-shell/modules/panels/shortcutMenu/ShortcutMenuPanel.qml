import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import qs.commons
import "." as Com

PanelWindow {
    id: root

    implicitWidth: ScalerService.s(250)
    implicitHeight: ScalerService.s(600) // Tăng chiều cao để chứa danh sách Category nằm dọc
    property real animationProgress: 0
    property real xMargins: 0
    property real yMargins: 0

    property string selectedCategory: "All"

    // Danh sách Category
    readonly property var categoryList: ["Accessories", "Programming", "Graphics", "Internet", "Office", "Sound & Video", "System", "Preferences", "Other"]

    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }

    anchors {
        left: true
        top: true
    }

    margins {
        left: root.xMargins
        top: root.yMargins
    }

    color: "transparent"
    focusable: true
    WifiService {
        id: wifiManager
    }

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0 ? parent.width : 0
        implicitHeight: root.animationProgress > 0 ? parent.height : 0
        Behavior on implicitHeight {
            NumberAnimation {
                id: heightAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                id: widthAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: FloatingCircles {
                circleColor: theme.button.text
                anchors.fill: parent
                circleCount: 2
            }
        }
        color: theme.primary.background
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        border.color: theme.button.border
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(16)
            spacing: ScalerService.s(5)

            Com.SearchMenu {}

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(1)
                radius: ScalerService.s(1)
                color: theme.primary.dim_foreground
            }

            Com.ItemShortcut {
                icon: "image://icon/kitty"
                name: "Terminal"
            }
            Com.ItemShortcut {
                icon: "image://icon/zen-browser"
                name: "Browser"
            }
            Com.ItemShortcut {
                icon: "image://icon/nautilus"
                name: "File explorer"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(1)
                radius: ScalerService.s(1)
                color: theme.primary.dim_foreground
            }

            // --- PHẦN CATEGORY (Xếp dọc giống ItemShortcut, Icon để trống) ---
            Repeater {
                model: root.categoryList

                delegate: Com.ItemShortcut {
                    required property string modelData
                    required property int index
                    icon: "image://icon/nautilus"
                    name: modelData
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(1)
                radius: ScalerService.s(1)
                color: theme.primary.dim_foreground
            }

            Com.ItemShortcut {
                icon: Directories.assetsPath + "/system/sys-lock.png"
                name: "Lock"
            }
            Com.ItemShortcut {
                icon: Directories.assetsPath + "/system/sys-exit.png"
                name: "Exit"
            }
        }

        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: StarField {
                starCount: 10
                shootingStarCount: 3
            }
        }
    }
}
