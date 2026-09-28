import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick.Layouts
import Quickshell.Wayland
import qs.ui.controls.auxiliary
import qs.ui.controls.providers
import qs.ui.controls.advanced
import qs.ui.controls.primitives
import qs.ui.controls.windows
import qs.core.system
import qs.config
import qs
import QtQuick.Controls.Fusion

Scope {
    function open() {
        root.bluetoothOpened = false;
        root.wifiOpened = false;
        panelWindow.opened = true;
    }
    id: root

    property color glassColor: Theme.glassColor
    property color glassRimColor: Theme.glassRimColor
    property real  glassRimStrengthWeak: Theme.glassRimStrengthWeak
    property real  glassRimStrength: Theme.glassRimStrength
    property real  glassRimStrengthStrong: Theme.glassRimStrengthStrong
    property point glassLightDirStrong: Theme.glassLightDirStrong
    property color textColor: Theme.textColor
    property int animationDur: 300

    required property var screen
    property alias opened: panelWindow.opened
    signal openBluetooth()
    signal openWifi()
    signal close()
    property bool bluetoothOpened: false
    property bool wifiOpened: false
    property bool windowOpened: bluetoothOpened || wifiOpened
    // ---- voice / call state (top pill) ----
    property bool inVoice: false
    property string voiceApp: ""
    readonly property bool voiceShift: inVoice && !windowOpened
    function voiceDisplayName() {
        const n = root.voiceApp;
        if (!n) return "";
        if (/discord|vesktop/i.test(n)) return "Discord";
        return n;
    }
    function refreshVoice() { voicePoll.running = true; }
    function doLock() {
        try {
            if (typeof ShellController !== "undefined") { ShellController.lock(); return; }
        } catch (e) {}
        if (typeof Ipc !== "undefined") Ipc.runMixin("eqdesktop.lock", "lock");
    }
    function doPower() {
        try {
            if (typeof ShellController !== "undefined") { ShellController.toggle("session"); return; }
        } catch (e) {}
    }
    // ---- airplane mode (rfkill wifi+bluetooth) ----
    property bool airplaneOn: false
    function toggleAirplane() {
        root.airplaneOn = !root.airplaneOn;
        _rfkill.command = ["bash", "-c", root.airplaneOn
            ? "rfkill block wifi; rfkill block bluetooth"
            : "rfkill unblock wifi; rfkill unblock bluetooth"];
        _rfkill.running = true;
    }
    function pollAirplane() { _rfkillQuery.running = true; }
    // ---- screen mirroring (state-only, like AirDrop) ----
    property bool mirroring: false

    Timer {
        interval: 2500
        running: root.opened
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refreshVoice()
    }
    Timer {
        interval: 3000
        running: root.opened
        repeat: true
        onTriggered: root.pollAirplane()
    }
    Process {
        id: voicePoll
        running: false
        command: ["bash", "-c", "(pactl -f json list source-outputs 2>/dev/null || echo []); echo '###SPLIT###'; (pactl -f json list sink-inputs 2>/dev/null || echo [])"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("###SPLIT###");
                    const firstName = (raw) => {
                        const d = JSON.parse(raw);
                        let name = "";
                        const walk = (o) => {
                            if (Array.isArray(o)) { o.forEach(walk); return; }
                            if (o && typeof o === "object") {
                                for (const k in o) {
                                    if (k === "application.name" && typeof o[k] === "string") {
                                        if (!name) name = o[k];
                                    } else walk(o[k]);
                                }
                            }
                        };
                        walk(d);
                        return name;
                    };
                    const rec = parts.length > 0 ? firstName(parts[0]) : "";
                    const play = parts.length > 1 ? firstName(parts[1]) : "";
                    root.voiceApp = rec || play;
                    root.inVoice = (rec + play).length > 0;
                } catch (e) { root.inVoice = false; }
            }
        }
    }
    Process {
        id: _rfkill
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }
    Process {
        id: _rfkillQuery
        running: false
        command: ["bash", "-c", "rfkill list 2>/dev/null | grep -A1 -E 'Wireless LAN|Bluetooth' | grep -c 'Soft blocked: yes' || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim());
                if (!isNaN(n)) root.airplaneOn = n >= 2;
            }
        }
    }
    function openCC() {
        root.open()
    }
    function closeCC() {
        panelWindow.opened = false;
    }
    Component.onCompleted: {
      Runtime.subscribe("controlCenterOpen", () => {
        openCC()
      })
      Runtime.subscribe("controlCenterClose", () => {
        closeCC()
      })
      Ipc.mixin("eqdesktop.controlCenter", "open", openCC)
      Ipc.mixin("eqdesktop.controlCenter", "close", closeCC)
    }
    Pop {
        id: panelWindow
        margins.right: 10
        keyboardFocus: WlrKeyboardFocus.Exclusive
        property int box: 65
        property int boxMargin: 10
        property int gridW: 4
        property int gridH: 7
        property int gridImplicitWidth: ((box*gridW)+(boxMargin*gridW)+boxMargin)
        property int gridImplicitHeight: ((box*gridH)+(boxMargin*gridH)+boxMargin)

        onClearing: {
        }

        onCleared: {
            root.close()
            if (root.bluetoothOpened) {
                root.bluetoothOpened = false;
                return;
            }
            if (root.wifiOpened) {
                root.wifiOpened = false;
                return;
            }
            panelWindow.opened = false;
        }

        function gridPos(x, y) {
            return {
                left: x*(box+boxMargin)+boxMargin,
                top: y*(box+boxMargin)+boxMargin
            }
        }

        function gridX(x) {
            return x*(box+boxMargin)+boxMargin
        }

        function gridY(y) {
            return y*(box+boxMargin)+boxMargin
        }

        component BoxButton: BoxGlass {
            id: boxbutton
            radius: 40
            property bool enabled: false
            property bool hideCause: root.bluetoothOpened || root.wifiOpened
            opacity: boxbutton.hideCause ? 0 : 1
            property bool scaleCause: false
            scale: boxbutton.scaleCause ? 1.25 : 1
            transform: Translate {
                y: boxbutton.hideCause ? 0 : 0
                Behavior on y { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            }
            transformOrigin: Item.Top
            property int xPos: 0
            property int yPos: 0
            property bool overwriteX: false
            property bool overwriteY: false
            property int overwriteXPos: 0
            property int overwriteYPos: 0
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: boxbutton.overwriteX ? boxbutton.overwriteXPos : panelWindow.gridX(boxbutton.xPos)
                topMargin: boxbutton.overwriteY ? boxbutton.overwriteYPos : panelWindow.gridY(boxbutton.yPos)
                Behavior on topMargin { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 1 } }
                Behavior on leftMargin { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 1 } }
            }
            Behavior on opacity { NumberAnimation { duration: root.animationDur/2 } }
            Behavior on scale { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            light: root.glassRimColor
            rimStrength: root.glassRimStrength
            color: boxbutton.enabled ? "#fff" : root.glassColor
            highlightEnabled: !boxbutton.enabled
        }

        component UIText: CFText {
            color: root.textColor
        }
        
        component Button1x1: BoxButton {
            id: buttonx1
            width: panelWindow.box
            height: panelWindow.box
        }

        onEscapePressed: () => {
            root.close()
            if (root.bluetoothOpened) {
                root.bluetoothOpened = false;
                return;
            }
            if (root.wifiOpened) {
                root.wifiOpened = false;
                return;
            }
            panelWindow.opened = false;
        }
        
        content: Item {
            id: contentRoot
            focus: true
            Rectangle {
                id: rect
                width: panelWindow.gridImplicitWidth
                height: panelWindow.gridImplicitHeight
                scale: root.windowOpened ? 0.8 : 1
                Behavior on scale { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                color: "transparent"
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: Config.bar.height + 5 + (root.voiceShift ? 46 : 0)
                    Behavior on topMargin { NumberAnimation { duration: root.animationDur } }
                }
                //Repeater {
                //    model: {
                //        var array = [];
                //        for (var i = 0; i <= 5; i++) {
                //            for (var j = 0; j <= 3; j++) {
                //                array.push([i, j]);
                //            }
                //        }
                //        return array
                //    }
                //    delegate: Item {
                //        width: panelWindow.box
                //        height: panelWindow.box
                //        anchors {
                //            top: parent.top
                //            left: parent.left
                //            topMargin: panelWindow.gridX(modelData[0])
                //            leftMargin: panelWindow.gridY(modelData[1])
                //        }
                //        Rectangle {
                //            anchors {
                //                top: parent.top
                //                left: parent.left
                //            }
                //            width: panelWindow.box
                //            height: 1
                //            color: "#f00"
                //        }
                //        Rectangle {
                //            anchors {
                //                top: parent.top
                //                left: parent.left
                //            }
                //            width: 1
                //            height: panelWindow.box
                //            color: "#0f0"
                //        }
                //        Rectangle {
                //            anchors.fill: parent
                //            color: "transparent"
                //            border {
                //                width: 1
                //                color: "#50ffffff"
                //            }
                //        }
                //        Rectangle {
                //            anchors.centerIn: parent
                //            color: "#ff0"
                //            width: 10
                //            height: 10
                //            radius: 5
                //        }
                //        Rectangle {
                //            anchors.centerIn: parent
                //            color: "#ff0"
                //            width: 20
                //            height: 3
                //            radius: 5
                //        }
                //        Rectangle {
                //            anchors.centerIn: parent
                //            color: "#ff0"
                //            width: 3
                //            height: 20
                //            radius: 5
                //        }
                //    }
                //}
                BoxButton {
                    id: wifiWidget
                    width: root.wifiOpened ? panelWindow.gridImplicitWidth : panelWindow.box*2+panelWindow.boxMargin
                    height: root.wifiOpened ? clippingRectWifi.implicitHeight : panelWindow.box
                    Behavior on width { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                    Behavior on height { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                    radius: root.wifiOpened ? 20 : 40
                    Behavior on radius { NumberAnimation { duration: root.animationDur } }
                    hideCause: root.bluetoothOpened

                    scaleCause: root.wifiOpened
                    light: root.wifiOpened ? "transparent" : root.glassRimColor
                    color: root.wifiOpened ? "transparent" : enabled ? "#fff" : root.glassColor
                    Behavior on color { ColorAnimation { duration: root.animationDur } }
                    xPos: 0
                    yPos: 0
                    overwriteX: root.wifiOpened
                    overwriteY: root.wifiOpened
                    overwriteXPos: 0
                    overwriteYPos: -60
                    Connections {
                        target: root
                        function onClose() {
                            if (root.wifiOpened) {
                                wifiWidget.scale = 1
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened || root.wifiOpened
                        onClicked: {
                            root.wifiOpened = !root.wifiOpened
                            if (root.wifiOpened) {
                                wifiWidget.scale = 1.25
                            } else {
                                wifiWidget.scale = 1
                            }
                        }
                        onPressed: {
                            if (root.wifiOpened) return;
                            wifiWidget.scale = 0.9
                        }
                        onReleased: {
                            wifiWidget.scale = 1.25
                        }
                        pressAndHoldInterval: 300
                        onPressAndHold: {
                            root.wifiOpened = true;
                            wifiWidget.scale = 1.25
                        }
                    }
                    UIText {
                        text: Translation.tr("Wi-Fi")
                        font.weight: 700
                        anchors {
                            left: wifiClipping.right
                            leftMargin: 5
                            top: wifiClipping.top
                        }
                        opacity: root.wifiOpened ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                    }
                    UIText {
                        text: NetworkManager.active ? NetworkManager.active.ssid : Translation.tr("No network")
                        elide: Text.ElideRight
                        gray: false
                        font.weight: 500
                        height: 20
                        width: panelWindow.box+10
                        anchors {
                            left: wifiClipping.right
                            leftMargin: 5
                            bottom: wifiClipping.bottom
                        }
                        opacity: root.wifiOpened ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                    }
                    ClippingRectangle {
                        id: wifiClipping
                        anchors {
                            left: parent.left
                            leftMargin: 15
                            verticalCenter: parent.verticalCenter
                        }
                        radius: 40
                        width: 40
                        height: 40
                        color: NetworkManager.active ? "#fff" : "transparent"
                        opacity: root.wifiOpened ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                        VectorImage {
                            transform: Translate {y:-3}
                            id: rBWifi
                            source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/wifi/nm-signal-100-symbolic.svg")
                            width: 25
                            height: 25
                            preferredRendererType: VectorImage.CurveRenderer
                            anchors.centerIn: parent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: NetworkManager.active ? "#2495ff" : "#fff"
                            }
                        }
                    }
                    ClippingRectangle {
                        anchors.fill: parent
                        id: clippingRectWifi
                        color: "transparent"
                        implicitHeight: root.wifiOpened ? wifiBox.implicitHeight : 0
                        implicitWidth: root.wifiOpened ? wifiWidget.width : 0
                        radius: root.wifiOpened ? 20 : 40
                        Behavior on radius { NumberAnimation { duration: root.animationDur } }
                        z: 100
                        layer.enabled: true
                        layer.samples: 4
                        opacity: root.wifiOpened ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                        BoxGlass {
                            id: wifiBox
                            anchors.fill: parent
                            radius: root.wifiOpened ? 20 : 40
                            Behavior on radius { NumberAnimation { duration: root.animationDur } }
                            implicitHeight: wifiCC.implicitHeight
                            color: root.glassColor
                            light: root.glassRimColor
                            rimStrength: root.glassRimStrengthStrong
                            lightDir: root.glassLightDirStrong
                            CCWifi {
                                id: wifiCC
                                width: panelWindow.gridImplicitWidth
                                glassColor: root.glassColor
                                glassRimColor: root.glassRimColor
                                glassRimStrength: root.glassRimStrength
                                glassRimStrengthStrong: root.glassRimStrengthStrong
                                glassLightDirStrong: root.glassLightDirStrong
                                textColor: root.textColor
                                z: 100
                            }
                        }
                    }
                }
                Button1x1 {
                    id: bluetoothWidget
                    xPos: 0
                    yPos: 1
                    overwriteX: root.bluetoothOpened
                    overwriteY: root.bluetoothOpened
                    overwriteXPos: 0
                    overwriteYPos: -60
                    hideCause: root.wifiOpened
                    width: root.bluetoothOpened ? panelWindow.gridImplicitWidth : panelWindow.box*2+panelWindow.boxMargin
                    height: root.bluetoothOpened ? 250 : panelWindow.box
                    Behavior on width { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                    Behavior on height { NumberAnimation { duration: root.animationDur; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
                    radius: root.bluetoothOpened ? 20 : 40
                    Behavior on radius { NumberAnimation { duration: root.animationDur } }
                    enabled: Bluetooth.defaultAdapter?.enabled || false
                    Connections {
                        target: root
                        function onClose() {
                            if (root.bluetoothOpened) {
                                bluetoothWidget.scale = 1
                            }
                        }
                    }
                    ClippingRectangle {
                        id: btClipping
                        anchors {
                            left: parent.left
                            leftMargin: 15
                            verticalCenter: parent.verticalCenter
                        }
                        radius: 40
                        width: 40
                        height: 40
                        color: Bluetooth.defaultAdapter?.enabled ? "#fff" : "transparent"
                        opacity: root.bluetoothOpened ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                        VectorImage {
                            id: rBBluetooth
                            source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/bluetooth-clear.svg")
                            width: 24
                            height: 24
                            preferredRendererType: VectorImage.CurveRenderer
                            anchors.centerIn: parent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: Bluetooth.defaultAdapter?.enabled ? "#2495ff" : "#fff"
                            }
                        }
                    }
                    UIText {
                        text: Translation.tr("Bluetooth")
                        font.weight: 700
                        anchors {
                            left: btClipping.right
                            leftMargin: 5
                            top: btClipping.top
                        }
                        opacity: root.bluetoothOpened ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                    }
                    UIText {
                        text: Bluetooth.defaultAdapter?.enabled ? Translation.tr("On") : Translation.tr("Off")
                        elide: Text.ElideRight
                        gray: false
                        font.weight: 500
                        height: 20
                        width: panelWindow.box+10
                        anchors {
                            left: btClipping.right
                            leftMargin: 5
                            bottom: btClipping.bottom
                        }
                        opacity: root.bluetoothOpened ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened || root.bluetoothOpened
                        onClicked: {
                            root.bluetoothOpened = !root.bluetoothOpened
                            if (root.bluetoothOpened) {
                                bluetoothWidget.scale = 1.25
                            } else {
                                bluetoothWidget.scale = 1
                            }
                        }
                        onPressed: {
                            if (root.bluetoothOpened) return;
                            bluetoothWidget.scale = 0.9
                        }
                        onReleased: {
                            bluetoothWidget.scale = 1.25
                        }
                        pressAndHoldInterval: 300
                        onPressAndHold: {
                            root.bluetoothOpened = true;
                            bluetoothWidget.scale = 1.25
                        }
                    }
                    scaleCause: root.bluetoothOpened
                    light: root.bluetoothOpened ? "transparent" : root.glassRimColor
                    color: root.bluetoothOpened ? "transparent" : root.glassColor
                    Behavior on color { ColorAnimation { duration: root.animationDur } }
                    ClippingRectangle {
                        id: clippingRectBluetooth
                        anchors.fill: parent
                        color: "transparent"
                        radius: root.bluetoothOpened ? 20 : 40
                        implicitHeight: root.bluetoothOpened ? bluetoothWidget.height : 0
                        implicitWidth: root.bluetoothOpened ? bluetoothWidget.width : 0
                        Behavior on radius { NumberAnimation { duration: root.animationDur } }
                        z: 100
                        layer.enabled: true
                        layer.samples: 4
                        opacity: root.bluetoothOpened ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                        BoxGlass {
                            anchors.fill: parent
                            radius: root.bluetoothOpened ? 20 : 40
                            Behavior on radius { NumberAnimation { duration: root.animationDur } }
                            color: root.glassColor
                            light: root.glassRimColor
                            rimStrength: root.glassRimStrengthStrong
                            lightDir: root.glassLightDirStrong
                            CCBluetooth {
                                width: panelWindow.gridImplicitWidth
                                height: 250
                                glassColor: root.glassColor
                                glassRimColor: root.glassRimColor
                                glassRimStrength: root.glassRimStrength
                                glassRimStrengthStrong: root.glassRimStrengthStrong
                                glassLightDirStrong: root.glassLightDirStrong
                                textColor: root.textColor
                            }
                        }
                    }
                }
                BoxButton {
                    id: airplaneWidget
                    width: panelWindow.box*2+panelWindow.boxMargin
                    height: panelWindow.box
                    radius: 40
                    xPos: 0
                    yPos: 2
                    enabled: false
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened
                        onClicked: root.toggleAirplane()
                    }
                    ClippingRectangle {
                        id: airClipping
                        anchors {
                            left: parent.left
                            leftMargin: 15
                            verticalCenter: parent.verticalCenter
                        }
                        radius: 40
                        width: 40
                        height: 40
                        color: root.airplaneOn ? "#fff" : "transparent"
                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/airplane.svg")
                            sourceSize: Qt.size(24, 24)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 40
                            color: "transparent"
                        }
                    }
                    UIText {
                        text: Translation.tr("Airplane")
                        font.weight: 700
                        anchors {
                            left: airClipping.right
                            leftMargin: 5
                            top: airClipping.top
                        }
                    }
                    UIText {
                        text: root.airplaneOn ? Translation.tr("On") : Translation.tr("Off")
                        font.weight: 500
                        height: 20
                        anchors {
                            left: airClipping.right
                            leftMargin: 5
                            bottom: airClipping.bottom
                        }
                    }
                }
                Button1x1 {
                    id: darkModeWidget
                    xPos: 2
                    yPos: 2
                    enabled: Config.general.darkMode && !Config.general.autoDarkMode
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened
                        onClicked: {
                            Config.general.darkMode = !Config.general.darkMode;
                            Config.general.autoDarkMode = false;
                        }
                    }
                    VectorImage {
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dnd.svg")
                        width: panelWindow.box-30
                        height: panelWindow.box-30
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors.centerIn: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: darkModeWidget.enabled ? "#2495ff" : "#fff"
                        }
                    }
                }
                Button1x1 {
                    id: lockWidget
                    xPos: 3
                    yPos: 2
                    enabled: false
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened
                        onClicked: root.doLock()
                    }
                    VectorImage {
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/lock.svg")
                        width: panelWindow.box-34
                        height: panelWindow.box-34
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors.centerIn: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: "#fff"
                        }
                    }
                }
                Button1x1 {
                    id: mirrorWidget
                    xPos: 0
                    yPos: 3
                    enabled: root.mirroring
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened
                        onClicked: root.mirroring = !root.mirroring
                    }
                    VectorImage {
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/arrow-right.svg")
                        width: panelWindow.box-30
                        height: panelWindow.box-30
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors.centerIn: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: mirrorWidget.enabled ? "#2495ff" : "#fff"
                        }
                    }
                }
                Button1x1 {
                    id: powerWidget
                    xPos: 1
                    yPos: 3
                    enabled: false
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened
                        onClicked: root.doPower()
                    }
                    VectorImage {
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/power.svg")
                        width: panelWindow.box-30
                        height: panelWindow.box-30
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors.centerIn: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: "#fff"
                        }
                    }
                }
                BoxButton {
                    id: focusWidget
                    width: panelWindow.box*2+panelWindow.boxMargin
                    height: panelWindow.box
                    radius: 40
                    xPos: 2
                    yPos: 3
                    Loader {
                        anchors.fill: parent
                        active: !root.windowOpened
                        sourceComponent: MouseArea {
                            preventStealing: true
                            propagateComposedEvents: true
                            onClicked: {
                                NotificationDaemon.toggleDND()
                            }
                        }
                    }
                    ClippingRectangle {
                        id: focusClipping
                        anchors {
                            left: parent.left
                            leftMargin: 15
                            verticalCenter: parent.verticalCenter
                        }
                        radius: 40
                        width: 40
                        height: 40
                        color: NotificationDaemon.popupInhibited ? "#ffffff" : root.glassColor
                        VectorImage {
                            id: rBFocus
                            source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/dnd.svg")
                            width: 40
                            height: 40
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            preferredRendererType: VectorImage.CurveRenderer
                            anchors.centerIn: parent
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: NotificationDaemon.popupInhibited ? "#2495ff" : "#fff"
                            }
                        }
                    }
                    UIText {
                        text: Translation.tr("Focus")
                        font.weight: 600
                        anchors {
                            left: focusClipping.right
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }
                BoxButton {
                    id: musicWidget
                    width: panelWindow.box*2+panelWindow.boxMargin
                    height: panelWindow.box*2+panelWindow.boxMargin
                    radius: 25
                    xPos: 2
                    yPos: 0
                    MusicPlayer {
                        glassColor: root.glassColor
                        glassRimColor: root.glassRimColor
                        glassRimStrength: root.glassRimStrength
                        glassRimStrengthStrong: root.glassRimStrengthStrong
                        glassLightDirStrong: root.glassLightDirStrong
                        textColor: root.textColor
                    }
                }
                BoxButton {
                    id: displayWidget
                    width: panelWindow.box*4+panelWindow.boxMargin*3
                    height: panelWindow.box
                    radius: 25
                    xPos: 0
                    yPos: 4
                    UIText {
                        id: brightnessTitle
                        anchors {
                            top: parent.top
                            left: parent.left
                            topMargin: 10
                            leftMargin: 15
                        }
                        font.weight: 600
                        text: Translation.tr("Display")
                    }
                    VectorImage {
                        id: rBDisplayLeft
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/sun-small.svg")
                        width: 15
                        height: 15
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors {
                            verticalCenter: brightnessSlider.verticalCenter
                            right: brightnessSlider.left
                            rightMargin: 5
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: "#fff"
                        }
                    }
                    VectorImage {
                        id: rBDisplayRight
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/sun-huge.svg")
                        width: 15
                        height: 15
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors {
                            verticalCenter: brightnessSlider.verticalCenter
                            left: brightnessSlider.right
                            leftMargin: 5
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: "#fff"
                        }
                    }
                    CFSlider {
                        id: brightnessSlider
                        anchors {
                            top: brightnessTitle.bottom
                            left: parent.left
                            right: parent.right
                            topMargin: 10
                            leftMargin: 30
                            rightMargin: 30
                        }
                        from: 0
                        to: 1
                        stepSize: 1 / 100.0
                        value: Brightness.monitors[0].brightness
                        property var lastValue: null
                        property bool screenDimHelper: false
                        enabled: !root.windowOpened

                        // Update the monitor brightness when the slider moves
                        onValueChanged: {
                            Brightness.monitors[0].setBrightnessDebounced(value)
                            if (value <= 0.01) {
                                screenIsStillOn.restart()
                            } else {
                                if (screenDimHelper) return
                                screenIsStillOn.stop()
                                screenIsStillOn2.stop()
                            }
                        }
                        Connections {
                            target: Brightness
                            function onMonitorBrightnessChanged(monitor, newBrightness) {
                                if (monitor === Brightness.monitors[0]) {
                                    brightnessSlider.value = newBrightness
                                }
                            }
                        }

                        Timer {
                            id: screenIsStillOn
                            interval: 1000 * 15 // 15 seconds
                            running: false
                            repeat: false
                            onTriggered: {
                                brightnessSlider.lastValue = brightnessSlider.value
                                brightnessSlider.screenDimHelper = true
                                Brightness.monitors[0].setBrightnessDebounced(0.05)
                                screenIsStillOn2.start()
                            }
                        }
                        Timer {
                            id: screenIsStillOn2
                            interval: 2500
                            running: false
                            onTriggered: {
                                Brightness.monitors[0].setBrightnessDebounced(brightnessSlider.lastValue)
                                brightnessSlider.screenDimHelper = false
                            }
                        }
                    }
                }
                BoxButton {
                    id: volumeWidget
                    width: panelWindow.box*4+panelWindow.boxMargin*3
                    height: panelWindow.box
                    radius: 25
                    xPos: 0
                    yPos: 5
                    UIText {
                        id: volumeTitle
                        anchors {
                            top: parent.top
                            left: parent.left
                            topMargin: 10
                            leftMargin: 15
                        }
                        font.weight: 600
                        text: Translation.tr("Sound")
                    }
                    VectorImage {
                        id: rBVolumeLeft
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/volume/audio-volume-1.svg")
                        width: 15
                        height: 15
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors {
                            verticalCenter: volumeSlider.verticalCenter
                            right: volumeSlider.left
                            rightMargin: 5
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: "#fff"
                        }
                    }
                    VectorImage {
                        id: rBVolumeRight
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/volume/audio-volume-3.svg")
                        width: 15
                        height: 15
                        preferredRendererType: VectorImage.CurveRenderer
                        anchors {
                            verticalCenter: volumeSlider.verticalCenter
                            left: volumeSlider.right
                            leftMargin: 5
                        }
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1
                            colorizationColor: "#fff"
                        }
                    }
                    PwObjectTracker {
                        objects: [ Pipewire.defaultAudioSink ]
                    }
                    CFSlider {
                        id: volumeSlider
                        anchors {
                            top: volumeTitle.bottom
                            left: parent.left
                            right: parent.right
                            topMargin: 10
                            leftMargin: 30
                            rightMargin: 30
                        }
                        enabled: !root.windowOpened
                        from: 0
                        to: 1
                        stepSize: 1 / 100.0
                        value: Pipewire.defaultAudioSink?.audio.volume || 0
                        onValueChanged: {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                Pipewire.defaultAudioSink.audio.volume = volumeSlider.value
                            }
                        }
                    }
                }
                BoxButton {
                    id: settingsWidget
                    width: settingsLabel.implicitWidth + 40
                    height: 46
                    radius: 40
                    xPos: 1
                    yPos: 6
                    enabled: false
                    anchors.leftMargin: panelWindow.gridX(1) + (panelWindow.box*2 + panelWindow.boxMargin - width) / 2
                    anchors.topMargin: panelWindow.gridY(6) + (panelWindow.box - height) / 2
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.windowOpened
                        onClicked: {
                            Runtime.settingsOpen = true;
                            root.closeCC();
                        }
                    }
                    UIText {
                        id: settingsLabel
                        text: Translation.tr("Edit Controls")
                        font.weight: 600
                        anchors.centerIn: parent
                    }
                }
                BoxGlass {
                    id: voicePill
                    radius: 30
                    height: 36
                    width: voiceRow.implicitWidth + 30
                    color: root.glassColor
                    light: root.glassRimColor
                    rimStrength: root.glassRimStrength
                    anchors {
                        bottom: parent.top
                        bottomMargin: 8
                        horizontalCenter: parent.horizontalCenter
                    }
                    opacity: (root.inVoice && !root.windowOpened) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: root.animationDur } }
                    Row {
                        id: voiceRow
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: "#ff9500"
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/audio-volume.svg")
                                sourceSize: Qt.size(15, 15)
                            }
                        }
                        UIText {
                            text: root.voiceDisplayName()
                            font.weight: 700
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}