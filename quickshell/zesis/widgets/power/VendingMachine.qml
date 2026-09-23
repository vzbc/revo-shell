pragma ComponentBehavior: Bound
import QtQuick
import "../shared"
import "../../"
import "../lockscreen"
import "../wm"

// Desktop widget: a drink machine take on the power menu.
Item {
    id: root

    readonly property real _margin: UIScale.spacingLg
    implicitWidth: bodyColumn.implicitWidth + _margin * 2
    implicitHeight: bodyColumn.implicitHeight + _margin * 2

    // idle -> dispensing (donut fill) -> falling -> stuck? -> dispensed -> lidOpen
    property string phase: "idle"
    property var selectedSlot: null
    property string enteredCode: ""
    property string badCodeText: ""
    property real dispensePct: 0
    property bool willJam: false
    property int shakeCount: 0

    readonly property int _gridCols: 4
    readonly property int _gridRows: 5
    readonly property real _cellW: Math.round(58 * UIScale.value)
    readonly property real _cellH: Math.round(44 * UIScale.value)
    readonly property real _cellGap: Math.round(4 * UIScale.value)
    readonly property real _shelfTopPad: Math.round(10 * UIScale.value)
    readonly property real _itemSize: Math.round(34 * UIScale.value)
    readonly property real _chuteHeight: Math.round(80 * UIScale.value)
    readonly property real _flapHeight: Math.round(72 * UIScale.value)

    readonly property real _glassContentW: _gridCols * _cellW + (_gridCols - 1) * _cellGap
    readonly property real _shelvesH: _gridRows * _cellH + (_gridRows - 1) * _cellGap
    readonly property real _glassH: _shelfTopPad + _shelvesH + _chuteHeight + _flapHeight

    readonly property real _machineBodyW: _glassContentW + UIScale.spacingSm * 2
    readonly property real _keyW: Math.round(40 * UIScale.value)
    readonly property real _keyGap: Math.round(4 * UIScale.value)
    readonly property real _keypadW: 3 * _keyW + 2 * _keyGap

    function _pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    readonly property var _items: {
        var real = [
            {
                row: 1,
                col: 1,
                key: "lock",
                icon: "󰌾",
                label: I18n.t("power.lock").toUpperCase()
            },
            {
                row: 2,
                col: 3,
                key: "logout",
                icon: "󰍃",
                label: I18n.t("power.logOut").toUpperCase()
            },
            {
                row: 4,
                col: 2,
                key: "reboot",
                icon: "󰜉",
                label: I18n.t("power.reboot").toUpperCase()
            },
            {
                row: 5,
                col: 4,
                key: "shutdown",
                icon: "󰐥",
                label: I18n.t("power.shutDown").toUpperCase()
            }
        ];
        var filler = I18n.t("power.fillerItems").split("|");
        var out = [];
        var fi = 0;
        for (var r = 1; r <= root._gridRows; r++) {
            for (var c = 1; c <= root._gridCols; c++) {
                var found = null;
                for (var i = 0; i < real.length; i++) {
                    if (real[i].row === r && real[i].col === c) {
                        found = real[i];
                        break;
                    }
                }
                if (found) {
                    out.push({
                        code: root._pad2(r) + root._pad2(c),
                        row: r,
                        col: c,
                        real: true,
                        key: found.key,
                        icon: found.icon,
                        label: found.label
                    });
                } else {
                    out.push({
                        code: root._pad2(r) + root._pad2(c),
                        row: r,
                        col: c,
                        real: false,
                        key: "",
                        icon: "",
                        label: filler[fi % filler.length]
                    });
                    fi++;
                }
            }
        }
        return out;
    }

    function _slotForCode(code) {
        for (var i = 0; i < root._items.length; i++)
            if (root._items[i].code === code)
                return root._items[i];
        return null;
    }

    function _restPos(row, col) {
        return {
            x: UIScale.spacingSm + (col - 1) * (root._cellW + root._cellGap) + (root._cellW - root._itemSize) / 2,
            y: root._shelfTopPad + (row - 1) * (root._cellH + root._cellGap) + (root._cellH - root._itemSize) / 2
        };
    }

    readonly property real _jamDrop: Math.round(22 * UIScale.value)
    readonly property real _trayY: root._glassH - root._flapHeight + (root._flapHeight - root._itemSize) / 2

    function pressDigit(d) {
        if (root.phase !== "idle" || root.badCodeText !== "")
            return;
        if (root.enteredCode.length >= 4)
            return;
        root.enteredCode += d;
        if (root.enteredCode.length === 4)
            root._submitCode();
    }

    function clearCode() {
        if (root.phase !== "idle")
            return;
        root.enteredCode = "";
        root.badCodeText = "";
    }

    function deleteDigit() {
        if (root.phase !== "idle" || root.enteredCode.length === 0)
            return;
        root.enteredCode = root.enteredCode.slice(0, -1);
    }

    function _submitCode() {
        var slot = root._slotForCode(root.enteredCode);
        root.enteredCode = "";
        if (!slot) {
            root.badCodeText = I18n.t("power.invalidCode");
            badCodeTimer.restart();
            return;
        }
        if (!slot.real) {
            root.badCodeText = I18n.t("power.soldOut");
            badCodeTimer.restart();
            return;
        }
        root.selectedSlot = slot;
        var pos = root._restPos(slot.row, slot.col);
        travelingItem.x = pos.x;
        travelingItem.y = pos.y;
        travelingItem.rotation = 0;
        root.phase = "dispensing";
        root.dispensePct = 0;
        dispenseAnim.restart();
    }

    Timer {
        id: badCodeTimer
        interval: 1100
        onTriggered: root.badCodeText = ""
    }

    NumberAnimation {
        id: dispenseAnim
        target: root
        property: "dispensePct"
        from: 0
        to: 1
        duration: 1300
        easing.type: Easing.Linear
        onStopped: if (root.phase === "dispensing")
            root._startFall()
    }

    function _startFall() {
        root.willJam = Math.random() < 0.4;
        root.phase = "falling";
        fallAnim.restart();
    }

    SequentialAnimation {
        id: fallAnim
        ParallelAnimation {
            NumberAnimation {
                target: travelingItem
                property: "y"
                to: root.willJam ? travelingItem.y + root._jamDrop : root._trayY
                duration: root.willJam ? 220 : 780
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: travelingItem
                property: "rotation"
                to: root.willJam ? 55 : 640
                duration: root.willJam ? 220 : 780
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: {
                root.shakeCount = 0;
                root.phase = root.willJam ? "stuck" : "dispensed";
            }
        }
    }

    property real _tapBaseX: 0
    property real _tapBaseRot: 0

    function tapGlass() {
        if (root.phase !== "stuck")
            return;
        root.shakeCount++;
        root._tapBaseX = travelingItem.x;
        root._tapBaseRot = travelingItem.rotation;
        tapAnim.restart();
        if (root.shakeCount >= 3) {
            // leave "stuck" immediately so further taps can't re-trigger
            // unstickAnim mid-flight
            root.phase = "falling";
            unstickAnim.restart();
        }
    }

    SequentialAnimation {
        id: tapAnim
        ParallelAnimation {
            NumberAnimation {
                target: travelingItem
                property: "x"
                to: root._tapBaseX - 6
                duration: 30
            }
            NumberAnimation {
                target: travelingItem
                property: "rotation"
                to: root._tapBaseRot - 14
                duration: 30
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: travelingItem
                property: "x"
                to: root._tapBaseX + 6
                duration: 30
            }
            NumberAnimation {
                target: travelingItem
                property: "rotation"
                to: root._tapBaseRot + 14
                duration: 30
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: travelingItem
                property: "x"
                to: root._tapBaseX - 3
                duration: 30
            }
            NumberAnimation {
                target: travelingItem
                property: "rotation"
                to: root._tapBaseRot - 6
                duration: 30
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: travelingItem
                property: "x"
                to: root._tapBaseX
                duration: 30
            }
            NumberAnimation {
                target: travelingItem
                property: "rotation"
                to: root._tapBaseRot
                duration: 30
            }
        }
    }

    SequentialAnimation {
        id: unstickAnim
        NumberAnimation {
            target: travelingItem
            property: "rotation"
            to: travelingItem.rotation + 30
            duration: 90
        }
        ParallelAnimation {
            NumberAnimation {
                target: travelingItem
                property: "y"
                to: root._trayY
                duration: 420
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: travelingItem
                property: "rotation"
                to: travelingItem.rotation + 260
                duration: 420
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: root.phase = "dispensed"
        }
    }

    function liftLid() {
        if (root.phase !== "dispensed")
            return;
        root.phase = "lidOpen";
    }

    function pressItem() {
        if (root.phase !== "lidOpen" || !root.selectedSlot)
            return;
        switch (root.selectedSlot.key) {
        case "lock":
            LockService.triggerLock();
            break;
        case "logout":
            WmService.logout();
            break;
        case "reboot":
            WmService.closeAppsThen("systemctl reboot || loginctl reboot");
            break;
        case "shutdown":
            WmService.closeAppsThen("systemctl poweroff || loginctl poweroff");
            break;
        }
        root.phase = "idle";
        root.selectedSlot = null;
    }

    readonly property string _statusText: {
        if (root.badCodeText !== "")
            return root.badCodeText;
        switch (root.phase) {
        case "idle":
            return root.enteredCode.length > 0 ? I18n.t("power.codePrefix") + root.enteredCode.padEnd(4, "_") : I18n.t("power.enterCode");
        case "dispensing":
            return I18n.t("power.dispensing");
        case "falling":
            return I18n.t("power.dropping");
        case "stuck":
            return I18n.t("power.stuckTapGlass");
        case "dispensed":
            return I18n.t("power.liftTheFlap");
        case "lidOpen":
            return I18n.t("power.pressItemToConfirm");
        }
        return "";
    }

    // Casing
    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusXl
        color: Colors.surface
        border.color: Colors.outline
        border.width: 2
    }

    Item {
        id: shakeWrapper
        anchors.fill: parent

        Column {
            id: bodyColumn
            anchors.centerIn: parent
            spacing: UIScale.spacingMd

            // Brand plate
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ZESIS " + I18n.t("power.vendingCorner")
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                font.weight: Font.Bold
                font.letterSpacing: 2
            }

            // LCD status screen, text normally, donut while dispensing
            Rectangle {
                width: root._machineBodyW + UIScale.spacingMd + root._keypadW
                implicitHeight: Math.round(72 * UIScale.value)
                radius: UIScale.radiusSm
                color: Colors.bg
                border.color: Colors.withAlpha(Colors.accent, 0.35)
                border.width: 1

                DonutChart {
                    visible: root.phase === "dispensing"
                    anchors.centerIn: parent
                    width: Math.round(56 * UIScale.value)
                    height: width
                    segments: [
                        {
                            color: Colors.accent,
                            value: root.dispensePct * 100
                        }
                    ]
                    total: 100
                    centerText: Math.round(root.dispensePct * 100) + "%"
                }

                Text {
                    visible: root.phase !== "dispensing"
                    anchors.centerIn: parent
                    text: root._statusText
                    color: Colors.accent
                    font.family: "monospace"
                    font.pixelSize: UIScale.fontLead
                    font.letterSpacing: 1
                }
            }

            // Machine body: glass cabinet (left) + keypad (right)
            Row {
                spacing: UIScale.spacingMd

                // Glass cabinet, shelves, open drop shaft, and the tray/flap,
                // all behind one continuous pane of glass
                Rectangle {
                    id: machineBody
                    width: root._machineBodyW
                    height: root._glassH
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.bg, 0.55)
                    border.color: Colors.withAlpha(Colors.outline, 0.7)
                    border.width: 1
                    clip: true

                    // Glass sheen
                    Rectangle {
                        x: -parent.width * 0.15
                        y: -parent.height * 0.05
                        width: parent.width * 0.3
                        height: parent.height * 1.1
                        rotation: 10
                        color: Colors.withAlpha(Colors.text, 0.03)
                    }

                    Repeater {
                        model: root._items
                        delegate: Rectangle {
                            id: cell
                            required property var modelData

                            readonly property bool _picked: root.selectedSlot !== null && root.selectedSlot.code === cell.modelData.code

                            x: UIScale.spacingSm + (cell.modelData.col - 1) * (root._cellW + root._cellGap)
                            y: root._shelfTopPad + (cell.modelData.row - 1) * (root._cellH + root._cellGap)
                            width: root._cellW
                            height: root._cellH
                            radius: UIScale.radiusSm
                            color: Colors.withAlpha(Colors.bg, 0.4)
                            border.color: cell.modelData.real ? Colors.withAlpha(Colors.accent, 0.5) : Colors.withAlpha(Colors.outline, 0.4)
                            border.width: 1

                            Text {
                                anchors.top: parent.top
                                anchors.topMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cell.modelData.code
                                color: Colors.textDim
                                font.pixelSize: Math.round(7 * UIScale.value)
                                font.letterSpacing: 1
                            }

                            Text {
                                visible: !cell._picked
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: Math.round(4 * UIScale.value)
                                width: parent.width - 4
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: cell.modelData.real ? cell.modelData.icon : cell.modelData.label
                                color: cell.modelData.real ? Colors.accent : Colors.textDim
                                font.pixelSize: cell.modelData.real ? Math.round(15 * UIScale.value) : Math.round(6.5 * UIScale.value)
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // The single item that actually travels: shelf -> fall -> (jam?) -> tray
                    Rectangle {
                        id: travelingItem
                        visible: root.selectedSlot !== null
                        width: root._itemSize
                        height: width
                        radius: width / 2
                        color: Colors.withAlpha(Colors.accent, 0.22)
                        border.color: Colors.accent
                        border.width: 2
                        scale: (itemHover.hovered && root.phase === "lidOpen") ? 1.12 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: Anim.fast
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.selectedSlot ? root.selectedSlot.icon : ""
                            color: Colors.accent
                            font.pixelSize: Math.round(16 * UIScale.value)
                        }

                        HoverHandler {
                            id: itemHover
                            enabled: root.phase === "lidOpen"
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.phase === "lidOpen"
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.pressItem()
                        }
                    }

                    // Mouse area only live on interaction, can't spoil the surprise
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.phase === "stuck"
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.tapGlass()
                    }

                    // Flap, sits over the tray zone until lifted
                    Rectangle {
                        id: flap
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: root._flapHeight
                        color: Colors.surfaceHigh
                        border.color: Colors.outline
                        border.width: 1
                        y: root._glassH - root._flapHeight + (root.phase === "lidOpen" ? -root._flapHeight - Math.round(10 * UIScale.value) : 0)
                        transformOrigin: Item.Top
                        rotation: root.phase === "lidOpen" ? -8 : 0

                        Behavior on y {
                            NumberAnimation {
                                duration: Anim.morph
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.05
                            }
                        }
                        Behavior on rotation {
                            NumberAnimation {
                                duration: Anim.morph
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.phase === "dispensed"
                            text: "▲ LIFT FLAP"
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            font.letterSpacing: 1
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.phase === "dispensed"
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.liftLid()
                        }
                    }
                }

                // Keypad the dial. 0-9 plus clear/delete
                Grid {
                    columns: 3
                    spacing: root._keyGap

                    Repeater {
                        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "D"]
                        delegate: Rectangle {
                            id: key
                            required property string modelData

                            readonly property bool _keyEnabled: root.phase === "idle"

                            width: root._keyW
                            height: Math.round(34 * UIScale.value)
                            radius: UIScale.radiusSm
                            color: key._keyEnabled ? (keyHover.hovered ? Colors.surfaceHigh : Colors.surface) : Colors.withAlpha(Colors.surface, 0.4)
                            border.color: key._keyEnabled ? Colors.outline : Colors.withAlpha(Colors.outline, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: key.modelData
                                color: key._keyEnabled ? Colors.text : Colors.textDim
                                font.pixelSize: UIScale.fontLead
                                font.weight: Font.DemiBold
                            }

                            HoverHandler {
                                id: keyHover
                                enabled: key._keyEnabled
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: key._keyEnabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (key.modelData === "C")
                                        root.clearCode();
                                    else if (key.modelData === "D")
                                        root.deleteDigit();
                                    else
                                        root.pressDigit(key.modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
