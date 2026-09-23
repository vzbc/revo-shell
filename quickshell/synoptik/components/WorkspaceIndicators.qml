import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "."

Item {
    id: root
    
    property bool isVertical: false

    signal popoutRequested(var item)
    readonly property var overviewButton: overviewBtn

    // Measure children directly to ensure accurate footprint without layout distortion
    implicitWidth: isVertical ? 32 : (containerBox.width + 4)
    implicitHeight: isVertical ? (containerBox.height + 4) : 32
    width: implicitWidth
    height: implicitHeight

    function parseSpecialPayload(data) {
        if (!data) return "";
        let parts = data.split(',');
        let target = parts[0].trim();
        if (target.startsWith("special:")) {
            return target.replace(/^special:/, "");
        }
        return target;
    }

    // --- TRACKING ENGINES ---
    property int activeWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property string activeSpecialName: ""
    property var occupiedMap: ({})
    property var workspaceList: []
    property var windowCountMap: ({})
    property var appClassMap: ({})
    
    property bool isMagicOccupied: false
    property bool isMagicActive: activeSpecialName === "magic"

    property bool isMusicOccupied: false
    property bool isMusicActive: activeSpecialName === "music"

    property bool isPrivateOccupied: false
    property bool isPrivateActive: activeSpecialName === "private"

    // Single-shot debounce timer collapsing multi-event bursts into 1 execution pass
    property Timer rebuildDebounceTimer: Timer {
        interval: 16
        repeat: false
        onTriggered: root.rebuildWorkspaceData()
    }

    function queueRebuild() {
        if (!rebuildDebounceTimer.running) {
            rebuildDebounceTimer.restart()
        }
    }

    function rebuildWorkspaceData() {
        let occupied = {};
        let counts = {};
        let apps = {};
        let magicOcc = false;
        let musicOcc = false;
        let privateOcc = false;

        let activeId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
        let currentSpecial = root.activeSpecialName;

        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.name) {
            let focusedName = Hyprland.focusedWorkspace.name;
            if (focusedName.startsWith("special:")) {
                currentSpecial = focusedName.replace(/^special:/, "");
            }
        }

        // 1. Workspaces
        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
            let ws = Hyprland.workspaces.values[i];
            if (ws.id > 0) {
                occupied[ws.id] = true;
            } else if (ws.name) {
                let cleanName = ws.name.replace(/^special:/, "");
                if (cleanName === "magic") magicOcc = true;
                if (cleanName === "music") musicOcc = true;
                if (cleanName === "private") privateOcc = true;
            }
        }

        // 2. Toplevel clients for density & icons
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let j = 0; j < Hyprland.toplevels.values.length; j++) {
                let client = Hyprland.toplevels.values[j];
                if (client && client.workspace && client.workspace.id > 0) {
                    let wid = client.workspace.id;
                    counts[wid] = (counts[wid] || 0) + 1;
                    if (!apps[wid]) {
                        apps[wid] = client.wayland?.appId || client.lastIpcObject?.class || "";
                    }
                }
            }
        }

        let listSet = new Set(Object.keys(occupied).map(Number));
        if (activeId > 0) {
            listSet.add(activeId);
        }

        let sortedList = Array.from(listSet).sort((a, b) => a - b);
        if (sortedList.length === 0) sortedList = [1];

        root.occupiedMap = occupied;
        root.windowCountMap = counts;
        root.appClassMap = apps;
        root.activeWorkspace = activeId;
        root.activeSpecialName = currentSpecial;
        root.workspaceList = sortedList;

        root.isMagicOccupied = magicOcc;
        root.isMusicOccupied = musicOcc;
        root.isPrivateOccupied = privateOcc;
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.queueRebuild(); }
    }

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { root.queueRebuild(); }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.queueRebuild(); }
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                let cleanName = root.parseSpecialPayload(event.data);
                root.activeSpecialName = cleanName;
                root.queueRebuild();
            }
            if (event.name === "destroyworkspace" || event.name === "createworkspace" || event.name === "openwindow" || event.name === "closewindow") {
                root.queueRebuild();
            }
        }
    }

    Component.onCompleted: root.rebuildWorkspaceData()

    // Outer Capsule / Frame Container
    Rectangle {
        id: containerBox
        anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
        width: root.isVertical ? 32 : (mainLayout.childrenRect.width + (Config.workspaceContainerStyle === "plain" ? 0 : 20))
        height: root.isVertical ? (mainLayout.childrenRect.height + (Config.workspaceContainerStyle === "plain" ? 0 : 20)) : 32
        radius: (Config.workspaceContainerStyle === "bordered") ? 8 : 10

        color: Config.workspaceContainerStyle === "capsule" 
            ? Qt.rgba(255, 255, 255, 0.08) 
            : (Config.workspaceContainerStyle === "bordered" ? Qt.rgba(0, 0, 0, 0.18) : "transparent")

        border.width: Config.workspaceContainerStyle === "bordered" ? 1.5 : (Config.workspaceContainerStyle === "capsule" ? 1 : 0)
        border.color: Config.workspaceContainerStyle === "bordered" 
            ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.5) 
            : Qt.rgba(255, 255, 255, 0.12)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Mouse Wheel Quick-Switch (catches scroll deltas, lets clicks pass to pills)
        MouseArea {
            anchors.fill: parent
            enabled: Config.workspaceScroll !== false
            acceptedButtons: Qt.NoButton

            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                    Hyprland.dispatch("hl.dsp.focus({ workspace = \"m-1\" })");
                } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                    Hyprland.dispatch("hl.dsp.focus({ workspace = \"m+1\" })");
                }
            }
        }

        Flow {
            id: mainLayout
            anchors.centerIn: parent
            flow: root.isVertical ? Flow.TopToBottom : Flow.LeftToRight
            spacing: 8

            // --- GROUP 1: WORKSPACE PILLS ---
            Flow {
                flow: root.isVertical ? Flow.TopToBottom : Flow.LeftToRight
                spacing: 8

                Repeater {
                    model: root.workspaceList
                    delegate: Item {
                        id: pillSlot
                        property int wsId: modelData
                        property bool isSpecialAnyActive: root.activeSpecialName !== ""
                        property bool isActive: root.activeWorkspace === wsId
                        property bool isOccupied: root.occupiedMap[wsId] === true
                        property int winCount: root.windowCountMap[wsId] || 0
                        property string appClass: root.appClassMap[wsId] || ""
                        readonly property string style: Config.workspaceStyle || "pill"

                        property int basePillW: {
                            if (root.isVertical) {
                                if (style === "sliding") return isActive ? 12 : 20
                                if (style === "numeric" || style === "window_pips") return 22
                                if (style === "app_icons") return 24
                                return isActive ? 12 : 18
                            }
                            if (style === "sliding") return isActive ? 30 : 10
                            if (style === "numeric") return isActive ? 32 : 20
                            if (style === "app_icons") return isActive ? (appClass !== "" ? 38 : 28) : 22
                            if (style === "window_pips") return isActive ? 34 : 22
                            if (style === "geometric") return isActive ? 30 : 12
                            return isActive ? 28 : 10
                        }

                        property int basePillH: {
                            if (root.isVertical) {
                                if (style === "sliding") return isActive ? 30 : 10
                                if (style === "numeric") return isActive ? 32 : 20
                                if (style === "app_icons") return isActive ? 38 : 22
                                if (style === "window_pips") return isActive ? 34 : 22
                                if (style === "geometric") return isActive ? 30 : 12
                                return isActive ? 28 : 10
                            }
                            if (style === "sliding") return isActive ? 12 : 20
                            if (style === "numeric" || style === "app_icons" || style === "window_pips") return 20
                            return 10
                        }

                        width: root.isVertical ? 28 : basePillW
                        height: root.isVertical ? basePillH : 28

                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Item {
                            id: pillVisual
                            anchors.centerIn: parent
                            width: pillSlot.basePillW
                            height: pillSlot.basePillH
                            scale: pillHover.hovered ? 1.25 : 1.0

                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                            Glow {
                                anchors.fill: pillRect
                                source: pillRect
                                radius: (Config.workspaceGlow !== false && (pillSlot.isActive || pillHover.hovered)) ? 5 : 0
                                samples: 16
                                color: Config.accent
                                spread: 0.15
                                transparentBorder: true
                                visible: Config.workspaceGlow !== false && (pillSlot.isActive || pillHover.hovered)

                                Behavior on radius { NumberAnimation { duration: 150 } }
                            }

                            Rectangle {
                                id: pillRect
                                anchors.fill: parent
                                radius: (pillSlot.style === "sliding") 
                                    ? (root.isVertical ? width / 3 : height / 3) 
                                    : ((pillSlot.style === "geometric") ? 3 : (root.isVertical ? width / 2 : height / 2))

                                color: {
                                    if (pillSlot.style === "geometric") {
                                        return pillSlot.isActive 
                                            ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.35) 
                                            : (pillHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                                    }
                                    return pillSlot.isActive ? Config.accent : (pillHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent")
                                }

                                border.width: (pillSlot.style === "sliding") 
                                    ? (pillSlot.isActive ? 0 : 3) 
                                    : (pillSlot.isActive ? (pillSlot.style === "geometric" ? 2 : 0) : 2)

                                border.color: (pillSlot.style === "sliding") 
                                    ? (pillSlot.isActive ? "transparent" : (pillSlot.isOccupied ? (pillHover.hovered ? Config.accent : Config.textMain) : Qt.rgba(255, 255, 255, 0.18)))
                                    : (pillSlot.isActive 
                                        ? (pillSlot.style === "geometric" ? Config.accent : "transparent") 
                                        : (pillSlot.isOccupied ? (pillHover.hovered ? Config.accent : Config.textMain) : Qt.rgba(255, 255, 255, 0.22)))

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        visible: (pillSlot.style === "numeric")
                                        text: pillSlot.wsId
                                        font.family: Config.sysFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: pillSlot.isActive ? Config.bgBase : Config.textMain
                                    }

                                    IconImage {
                                        visible: (pillSlot.style === "app_icons" && pillSlot.appClass !== "")
                                        source: {
                                            if (!pillSlot.appClass) return ""
                                            let entry = DesktopEntries.heuristicLookup(pillSlot.appClass)
                                            if (entry && entry.icon) {
                                                let p = Quickshell.iconPath(entry.icon, true)
                                                if (p) return p
                                            }
                                            return Quickshell.iconPath(pillSlot.appClass, true) || Quickshell.iconPath("application-x-executable", true)
                                        }
                                        implicitWidth: 14
                                        implicitHeight: 14
                                    }

                                    Text {
                                        visible: (pillSlot.style === "app_icons" && pillSlot.appClass === "")
                                        text: pillSlot.wsId
                                        font.family: Config.sysFont
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: pillSlot.isActive ? Config.bgBase : Config.textMain
                                    }

                                    Row {
                                        visible: (pillSlot.style === "window_pips")
                                        spacing: 2
                                        Repeater {
                                            model: Math.min(Math.max(pillSlot.winCount, 1), 3)
                                            Rectangle {
                                                width: 3; height: 3; radius: 1.5
                                                color: pillSlot.isActive ? Config.bgBase : Config.accent
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            z: 200
                            anchors.bottom: root.isVertical ? undefined : parent.top
                            anchors.bottomMargin: root.isVertical ? undefined : 6
                            anchors.left: root.isVertical ? parent.right : undefined
                            anchors.leftMargin: root.isVertical ? 6 : undefined
                            anchors.horizontalCenter: root.isVertical ? undefined : parent.horizontalCenter
                            anchors.verticalCenter: root.isVertical ? parent.verticalCenter : undefined
                            implicitWidth: tooltipText.implicitWidth + 14
                            implicitHeight: 22
                            radius: 6
                            color: Qt.rgba(10, 12, 16, 0.95)
                            border.width: 1
                            border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.4)
                            visible: opacity > 0
                            opacity: (Config.workspaceTooltips !== false && pillHover.hovered) ? 1.0 : 0.0

                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                text: "Workspace " + pillSlot.wsId + (pillSlot.winCount > 0 ? " (" + pillSlot.winCount + " win)" : "")
                                font.family: Config.sysFont
                                font.pixelSize: 10
                                font.bold: true
                                color: Config.accent
                            }
                        }

                        TapHandler {
                            onTapped: {
                                if (typeof Config.showWorkspacePreview !== "undefined") Config.showWorkspacePreview = false;
                                root.activeSpecialName = "";
                                Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + pillSlot.wsId + "\" })");
                            }
                        }
                        HoverHandler { id: pillHover; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            Rectangle {
                implicitWidth: root.isVertical ? 16 : 1
                implicitHeight: root.isVertical ? 1 : 16
                color: Qt.rgba(255, 255, 255, 0.15)
                visible: (Config.workspaceShowAddBtn !== false) || (Config.workspaceShowOverviewBtn !== false) || (Config.workspaceShowSpecial !== false && (root.isMagicOccupied || root.isMagicActive || root.isMusicOccupied || root.isMusicActive || root.isPrivateOccupied || root.isPrivateActive))
            }

            // --- GROUP 2: ACTION BUTTONS ---
            Flow {
                flow: root.isVertical ? Flow.TopToBottom : Flow.LeftToRight
                spacing: 4

                Item {
                    implicitWidth: 28; implicitHeight: 28
                    visible: Config.workspaceShowAddBtn !== false

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.centerIn: parent
                        implicitWidth: addIconText.implicitWidth
                        implicitHeight: addIconText.implicitHeight
                        scale: addHover.hovered ? 1.2 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Glow {
                            anchors.fill: addIconText
                            source: addIconText
                            radius: (Config.workspaceGlow !== false && addHover.hovered) ? 6 : 0
                            samples: 16
                            color: Config.accent
                            spread: 0.15
                            transparentBorder: true
                            visible: Config.workspaceGlow !== false && addHover.hovered

                            Behavior on radius { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            id: addIconText
                            anchors.centerIn: parent
                            font.family: Config.sysFont; font.pixelSize: 18; font.bold: true
                            color: addHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.35)
                            text: "+"

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    TapHandler {
                        onTapped: {
                            let maxWs = root.workspaceList.length > 0 ? Math.max(...root.workspaceList) : 0;
                            root.activeSpecialName = "";
                            Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + (maxWs + 1) + "\" })");
                        }
                    }
                    HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
                }

                Item {
                    id: overviewBtn
                    implicitWidth: 28; implicitHeight: 28
                    visible: Config.workspaceShowOverviewBtn !== false

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Config.showWorkspacePreview ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.centerIn: parent
                        implicitWidth: overviewIconText.implicitWidth
                        implicitHeight: overviewIconText.implicitHeight
                        scale: overviewHover.hovered ? 1.2 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Glow {
                            anchors.fill: overviewIconText
                            source: overviewIconText
                            radius: (Config.workspaceGlow !== false && overviewHover.hovered) ? 6 : 0
                            samples: 16
                            color: Config.accent
                            spread: 0.15
                            transparentBorder: true
                            visible: Config.workspaceGlow !== false && overviewHover.hovered

                            Behavior on radius { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            id: overviewIconText
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"; font.weight: Font.Bold; font.pixelSize: 18
                            color: (Config.showWorkspacePreview || overviewHover.hovered) ? Config.accent : Qt.rgba(255, 255, 255, 0.35)
                            text: Config.getIcon("overview")

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    TapHandler { onTapped: { root.popoutRequested(overviewBtn); if (typeof Config.showWorkspacePreview !== "undefined") Config.showWorkspacePreview = !Config.showWorkspacePreview; } }
                    HoverHandler { id: overviewHover; cursorShape: Qt.PointingHandCursor }
                }

                Item {
                    implicitWidth: 28; implicitHeight: 28
                    visible: Config.workspaceShowSpecial !== false && (root.isMagicOccupied || root.isMagicActive)

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: root.isMagicActive ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.centerIn: parent
                        implicitWidth: 20
                        implicitHeight: 20
                        scale: magicHover.hovered ? 1.2 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Glow {
                            anchors.fill: magicIconText
                            source: magicIconText
                            radius: (Config.workspaceGlow !== false && magicHover.hovered) ? 6 : 0
                            samples: 16
                            color: Config.accent
                            spread: 0.15
                            transparentBorder: true
                            visible: Config.workspaceGlow !== false && magicHover.hovered

                            Behavior on radius { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            id: magicIconText
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"; font.weight: Font.Bold
                            font.pixelSize: root.isMagicActive ? 20 : 18
                            color: (root.isMagicActive || magicHover.hovered) ? Config.accent : Qt.rgba(255, 255, 255, 0.35)
                            text: root.isMagicActive ? Config.getIcon("magic_active") : Config.getIcon("magic")

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    TapHandler { onTapped: Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"magic\")") }
                    HoverHandler { id: magicHover; cursorShape: Qt.PointingHandCursor }
                }

                Item {
                    implicitWidth: 28; implicitHeight: 28
                    visible: Config.workspaceShowSpecial !== false && (root.isMusicOccupied || root.isMusicActive)

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: root.isMusicActive ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.centerIn: parent
                        implicitWidth: 20
                        implicitHeight: 20
                        scale: musicHover.hovered ? 1.2 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Glow {
                            anchors.fill: musicIconText
                            source: musicIconText
                            radius: (Config.workspaceGlow !== false && musicHover.hovered) ? 6 : 0
                            samples: 16
                            color: Config.accent
                            spread: 0.15
                            transparentBorder: true
                            visible: Config.workspaceGlow !== false && musicHover.hovered

                            Behavior on radius { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            id: musicIconText
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"; font.weight: Font.Bold
                            font.pixelSize: root.isMusicActive ? 20 : 18
                            color: (root.isMusicActive || musicHover.hovered) ? Config.accent : Qt.rgba(255, 255, 255, 0.35)
                            text: root.isMusicActive ? Config.getIcon("music_active") : Config.getIcon("music")

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    TapHandler { onTapped: Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"music\")") }
                    HoverHandler { id: musicHover; cursorShape: Qt.PointingHandCursor }
                }

                Item {
                    implicitWidth: 28; implicitHeight: 28
                    visible: Config.workspaceShowSpecial !== false && (root.isPrivateOccupied || root.isPrivateActive)

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: root.isPrivateActive ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item {
                        anchors.centerIn: parent
                        implicitWidth: 20
                        implicitHeight: 20
                        scale: privateHover.hovered ? 1.2 : 1.0

                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                        Glow {
                            anchors.fill: privateIconText
                            source: privateIconText
                            radius: (Config.workspaceGlow !== false && privateHover.hovered) ? 6 : 0
                            samples: 16
                            color: Config.accent
                            spread: 0.15
                            transparentBorder: true
                            visible: Config.workspaceGlow !== false && privateHover.hovered

                            Behavior on radius { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            id: privateIconText
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"; font.weight: Font.Bold
                            font.pixelSize: root.isPrivateActive ? 20 : 18
                            color: (root.isPrivateActive || privateHover.hovered) ? Config.accent : Qt.rgba(255, 255, 255, 0.35)
                            text: root.isPrivateActive ? Config.getIcon("private_active") : Config.getIcon("private")

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    TapHandler { onTapped: Hyprland.dispatch("hl.dsp.workspace.toggle_special(\"private\")") }
                    HoverHandler { id: privateHover; cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}