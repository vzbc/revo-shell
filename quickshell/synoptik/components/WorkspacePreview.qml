import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io

FocusScope {
    id: overviewFlyout
    focus: true

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: Math.max(480, (rowContainer.childrenRect.width > 0 ? rowContainer.childrenRect.width + (cardMargin * 4) : 480))
    implicitHeight: Math.max(260, (cardLayout.implicitHeight > 0 ? cardLayout.implicitHeight + (cardMargin * 4) : 260))
    
    readonly property bool isOpen: typeof Config.showWorkspacePreview !== "undefined" ? Config.showWorkspacePreview : false

    property var liveClientJson: []
    property var liveMonitorJson: []
    
    // In-memory persistent cache for class -> iconPath (Fix #16)
    property var appIconCache: ({})

    function resolveAppIcon(cls) {
        if (!cls) return ""
        if (appIconCache[cls]) return appIconCache[cls]

        let iconPath = ""
        let entry = DesktopEntries.heuristicLookup(cls)
        if (entry && entry.icon) {
            iconPath = Quickshell.iconPath(entry.icon, true)
        }
        if (!iconPath) {
            iconPath = Quickshell.iconPath(cls, true) || Quickshell.iconPath(cls.toLowerCase(), true) || ""
        }
        if (!iconPath) {
            iconPath = Quickshell.iconPath("application-x-executable", true) || ""
        }

        appIconCache[cls] = iconPath
        return iconPath
    }

    property int highlightedIndex: 0
    property bool contentReady: false
    property string selectedWindowAddress: ""
    property string draggingWindowAddress: ""
    property string draggingWindowClass: ""
    property int dragHoverWorkspaceId: -1
    property real dragX: 0
    property real dragY: 0
    property bool isDraggingWindow: false
    property real draggingWindowWidth: 100
    property real draggingWindowHeight: 60

    property var draggingWlToplevel: {
        if (!draggingWindowAddress) return null;
        let targetAddr = draggingWindowAddress.trim().toLowerCase();
        let match = Hyprland.toplevels.values.find(t => {
            if (!t.lastIpcObject || !t.lastIpcObject.address) return false;
            return t.lastIpcObject.address.trim().toLowerCase() === targetAddr;
        });
        if (match && match.wayland) return match.wayland;
        return null;
    }

    function findWorkspaceAtPoint(globalX, globalY) {
        if (!rowContainer || !rowContainer.children) return -1;
        for (let i = 0; i < rowContainer.children.length; i++) {
            let child = rowContainer.children[i];
            if (child && typeof child.workingWorkspace !== "undefined") {
                let localPt = child.mapFromItem(overviewFlyout, globalX, globalY);
                if (localPt.x >= 0 && localPt.x <= child.width &&
                    localPt.y >= 0 && localPt.y <= child.height) {
                    return child.workingWorkspace;
                }
            }
        }
        return -1;
    }

    readonly property var activeWorkspaces: {
        let ids = [1];
        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
            let ws = Hyprland.workspaces.values[i];
            if (ws.id > 0 && !ids.includes(ws.id)) {
                ids.push(ws.id);
            }
        }
        return ids.sort((a, b) => a - b);
    }

    function switchWorkspace(targetWs) {
        Hyprland.dispatch("hl.dsp.release_input_capture()");
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + targetWs + " })");

        if (typeof Config.showWorkspacePreview !== "undefined") {
            Config.showWorkspacePreview = false;
        }
    }

    function formatWindowRef(windowAddr) {
        if (!windowAddr) return "";
        let trimmed = windowAddr.trim();
        if (trimmed.startsWith("address:")) return trimmed;
        if (trimmed.startsWith("0x")) return "address:" + trimmed;
        return trimmed;
    }

    function moveWindowToWorkspace(targetWs, windowAddr) {
        Hyprland.dispatch("hl.dsp.release_input_capture()");

        let formatted = formatWindowRef(windowAddr);
        if (formatted !== "") {
            Hyprland.dispatch("hl.dsp.focus({ window = \"" + formatted + "\" })");
            Hyprland.dispatch("hl.dsp.window.move({ workspace = " + targetWs + " })");
        } else {
            Hyprland.dispatch("hl.dsp.window.move({ workspace = " + targetWs + " })");
        }

        clientQueryProcess.running = true;
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function focusWindow(windowAddr) {
        let formatted = formatWindowRef(windowAddr);
        if (formatted !== "") {
            Hyprland.dispatch("hl.dsp.release_input_capture()");
            Hyprland.dispatch("hl.dsp.focus({ window = \"" + formatted + "\" })");
            if (typeof Config.showWorkspacePreview !== "undefined") {
                Config.showWorkspacePreview = false;
            }
        }
    }

    Keys.onPressed: (event) => {
        if (!overviewFlyout.isOpen) return;

        if (event.key === Qt.Key_Left) {
            if (overviewFlyout.highlightedIndex > 0) {
                overviewFlyout.highlightedIndex--;
            } else {
                overviewFlyout.highlightedIndex = overviewFlyout.activeWorkspaces.length - 1;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            if (overviewFlyout.highlightedIndex < overviewFlyout.activeWorkspaces.length - 1) {
                overviewFlyout.highlightedIndex++;
            } else {
                overviewFlyout.highlightedIndex = 0;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Select) {
            let targetWs = overviewFlyout.activeWorkspaces[overviewFlyout.highlightedIndex];
            event.accepted = true;
            switchWorkspace(targetWs);
        } else if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            if (typeof Config.showWorkspacePreview !== "undefined") {
                Config.showWorkspacePreview = false;
            }
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            contentReady = false
            renderDelayTimer.restart()

            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            clientQueryProcess.running = true
            
            let currentId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            let idx = activeWorkspaces.indexOf(currentId)
            highlightedIndex = idx !== -1 ? idx : 0
        } else {
            renderDelayTimer.stop()
            contentReady = false
        }
    }

    Component.onCompleted: {
        if (isOpen) {
            contentReady = false
            renderDelayTimer.restart()
            
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            clientQueryProcess.running = true
        }
    }

    Timer {
        id: renderDelayTimer
        interval: 300
        repeat: false
        onTriggered: {
            overviewFlyout.contentReady = true
            overviewFlyout.forceActiveFocus() 
        }
    }

    Connections {
        target: Hyprland
        ignoreUnknownSignals: true
        function onRawEvent(event) {
            let evtName = event && event.name ? event.name : "";
            let evtData = event && event.data ? event.data : "";

            if (evtName.includes("openwindow") || evtName.includes("closewindow") || evtName.includes("movewindow")) {
                clientQueryProcess.running = true;
            }

            if (evtName.includes("workspaceoverview") || evtData.includes("workspaceoverview")) {
                if (typeof Config.showWorkspacePreview !== "undefined") {
                    Config.showWorkspacePreview = !Config.showWorkspacePreview;
                }
            }
        }
    }

    Process {
        id: clientQueryProcess
        command: ["hyprctl", "clients", "-j"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                let cleanText = text.trim();
                if (!cleanText || cleanText === "[]") return;
                try { 
                    overviewFlyout.liveClientJson = JSON.parse(cleanText);
                } catch(e) {}
            }
        }
    }

    Process {
        id: monitorQueryProcess
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                let cleanText = text.trim();
                if (!cleanText || cleanText === "[]") return;
                try { 
                    overviewFlyout.liveMonitorJson = JSON.parse(cleanText);
                } catch(e) {}
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: overviewFlyout.cardMargin
        spacing: overviewFlyout.cardMargin

        opacity: overviewFlyout.contentReady ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: cardLayout.implicitHeight + (overviewFlyout.cardMargin * 2)
            color: Qt.rgba(255, 255, 255, 0.05)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            Watermark {
                icon: Config.getIcon("overview")
                iconSize: 150
                seed: 13
            }

            ColumnLayout {
                id: cardLayout
                anchors.fill: parent
                anchors.margins: overviewFlyout.cardMargin
                spacing: overviewFlyout.cardMargin

                Item {
                    implicitWidth: wsTitleText.implicitWidth
                    implicitHeight: wsTitleText.implicitHeight
                    Layout.fillWidth: true

                    Glow {
                        anchors.fill: wsTitleText
                        source: wsTitleText
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    Text {
                        id: wsTitleText
                        anchors.fill: parent
                        text: "WORKSPACES"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle)
                        font.bold: true
                        font.italic: true
                    }
                }

                Row {
                    id: rowContainer
                    Layout.alignment: Qt.AlignHCenter
                    spacing: overviewFlyout.cardMargin

                    Repeater {
                        model: overviewFlyout.activeWorkspaces

                        delegate: Rectangle {
                            id: wsTile
                            required property int modelData
                            required property int index

                            readonly property bool isCurrent: (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1) === modelData
                            readonly property bool isSelected: overviewFlyout.highlightedIndex === index
                            readonly property bool isDragTarget: overviewFlyout.isDraggingWindow && overviewFlyout.dragHoverWorkspaceId === modelData
                            property int workingWorkspace: modelData

                            color: tileHover.hovered || isSelected || isDragTarget ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(0, 0, 0, 0.3)
                    
                            border.color: tileHover.hovered || isSelected || isCurrent || isDragTarget ? Config.accent : "transparent"
                            border.width: tileHover.hovered || isSelected || isDragTarget ? 3 : (isCurrent ? 2 : 0)
                            
                            radius: Config.cornerRadius / 2
                            clip: false

                            Behavior on color { ColorAnimation { duration: 150 } }

                            property var monitorBounds: {
                                let _json = overviewFlyout.liveMonitorJson;
                                let monName = "";
                                let wsObj = Hyprland.workspaces.values.find(w => w.id === wsTile.workingWorkspace);
                                if (wsObj && wsObj.monitor) {
                                    monName = typeof wsObj.monitor === "string" ? wsObj.monitor : wsObj.monitor.name;
                                }

                                let monData = null;
                                if (_json && _json.length > 0) {
                                    monData = _json.find(m => m.name === monName);
                                    if (!monData) {
                                        let activeMon = Hyprland.activeMonitor;
                                        let activeName = activeMon ? (typeof activeMon === "string" ? activeMon : activeMon.name) : "";
                                        monData = _json.find(m => m.name === activeName);
                                    }
                                }

                                let mWidth = 1920, mHeight = 1080, mX = 0, mY = 0;
                                let isRotated = false;

                                if (monData) {
                                    let scale = monData.scale > 0 ? monData.scale : 1.0;
                                    let rawW = Math.round(monData.width / scale);
                                    let rawH = Math.round(monData.height / scale);
                                    
                                    if (monData.transform !== undefined) {
                                        isRotated = [1, 3, 5, 7].includes(parseInt(monData.transform, 10));
                                    }

                                    mWidth = isRotated ? rawH : rawW;
                                    mHeight = isRotated ? rawW : rawH;
                                    mX = monData.x !== undefined ? monData.x : 0;
                                    mY = monData.y !== undefined ? monData.y : 0;
                                } else {
                                    let fb = Hyprland.monitors.values.find(m => m.name === monName) || Hyprland.activeMonitor;
                                    if (fb) {
                                        let scale = fb.scale > 0 ? fb.scale : 1.0;
                                        mWidth = Math.round(fb.width / scale) || 1920;
                                        mHeight = Math.round(fb.height / scale) || 1080;
                                        mX = fb.x || 0;
                                        mY = fb.y || 0;
                                    }
                                }

                                return {
                                    "w": mWidth,
                                    "h": mHeight,
                                    "isVertical": mHeight > mWidth,
                                    "originX": mX,
                                    "originY": mY
                                };
                            }

                            width: Math.max(160, viewportFrame.width + (overviewFlyout.cardMargin * 2))
                            height: viewportFrame.height + headerRow.height + (overviewFlyout.cardMargin * 2)

                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 0

                                RowLayout {
                                    id: headerRow
                                    Layout.fillWidth: true
                                    height: 18

                                    Text {
                                        text: wsTile.modelData
                                        color: wsTile.isCurrent ? Config.accent : Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontSubhead)
                                        font.bold: true
                                    }

                                    Text {
                                        text: "task_alt"
                                        color: Config.accent
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: Config.size(Config.fontSubhead)
                                        font.bold: true
                                        visible: wsTile.isCurrent
                                    }

                                    Item { Layout.fillWidth: true }

                                    RowLayout {
                                        spacing: 4
                                        Repeater {
                                            model: viewportFrame.workspaceWindows
                                            delegate: Image {
                                                property string currentClass: (modelData && modelData.class) ? modelData.class : ""
                                                property string resolvedPath: overviewFlyout.resolveAppIcon(currentClass)
                                                
                                                visible: modelData && currentClass !== "" && modelData.mapped && resolvedPath !== ""
                                                source: resolvedPath
                                                
                                                Layout.preferredWidth: 14
                                                Layout.preferredHeight: 14
                                                fillMode: Image.PreserveAspectFit
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: viewportFrame
                                    Layout.fillWidth: false
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Qt.rgba(0, 0, 0, 0.3)
                                    radius: 4
                                    clip: true

                                    property var targetMonitorOutput: {
                                        let wsObj = Hyprland.workspaces.values.find(w => w.id === wsTile.workingWorkspace);
                                        let monName = wsObj && wsObj.monitor ? (typeof wsObj.monitor === "string" ? wsObj.monitor : wsObj.monitor.name) : "";
                                        
                                        if (!monName && Hyprland.activeMonitor) {
                                            monName = typeof Hyprland.activeMonitor === "string" ? Hyprland.activeMonitor : Hyprland.activeMonitor.name;
                                        }

                                        let qsScreen = Quickshell.screens.find(s => s.name === monName) || Quickshell.screens[0];
                                        return qsScreen ? qsScreen : null;
                                    }

                                    property var workspaceWindows: overviewFlyout.liveClientJson.filter(w => w.workspace.id === wsTile.workingWorkspace)
                                    property var sortedWorkspaceWindows: {
                                        let list = workspaceWindows.slice();
                                        list.sort((a, b) => {
                                            let aX = a && a.at ? a.at[0] : 0;
                                            let bX = b && b.at ? b.at[0] : 0;
                                            let aY = a && a.at ? a.at[1] : 0;
                                            let bY = b && b.at ? b.at[1] : 0;

                                            if (list.length <= 2) {
                                                return aX - bX;
                                            }

                                            if (Math.abs(aY - bY) > 50) {
                                                return aY - bY;
                                            }
                                            return aX - bX;
                                        });
                                        return list;
                                    }
                                    readonly property bool isGridMode: (tileHover.hovered || wsTile.isSelected) && workspaceWindows.length > 1

                                    implicitHeight: wsTile.monitorBounds.isVertical ? 220 : 135
                                    implicitWidth: Math.round(implicitHeight * (wsTile.monitorBounds.w / wsTile.monitorBounds.h))
                                    width: isGridMode ? Math.max(implicitWidth, Math.min(360, Math.round(implicitWidth * 1.35))) : implicitWidth
                                    height: implicitHeight
                                    Layout.preferredWidth: width
                                    Layout.preferredHeight: implicitHeight
                                    
                                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                    property real scaleX: width / wsTile.monitorBounds.w
                                    property real scaleY: height / wsTile.monitorBounds.h

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: viewportFrame.targetMonitorOutput
                                        live: overviewFlyout.isOpen
                                        paintCursor: false
                                        opacity: isGridMode ? 0.0 : 0.7
                                        visible: wsTile.isCurrent && opacity > 0

                                        readonly property bool isGridMode: (tileHover.hovered || wsTile.isSelected) && viewportFrame.workspaceWindows.length > 1
                                        Behavior on opacity { NumberAnimation { duration: 180 } }
                                    }
                                    
                                    Repeater {
                                        model: viewportFrame.workspaceWindows

                                        delegate: Rectangle {
                                            id: windowDelegate

                                            readonly property bool isGridMode: (tileHover.hovered || wsTile.isSelected) && viewportFrame.workspaceWindows.length > 1
                                            readonly property int totalCount: viewportFrame.workspaceWindows.length

                                            readonly property int cols: totalCount <= 2 ? totalCount : Math.ceil(Math.sqrt(totalCount))
                                            readonly property int rows: Math.ceil(totalCount / cols)

                                            readonly property real gap: 4
                                            readonly property real cellW: Math.max(10, Math.floor((viewportFrame.width - (gap * (cols + 1))) / cols))
                                            readonly property real cellH: Math.max(10, Math.floor((viewportFrame.height - (gap * (rows + 1))) / rows))

                                            readonly property int spatialIndex: {
                                                if (!modelData || !modelData.address || !viewportFrame.sortedWorkspaceWindows) return index;
                                                let addr = modelData.address.trim().toLowerCase();
                                                let idx = viewportFrame.sortedWorkspaceWindows.findIndex(w => w && w.address && w.address.trim().toLowerCase() === addr);
                                                return idx !== -1 ? idx : index;
                                            }

                                            readonly property int colIndex: spatialIndex % cols
                                            readonly property int rowIndex: Math.floor(spatialIndex / cols)

                                            readonly property real gridX: gap + colIndex * (cellW + gap)
                                            readonly property real gridY: gap + rowIndex * (cellH + gap)

                                            readonly property real normalX: Math.round((modelData.at[0] - wsTile.monitorBounds.originX) * viewportFrame.scaleX)
                                            readonly property real normalY: Math.round((modelData.at[1] - wsTile.monitorBounds.originY) * viewportFrame.scaleY)
                                            readonly property real normalW: Math.max(4, Math.round(modelData.size[0] * viewportFrame.scaleX))
                                            readonly property real normalH: Math.max(4, Math.round(modelData.size[1] * viewportFrame.scaleY))

                                            x: isGridMode ? Math.round(gridX) : Math.round(normalX)
                                            y: isGridMode ? Math.round(gridY) : Math.round(normalY)
                                            width: isGridMode ? Math.round(cellW) : Math.round(normalW)
                                            height: isGridMode ? Math.round(cellH) : Math.round(normalH)

                                            visible: modelData.mapped
                                            opacity: (overviewFlyout.isDraggingWindow && overviewFlyout.draggingWindowAddress === modelData.address) ? 0.4 : 1.0
                                            color: Qt.rgba(255, 255, 255, 0.08)
                                            border.color: windowMouseArea.containsMouse ? Config.accent : (isGridMode ? Qt.rgba(255, 255, 255, 0.25) : "transparent")
                                            border.width: windowMouseArea.containsMouse ? 2 : (isGridMode ? 1 : 0)
                                            radius: 2
                                            clip: true

                                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                            property var wlToplevel: {
                                                if (!modelData || !modelData.address) return null;
                                                let targetAddr = modelData.address.trim().toLowerCase();
                                                let match = Hyprland.toplevels.values.find(t => {
                                                    if (!t.lastIpcObject || !t.lastIpcObject.address) return false;
                                                    return t.lastIpcObject.address.trim().toLowerCase() === targetAddr;
                                                });
                                                if (match && match.wayland) return match.wayland;
                                                return null;
                                            }

                                            ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: windowDelegate.wlToplevel
                                                live: overviewFlyout.isOpen
                                                paintCursor: false
                                            }

                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                height: Math.min(16, parent.height * 0.3)
                                                color: "#cc11111b"
                                                visible: parent.height > 20 && parent.width > 32
                                                radius: 2

                                                Text {
                                                    text: (modelData.class || "")
                                                    font.family: Config.sysFont
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                    color: Config.textMain
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    elide: Text.ElideRight
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                            }

                                            MouseArea {
                                                id: windowMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: overviewFlyout.isDraggingWindow ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                                property point pressPos: Qt.point(0, 0)

                                                onPressed: (mouse) => {
                                                    overviewFlyout.forceActiveFocus();
                                                    pressPos = Qt.point(mouse.x, mouse.y);
                                                    if (modelData && modelData.address) {
                                                        overviewFlyout.selectedWindowAddress = modelData.address;
                                                    }
                                                }

                                                onPositionChanged: (mouse) => {
                                                    if (pressed) {
                                                        let dx = mouse.x - pressPos.x;
                                                        let dy = mouse.y - pressPos.y;
                                                        let dist = Math.sqrt(dx * dx + dy * dy);

                                                        let mapped = mapToItem(overviewFlyout, mouse.x, mouse.y);
                                                        if (!overviewFlyout.isDraggingWindow && dist > 5) {
                                                            overviewFlyout.isDraggingWindow = true;
                                                            overviewFlyout.draggingWindowAddress = modelData.address;
                                                            overviewFlyout.draggingWindowClass = modelData.class || "Window";
                                                            overviewFlyout.draggingWindowWidth = windowDelegate.width;
                                                            overviewFlyout.draggingWindowHeight = windowDelegate.height;
                                                        }

                                                        if (overviewFlyout.isDraggingWindow) {
                                                            overviewFlyout.dragX = mapped.x;
                                                            overviewFlyout.dragY = mapped.y;
                                                            overviewFlyout.dragHoverWorkspaceId = overviewFlyout.findWorkspaceAtPoint(mapped.x, mapped.y);
                                                        }
                                                    }
                                                }

                                                onReleased: (mouse) => {
                                                    if (overviewFlyout.isDraggingWindow) {
                                                        let mapped = mapToItem(overviewFlyout, mouse.x, mouse.y);
                                                        let dropWs = overviewFlyout.findWorkspaceAtPoint(mapped.x, mapped.y);
                                                        let targetAddr = overviewFlyout.draggingWindowAddress;

                                                        overviewFlyout.isDraggingWindow = false;
                                                        overviewFlyout.draggingWindowAddress = "";
                                                        overviewFlyout.draggingWindowClass = "";
                                                        overviewFlyout.dragHoverWorkspaceId = -1;

                                                        if (dropWs > 0) {
                                                            overviewFlyout.moveWindowToWorkspace(dropWs, targetAddr);
                                                        }
                                                    } else {
                                                        if (mouse.modifiers & Qt.ShiftModifier) {
                                                            let currentWs = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
                                                            overviewFlyout.moveWindowToWorkspace(currentWs, modelData.address);
                                                        } else {
                                                            overviewFlyout.focusWindow(modelData.address);
                                                        }
                                                    }
                                                }

                                                onEntered: {
                                                    if (modelData && modelData.address) {
                                                        overviewFlyout.selectedWindowAddress = modelData.address;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            TapHandler {
                                id: tileNormalTapHandler
                                acceptedModifiers: Qt.NoModifier
                                onTapped: {
                                    overviewFlyout.forceActiveFocus();
                                    overviewFlyout.switchWorkspace(wsTile.modelData);
                                }
                            }

                            TapHandler {
                                id: tileShiftTapHandler
                                acceptedModifiers: Qt.ShiftModifier
                                onTapped: {
                                    overviewFlyout.forceActiveFocus();
                                    overviewFlyout.moveWindowToWorkspace(wsTile.modelData, overviewFlyout.selectedWindowAddress);
                                }
                            }

                            HoverHandler {
                                id: tileHover
                                cursorShape: Qt.PointingHandCursor
                                
                                onHoveredChanged: {
                                    if (hovered) {
                                        overviewFlyout.highlightedIndex = wsTile.index
                                        overviewFlyout.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: dragGhost
        parent: overviewFlyout
        z: 999
        visible: overviewFlyout.isDraggingWindow
        width: Math.max(40, overviewFlyout.draggingWindowWidth)
        height: Math.max(25, overviewFlyout.draggingWindowHeight)
        color: Qt.rgba(20, 20, 30, 0.85)
        border.color: Config.accent
        border.width: 2
        radius: 4
        clip: true
        opacity: 0.9
        x: overviewFlyout.dragX - width / 2
        y: overviewFlyout.dragY - height / 2

        ScreencopyView {
            anchors.fill: parent
            captureSource: overviewFlyout.draggingWlToplevel
            live: overviewFlyout.isOpen
            paintCursor: false
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(16, parent.height * 0.3)
            color: "#cc11111b"
            visible: parent.height > 18 && parent.width > 30
            radius: 2

            Text {
                text: overviewFlyout.draggingWindowClass
                font.family: Config.sysFont
                font.pixelSize: 8
                font.bold: true
                color: Config.textMain
                anchors.centerIn: parent
                width: parent.width - 4
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}