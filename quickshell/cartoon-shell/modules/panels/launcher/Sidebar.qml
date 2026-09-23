import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components
import qs.commons

Rectangle {
    id: root
    Layout.preferredWidth: ScalerService.s(210)
    property real animationProgress: 0

    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 700
            easing.type: Easing.Linear
        }
    }
    Layout.fillHeight: true
    color: Qt.alpha(theme.primary.dim_background, 0.6)
    border.color: theme.button.border
    radius: ScalerService.s(Settings.appearance.radius2)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    signal confirmRequested(string action, string actionLabel)

    function showConfirmDialog(action, actionLabel) {
        // Emit signal để parent components xử lý
        confirmRequested(action, actionLabel);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(12)
        spacing: ScalerService.s(10)

        // Tiêu đề Menu
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: launcherButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.1 ? parent.height : 0
                color: mouseAreaLauncher.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaLauncher.containsPress ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaLauncher.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "launcher/dashboard"
                        rotation: mouseAreaLauncher.containsMouse ? 0 : 90
                        opacity: root.animationProgress > 0.2 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "apps"
                        textColor: theme.button.text
                        opacity: root.animationProgress > 0.2 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        opacity: root.animationProgress > 0.2 ? 1 : 0
                        text: lang.system.application
                        scale: mouseAreaLauncher.containsMouse ? 1.05 : 1.0
                        textColor: mouseAreaLauncher.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaLauncher.containsMouse
                        size: "small"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Indicator khi selected
                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.green
                        visible: false // Sẽ được điều khiển bởi trạng thái selected
                        opacity: mouseAreaLauncher.containsMouse ? 1.0 : 0.8

                        scale: false ? 1.0 : 0.0 // Thay false bằng điều kiện selected thực tế
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaLauncher
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        VisibleService.togglePanel("listLauncher");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Cài đặt
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: settingsButton
                implicitWidth: root.animationProgress > 0.2 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.2 ? parent.height : 0
                anchors.centerIn: parent
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                color: mouseAreaSettings.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaSettings.containsPress ? theme.button.border_select : theme.button.border

                scale: mouseAreaSettings.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "system/setting.png"
                        rotation: mouseAreaSettings.containsMouse ? 360 : 0
                        opacity: root.animationProgress > 0.3 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "settings"
                        rotation: mouseAreaSettings.containsMouse ? 360 : 0
                        opacity: root.animationProgress > 0.3 ? 1 : 0
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.settings.title
                        textColor: mouseAreaSettings.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaSettings.containsMouse
                        size: "small"
                        scale: mouseAreaSettings.containsMouse ? 1.05 : 1.0
                        opacity: root.animationProgress > 0.3 ? 1 : 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Indicator khi selected
                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.blue
                        visible: false // Sẽ được điều khiển bởi trạng thái selected
                        opacity: mouseAreaSettings.containsMouse ? 1.0 : 0.8

                        scale: false ? 1.0 : 0.0 // Thay false bằng điều kiện selected thực tế
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaSettings
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        VisibleService.togglePanel("setting");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Chế độ ngủ - Sửa theo chuẩn CustomRectangle
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: sleepButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.3 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.3 ? parent.height : 0
                color: mouseAreaSleep.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaSleep.containsPress ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaSleep.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "system/sys-sleep.png"
                        rotation: mouseAreaSleep.containsMouse ? 5 : 0
                        opacity: root.animationProgress > 0.4 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "moon_stars"
                        opacity: root.animationProgress > 0.4 ? 1 : 0
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.system.sleep
                        textColor: mouseAreaSleep.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaSleep.containsMouse
                        size: "small"
                        opacity: root.animationProgress > 0.4 ? 1 : 0
                        scale: mouseAreaSleep.containsMouse ? 1.05 : 1.0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.blue
                        visible: false
                        opacity: mouseAreaSleep.containsMouse ? 1.0 : 0.8
                        scale: false ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaSleep
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        showConfirmDialog("sleep", lang?.confirm?.sleep || "chuyển sang chế độ ngủ");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Khóa màn hình - Sửa theo chuẩn CustomRectangle
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: lockButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.4 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.4 ? parent.height : 0
                color: mouseAreaLock.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaLock.containsPress ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaLock.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "system/sys-lock.png"
                        rotation: mouseAreaLock.containsMouse ? 5 : 0
                        opacity: root.animationProgress > 0.5 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "lock_clock"
                        opacity: root.animationProgress > 0.5 ? 1 : 0
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.system.lock
                        textColor: mouseAreaLock.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaLock.containsMouse
                        size: "small"
                        scale: mouseAreaLock.containsMouse ? 1.05 : 1.0
                        opacity: root.animationProgress > 0.5 ? 1 : 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.blue
                        visible: false
                        opacity: mouseAreaLock.containsMouse ? 1.0 : 0.8
                        scale: false ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaLock
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        showConfirmDialog("lock", lang?.confirm?.lock || "khóa màn hình");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Đăng xuất - Sửa theo chuẩn CustomRectangle
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: logoutButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.5 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.5 ? parent.height : 0
                color: mouseAreaLogout.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaLogout.containsPress ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaLogout.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "system/sys-exit.png"
                        rotation: mouseAreaLogout.containsMouse ? -5 : 0
                        opacity: root.animationProgress > 0.6 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "logout"
                        opacity: root.animationProgress > 0.6 ? 1 : 0
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.system.logout
                        textColor: mouseAreaLogout.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaLogout.containsMouse
                        size: "small"
                        scale: mouseAreaLogout.containsMouse ? 1.05 : 1.0
                        opacity: root.animationProgress > 0.6 ? 1 : 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.blue
                        visible: false
                        opacity: mouseAreaLogout.containsMouse ? 1.0 : 0.8
                        scale: false ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaLogout
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        showConfirmDialog("logout", lang?.confirm?.logout || "đăng xuất");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Khởi động lại - Sửa theo chuẩn CustomRectangle
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: restartButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.6 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.6 ? parent.height : 0
                color: mouseAreaRestart.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaRestart.containsPress ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaRestart.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "system/sys-reboot.png"
                        rotation: mouseAreaRestart.containsMouse ? 180 : 0
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "refresh"
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.system.restart
                        textColor: mouseAreaRestart.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaRestart.containsMouse
                        size: "small"
                        scale: mouseAreaRestart.containsMouse ? 1.05 : 1.0
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.blue
                        visible: false
                        opacity: mouseAreaRestart.containsMouse ? 1.0 : 0.8
                        scale: false ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaRestart
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        showConfirmDialog("restart", lang?.confirm?.restart || "khởi động lại");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // Tắt máy - Sửa theo chuẩn CustomRectangle
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(60)
            CustomRectangle {
                id: shutdownButton
                anchors.centerIn: parent
                implicitWidth: root.animationProgress > 0.7 ? parent.width : 0
                implicitHeight: root.animationProgress > 0.7 ? parent.height : 0
                color: mouseAreaShutdown.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6)
                border.color: mouseAreaShutdown.containsPress ? theme.button.border_select : theme.button.border
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
                radius: ScalerService.s(Settings.appearance.radius3)
                scale: mouseAreaShutdown.containsPress ? 0.98 : 1.0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    IconImage {
                        path: "system/poweroff.png"
                        scale: mouseAreaShutdown.containsMouse ? 1.1 : 1.0
                        opacity: root.animationProgress > 0.8 ? 1 : 0
                        visible: Settings.appearance.styleIcons === "image"
                    }
                    IconText {
                        name: "power_settings_new"
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                        textColor: theme.button.text
                        visible: Settings.appearance.styleIcons === "icon"
                    }

                    CustomText {
                        text: lang.system.shutdown
                        textColor: mouseAreaShutdown.containsMouse ? theme.primary.bright_foreground : theme.primary.foreground
                        isBold: mouseAreaShutdown.containsMouse
                        size: "small"
                        scale: mouseAreaShutdown.containsMouse ? 1.05 : 1.0
                        opacity: root.animationProgress > 0.8 ? 1 : 0
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(4)
                        Layout.preferredHeight: ScalerService.s(20)
                        radius: ScalerService.s(2)
                        color: theme.normal.blue
                        visible: false
                        opacity: mouseAreaShutdown.containsMouse ? 1.0 : 0.8
                        scale: false ? 1.0 : 0.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseAreaShutdown
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        showConfirmDialog("shutdown", lang?.confirm?.shutdown || "tắt máy");
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
