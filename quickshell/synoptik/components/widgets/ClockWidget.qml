import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

PanelWindow {
    id: clockWindow
    visible: Config.showDesktopClock && (screen ? Config.isClockEnabledForScreen(screen.name) : true)

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop-clock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusiveZone: 0

    // Bind region directly to the clock container item
    mask: Region { item: clockContainer }

    Item {
        id: clockContainer
        
        readonly property real basePadding: 16
        width: clockLoader.implicitWidth + (basePadding * 2)
        height: clockLoader.implicitHeight + (basePadding * 2)

        property real currentScale: clockWindow.screen ? Config.getClockScale(clockWindow.screen.name) : 1.0

        property real dragX: 100
        property real dragY: 100
        property bool initialized: false

        x: dragX
        y: dragY

        function restorePosition() {
            if (!clockWindow.screen) return

            let defaultX = Math.max(0, clockWindow.width - width - 60)
            let defaultY = 60

            let savedPos = Config.getClockPosition(clockWindow.screen.name, defaultX, defaultY)
            
            if (savedPos && typeof savedPos.x === "number" && typeof savedPos.y === "number") {
                dragX = savedPos.x
                dragY = savedPos.y
                initialized = true
            }
        }

        Connections {
            target: Config
            function onIsLoadedChanged() {
                if (Config.isLoaded) clockContainer.restorePosition()
            }
        }

        Component.onCompleted: {
            if (Config.isLoaded) restorePosition()
        }

        onXChanged: {
            if (initialized && dragArea.drag.active && clockWindow.screen) {
                Config.saveClockPosition(clockWindow.screen.name, dragX, dragY)
            }
        }
        onYChanged: {
            if (initialized && dragArea.drag.active && clockWindow.screen) {
                Config.saveClockPosition(clockWindow.screen.name, dragX, dragY)
            }
        }

        // BACKGROUND PANEL
        Rectangle {
            anchors.fill: parent
            visible: Config.clockShowBackground || Config.clockShowBorder
            color: Config.clockShowBackground ? Config.bgPanel : "transparent"
            radius: Config.cornerRadius
            border.width: Config.clockShowBorder ? (Config.showBorders ? 2 : 1) : 0
            border.color: Config.showBorders ? Config.accent : Qt.rgba(255, 255, 255, 0.15)
            opacity: Config.clockShowBackground ? 0.85 : 1.0
        }

        // DYNAMIC CLOCK LOADER
        Loader {
            id: clockLoader
            anchors.centerIn: parent
            sourceComponent: Config.clockStyle === "modern" ? modernComp : (Config.clockStyle === "analog" ? analogComp : digitalComp)
        }

        // --- AUTHENTIC 5x7 DOT MATRIX CLOCK FACE ---
        Component {
            id: modernComp

            ColumnLayout {
                id: modernLayout
                spacing: 12 * clockContainer.currentScale

                // Ensure loader reads full unconstrained layout dimensions
                implicitWidth: timeRow.implicitWidth
                implicitHeight: dateHeader.implicitHeight + timeRow.implicitHeight + spacing

                property var currentDate: new Date()

                Timer {
                    interval: Config.clockShowSeconds ? 1000 : 5000
                    running: true
                    repeat: true
                    onTriggered: modernLayout.currentDate = new Date()
                }

                // 5x7 Font Bitmaps (Column-wise bitmasks)
                readonly property var fontMap: ({
                    "0": [0x3E, 0x51, 0x49, 0x45, 0x3E],
                    "1": [0x00, 0x42, 0x7F, 0x40, 0x00],
                    "2": [0x42, 0x61, 0x51, 0x49, 0x46],
                    "3": [0x21, 0x41, 0x45, 0x4B, 0x31],
                    "4": [0x18, 0x14, 0x12, 0x7F, 0x10],
                    "5": [0x27, 0x45, 0x45, 0x45, 0x39],
                    "6": [0x3C, 0x4A, 0x49, 0x49, 0x30],
                    "7": [0x01, 0x71, 0x09, 0x05, 0x03],
                    "8": [0x36, 0x49, 0x49, 0x49, 0x36],
                    "9": [0x06, 0x49, 0x49, 0x29, 0x1E],
                    " ": [0x00, 0x00, 0x00, 0x00, 0x00]
                })

                readonly property string formattedTime: {
                    let h = currentDate.getHours()
                    if (Config.clockUse12Hour) h = h % 12 || 12
                    let m = currentDate.getMinutes()
                    let s = currentDate.getSeconds()
                    let hStr = h < 10 && !Config.clockUse12Hour ? "0" + h : (h < 10 ? " " + h : h.toString())
                    let mStr = m < 10 ? "0" + m : m.toString()
                    let sStr = s < 10 ? "0" + s : s.toString()
                    return hStr + mStr + sStr
                }

                // Header Date String (with Accent Glow)
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: dateHeader.implicitWidth
                    implicitHeight: dateHeader.implicitHeight

                    Glow {
                        anchors.fill: dateHeader
                        source: dateHeader
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    RowLayout {
                        id: dateHeader
                        anchors.fill: parent
                        spacing: 8 * clockContainer.currentScale

                        Text {
                            text: "schedule"
                            color: Config.accent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: Config.size(Config.fontCaption) * 1.2 * clockContainer.currentScale
                            font.bold: true
                        }

                        Text {
                            text: Qt.formatDate(modernLayout.currentDate, "dddd, MMMM d").toUpperCase()
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro) * 1.1 * clockContainer.currentScale
                            font.bold: true
                            font.letterSpacing: 1.5
                        }
                    }
                }

                // Dot Matrix Main Time Layout (with Accent Glow)
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: timeRow.implicitWidth
                    implicitHeight: timeRow.implicitHeight

                    Glow {
                        anchors.fill: timeRow
                        source: timeRow
                        radius: 12
                        samples: 24
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    RowLayout {
                        id: timeRow
                        anchors.fill: parent
                        spacing: 8 * clockContainer.currentScale

                        // Hours Digits
                        Repeater {
                            model: 2
                            delegate: DotMatrixDigit {
                                required property int index
                                readonly property string charVal: modernLayout.formattedTime[index] || " "
                                digitData: modernLayout.fontMap[charVal] || modernLayout.fontMap[" "]
                                scaleFactor: clockContainer.currentScale
                            }
                        }

                        // Pulsing Colon (Hours/Minutes)
                        ColumnLayout {
                            spacing: 8 * clockContainer.currentScale
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: 2
                                delegate: Rectangle {
                                    implicitWidth: 6 * clockContainer.currentScale
                                    implicitHeight: 6 * clockContainer.currentScale
                                    radius: width / 2
                                    color: Config.accent

                                    SequentialAnimation on opacity {
                                        running: true
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }

                        // Minutes Digits
                        Repeater {
                            model: 2
                            delegate: DotMatrixDigit {
                                required property int index
                                readonly property string charVal: modernLayout.formattedTime[index + 2] || " "
                                digitData: modernLayout.fontMap[charVal] || modernLayout.fontMap[" "]
                                scaleFactor: clockContainer.currentScale
                            }
                        }

                        // Pulsing Colon (Minutes/Seconds)
                        ColumnLayout {
                            visible: Config.clockShowSeconds
                            spacing: 8 * clockContainer.currentScale
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: 2
                                delegate: Rectangle {
                                    implicitWidth: 4 * clockContainer.currentScale
                                    implicitHeight: 4 * clockContainer.currentScale
                                    radius: width / 2
                                    color: Config.accent

                                    SequentialAnimation on opacity {
                                        running: true
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.2; duration: 800; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }

                        // Seconds Digits
                        Repeater {
                            model: Config.clockShowSeconds ? 2 : 0
                            delegate: DotMatrixDigit {
                                required property int index
                                readonly property string charVal: modernLayout.formattedTime[index + 4] || " "
                                digitData: modernLayout.fontMap[charVal] || modernLayout.fontMap[" "]
                                scaleFactor: clockContainer.currentScale * 0.75
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        // AM/PM Indicator
                        ColumnLayout {
                            visible: Config.clockUse12Hour && Config.clockShowAmPm
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 6 * clockContainer.currentScale

                            Text {
                                text: Qt.formatTime(modernLayout.currentDate, "ap").toUpperCase()
                                color: Config.accent
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontMicro) * 1.1 * clockContainer.currentScale
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        // --- DIGITAL FACE COMPONENT ---
        Component {
            id: digitalComp

            ColumnLayout {
                spacing: 4

                property var currentDate: new Date()

                Timer {
                    interval: Config.clockShowSeconds ? 1000 : 5000
                    running: true
                    repeat: true
                    onTriggered: currentDate = new Date()
                }

                function formatTimeString() {
                    let fmt = ""
                    if (Config.clockUse12Hour) {
                        fmt = Config.clockShowSeconds ? "h:mm:ss" : "h:mm"
                        if (Config.clockShowAmPm) fmt += " ap"
                    } else {
                        fmt = Config.clockShowSeconds ? "hh:mm:ss" : "hh:mm"
                    }
                    return Qt.formatTime(currentDate, fmt)
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: digitalTimeText.implicitWidth
                    implicitHeight: digitalTimeText.implicitHeight

                    Glow {
                        anchors.fill: digitalTimeText
                        source: digitalTimeText
                        radius: 12
                        samples: 24
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    Text {
                        id: digitalTimeText
                        anchors.fill: parent
                        text: formatTimeString()
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle) * 1.5 * clockContainer.currentScale
                        font.bold: true
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: digitalDateRow.implicitWidth
                    implicitHeight: digitalDateRow.implicitHeight

                    Glow {
                        anchors.fill: digitalDateRow
                        source: digitalDateRow
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    RowLayout {
                        id: digitalDateRow
                        anchors.fill: parent
                        spacing: 6

                        Text {
                            text: Qt.formatDate(currentDate, "ddd")
                            color: Config.accent
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontSubhead) * clockContainer.currentScale
                            font.bold: true
                        }

                        Text {
                            text: "|"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontSubhead) * clockContainer.currentScale
                            opacity: 0.6
                        }

                        Text {
                            text: Qt.formatDate(currentDate, "MMM d")
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontSubhead) * clockContainer.currentScale
                            font.bold: false
                        }
                    }
                }
            }
        }

        // --- ANALOG FACE COMPONENT ---
        Component {
            id: analogComp

            Item {
                readonly property real baseSize: 140
                implicitWidth: baseSize * clockContainer.currentScale
                implicitHeight: baseSize * clockContainer.currentScale

                Glow {
                    anchors.fill: analogCanvas
                    source: analogCanvas
                    radius: 12
                    samples: 24
                    color: Config.accent
                    spread: 0.2
                    transparentBorder: true
                    visible: Config.clockShowGlow
                }

                Canvas {
                    id: analogCanvas
                    anchors.fill: parent

                    property var now: new Date()

                    Timer {
                        interval: Config.clockShowSeconds ? 1000 : 5000
                        running: true
                        repeat: true
                        onTriggered: {
                            analogCanvas.now = new Date()
                            analogCanvas.requestPaint()
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        var cx = width / 2
                        var cy = height / 2
                        var strokeMargin = Math.max(2, 3 * clockContainer.currentScale)
                        var radius = (Math.min(width, height) / 2) - strokeMargin

                        ctx.reset()

                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
                        ctx.strokeStyle = Qt.color(Config.accent)
                        ctx.lineWidth = strokeMargin
                        ctx.stroke()

                        var hours = now.getHours() % 12
                        var minutes = now.getMinutes()
                        var seconds = now.getSeconds()

                        var hourAngle = (hours + minutes / 60) * (Math.PI / 6) - (Math.PI / 2)
                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.lineTo(cx + Math.cos(hourAngle) * (radius * 0.5), cy + Math.sin(hourAngle) * (radius * 0.5))
                        ctx.strokeStyle = Qt.color(Config.textMain)
                        ctx.lineWidth = Math.max(1.5, 4 * clockContainer.currentScale)
                        ctx.stroke()

                        var minAngle = (minutes + seconds / 60) * (Math.PI / 30) - (Math.PI / 2)
                        ctx.beginPath()
                        ctx.moveTo(cx, cy)
                        ctx.lineTo(cx + Math.cos(minAngle) * (radius * 0.75), cy + Math.sin(minAngle) * (radius * 0.75))
                        ctx.strokeStyle = Qt.color(Config.textMain)
                        ctx.lineWidth = Math.max(1.0, 2.5 * clockContainer.currentScale)
                        ctx.stroke()

                        if (Config.clockShowSeconds) {
                            var secAngle = seconds * (Math.PI / 30) - (Math.PI / 2)
                            ctx.beginPath()
                            ctx.moveTo(cx, cy)
                            ctx.lineTo(cx + Math.cos(secAngle) * (radius * 0.85), cy + Math.sin(secAngle) * (radius * 0.85))
                            ctx.strokeStyle = Qt.color(Config.accent)
                            ctx.lineWidth = Math.max(1.0, 1.5 * clockContainer.currentScale)
                            ctx.stroke()
                        }

                        ctx.beginPath()
                        ctx.arc(cx, cy, Math.max(2, 4 * clockContainer.currentScale), 0, 2 * Math.PI)
                        ctx.fillStyle = Qt.color(Config.accent)
                        ctx.fill()
                    }
                }
            }
        }

        // DRAG & SCROLL-RESIZE MOUSE AREA
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: clockContainer
            drag.axis: Drag.XAndYAxis
            cursorShape: Qt.PointingHandCursor

            onPositionChanged: {
                if (drag.active) {
                    clockContainer.dragX = clockContainer.x
                    clockContainer.dragY = clockContainer.y
                }
            }

            onWheel: (wheel) => {
                let step = 0.1
                let newScale = clockContainer.currentScale
                if (wheel.angleDelta.y > 0) {
                    newScale = Math.min(5.0, newScale + step)
                } else {
                    newScale = Math.max(0.5, newScale - step)
                }

                if (clockWindow.screen) {
                    Config.saveClockScale(clockWindow.screen.name, newScale)
                }
            }
        }
    }

    // INLINE COMPONENT: 5x7 LED MATRIX DIGIT
    component DotMatrixDigit: Item {
        id: gridRoot
        property var digitData: [0, 0, 0, 0, 0]
        property real scaleFactor: 1.0

        readonly property real dotSize: 6 * scaleFactor
        readonly property real dotGap: 3 * scaleFactor

        implicitWidth: (5 * dotSize) + (4 * dotGap)
        implicitHeight: (7 * dotSize) + (6 * dotGap)

        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        Grid {
            columns: 5
            rows: 7
            spacing: gridRoot.dotGap
            anchors.fill: parent

            Repeater {
                model: 35
                delegate: Rectangle {
                    required property int index
                    readonly property int col: index % 5
                    readonly property int row: Math.floor(index / 5)

                    readonly property bool isLit: {
                        if (!gridRoot.digitData || col >= gridRoot.digitData.length) return false
                        let mask = gridRoot.digitData[col]
                        return (mask & (1 << row)) !== 0
                    }

                    width: gridRoot.dotSize
                    height: gridRoot.dotSize
                    radius: width / 2

                    color: isLit ? Config.accent : Qt.rgba(255, 255, 255, 0.08)
                    opacity: isLit ? 1.0 : 0.25
                }
            }
        }
    }
}