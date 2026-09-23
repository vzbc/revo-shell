import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import ".."

Rectangle {
    id: rightCard

    property var rootRef
    signal popoutRequested(var item)

    function getButton(name) {
        let layout = centerContentLayout.item
        if (!layout) return rightCard

        switch (name) {
            case "cc":
            case "controlCenter":
                return layout.ccBtn || rightCard
            case "clock":
            case "calendar":
                return layout.clockBtn || rightCard
            case "overview":
            case "workspacePreview":
                return layout.overviewBtn || rightCard
            default:
                return rightCard
        }
    }

    // Direct binding to loaded layout implicitWidth
    readonly property real contentWidth: centerContentLayout.item ? centerContentLayout.item.implicitWidth : 0
    readonly property real contentHeight: centerContentLayout.item ? centerContentLayout.item.implicitHeight : 0

    width: (rootRef && rootRef.isHorizontal) 
        ? Math.max(36, contentWidth + 24)
        : Math.max(36, contentWidth + 4)

    height: (rootRef && rootRef.isHorizontal) 
        ? 36
        : Math.min(contentHeight + 16, (rootRef.height || 1080) - 100)

    clip: true
    radius: Config.cornerRadius / 2
    color: Qt.rgba(255, 255, 255, 0.05)
    border.width: 1
    border.color: Qt.rgba(255, 255, 255, 0.1)

    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    states: [
        State {
            name: "horizontal"
            when: rootRef.isHorizontal
            AnchorChanges {
                target: rightCard
                anchors.right: rightCard.parent.right
                anchors.verticalCenter: rightCard.parent.verticalCenter
                anchors.top: undefined
                anchors.horizontalCenter: undefined
            }
        },
        State {
            name: "vertical"
            when: rootRef && !rootRef.isHorizontal
            AnchorChanges {
                target: rightCard
                anchors.right: undefined
                anchors.verticalCenter: undefined
                anchors.bottom: rightCard.parent.bottom
                anchors.horizontalCenter: rightCard.parent.horizontalCenter
            }
        }
    ]

    anchors.rightMargin: (rootRef && rootRef.isHorizontal) ? 30 : 0
    anchors.bottomMargin: (rootRef && !rootRef.isHorizontal) ? 30 : 0

    Loader {
        id: centerContentLayout
        anchors.fill: parent
        anchors.leftMargin: (rootRef && rootRef.isHorizontal) ? 4 : 2
        anchors.rightMargin: (rootRef && rootRef.isHorizontal) ? 4 : 2
        anchors.topMargin: (rootRef && !rootRef.isHorizontal) ? 4 : 2
        anchors.bottomMargin: (rootRef && !rootRef.isHorizontal) ? 4 : 2

        sourceComponent: (rootRef && rootRef.isHorizontal) ? horizRightComp : vertRightComp
    }

    // --- HORIZONTAL RIGHT MODULES ---
    Component {
        id: horizRightComp
        RowLayout {
            id: horizLayout
            spacing: 8

            readonly property var ccBtn: btnCCHoriz
            readonly property var clockBtn: btnClockHoriz
            readonly property var overviewBtn: wsHoriz.overviewButton

            WorkspaceIndicators {
                id: wsHoriz
                isVertical: false
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 6
                onPopoutRequested: item => rightCard.popoutRequested(item)
            }

            Rectangle {
                id: btnCCHoriz
                implicitWidth: 32
                implicitHeight: 32
                radius: 10
                color: Config.showControlCenter ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 150 } }

                Item {
                    anchors.centerIn: parent
                    implicitWidth: ccIconHorizText.implicitWidth
                    implicitHeight: ccIconHorizText.implicitHeight
                    scale: ccHorizHover.hovered ? 1.25 : 1.0

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                    Glow {
                        anchors.fill: ccIconHorizText
                        source: ccIconHorizText
                        radius: ccHorizHover.hovered ? 8 : 0
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: ccHorizHover.hovered

                        Behavior on radius { NumberAnimation { duration: 180 } }
                    }

                    Text {
                        id: ccIconHorizText
                        anchors.centerIn: parent
                        text: Config.getIcon("cc")
                        color: (Config.showControlCenter || ccHorizHover.hovered) ? Config.accent : Config.textMain
                        font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 18

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                TapHandler {
                    onTapped: {
                        if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                        rightCard.popoutRequested(btnCCHoriz)
                        Config.showControlCenter = !Config.showControlCenter
                    }
                }
                HoverHandler { 
                    id: ccHorizHover
                    cursorShape: Qt.PointingHandCursor 
                    onHoveredChanged: {
                        if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnCCHoriz)
                        else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    }
                }
            }

            Rectangle {
                id: btnClockHoriz
                implicitWidth: dateRow.implicitWidth + 20
                implicitHeight: 32
                radius: 10
                color: Config.showCalendar ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 150 } }

                Item {
                    anchors.centerIn: parent
                    implicitWidth: dateRow.implicitWidth
                    implicitHeight: dateRow.implicitHeight
                    scale: clockHorizHover.hovered ? 1.08 : 1.0

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                    Glow {
                        anchors.fill: dateRow
                        source: dateRow
                        radius: clockHorizHover.hovered ? 8 : 0
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: clockHorizHover.hovered

                        Behavior on radius { NumberAnimation { duration: 180 } }
                    }

                    RowLayout {
                        id: dateRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: (shellRoot.vertHour || (new Date().getHours() % 12 || 12).toString()) + ":" + (shellRoot.vertMinute || Qt.formatTime(new Date(), "mm"))
                            color: (Config.showCalendar || clockHorizHover.hovered) ? Config.accent : Config.textMain
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: Config.size(Config.fontTitle)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: shellRoot.vertAmPm || Qt.formatTime(new Date(), "ap").toLowerCase()
                            color: Config.accent
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: Config.size(Config.fontSubhead)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: (shellRoot.vertMonth || Qt.formatDate(new Date(), "MMM")) + " " + (shellRoot.vertDay || Qt.formatDate(new Date(), "d"))
                            color: (Config.showCalendar || clockHorizHover.hovered) ? Config.accent : Config.textMuted
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: Config.size(Config.fontSubhead)
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                TapHandler { 
                    onTapped: { 
                        if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                        rightCard.popoutRequested(btnClockHoriz)
                        Config.showCalendar = !Config.showCalendar 
                    } 
                }
                HoverHandler { 
                    id: clockHorizHover
                    cursorShape: Qt.PointingHandCursor 
                    onHoveredChanged: {
                        if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnClockHoriz)
                        else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    }
                }
            }
        }
    }

    // --- VERTICAL RIGHT MODULES ---
    Component {
        id: vertRightComp
        ColumnLayout {
            id: vertLayout
            spacing: 8
            anchors.fill: parent

            readonly property var ccBtn: btnCCVert
            readonly property var clockBtn: btnClockVert
            readonly property var overviewBtn: wsVert.overviewButton

            WorkspaceIndicators {
                id: wsVert
                isVertical: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                onPopoutRequested: item => rightCard.popoutRequested(item)
            }

            Rectangle {
                id: btnCCVert
                implicitWidth: 32
                implicitHeight: 32
                radius: 10
                color: Config.showControlCenter ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                Layout.alignment: Qt.AlignHCenter

                Behavior on color { ColorAnimation { duration: 150 } }

                Item {
                    anchors.centerIn: parent
                    implicitWidth: ccIconVertText.implicitWidth
                    implicitHeight: ccIconVertText.implicitHeight
                    scale: ccVertHover.hovered ? 1.25 : 1.0

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                    Glow {
                        anchors.fill: ccIconVertText
                        source: ccIconVertText
                        radius: ccVertHover.hovered ? 8 : 0
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: ccVertHover.hovered

                        Behavior on radius { NumberAnimation { duration: 180 } }
                    }

                    Text {
                        id: ccIconVertText
                        anchors.centerIn: parent
                        text: Config.getIcon("cc")
                        color: (Config.showControlCenter || ccVertHover.hovered) ? Config.accent : Config.textMain
                        font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 18

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                TapHandler {
                    onTapped: {
                        if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                        rightCard.popoutRequested(btnCCVert)
                        Config.showControlCenter = !Config.showControlCenter
                    }
                }
                HoverHandler { 
                    id: ccVertHover
                    cursorShape: Qt.PointingHandCursor 
                    onHoveredChanged: {
                        if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnCCVert)
                        else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    }
                }
            }

            Rectangle {
                id: btnClockVert
                implicitWidth: 32
                implicitHeight: dateColumn.implicitHeight + 16
                radius: 10
                color: Config.showCalendar ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                Layout.alignment: Qt.AlignHCenter

                Behavior on color { ColorAnimation { duration: 150 } }

                Item {
                    anchors.centerIn: parent
                    implicitWidth: dateColumn.implicitWidth
                    implicitHeight: dateColumn.implicitHeight
                    scale: clockVertHover.hovered ? 1.08 : 1.0

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                    Glow {
                        anchors.fill: dateColumn
                        source: dateColumn
                        radius: clockVertHover.hovered ? 8 : 0
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: clockVertHover.hovered

                        Behavior on radius { NumberAnimation { duration: 180 } }
                    }

                    ColumnLayout {
                        id: dateColumn
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            text: shellRoot.vertHour || (new Date().getHours() % 12 || 12).toString()
                            color: (Config.showCalendar || clockVertHover.hovered) ? Config.accent : Config.textMain
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: 15
                            renderType: Config.textRenderType
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: shellRoot.vertMinute || Qt.formatTime(new Date(), "mm")
                            color: (Config.showCalendar || clockVertHover.hovered) ? Config.accent : Config.textMain
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: 15
                            renderType: Config.textRenderType
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: shellRoot.vertAmPm || Qt.formatTime(new Date(), "ap").toLowerCase()
                            color: Config.accent
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: 12
                            renderType: Config.textRenderType
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: shellRoot.vertMonth || Qt.formatDate(new Date(), "MMM")
                            color: (Config.showCalendar || clockVertHover.hovered) ? Config.accent : Config.textMuted
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: 12
                            renderType: Config.textRenderType
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: shellRoot.vertDay || Qt.formatDate(new Date(), "d")
                            color: (Config.showCalendar || clockVertHover.hovered) ? Config.accent : Config.textMuted
                            font.family: Config.sysFont; font.weight: Font.Bold; font.pixelSize: 12
                            renderType: Config.textRenderType
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                TapHandler { 
                    onTapped: { 
                        if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
                        rightCard.popoutRequested(btnClockVert)
                        Config.showCalendar = !Config.showCalendar 
                    } 
                }

                HoverHandler { 
                    id: clockVertHover
                    cursorShape: Qt.PointingHandCursor 
                    onHoveredChanged: {
                        if (hovered && rootRef && rootRef.startPeek) rootRef.startPeek(btnClockVert)
                        else if (!hovered && rootRef && rootRef.stopPeek) rootRef.stopPeek()
                    }
                }
            }
        }
    }
}