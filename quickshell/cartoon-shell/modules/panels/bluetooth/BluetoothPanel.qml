// Bluetooth Panel - Main component
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.services
import "." as Com
import qs.commons
import qs.components

PanelWindow {
    id: root
    implicitWidth: ScalerService.s(450)
    implicitHeight: ScalerService.s(600)
    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 60
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 60
            easing.type: Easing.OutCubic
        }
    }
    anchors {
        // Anchor theo vị trí của bar
        left: Settings.bar.position === "left"
        right: Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom"
        top: Settings.bar.position === "top"
        bottom: Settings.bar.position === "left" || Settings.bar.position === "right" || Settings.bar.position === "bottom"
    }

    margins {
        top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
        bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(10) : 0
        left: Settings.bar.position === "left" ? ScalerService.s(10) : 0
        right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
    }
    color: "transparent"
    focusable: true
    aboveWindows: true
    objectName: "BluetoothPanel"

    property var adapter: Bluetooth.defaultAdapter
    property int connectedCount: {
        let count = 0;
        for (let i = 0; i < Bluetooth.devices.length; i++) {
            if (Bluetooth.devices[i].connected)
                count++;
        }
        return count;
    }

    property bool isDiscoverable: adapter ? adapter.discoverable : false
    property bool isPairable: adapter ? adapter.pairable : true

    // Timer to automatically stop scanning after 30 seconds
    Timer {
        id: scanTimer
        interval: 30000
        onTriggered: {
            if (adapter && adapter.discovering) {
                adapter.discovering = false;
            }
        }
    }

    // Show error message when pairing fails
    property string pairErrorMessage: ""
    Timer {
        id: errorMessageTimer
        interval: 5000
        onTriggered: pairErrorMessage = ""
    }

    // Main container
    Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0 ? parent.width : 0
        implicitHeight: root.animationProgress > 0 ? parent.height : 0
        color: theme.primary.background
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
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
                circleCount: 4
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(10)
            spacing: ScalerService.s(6)

            // Header with title and scan button
            Com.BluetoothHeader {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(40)
            }

            // Error message
            Rectangle {
                Layout.fillWidth: true
                height: pairErrorMessage ? ScalerService.s(40) : 0
                radius: ScalerService.s(8)
                color: theme.normal.red
                visible: pairErrorMessage !== ""
                clip: true

                Behavior on height {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)

                    Text {
                        text: "⚠️ " + pairErrorMessage
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(12)
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "✕"
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(14)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: pairErrorMessage = ""
                        }
                    }
                }
            }

            // Status card with toggle
            Com.BluetoothStatusCard {
                adapter: root.adapter
                connectedCount: root.connectedCount
            }

            // Device list
            Com.BluetoothDeviceList {
                adapter: root.adapter
                connectedCount: root.connectedCount

                onPairError: function (message) {
                    pairErrorMessage = message;
                    errorMessageTimer.restart();
                }
            }

            // Disabled state message
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !adapter?.enabled

                Column {
                    anchors.centerIn: parent
                    spacing: ScalerService.s(16)

                    IconText {
                        name: "android_cell_5_bar_off"
                        textColor: theme.primary.dim_foreground
                        size: "2xl"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: lang?.bluetooth?.disabled || "Bluetooth đã tắt"
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(16)
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: lang?.bluetooth?.turn_on || "Bật Bluetooth để kết nối với thiết bị"
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(12)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
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

    // Monitor adapter changes
    Connections {
        target: adapter
        enabled: !!adapter
        function onEnabledChanged() {
            if (adapter?.enabled) {
                // When enabling adapter, set default modes
                adapter.pairable = true;
                adapter.discoverable = false; // Default not discoverable
            }
        }
        function onDiscoveringChanged() {
        }
        function onDiscoverableChanged() {
        }
        function onPairableChanged() {
        }
    }

    // Monitor device list changes
    Connections {
        target: Bluetooth
        function onDevicesChanged() {
        }
    }

    Component.onCompleted: {
        // Ensure adapter is pairable on startup
        if (adapter && adapter.enabled) {
            adapter.pairable = true;
        }
    }
}
