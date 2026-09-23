import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import ".."

Rectangle {
    id: activeWinCard

    property var rootRef
    property string activeScreenName: (rootRef && rootRef.screen) ? rootRef.screen.name : ""

    readonly property string barPos: rootRef ? (rootRef.barPosition || "top") : "top"
    readonly property bool isHoriz: rootRef ? rootRef.isHorizontal : true

    // Direct O(1) focused client resolution without O(n) toplevel list traversal (Fix #14)
    readonly property var activeClient: {
        let top = Hyprland.activeToplevel
        if (top) {
            let matchesScreen = !activeScreenName || !top.monitor || top.monitor.name === activeScreenName
            if (matchesScreen && top.activated) return top
        }

        // Fallback to the monitor's focused workspace active window if activeToplevel is on another monitor
        if (rootRef && rootRef.screen && Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === activeScreenName) {
            return Hyprland.activeToplevel
        }
        return null
    }

    readonly property string appId: activeClient ? (activeClient.wayland?.appId || activeClient.lastIpcObject?.class || "") : ""
    readonly property string winTitle: activeClient ? (activeClient.title || appId || "") : ""
    readonly property bool hasWindow: activeClient !== null && winTitle !== ""

    visible: hasWindow

    signal popoutRequested(var item)

    // Rotation angle for text in vertical mode
    readonly property real textRotation: {
        if (isHoriz) return 0
        return barPos === "left" ? -90 : 90
    }

    // Dynamic dimensions
    property real maxAvailableSpan: 190
    width: isHoriz ? Math.max(36, Math.min(190, maxAvailableSpan)) : 36
    height: isHoriz ? 36 : Math.max(36, Math.min(190, maxAvailableSpan))

    radius: Config.cornerRadius / 2
    color: (Config.showTaskOverflow || cardHover.hovered) ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
    border.width: (Config.showTaskOverflow || cardHover.hovered) ? 2 : 1
    border.color: (Config.showTaskOverflow || cardHover.hovered) ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
    clip: true

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    TapHandler {
        onTapped: {
            if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
            activeWinCard.popoutRequested(activeWinCard)
            if (rootRef) rootRef.setPopoutPos(activeWinCard)
            Config.showTaskOverflow = !Config.showTaskOverflow
        }
    }

    HoverHandler { 
        id: cardHover
        cursorShape: Qt.PointingHandCursor 
        onHoveredChanged: {
            if (hovered) {
                if (rootRef && rootRef.startPeek) rootRef.startPeek(activeWinCard)
            } else {
                if (rootRef && rootRef.stopPeek) rootRef.stopPeek()
            }
        }
    }

    // HORIZONTAL LAYOUT
    RowLayout {
        id: contentRow
        visible: isHoriz
        anchors.fill: parent
        anchors.leftMargin: activeWinCard.width <= 44 ? 0 : 10
        anchors.rightMargin: activeWinCard.width <= 44 ? 0 : 10
        spacing: activeWinCard.width <= 44 ? 0 : 8

        IconImage {
            id: iconHoriz
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: activeWinCard.width <= 44 ? Qt.AlignCenter : Qt.AlignVCenter
            asynchronous: true
            source: {
                if (!activeWinCard.appId) return Quickshell.iconPath("application-x-executable", true)
                let entry = DesktopEntries.heuristicLookup(activeWinCard.appId)
                if (entry && entry.icon) {
                    let path = Quickshell.iconPath(entry.icon, true)
                    if (path) return path
                }
                return Quickshell.iconPath(activeWinCard.appId, true) || Quickshell.iconPath("application-x-executable", true)
            }
        }

        Item {
            id: tickerBoxHoriz
            visible: activeWinCard.width > 50
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            readonly property real overflowDist: Math.max(0, titleTextHoriz.implicitWidth - tickerBoxHoriz.width)
            readonly property bool needsTicker: overflowDist > 2

            Text {
                id: titleTextHoriz
                anchors.verticalCenter: parent.verticalCenter
                text: activeWinCard.winTitle
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                font.bold: true

                x: 0

                SequentialAnimation on x {
                    id: tickerAnimHoriz
                    running: activeWinCard.isHoriz && tickerBoxHoriz.needsTicker && activeWinCard.visible && tickerBoxHoriz.visible
                    loops: 1

                    PauseAnimation { duration: 1000 }

                    NumberAnimation {
                        to: -tickerBoxHoriz.overflowDist
                        duration: Math.max(1000, tickerBoxHoriz.overflowDist * 40)
                        easing.type: Easing.Linear
                    }
                }

                onTextChanged: {
                    x = 0
                    tickerAnimHoriz.restart()
                }
            }
        }
    }

    // VERTICAL LAYOUT (Icon positioned at the leading start of the text reading direction)
    GridLayout {
        id: contentColumn
        visible: !isHoriz
        anchors.fill: parent
        anchors.topMargin: activeWinCard.height <= 44 ? 0 : 10
        anchors.bottomMargin: activeWinCard.height <= 44 ? 0 : 10
        columnSpacing: 0
        rowSpacing: activeWinCard.height <= 44 ? 0 : 8
        columns: 1
        rows: 2

        IconImage {
            id: iconVert
            Layout.row: activeWinCard.barPos === "left" ? 1 : 0
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: activeWinCard.height <= 44 ? Qt.AlignCenter : Qt.AlignHCenter
            asynchronous: true
            source: {
                if (!activeWinCard.appId) return Quickshell.iconPath("application-x-executable", true)
                let entry = DesktopEntries.heuristicLookup(activeWinCard.appId)
                if (entry && entry.icon) {
                    let path = Quickshell.iconPath(entry.icon, true)
                    if (path) return path
                }
                return Quickshell.iconPath(activeWinCard.appId, true) || Quickshell.iconPath("application-x-executable", true)
            }
        }

        Item {
            id: tickerBoxVert
            Layout.row: activeWinCard.barPos === "left" ? 0 : 1
            visible: activeWinCard.height > 50
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            readonly property real overflowDist: Math.max(0, titleTextVert.implicitWidth - tickerBoxVert.height)
            readonly property bool needsTicker: overflowDist > 2
            readonly property bool isCcw: activeWinCard.textRotation === -90
            property real tickerOffset: 0

            SequentialAnimation on tickerOffset {
                id: tickerAnimVert
                running: !activeWinCard.isHoriz && tickerBoxVert.needsTicker && activeWinCard.visible && tickerBoxVert.visible
                loops: 1

                PauseAnimation { duration: 1000 }

                NumberAnimation {
                    to: tickerBoxVert.isCcw ? tickerBoxVert.overflowDist : -tickerBoxVert.overflowDist
                    duration: Math.max(1000, tickerBoxVert.overflowDist * 40)
                    easing.type: Easing.Linear
                }
            }

            Text {
                id: titleTextVert
                text: activeWinCard.winTitle
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                font.bold: true

                transformOrigin: Item.TopLeft
                rotation: activeWinCard.textRotation

                x: tickerBoxVert.isCcw
                    ? Math.round((tickerBoxVert.width - titleTextVert.implicitHeight) / 2.0)
                    : Math.round((tickerBoxVert.width + titleTextVert.implicitHeight) / 2.0)

                y: {
                    if (tickerBoxVert.needsTicker) {
                        return tickerBoxVert.isCcw
                            ? (tickerBoxVert.height + tickerBoxVert.tickerOffset)
                            : tickerBoxVert.tickerOffset
                    }
                    return tickerBoxVert.isCcw
                        ? Math.round((tickerBoxVert.height + titleTextVert.implicitWidth) / 2.0)
                        : Math.round((tickerBoxVert.height - titleTextVert.implicitWidth) / 2.0)
                }

                onTextChanged: {
                    tickerBoxVert.tickerOffset = 0
                    tickerAnimVert.restart()
                }
            }
        }
    }
}