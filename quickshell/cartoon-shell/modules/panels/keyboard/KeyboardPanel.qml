import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import qs.commons
import qs.components

PanelWindow {
    id: root

    implicitWidth: ScalerService.s(1000)
    implicitHeight: ScalerService.s(400)
    WlrLayershell.layer: WlrLayer.Overlay

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
    exclusiveZone: 0

    property var lang: LanguageService.translations

    // --- CẤU HÌNH TỰ DO DI CHUYỂN (FREE MOVABLE) ---
    anchors {
        top: true
        left: true
        bottom: false
        right: false
    }

    margins {
        left: ScalerService.s(460)
        top: ScalerService.s(600)
    }

    color: "transparent"

    // --- TRẠNG THÁI BÀN PHÍM ---
    property bool isShifted: false
    property bool isCapsLock: false
    readonly property bool isUppercase: isShifted || isCapsLock

    signal keyClicked(string keyText)

    Process {
        id: dotoolProcess
        command: ["dotool"]
        running: true
    }

    function sendKey(key) {
        var commandString = "";

        if (key === "Backspace") {
            commandString = "key k:14\n";
        } else if (key === "\t") {
            commandString = "key k:15\n";
        } else if (key === "\n") {
            commandString = "key k:28\n";
        } else if (key === " ") {
            commandString = "key k:57\n";
        } else if (key === "Left") {
            commandString = "key k:105\n";
        } else if (key === "Right") {
            commandString = "key k:106\n";
        } else if (key === "Up") {
            commandString = "key k:103\n";
        } else if (key === "Down") {
            commandString = "key k:108\n";
        } else if (key.length === 1) {
            commandString = "type " + key + "\n";
        }

        if (commandString !== "" && dotoolProcess.running) {
            dotoolProcess.write(commandString);
        }
    }

    onKeyClicked: function (keyText) {
        sendKey(keyText);
        if (root.isShifted) {
            root.isShifted = false;
        }
    }

    // --- NỀN VÀ KHU VỰC KÉO DI CHUYỂN ---
    Rectangle {
        id: backgroundRect
        anchors.fill: parent

        color: theme.primary.background
        border.color: dragTimer.dragEnabled ? theme.normal.blue : theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        clip: true

        // KHU VỰC BẮT SỰ KIỆN GIỮ CHUỘT 1 GIÂY
        MouseArea {
            id: holdArea
            anchors.fill: parent
            // Đặt prop: true để MouseArea không chặn bấm nút phím phía trên
            propagateComposedEvents: true

            onPressed: mouse => {
                dragTimer.start();
                mouse.accepted = false; // Cho phép sự kiện truyền tiếp xuống các phím
            }
            onReleased: {
                dragTimer.stop();
                dragTimer.dragEnabled = false;
            }
            onCanceled: {
                dragTimer.stop();
                dragTimer.dragEnabled = false;
            }
        }

        Timer {
            id: dragTimer
            interval: 1000 // Giữ 1000ms (1 giây)
            repeat: false
            property bool dragEnabled: false

            onTriggered: {
                dragEnabled = true;
            }
        }

        // DRAG HANDLER CHO PHÉP KÉO TOÀN BỘ BACKGROUND
        DragHandler {
            id: dragHandler
            target: null
            // Chỉ bật DragHandler khi đã giữ đủ 1 giây
            enabled: dragTimer.dragEnabled

            property real startLeft: 0
            property real startTop: 0

            onActiveChanged: {
                if (active) {
                    startLeft = root.margins.left;
                    startTop = root.margins.top;
                }
            }

            onTranslationChanged: {
                if (active) {
                    var newLeft = startLeft + translation.x;
                    var newTop = startTop + translation.y;

                    if (root.screen) {
                        var maxLeft = root.screen.width - root.implicitWidth;
                        var maxTop = root.screen.height - root.implicitHeight;
                        newLeft = Math.max(0, Math.min(newLeft, maxLeft));
                        newTop = Math.max(0, Math.min(newTop, maxTop));
                    }

                    root.margins.left = newLeft;
                    root.margins.top = newTop;
                }
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: FloatingCircles {
                circleColor: theme.button.text
                anchors.fill: parent
                circleCount: 2
                minOpacity: 0.02
                maxOpacity: 0.04
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: StarField {
                starCount: 10
                shootingStarCount: 2
            }
        }

        // --- MẶT BÀN PHÍM ---
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(12)
            spacing: ScalerService.s(6)

            // Hàng 1: Numbers & Backspace
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(6)

                Repeater {
                    model: ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
                    delegate: KeyButton {
                        textLabel: modelData
                    }
                }
                KeyButton {
                    textLabel: "Backspace"
                    symbolLabel: "⌫"
                    flexWeight: 1.8
                    buttonColor: theme.button.background
                    onPressed: root.keyClicked("Backspace")
                }
            }

            // Hàng 2: Tab & QWERTY
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(6)

                KeyButton {
                    textLabel: "Tab"
                    symbolLabel: "⇥"
                    flexWeight: 1.5
                    buttonColor: theme.button.background
                    onPressed: root.keyClicked("\t")
                }
                Repeater {
                    model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\"]
                    delegate: KeyButton {
                        textLabel: modelData
                    }
                }
            }

            // Hàng 3: Caps Lock & ASDFGHJKL
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(6)

                KeyButton {
                    textLabel: "Caps"
                    symbolLabel: "⇪"
                    flexWeight: 1.8
                    isToggle: true
                    isActive: root.isCapsLock
                    buttonColor: root.isCapsLock ? theme.normal.blue : theme.button.background
                    onPressed: root.isCapsLock = !root.isCapsLock
                }
                Repeater {
                    model: ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"]
                    delegate: KeyButton {
                        textLabel: modelData
                    }
                }
                KeyButton {
                    textLabel: "Enter"
                    symbolLabel: "↵"
                    flexWeight: 2.2
                    buttonColor: theme.normal.blue
                    textColor: "#ffffff"
                    onPressed: root.keyClicked("\n")
                }
            }

            // Hàng 4: Shift & ZXCVBNM
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(6)

                KeyButton {
                    textLabel: "Shift"
                    symbolLabel: "⇧"
                    flexWeight: 2.3
                    isToggle: true
                    isActive: root.isShifted
                    buttonColor: root.isShifted ? theme.normal.blue : theme.button.background
                    onPressed: root.isShifted = !root.isShifted
                }
                Repeater {
                    model: ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
                    delegate: KeyButton {
                        textLabel: modelData
                    }
                }
                KeyButton {
                    textLabel: "Shift"
                    symbolLabel: "⇧"
                    flexWeight: 2.3
                    isToggle: true
                    isActive: root.isShifted
                    buttonColor: root.isShifted ? theme.normal.blue : theme.button.background
                    onPressed: root.isShifted = !root.isShifted
                }
            }

            // Hàng 5: Spacebar & Navigation
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(6)

                KeyButton {
                    textLabel: "Ctrl"
                    flexWeight: 1.2
                }
                KeyButton {
                    textLabel: "Super"
                    symbolLabel: "❖"
                    flexWeight: 1.2
                }
                KeyButton {
                    textLabel: "Alt"
                    flexWeight: 1.2
                }
                KeyButton {
                    textLabel: "Space"
                    symbolLabel: ""
                    flexWeight: 6.0
                    onPressed: root.keyClicked(" ")
                }
                KeyButton {
                    textLabel: "Alt"
                    flexWeight: 1.2
                }
                KeyButton {
                    textLabel: "Ctrl"
                    flexWeight: 1.2
                }
                KeyButton {
                    textLabel: "←"
                    flexWeight: 0.9
                    onPressed: root.keyClicked("Left")
                }
                KeyButton {
                    textLabel: "↑"
                    flexWeight: 0.9
                    onPressed: root.keyClicked("Up")
                }
                KeyButton {
                    textLabel: "↓"
                    flexWeight: 0.9
                    onPressed: root.keyClicked("Down")
                }
                KeyButton {
                    textLabel: "→"
                    flexWeight: 0.9
                    onPressed: root.keyClicked("Right")
                }
            }
        }
    }

    // --- COMPONENT NÚT PHÍM TÁI SỬ DỤNG ---
    component KeyButton: Rectangle {
        id: btn
        property string textLabel: ""
        property string symbolLabel: ""
        property real flexWeight: 1.0
        property bool isToggle: false
        property bool isActive: false
        property color buttonColor: theme.button.background
        property color textColor: theme.primary.foreground

        signal pressed

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: flexWeight * 100

        color: {
            if (btnArea.pressed) {
                return Qt.darker(btn.buttonColor, 1.2);
            } else if (btnArea.containsMouse) {
                return Qt.lighter(btn.buttonColor, 1.2);
            } else if (btn.isActive) {
                return btn.buttonColor;
            } else {
                return Qt.alpha(btn.buttonColor, 0.7);
            }
        }

        radius: ScalerService.s(8)
        border.color: btnArea.pressed ? theme.button.border_select : theme.button.border
        border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0

        CustomText {
            anchors.centerIn: parent
            name: {
                if (btn.symbolLabel !== "")
                    return btn.symbolLabel;
                if (btn.textLabel.length === 1) {
                    return root.isUppercase ? btn.textLabel.toUpperCase() : btn.textLabel.toLowerCase();
                }
                return btn.textLabel;
            }
            textColor: btn.textColor
            size: "large"
            isBold: true
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                SoundService.playSound("hover");
            }
            onPressed: {
                btn.pressed();
                SoundService.playSound("pick");
                if (!btn.isToggle) {
                    var charToEmit = btn.textLabel;
                    if (charToEmit.length === 1) {
                        charToEmit = root.isUppercase ? charToEmit.toUpperCase() : charToEmit.toLowerCase();
                        root.keyClicked(charToEmit);
                    }
                }
            }
        }
    }
}
