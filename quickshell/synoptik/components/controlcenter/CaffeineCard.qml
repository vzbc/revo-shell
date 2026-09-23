import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import ".."

Item {
    id: cardRoot
    
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.alignment: Qt.AlignTop

    implicitHeight: 64
    Layout.preferredHeight: 64
    z: panelExpanded ? 1000 : 1

    property Item controlCenterPanel: null
    property bool panelExpanded: false

    readonly property bool hasHypridle: Config.caffeineHasHypridle
    readonly property int caffeineState: Config.caffeineState
    readonly property string remainingTimeString: Config.caffeineRemainingTimeString
    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    property int typedMinutes: 15

    onVisibleChanged: {
        if (!visible) panelExpanded = false
    }

    onPanelExpandedChanged: {
        if (panelExpanded) stopwatchCanvas.updateProgress()
    }

    onCaffeineStateChanged: {
        stopwatchCanvas.updateProgress()
    }

    readonly property real collapsedX: {
        let sum = 0
        let p = cardRoot
        while (p && p !== controlCenterPanel) {
            sum += p.x
            p = p.parent
        }
        return sum
    }

    readonly property real collapsedY: {
        let sum = 0
        let p = cardRoot
        while (p && p !== controlCenterPanel) {
            sum += p.y
            p = p.parent
        }
        return sum
    }

    Rectangle {
        id: visualBackground
        parent: controlCenterPanel ? controlCenterPanel : cardRoot.parent
        z: cardRoot.panelExpanded ? 1000 : 100
        clip: true

        x: cardRoot.panelExpanded ? cardRoot.cardMargin : cardRoot.collapsedX
        y: cardRoot.panelExpanded ? cardRoot.cardMargin : cardRoot.collapsedY
        width: cardRoot.panelExpanded ? (controlCenterPanel ? (controlCenterPanel.width - (cardRoot.cardMargin * 2)) : 400) : cardRoot.width
        height: cardRoot.panelExpanded ? (controlCenterPanel ? (controlCenterPanel.height - (cardRoot.cardMargin * 2)) : 500) : 64

        radius: Config.cornerRadius

        color: cardRoot.panelExpanded
            ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 1.0)
            : ((cardHover.hovered && cardRoot.hasHypridle) ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 0.85) : Qt.rgba(0, 0, 0, 0.25))
        border.width: 1
        border.color: cardRoot.panelExpanded ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

        opacity: cardRoot.hasHypridle ? 1.0 : 0.45
        enabled: cardRoot.hasHypridle

        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler {
            id: cardHover
            enabled: !cardRoot.panelExpanded
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardRoot.panelExpanded
            preventStealing: true
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => mouse.accepted = true
            onReleased: (mouse) => mouse.accepted = true
            onClicked: (mouse) => mouse.accepted = true
        }

        TapHandler {
            enabled: cardRoot.panelExpanded
            gesturePolicy: TapHandler.WithinBounds
            onTapped: {}
        }

        // --- 1. COLLAPSED CARD HEADER VIEW ---
        Item {
            id: collapsedView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            visible: opacity > 0
            enabled: !cardRoot.panelExpanded
            opacity: cardRoot.panelExpanded ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Item {
                anchors.fill: parent
                anchors.margins: 10

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: Config.cornerRadius / 2
                        color: {
                            if (!cardRoot.hasHypridle || cardRoot.caffeineState === 0) {
                                return iconHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                            } else if (cardRoot.caffeineState === 1) {
                                return iconHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent
                            } else {
                                return iconHover.hovered ? Qt.lighter(Config.accent, 1.2) : Qt.tint(Config.accent, Qt.rgba(1, 1, 1, 0.4))
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: cardRoot.caffeineState === 2 ? "schedule" : "coffee"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: cardRoot.caffeineState !== 0 ? Config.bgBase : Config.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: cardRoot.hasHypridle ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (cardRoot.hasHypridle) {
                                    if (cardRoot.caffeineState !== 0) {
                                        Config.startCaffeineTimer(0)
                                    } else {
                                        Config.setIndefiniteCaffeine()
                                    }
                                }
                            }
                        }
                        HoverHandler { id: iconHover }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        clip: true

                        Text {
                            text: "Caffeine"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            color: Config.textMain
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: {
                                if (!cardRoot.hasHypridle) return "Unavailable"
                                switch (cardRoot.caffeineState) {
                                    case 1: return "Awake"
                                    case 2: return cardRoot.remainingTimeString
                                    default: return "Off"
                                }
                            }
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: cardRoot.caffeineState !== 0
                            color: cardRoot.caffeineState !== 0 ? Config.accent : Config.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "chevron_right"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: cardHover.hovered ? Config.textMain : Config.textMuted
                        opacity: cardRoot.hasHypridle ? 0.7 : 0.2
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.leftMargin: 52
                    cursorShape: cardRoot.hasHypridle ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (cardRoot.hasHypridle) cardRoot.panelExpanded = true
                    }
                }
            }
        }

        // --- 2. EXPANDED FULL CONTROL CENTER PANEL VIEW ---
        Item {
            id: expandedView
            anchors.fill: parent
            anchors.margins: 14
            visible: opacity > 0
            enabled: cardRoot.panelExpanded
            opacity: cardRoot.panelExpanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            RowLayout {
                id: caffHeaderRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44
                spacing: 10

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    Layout.alignment: Qt.AlignVCenter
                    color: backHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Config.textMain
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.panelExpanded = false
                    }
                    HoverHandler { id: backHover }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Item {
                        implicitWidth: caffExpTitleText.implicitWidth
                        implicitHeight: caffExpTitleText.implicitHeight
                        Layout.fillWidth: true

                        Text {
                            id: caffExpTitleText
                            text: "CAFFEINE"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                            elide: Text.ElideRight
                        }

                        Glow {
                            anchors.fill: caffExpTitleText
                            source: caffExpTitleText
                            radius: 6
                            samples: 12
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }
                    }

                    Text {
                        text: cardRoot.caffeineState === 2 
                            ? "Countdown Timer Active" 
                            : (cardRoot.caffeineState === 1 ? "System Awake (Indefinite)" : "Anti-Sleep Timer Disabled")
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: cardRoot.caffeineState !== 0 ? Config.accent : Config.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    color: cardRoot.caffeineState !== 0
                        ? (topPwrHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent)
                        : (topPwrHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: cardRoot.caffeineState === 2 ? "schedule" : "coffee"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: cardRoot.caffeineState !== 0 ? Config.bgBase : Config.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cardRoot.caffeineState !== 0) {
                                Config.startCaffeineTimer(0)
                            } else {
                                Config.setIndefiniteCaffeine()
                            }
                        }
                    }
                    HoverHandler { id: topPwrHover }
                }
            }

            Rectangle {
                id: caffDividerLine
                anchors.top: caffHeaderRow.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(255, 255, 255, 0.08)
            }

            RowLayout {
                id: bottomActionRow
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 38
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Config.cornerRadius / 2
                    color: disBtnHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "ALLOW SLEEP"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                        color: disBtnHover.hovered ? Config.accent : Config.textMain
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.startCaffeineTimer(0)
                    }
                    HoverHandler { id: disBtnHover }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Config.cornerRadius / 2
                    color: startBtnHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: cardRoot.caffeineState === 2 ? "UPDATE TIMER" : "START TIMER"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                        color: Config.bgBase
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cardRoot.typedMinutes > 0) {
                                Config.startCaffeineTimer(cardRoot.typedMinutes)
                            }
                        }
                    }
                    HoverHandler { id: startBtnHover }
                }
            }

            Item {
                anchors.top: caffDividerLine.bottom
                anchors.bottom: bottomActionRow.top
                anchors.left: parent.left
                anchors.right: parent.right
                clip: true

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 14

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 220
                        Layout.alignment: Qt.AlignHCenter

                        Canvas {
                            id: stopwatchCanvas
                            width: 220
                            height: 220
                            anchors.centerIn: parent

                            property real animProgress: 0.0

                            function updateProgress() {
                                if (cardRoot.caffeineState === 0) {
                                    animProgress = 0.0
                                } else if (cardRoot.caffeineState === 1) {
                                    animProgress = 1.0
                                } else if (cardRoot.caffeineState === 2) {
                                    let diffMs = Math.max(0, Config.caffeineTimerEndTime - Date.now())
                                    if (diffMs <= 0) {
                                        animProgress = 0.0
                                    } else {
                                        let rem = diffMs % 3600000
                                        animProgress = (rem === 0) ? 1.0 : (rem / 3600000.0)
                                    }
                                } else {
                                    animProgress = 0.0
                                }
                                requestPaint()
                            }

                            onAnimProgressChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = 96
                                var startAngle = -Math.PI / 2
                                var endAngle = startAngle + (2 * Math.PI * animProgress)

                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.06)
                                ctx.stroke()

                                if (animProgress > 0) {
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle, false)
                                    ctx.lineWidth = 8
                                    ctx.strokeStyle = Config.accent
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                            }

                            Timer {
                                interval: 250
                                running: cardRoot.caffeineState === 2 && cardRoot.panelExpanded
                                repeat: true
                                onTriggered: stopwatchCanvas.updateProgress()
                            }

                            Component.onCompleted: stopwatchCanvas.updateProgress()
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                text: cardRoot.caffeineState === 2 
                                    ? cardRoot.remainingTimeString 
                                    : (cardRoot.caffeineState === 1 ? "∞" : "00:00")
                                font.family: Config.sysFont
                                font.pixelSize: cardRoot.caffeineState === 1 ? 64 : 56
                                font.bold: true
                                color: cardRoot.caffeineState !== 0 ? Config.accent : Config.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: cardRoot.caffeineState === 2 
                                    ? "REMAINING" 
                                    : (cardRoot.caffeineState === 1 ? "INDEFINITE" : "DISABLED")
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontMicro)
                                font.bold: true
                                color: Config.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Text {
                            text: "ADJUST DURATION"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                            color: Config.textMuted
                            Layout.alignment: Qt.AlignHCenter
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Rectangle {
                                implicitWidth: 42
                                implicitHeight: 32
                                radius: Config.cornerRadius / 2
                                color: minus5Hover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "-5m"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    color: Config.textMain
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cardRoot.typedMinutes = Math.max(1, cardRoot.typedMinutes - 5)
                                }
                                HoverHandler { id: minus5Hover }
                            }

                            Rectangle {
                                implicitWidth: 70
                                implicitHeight: 32
                                radius: Config.cornerRadius / 2
                                color: Qt.rgba(0, 0, 0, 0.35)
                                border.width: 2
                                border.color: minutesInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    TextInput {
                                        id: minutesInput
                                        text: cardRoot.typedMinutes.toString()
                                        color: Config.accent
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        selectByMouse: true
                                        validator: IntValidator { bottom: 1; top: 1440 }

                                        onTextChanged: {
                                            let val = parseInt(text)
                                            if (!isNaN(val) && val > 0) {
                                                cardRoot.typedMinutes = val
                                            }
                                        }
                                    }

                                    Text {
                                        text: "min"
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        color: Config.textMuted
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: 42
                                implicitHeight: 32
                                radius: Config.cornerRadius / 2
                                color: plus5Hover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+5m"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    color: Config.textMain
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cardRoot.typedMinutes = cardRoot.typedMinutes + 5
                                }
                                HoverHandler { id: plus5Hover }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Rectangle {
                                implicitWidth: 68
                                implicitHeight: 28
                                radius: 14
                                color: cardRoot.typedMinutes === 30 
                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                    : (p30Hover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06))
                                border.width: cardRoot.typedMinutes === 30 ? 2 : 0
                                border.color: Config.accent
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "30m"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    color: cardRoot.typedMinutes === 30 ? Config.accent : Config.textMain
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cardRoot.typedMinutes = 30
                                }
                                HoverHandler { id: p30Hover }
                            }

                            Rectangle {
                                implicitWidth: 68
                                implicitHeight: 28
                                radius: 14
                                color: cardRoot.typedMinutes === 60 
                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                    : (p1hHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06))
                                border.width: cardRoot.typedMinutes === 60 ? 2 : 0
                                border.color: Config.accent
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "1h"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    color: cardRoot.typedMinutes === 60 ? Config.accent : Config.textMain
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cardRoot.typedMinutes = 60
                                }
                                HoverHandler { id: p1hHover }
                            }

                            Rectangle {
                                implicitWidth: 100
                                implicitHeight: 28
                                radius: 14
                                color: cardRoot.caffeineState === 1 
                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                    : (pAlwaysHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06))
                                border.width: cardRoot.caffeineState === 1 ? 2 : 0
                                border.color: Config.accent
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Always On"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                    color: cardRoot.caffeineState === 1 ? Config.accent : Config.textMain
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Config.setIndefiniteCaffeine()
                                }
                                HoverHandler { id: pAlwaysHover }
                            }
                        }
                    }
                }
            }
        }
    }
}