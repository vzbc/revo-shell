import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: floatingWidget
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qs-floating-overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore 
            color: "transparent"
            
            focusable: isSidebarVisible && (!isPinned || (typeof mainHoverTracker !== "undefined" && mainHoverTracker.hovered))

            // =========================================================
            // --- FULL SCREEN LAYOUT & TOPBAR CLEARANCE
            // =========================================================
            anchors {
                top: false; bottom: true; left: true; right: true
            }
            implicitHeight: floatingWidget.screen.height - 60

            // =========================================================
            // --- FOCUS TRACKING (FALLBACK CLOSER)
            // =========================================================
            Item {
                id: focusTracker
                focus: true
                onActiveFocusChanged: {
                    if (!activeFocus && !floatingWidget.isPinned) {
                        floatingWidget.isExpanded = false;
                        hideTimer.restart(); 
                    }
                }
            }

            // =========================================================
            // --- STATE LOGIC
            // =========================================================
            property bool isPinned: false 
            property bool useGraceTimer: false // Tracks if the 3s drag grace period is active
            
            onIsPinnedChanged: {
                if (!isPinned) kickTimer();
            }

            property int hoveredBars: 0

            // =========================================================
            // --- MODULE CONFIGURATION
            // =========================================================
            property var tabModules: [
                "quickactions/DrawAction.qml",
		"quickactions/SystemUsage.qml",
		"quickactions/Timer.qml"
            ]

            property int tabCount: Math.max(1, tabModules.length)

            // =========================================================
            // --- IPC CONTROLS
            // =========================================================
            IpcHandler {
                target: "floating"

                function setIndex(idx: string) {
                    let newIdx = parseInt(idx);
                    if (!isNaN(newIdx) && newIdx >= 0 && newIdx < floatingWidget.tabCount) {
                        floatingWidget.activeIndex = newIdx;
                    }
                }

                function forceReload() {
                    Quickshell.reload(true) 
                }
            }

            // =========================================================
            // --- UNIVERSAL SHORTCUT ROUTER
            // =========================================================
            function childIntercepts(sequenceStr) {
                // If not expanded, parent always keeps control
                if (!isExpanded) return false; 

                if (typeof moduleRepeater !== "undefined" && activeIndex >= 0 && activeIndex < moduleRepeater.count) {
                    let loader = moduleRepeater.itemAt(activeIndex);
                    
                    if (loader && loader.status === Loader.Ready && loader.item) {
                        // Check if the child has exposed a list of shortcuts it wants to steal
                        if (loader.item.interceptedShortcuts !== undefined) {
                            return loader.item.interceptedShortcuts.includes(sequenceStr);
                        }
                    }
                }
                return false; // Safe default: parent retains the shortcut
            }

            // =========================================================
            // --- KEYBOARD SHORTCUTS & ACTIVITY TRACKER
            // =========================================================
            function kickTimer() {
                if (!isPinned) {
                    if ((typeof mainHoverTracker !== "undefined" && mainHoverTracker.hovered) ||
                        (typeof sidebarDragArea !== "undefined" && (sidebarDragArea.containsMouse || sidebarDragArea.pressed)) ||
                        (typeof gridMouseArea !== "undefined" && (gridMouseArea.containsMouse || gridMouseArea.pressed)) ||
                        (typeof peekMouse !== "undefined" && (peekMouse.containsMouse || peekMouse.pressed)) ||
                        (typeof pinMouse !== "undefined" && pinMouse.containsMouse) ||
                        (typeof expandMouse !== "undefined" && expandMouse.containsMouse) ||
                        floatingWidget.hoveredBars > 0) {
                        return;
                    }
                    hideTimer.restart();
                }
            }

            Shortcut { enabled: floatingWidget.isSidebarVisible && !floatingWidget.childIntercepts("Tab"); sequence: "Tab"; onActivated: { floatingWidget.activeIndex = (floatingWidget.activeIndex + 1) % floatingWidget.tabCount; floatingWidget.kickTimer(); } }
            Shortcut { enabled: floatingWidget.isSidebarVisible && !floatingWidget.childIntercepts("Shift+Tab"); sequence: "Shift+Tab"; onActivated: { floatingWidget.activeIndex = (floatingWidget.activeIndex + (floatingWidget.tabCount - 1)) % floatingWidget.tabCount; floatingWidget.kickTimer(); } }
            Shortcut { enabled: floatingWidget.isSidebarVisible && !floatingWidget.childIntercepts("Return"); sequence: "Return"; onActivated: { floatingWidget.isExpanded = !floatingWidget.isExpanded; floatingWidget.kickTimer(); } }
            Shortcut { enabled: floatingWidget.isSidebarVisible && !floatingWidget.childIntercepts("Enter"); sequence: "Enter"; onActivated: { floatingWidget.isExpanded = !floatingWidget.isExpanded; floatingWidget.kickTimer(); } }
            
            Shortcut { 
                enabled: floatingWidget.isSidebarVisible && floatingWidget.activeEdge === "bottom" && !floatingWidget.childIntercepts("Left")
                sequence: "Left"
                onActivated: { floatingWidget.activeIndex = Math.max(0, floatingWidget.activeIndex - 1); floatingWidget.kickTimer(); } 
            }
            Shortcut { 
                enabled: floatingWidget.isSidebarVisible && floatingWidget.activeEdge === "bottom" && !floatingWidget.childIntercepts("Right")
                sequence: "Right"
                onActivated: { floatingWidget.activeIndex = Math.min(floatingWidget.tabCount - 1, floatingWidget.activeIndex + 1); floatingWidget.kickTimer(); } 
            }
            Shortcut { 
                enabled: floatingWidget.isSidebarVisible && (floatingWidget.activeEdge === "left" || floatingWidget.activeEdge === "right") && !floatingWidget.childIntercepts("Up")
                sequence: "Up"
                onActivated: { 
                    let step = floatingWidget.activeEdge === "right" ? 1 : -1;
                    floatingWidget.activeIndex = Math.max(0, Math.min(floatingWidget.tabCount - 1, floatingWidget.activeIndex + step)); 
                    floatingWidget.kickTimer(); 
                } 
            }
            Shortcut { 
                enabled: floatingWidget.isSidebarVisible && (floatingWidget.activeEdge === "left" || floatingWidget.activeEdge === "right") && !floatingWidget.childIntercepts("Down")
                sequence: "Down"
                onActivated: { 
                    let step = floatingWidget.activeEdge === "right" ? -1 : 1;
                    floatingWidget.activeIndex = Math.max(0, Math.min(floatingWidget.tabCount - 1, floatingWidget.activeIndex + step)); 
                    floatingWidget.kickTimer(); 
                } 
            }

            Shortcut { 
                enabled: floatingWidget.isSidebarVisible && !floatingWidget.childIntercepts("Escape")
                sequence: "Escape"
                onActivated: {
                    if (floatingWidget.isExpanded) {
                        floatingWidget.isExpanded = false;
                        floatingWidget.kickTimer();
                    } else if (!floatingWidget.isPinned) {
                        floatingWidget.isSidebarVisible = false;
                        floatingWidget.isPeekVisible = true;
                        peekHideTimer.restart();
                    }
                }
            }

            // =========================================================
            // --- SCALER & THEMING
            // =========================================================
            Scaler {
                id: scaler
                currentWidth: floatingWidget.screen.width
            }

            property real baseScale: scaler.baseScale
            function s(val) { 
                let res = scaler.s(val); 
                return isNaN(res) ? val : res; 
            }

            MatugenColors { id: mocha }

            // =========================================================
            // --- DYNAMIC LAYOUT LOGIC
            // =========================================================
            property int activeIndex: 0 
            property bool isExpanded: false 

            property var currentLayoutTemplate: [{x: 0, y: 0, w: 1, h: 1}]

            function evaluateDrag(gpStartX, gpStartY, gpMouseX, gpMouseY) {
                let delta = 0;
                if (activeEdge === "left") delta = gpMouseX - gpStartX;
                else if (activeEdge === "right") delta = gpStartX - gpMouseX;
                else if (activeEdge === "bottom") delta = gpStartY - gpMouseY;

                if (delta > s(30) && !isExpanded) {
                    isExpanded = true;
                } else if (delta < -s(30) && (isExpanded || isSidebarVisible)) {
                    isExpanded = false;
                    if (!isPinned) {
                        isSidebarVisible = false;
                        isPeekVisible = true;
                        peekHideTimer.restart(); 
                    }
                }
            }
            
            property real h_in: s(32) 
            property real h_ac: s(112)
            property real itemSpacing: s(10)

            property real buttonSize: s(19)
            property real controlAreaHeight: buttonSize * 2 + s(14)

            property real barOffsetY: activeEdge === "left" ? (controlAreaHeight + itemSpacing) : 0

            function getTargetY(idx, activeIdx) {
                let y = 0;
                for (let i = 0; i < idx; i++) {
                    y += (i === activeIdx ? h_ac : h_in) + itemSpacing;
                }
                return y;
            }

            // =========================================================
            // --- SYNCHRONIZED MORPH PROGRESS
            // =========================================================
            property real baseExpandedWidth: s(378)
            property real baseExpandedExtraLength: s(224)
            property real expandedPadding: s(15)
            
            property real targetExpandedExtraLength: baseExpandedExtraLength

            property real expandedWidth: baseExpandedWidth
            property real expandedExtraLength: baseExpandedExtraLength

            Behavior on expandedWidth { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }
            Behavior on expandedExtraLength { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 450; easing.type: Easing.OutQuart } }

            property real expandProgress: isExpanded ? 1.0 : 0.0
            Behavior on expandProgress { 
                enabled: !floatingWidget.disableAnim
                NumberAnimation { duration: 450; easing.type: Easing.OutQuart } 
            }

            property real visibleProgress: isSidebarVisible ? 1.0 : 0.0
            Behavior on visibleProgress { 
                enabled: !floatingWidget.disableAnim
                NumberAnimation { duration: 300; easing.type: Easing.OutExpo } 
            }

            property real currentExtraWidth: (expandedWidth + expandedPadding) * expandProgress
            property real currentExtraLength: expandedExtraLength * expandProgress
            
            property real totalSidebarWidth: s(35) + currentExtraWidth

            // =========================================================
            // --- PRECISE MATHEMATICAL WAYLAND INPUT MASK
            // =========================================================
	    property var activeMaskAABB: {
		if (!floatingWidget.isSidebarVisible) return Qt.rect(0, 0, 0, 0);
                let cw = sidebarContainer.width;
                let ch = sidebarContainer.height;
                let cx = sidebarContainer.x + cw / 2;
                let cy = sidebarContainer.y + ch / 2;

                let innerW = floatingWidget.sidebarW + floatingWidget.currentExtraWidth;
                let innerH = floatingWidget.baseSidebarH + floatingWidget.currentExtraLength;

                let buffer = floatingWidget.s(15); 

                let relMinX = -cw / 2 - buffer;
                let relMaxX = -cw / 2 + innerW + buffer;
                let relMinY = -innerH / 2 - buffer;
                let relMaxY = innerH / 2 + buffer;

                let rot = floatingWidget.targetRotation;
                let aabbX = 0, aabbY = 0, aabbW = 0, aabbH = 0;
                
                if (rot === 0) {
                    aabbX = cx + relMinX;
                    aabbY = cy + relMinY;
                    aabbW = relMaxX - relMinX;
                    aabbH = relMaxY - relMinY;
                } else if (rot === 180) {
                    aabbX = cx - relMaxX;
                    aabbY = cy - relMaxY;
                    aabbW = relMaxX - relMinX;
                    aabbH = relMaxY - relMinY;
                } else if (rot === -90) {
                    aabbX = cx + relMinY;
                    aabbY = cy - relMaxX;
                    aabbW = relMaxY - relMinY; 
                    aabbH = relMaxX - relMinX;
                } else {
                    aabbW = innerW + buffer * 2; 
                    aabbH = innerH + buffer * 2;
                    aabbX = cx - aabbW / 2; 
                    aabbY = cy - aabbH / 2;
                }
                
                return Qt.rect(aabbX, aabbY, aabbW, aabbH);
            }

            mask: Region {
                Region { x: 0; y: 0; width: 1; height: floatingWidget.height }
                Region { x: floatingWidget.width - 1; y: 0; width: 1; height: floatingWidget.height }
                Region { x: 0; y: floatingWidget.height - 1; width: floatingWidget.width; height: 1 }

                Region {
                    x: floatingWidget.isPeekVisible ? peekBar.x - floatingWidget.s(15) : 0
                    y: floatingWidget.isPeekVisible ? peekBar.y - floatingWidget.s(15) : 0
                    width: floatingWidget.isPeekVisible ? peekBar.width + floatingWidget.s(30) : 0
                    height: floatingWidget.isPeekVisible ? peekBar.height + floatingWidget.s(30) : 0
                }

                Region {
                    x: floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.x : 0
                    y: floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.y : 0
                    width: floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.width : 0
                    height: floatingWidget.isSidebarVisible ? floatingWidget.activeMaskAABB.height : 0
                }
            }

            // =========================================================
            // --- CLAMPED CENTERING LOGIC
            // =========================================================
            function safeClamp(pos, size, margin) {
                let minCenter = margin;
                let maxCenter = size - margin;
                if (minCenter <= maxCenter) {
                    return Math.max(minCenter, Math.min(maxCenter, pos));
                } else {
                    let ratio = Math.max(0, Math.min(1, pos / size));
                    return minCenter + ratio * (maxCenter - minCenter); 
                }
            }

            property real targetEdgeMargin: {
                let length = baseSidebarH;
                if (isExpanded) {
                    length += targetExpandedExtraLength;
                }
                return (length / 2) + s(5);
            }

            property real clampedCenterX: safeClamp(currentPos, floatingWidget.width, targetEdgeMargin)
            property real clampedCenterY: safeClamp(currentPos, floatingWidget.height, targetEdgeMargin)

            // =========================================================
            // --- EDGE TRANSITION STATE MACHINE
            // =========================================================
            property string pendingEdge: ""
            property real pendingPos: 0
            property bool pendingWasExpanded: false
            property string pendingMode: "" 

            Timer {
                id: edgeTransitionTimer
                interval: 350
                onTriggered: {
                    floatingWidget.disableAnim = true;
                    floatingWidget.activeEdge = floatingWidget.pendingEdge;
                    floatingWidget.currentPos = floatingWidget.pendingPos;
                    teleportTimer.restart();
                }
            }

            Timer {
                id: teleportTimer
                interval: 32 
                onTriggered: {
                    floatingWidget.disableAnim = false;
                    if (floatingWidget.pendingMode === "sidebar") {
                        floatingWidget.isSidebarVisible = true;
                        floatingWidget.isExpanded = floatingWidget.pendingWasExpanded;
                        floatingWidget.isPeekVisible = false;
                        hideTimer.restart();
                    } else if (floatingWidget.pendingMode === "peek") {
                        floatingWidget.isPeekVisible = true;
                        floatingWidget.isSidebarVisible = false;
                        floatingWidget.isExpanded = false;
                    }
                    floatingWidget.pendingMode = "";
                }
            }

            // =========================================================
            // --- SLIDE-IN POPUP LOGIC & DYNAMIC HEIGHT SCALING
            // =========================================================
            property bool isSidebarVisible: false
            property bool isPeekVisible: false
            property bool disableAnim: false
            
            property string activeEdge: "left"
            property real currentPos: 0

            property real baseSidebarH: {
                let count = floatingWidget.tabCount;
                let activeTabH = count > 0 ? floatingWidget.h_ac : 0;
                let inactiveTabsH = Math.max(0, count - 1) * floatingWidget.h_in;
                let tabsSpacing = Math.max(0, count - 1) * floatingWidget.itemSpacing;
                
                let controlSpacing = count > 0 ? floatingWidget.itemSpacing : 0;
                let margins = floatingWidget.s(16); 
                
                return floatingWidget.controlAreaHeight + controlSpacing + activeTabH + inactiveTabsH + tabsSpacing + margins;
            }

            property real sidebarW: s(35)
            
            property real sidebarTargetX: {
                if (activeEdge === "left") return 0;
                if (activeEdge === "right") return floatingWidget.width - sidebarW;
                if (activeEdge === "bottom") return clampedCenterX - sidebarW / 2;
                return 0;
            }

            property real sidebarTargetY: {
                if (activeEdge === "left" || activeEdge === "right") return clampedCenterY - baseSidebarH / 2;
                if (activeEdge === "bottom") return floatingWidget.height - sidebarW / 2 - baseSidebarH / 2; 
                return 0;
            }

            property real targetRotation: {
                if (activeEdge === "left") return 0;
                if (activeEdge === "right") return 180;
                if (activeEdge === "bottom") return -90;
                return 0;
            }

            function showPeek(edge, pos) {
                if (isPinned || isSidebarVisible || pendingMode === "sidebar") return;

                if (activeEdge !== edge) {
                    if (isPeekVisible || edgeTransitionTimer.running) {
                        pendingEdge = edge;
                        pendingPos = pos;
                        pendingMode = "peek";
                        
                        if (!edgeTransitionTimer.running) {
                            isPeekVisible = false;
                            edgeTransitionTimer.restart();
                        }
                    } else {
                        disableAnim = true;
                        activeEdge = edge;
                        currentPos = pos;
                        pendingMode = "peek";
                        teleportTimer.restart();
                    }
                    return;
                } else {
                    if (edgeTransitionTimer.running) {
                        edgeTransitionTimer.stop();
                        pendingMode = "";
                    }
                }

                currentPos = pos;
                isPeekVisible = true;
                peekHideTimer.stop();
            }

            function showSidebar(edge, pos) {
                if (isPinned) return;

                if (activeEdge !== edge) {
                    if (isSidebarVisible || isExpanded || edgeTransitionTimer.running) {
                        pendingEdge = edge;
                        pendingPos = pos;
                        pendingMode = "sidebar";
                        
                        if (!edgeTransitionTimer.running) {
                            pendingWasExpanded = isExpanded;
                            isExpanded = false;
                            isSidebarVisible = false;
                            isPeekVisible = false;
                            edgeTransitionTimer.restart();
                        }
                    } else {
                        disableAnim = true;
                        activeEdge = edge;
                        currentPos = pos;
                        pendingMode = "sidebar";
                        pendingWasExpanded = false;
                        teleportTimer.restart(); 
                    }
                    return; 
                } else {
                    if (edgeTransitionTimer.running) {
                        edgeTransitionTimer.stop();
                        if (pendingMode === "sidebar") {
                            isExpanded = pendingWasExpanded;
                        }
                        pendingMode = "";
                    }
                }

                currentPos = pos;
                isSidebarVisible = true;
                isPeekVisible = false;
                hideTimer.restart();
            }

            Timer {
                id: peekHideTimer
                interval: 50
                onTriggered: {
                    if (typeof peekMouse !== "undefined" && peekMouse.pressed) {
                        peekHideTimer.restart();
                        return;
                    }
                    if (!peekMouse.containsMouse && 
                        !leftEdge.containsMouse && !rightEdge.containsMouse && !bottomEdge.containsMouse) {
                        floatingWidget.isPeekVisible = false;
                    }
                }
            }

            Timer {
                id: hideTimer
                interval: floatingWidget.useGraceTimer ? 3000 : 800 // 3 seconds if drag was just happening, else 800ms
                onTriggered: {
                    if (floatingWidget.isPinned) return;

                    if ((typeof sidebarDragArea !== "undefined" && sidebarDragArea.pressed) || 
                        (typeof peekMouse !== "undefined" && peekMouse.pressed) ||
                        (typeof gridMouseArea !== "undefined" && gridMouseArea.pressed)) {
                        hideTimer.restart();
                        return;
                    }

                    floatingWidget.isExpanded = false;
                    floatingWidget.isSidebarVisible = false;
                    floatingWidget.useGraceTimer = false; // Reset grace state when finally hidden
                }
            }

            Timer {
                id: peekShowTimer
                interval: 300
                property string pendingShowEdge: ""
                property real pendingShowPos: 0
                onTriggered: {
                    if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") {
                        floatingWidget.showSidebar(pendingShowEdge, pendingShowPos);
                    } else {
                        floatingWidget.showPeek(pendingShowEdge, pendingShowPos);
                    }
                }
            }

            // =========================================================
            // --- EDGE TRIGGERS
            // =========================================================
            Item {
                id: mainHitArea 
                anchors.fill: parent

                MouseArea {
                    id: leftEdge
                    x: 0; y: 0; width: 1; height: floatingWidget.height
                    hoverEnabled: true
                    onEntered: { 
                        peekHideTimer.stop(); 
                        if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") { 
                            floatingWidget.showSidebar("left", mouseY + y); 
                        } else if (floatingWidget.isPeekVisible) {
                            floatingWidget.showPeek("left", mouseY + y);
                        } else {
                            peekShowTimer.pendingShowEdge = "left";
                            peekShowTimer.pendingShowPos = mouseY + y;
                            peekShowTimer.restart();
                        }
                    }
                    onPositionChanged: mouse => { 
                        if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") { 
                            floatingWidget.showSidebar("left", mouse.y + y); 
                        } else if (floatingWidget.isPeekVisible) {
                            floatingWidget.showPeek("left", mouse.y + y);
                        } else {
                            peekShowTimer.pendingShowPos = mouse.y + y;
                        }
                    }
                    onExited: {
                        peekShowTimer.stop();
                        peekHideTimer.restart();
                    }
                }

                MouseArea {
                    id: rightEdge
                    x: floatingWidget.width - 1; y: 0; width: 1; height: floatingWidget.height
                    hoverEnabled: true
                    onEntered: { 
                        peekHideTimer.stop(); 
                        if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") { 
                            floatingWidget.showSidebar("right", mouseY + y); 
                        } else if (floatingWidget.isPeekVisible) {
                            floatingWidget.showPeek("right", mouseY + y);
                        } else {
                            peekShowTimer.pendingShowEdge = "right";
                            peekShowTimer.pendingShowPos = mouseY + y;
                            peekShowTimer.restart();
                        }
                    }
                    onPositionChanged: mouse => { 
                        if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") { 
                            floatingWidget.showSidebar("right", mouse.y + y); 
                        } else if (floatingWidget.isPeekVisible) {
                            floatingWidget.showPeek("right", mouse.y + y);
                        } else {
                            peekShowTimer.pendingShowPos = mouse.y + y;
                        }
                    }
                    onExited: {
                        peekShowTimer.stop();
                        peekHideTimer.restart();
                    }
                }

                MouseArea {
                    id: bottomEdge
                    x: 0; y: floatingWidget.height - 1; width: floatingWidget.width; height: 1
                    hoverEnabled: true
                    onEntered: { 
                        peekHideTimer.stop(); 
                        if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") { 
                            floatingWidget.showSidebar("bottom", mouseX + x); 
                        } else if (floatingWidget.isPeekVisible) {
                            floatingWidget.showPeek("bottom", mouseX + x);
                        } else {
                            peekShowTimer.pendingShowEdge = "bottom";
                            peekShowTimer.pendingShowPos = mouseX + x;
                            peekShowTimer.restart();
                        }
                    }
                    onPositionChanged: mouse => { 
                        if (floatingWidget.isSidebarVisible || floatingWidget.pendingMode === "sidebar") { 
                            floatingWidget.showSidebar("bottom", mouse.x + x); 
                        } else if (floatingWidget.isPeekVisible) {
                            floatingWidget.showPeek("bottom", mouse.x + x);
                        } else {
                            peekShowTimer.pendingShowPos = mouse.x + x;
                        }
                    }
                    onExited: {
                        peekShowTimer.stop();
                        peekHideTimer.restart();
                    }
                }
            }

            // =========================================================
            // --- FLOATING PEEK BAR (DRAG HANDLE)
            // =========================================================
            Rectangle {
                id: peekBar
                // 10px smaller on each side = 20px total subtraction
                width: floatingWidget.activeEdge === "bottom" ? Math.max(floatingWidget.s(20), floatingWidget.baseSidebarH - floatingWidget.s(20)) : floatingWidget.s(12)
                height: floatingWidget.activeEdge === "bottom" ? floatingWidget.s(12) : Math.max(floatingWidget.s(20), floatingWidget.baseSidebarH - floatingWidget.s(20))
                radius: floatingWidget.s(6)
                
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 1.0)
                border.width: 0
                
                opacity: (floatingWidget.isPeekVisible && !floatingWidget.isSidebarVisible) ? (peekMouse.containsMouse || peekMouse.pressed ? 1.0 : 0.6) : 0.0
                scale: floatingWidget.isPeekVisible ? 1.0 : 0.6
                
                Behavior on opacity { NumberAnimation { duration: 250 } }
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                property real visualDragOffset: {
                    if (!peekMouse.pressed) return 0;
                    return Math.max(-floatingWidget.s(15), Math.min(peekMouse.currentDragDelta, floatingWidget.s(15))); 
                }

                x: {
                    let offscreen = 0, visibleX = 0;
                    if (floatingWidget.activeEdge === "left") {
                        offscreen = -width - floatingWidget.s(10);
                        visibleX = floatingWidget.s(4); 
                        return (floatingWidget.isPeekVisible ? visibleX : offscreen) + visualDragOffset;
                    }
                    if (floatingWidget.activeEdge === "right") {
                        offscreen = floatingWidget.width + floatingWidget.s(10);
                        visibleX = floatingWidget.width - width - floatingWidget.s(4); 
                        return (floatingWidget.isPeekVisible ? visibleX : offscreen) - visualDragOffset;
                    }
                    if (floatingWidget.activeEdge === "bottom") return clampedCenterX - width / 2;
                    return 0;
                }

                y: {
                    let offscreen = 0, visibleY = 0;
                    if (floatingWidget.activeEdge === "bottom") {
                        offscreen = floatingWidget.height + floatingWidget.s(10);
                        visibleY = floatingWidget.height - height - floatingWidget.s(4); 
                        return (floatingWidget.isPeekVisible ? visibleY : offscreen) - visualDragOffset;
                    }
                    if (floatingWidget.activeEdge === "left" || floatingWidget.activeEdge === "right") return clampedCenterY - height / 2;
                    return 0;
                }

                Behavior on x { enabled: !floatingWidget.disableAnim && !peekMouse.pressed; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                Behavior on y { enabled: !floatingWidget.disableAnim && !peekMouse.pressed; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                Rectangle {
                    anchors.centerIn: parent
                    width: floatingWidget.activeEdge === "bottom" ? floatingWidget.s(30) : floatingWidget.s(4)
                    height: floatingWidget.activeEdge === "bottom" ? floatingWidget.s(4) : floatingWidget.s(30)
                    radius: floatingWidget.s(2)
                    color: Qt.darker(mocha.mauve, 1.8)
                }

                MouseArea {
                    id: peekMouse
                    anchors.fill: parent
                    anchors.margins: -floatingWidget.s(15) 
                    hoverEnabled: true
                    enabled: floatingWidget.isPeekVisible || pressed
                    
                    property real startGlobalX: 0
                    property real startGlobalY: 0
                    property real currentDragDelta: 0

                    onEntered: { floatingWidget.isPeekVisible = true; peekHideTimer.stop(); }
                    onExited: { if (!pressed) peekHideTimer.restart(); }
                    
                    onPressed: mouse => { 
                        let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                        startGlobalX = gp.x; 
                        startGlobalY = gp.y;
                        currentDragDelta = 0;
                        floatingWidget.useGraceTimer = true; // Give grace time after drag interaction
                    }
                    
                    onPositionChanged: mouse => {
                        if (!pressed) return;
                        
                        let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                        let delta = 0;
                        
                        if (floatingWidget.activeEdge === "left") delta = gp.x - startGlobalX;
                        else if (floatingWidget.activeEdge === "right") delta = startGlobalX - gp.x;
                        else if (floatingWidget.activeEdge === "bottom") delta = startGlobalY - gp.y;

                        currentDragDelta = delta;

                        if (delta > floatingWidget.s(15) && !floatingWidget.isExpanded) {
                            floatingWidget.showSidebar(floatingWidget.activeEdge, floatingWidget.currentPos);
                            floatingWidget.isExpanded = true;
                        } else if (delta < -floatingWidget.s(10) && floatingWidget.isPeekVisible) {
                            floatingWidget.isPeekVisible = false;
                        }
                    }
                    
                    onReleased: { 
                        currentDragDelta = 0;
                        peekHideTimer.restart(); 
                    }
                    
                    onClicked: floatingWidget.showSidebar(floatingWidget.activeEdge, floatingWidget.currentPos)
                }
            }

            // =========================================================
            // --- SIDEBAR CONTAINER
            // =========================================================
            Item {
                id: sidebarContainer
                
                width: floatingWidget.sidebarW
                height: floatingWidget.baseSidebarH

                transformOrigin: Item.Center
                rotation: floatingWidget.targetRotation
                Behavior on rotation { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                x: {
                    if (floatingWidget.isSidebarVisible) return floatingWidget.sidebarTargetX;
                    if (floatingWidget.activeEdge === "left") return -width - floatingWidget.s(20);
                    if (floatingWidget.activeEdge === "right") return floatingWidget.width + floatingWidget.s(20);
                    return floatingWidget.sidebarTargetX;
                }

                y: {
                    if (floatingWidget.isSidebarVisible) return floatingWidget.sidebarTargetY;
                    if (floatingWidget.activeEdge === "bottom") return floatingWidget.height + floatingWidget.s(10) - floatingWidget.baseSidebarH / 2 + floatingWidget.sidebarW / 2;
                    return floatingWidget.sidebarTargetY; 
                }

                Behavior on x { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                Behavior on y { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                Item {
                    id: morphOrigin
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    
                    width: floatingWidget.sidebarW + floatingWidget.currentExtraWidth
                    height: floatingWidget.baseSidebarH + floatingWidget.currentExtraLength

                    HoverHandler {
                        id: mainHoverTracker
                        onHoveredChanged: {
                            if (hovered) {
                                floatingWidget.useGraceTimer = false; // Reset grace period safely if they returned
                                hideTimer.stop();
                            } else {
                                floatingWidget.kickTimer();
                            }
                        }
                    }

                    Rectangle {
                        id: morphingBackground
                        x: -floatingWidget.s(15) 
                        y: 0
                        width: floatingWidget.s(15) + parent.width
                        height: parent.height
                        radius: floatingWidget.s(15) 
                        color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.95) 
                        border.width: 1
                        border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)

                        MouseArea {
                            id: sidebarDragArea
                            anchors.fill: parent
                            anchors.margins: floatingWidget.isExpanded ? -floatingWidget.s(60) : -floatingWidget.s(15) 
                            hoverEnabled: true
                            enabled: floatingWidget.isSidebarVisible 
                            
                            property real startGlobalX: 0
                            property real startGlobalY: 0

                            onEntered: hideTimer.stop()
                            onExited: { if (!pressed && !gridMouseArea.containsMouse) floatingWidget.kickTimer(); }
                            onPressed: mouse => { 
                                let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                startGlobalX = gp.x; 
                                startGlobalY = gp.y; 
                                floatingWidget.useGraceTimer = true; // Initiated a drag, enable 3s grace
                            }
                            onPositionChanged: mouse => {
                                if (!pressed) return;
                                let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                floatingWidget.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
                            }
                            onReleased: { if (!containsMouse) floatingWidget.kickTimer(); }
                        }
                    }

                    Item {
                        id: expandedContainer
                        x: floatingWidget.sidebarW 
                        y: 0
                        height: parent.height
                        width: floatingWidget.currentExtraWidth
                        opacity: floatingWidget.expandProgress
                        clip: true 

                        component EmptyBlock : Rectangle {
                            radius: floatingWidget.s(12) 
                            color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                            border.width: 1
                            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                            clip: true
                        }

                        // =========================================================
                        // --- ADAPTIVE INNER COUNTER-ROTATION FIX 
                        // =========================================================
                        Item {
                            anchors.fill: parent
                            anchors.topMargin: floatingWidget.s(15)
                            anchors.bottomMargin: floatingWidget.s(15)
                            anchors.leftMargin: floatingWidget.s(15)
                            anchors.rightMargin: floatingWidget.s(15)
                            visible: floatingWidget.expandProgress > 0.01

                            Item {
                                anchors.centerIn: parent
                                width: floatingWidget.activeEdge === "bottom" ? parent.height : parent.width
                                height: floatingWidget.activeEdge === "bottom" ? parent.width : parent.height
                                rotation: floatingWidget.activeEdge === "right" ? 180 : (floatingWidget.activeEdge === "bottom" ? 90 : 0)

                                property real sp: floatingWidget.s(10) 
                                property real cw: Math.max(0, width) 
                                property real ch: Math.max(0, height)
                                
                                Repeater {
                                    model: floatingWidget.currentLayoutTemplate
                                    delegate: EmptyBlock {
                                        x: (modelData.x * parent.cw) + (modelData.x > 0 ? parent.sp / 2 : 0)
                                        y: (modelData.y * parent.ch) + (modelData.y > 0 ? parent.sp / 2 : 0)
                                        width: (modelData.w * parent.cw) - ((modelData.x > 0 ? parent.sp / 2 : 0) + ((modelData.x + modelData.w) < 0.99 ? parent.sp / 2 : 0))
                                        height: (modelData.h * parent.ch) - ((modelData.y > 0 ? parent.sp / 2 : 0) + ((modelData.y + modelData.h) < 0.99 ? parent.sp / 2 : 0))
                                    }
                                }
                            }
                        }

                        Repeater {
                            id: moduleRepeater
                            model: floatingWidget.tabModules

                            delegate: Loader {
                                id: contentLoader
                                z: 10
                                anchors.fill: parent
                                anchors.topMargin: floatingWidget.s(15)
                                anchors.bottomMargin: floatingWidget.s(15)
                                anchors.leftMargin: floatingWidget.s(15)
                                anchors.rightMargin: floatingWidget.s(15)

                                visible: index === floatingWidget.activeIndex && floatingWidget.expandProgress > 0.01
                                source: modelData
                                asynchronous: false

                                property var scaleFunc: floatingWidget.s
                                property var mochaColors: mocha 
                                property string activeEdge: floatingWidget.activeEdge 

                                property bool isCurrentTarget: index === floatingWidget.activeIndex
                                property real modWidth: (status === Loader.Ready && item && item.preferredWidth !== undefined) ? item.preferredWidth : floatingWidget.baseExpandedWidth
                                property real modExt: (status === Loader.Ready && item && item.preferredExtraLength !== undefined) ? item.preferredExtraLength : floatingWidget.baseExpandedExtraLength
                                
                                property var modLayout: {
                                    if (status === Loader.Ready && item && item.requestedLayoutTemplate !== undefined) {
                                        let req = item.requestedLayoutTemplate;
                                        if (typeof req === "number") {
                                            if (req === 0) return [ {x:0, y:0, w:0.5, h:0.5}, {x:0.5, y:0, w:0.5, h:0.5}, {x:0, y:0.5, w:0.5, h:0.5}, {x:0.5, y:0.5, w:0.5, h:0.5} ];
                                            else return [ {x:0, y:0, w:1, h:1} ]; 
                                        }
                                        return req; 
                                    }
                                    return [ {x:0, y:0, w:1, h:1} ];
                                }

                                function updateSizes() {
                                    if (isCurrentTarget) {
                                        floatingWidget.targetExpandedExtraLength = modExt;
                                        floatingWidget.expandedWidth = modWidth;
                                        floatingWidget.expandedExtraLength = modExt;
                                        floatingWidget.currentLayoutTemplate = modLayout;
                                    }
                                }

                                onLoaded: updateSizes()
                                onIsCurrentTargetChanged: updateSizes()
                                onModWidthChanged: updateSizes()
                                onModExtChanged: updateSizes()
                                onModLayoutChanged: updateSizes()
                                Component.onCompleted: updateSizes()
                            }
                        }

                        MouseArea {
                            id: gridMouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton 
                            hoverEnabled: true
                            
                            onEntered: hideTimer.stop()
                            onExited: { if (!sidebarDragArea.containsMouse) floatingWidget.kickTimer(); }
                            onWheel: wheel => {
                                let step = 0;
                                if (wheel.angleDelta.y > 0) step = floatingWidget.activeEdge === "right" ? 1 : -1;
                                else if (wheel.angleDelta.y < 0) step = floatingWidget.activeEdge === "right" ? -1 : 1;
                                
                                if (step !== 0) {
                                    floatingWidget.activeIndex = Math.max(0, Math.min(floatingWidget.tabCount - 1, floatingWidget.activeIndex + step));
                                }
                            }
                        }
                    }

                    // =========================================================
                    // --- STATIC INNER LAYOUT WRAPPER (TABS)
                    // =========================================================
                    Item {
                        id: staticContentWrapper
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter 
                        width: floatingWidget.sidebarW
                        height: floatingWidget.baseSidebarH

                        Item {
                            anchors.fill: parent
                            anchors.margins: floatingWidget.s(8)

                            // ---------------------------------------------------------
                            // CONTROL AREA (expand + pin buttons)
                            // ---------------------------------------------------------
                            Item {
                                id: controlArea
                                width: parent.width
                                height: floatingWidget.controlAreaHeight
                                x: 0
                                y: floatingWidget.activeEdge === "left"
                                    ? 0
                                    : floatingWidget.getTargetY(floatingWidget.tabCount, floatingWidget.activeIndex)

                                Behavior on y {
                                    enabled: !floatingWidget.disableAnim
                                    NumberAnimation { duration: 350; easing.type: Easing.OutExpo }
                                }

                                // EXPAND BUTTON
                                Item {
                                    id: expandButton
                                    width: floatingWidget.buttonSize
                                    height: floatingWidget.buttonSize
                                    x: (parent.width - width) / 2
                                    y: floatingWidget.activeEdge === "left"
                                        ? floatingWidget.s(6)
                                        : parent.height - height - floatingWidget.s(6)

                                    rotation: floatingWidget.isExpanded ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                                    Item {
                                        anchors.fill: parent
                                        
                                        property color iconColor: floatingWidget.isExpanded ? mocha.mauve : 
                                                                  (expandMouse.pressed ? Qt.darker(mocha.mauve, 1.2) : 
                                                                  (expandMouse.containsMouse ? mocha.mauve : 
                                                                  Qt.tint(mocha.base, Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.3))))
                                                                  
                                        property real pivotX: parent.width / 2 - floatingWidget.s(4)

                                        Rectangle {
                                            width: floatingWidget.s(5)
                                            height: floatingWidget.s(5)
                                            radius: width / 2
                                            color: parent.iconColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: parent.pivotX - (width / 2)
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }

                                        Rectangle {
                                            x: parent.pivotX
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: floatingWidget.s(13)
                                            height: floatingWidget.s(4.5)
                                            radius: height / 2
                                            transformOrigin: Item.Left
                                            rotation: 42
                                            color: parent.iconColor
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }

                                        Rectangle {
                                            x: parent.pivotX
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: floatingWidget.s(13)
                                            height: floatingWidget.s(4.5)
                                            radius: height / 2
                                            transformOrigin: Item.Left
                                            rotation: -42
                                            color: parent.iconColor
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                    }

                                    MouseArea {
                                        id: expandMouse
                                        anchors.fill: parent
                                        hoverEnabled: true

                                        property real startGlobalX: 0
                                        property real startGlobalY: 0
                                        property bool isDragging: false

                                        onEntered: hideTimer.stop()
                                        onExited: floatingWidget.kickTimer()

                                        onPressed: mouse => {
                                            let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                            startGlobalX = gp.x;
                                            startGlobalY = gp.y;
                                            isDragging = false;
                                        }
                                        onPositionChanged: mouse => {
                                            if (!pressed) return;
                                            let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                            let deltaX = Math.abs(gp.x - startGlobalX);
                                            let deltaY = Math.abs(gp.y - startGlobalY);
                                            if (deltaX > 5 || deltaY > 5) isDragging = true;
                                            floatingWidget.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
                                        }
                                        onClicked: {
                                            if (!isDragging) {
                                                floatingWidget.isExpanded = !floatingWidget.isExpanded;
                                                floatingWidget.kickTimer();
                                            }
                                        }
                                    }
                                }

                                // PIN BUTTON
                                Rectangle {
                                    id: pinButton
                                    width: floatingWidget.buttonSize
                                    height: floatingWidget.buttonSize
                                    radius: width / 2
                                    x: (parent.width - width) / 2
                                    y: floatingWidget.activeEdge === "left"
                                        ? expandButton.y + expandButton.height + floatingWidget.s(8)
                                        : expandButton.y - height - floatingWidget.s(8)

                                    color: floatingWidget.isPinned
                                        ? mocha.mauve
                                        : (pinMouse.pressed
                                            ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)
                                            : (pinMouse.containsMouse
                                                ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.25)
                                                : "transparent"))
                                    border.width: floatingWidget.s(2)
                                    border.color: floatingWidget.isPinned
                                        ? mocha.mauve
                                        : Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.2)
                                    
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on border.color { ColorAnimation { duration: 200 } }

                                    MouseArea {
                                        id: pinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        property real startGlobalX: 0
                                        property real startGlobalY: 0
                                        property bool isDragging: false

                                        onEntered: hideTimer.stop()
                                        onExited: floatingWidget.kickTimer()
                                        
                                        onPressed: mouse => { 
                                            let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                            startGlobalX = gp.x; 
                                            startGlobalY = gp.y; 
                                            isDragging = false;
                                        }
                                        onPositionChanged: mouse => {
                                            if (!pressed) return;
                                            let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                            let deltaX = Math.abs(gp.x - startGlobalX);
                                            let deltaY = Math.abs(gp.y - startGlobalY);
                                            if (deltaX > 5 || deltaY > 5) isDragging = true;
                                            floatingWidget.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
                                        }
                                        onClicked: {
                                            if (!isDragging) {
                                                floatingWidget.isPinned = !floatingWidget.isPinned;
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: activeHighlight
                                x: 0
                                width: parent.width
                                z: 0
                                radius: floatingWidget.s(7) 
                                color: mocha.mauve

                                property int prevIdx: 0
                                property int curIdx: floatingWidget.activeIndex

                                onCurIdxChanged: {
                                    if (curIdx > prevIdx) { bottomAnim.duration = 200; topAnim.duration = 350; } 
                                    else if (curIdx < prevIdx) { topAnim.duration = 200; bottomAnim.duration = 350; }
                                    prevIdx = curIdx;
                                }

                                property real targetTop: floatingWidget.barOffsetY + floatingWidget.getTargetY(curIdx, curIdx)
                                property real targetBottom: targetTop + floatingWidget.h_ac

                                property real actualTop: targetTop
                                property real actualBottom: targetBottom

                                Behavior on actualTop { NumberAnimation { id: topAnim; duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on actualBottom { NumberAnimation { id: bottomAnim; duration: 250; easing.type: Easing.OutExpo } }

                                y: actualTop
                                height: actualBottom - actualTop
                            }

                            Repeater {
                                model: floatingWidget.tabCount
                                delegate: Rectangle {
                                    id: barPill
                                    property bool isActive: floatingWidget.activeIndex === index
                                    property bool isHovered: barMouse.containsMouse
                                    property bool isPressed: barMouse.pressed
                                    
                                    x: 0
                                    width: parent.width
                                    radius: floatingWidget.s(7) 
                                    z: 1 

                                    y: floatingWidget.barOffsetY + floatingWidget.getTargetY(index, floatingWidget.activeIndex)
                                    Behavior on y { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                                    height: isActive ? floatingWidget.h_ac : floatingWidget.h_in
                                    Behavior on height { enabled: !floatingWidget.disableAnim; NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                                    color: isActive ? "transparent" : (isPressed ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4) : (isHovered ? Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.25) : Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)))
                                    Behavior on color { ColorAnimation { duration: 250 } }

                                    scale: isActive ? 1.0 : (isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
                                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                    MouseArea {
                                        id: barMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        property real startGlobalX: 0
                                        property real startGlobalY: 0
                                        property bool isDragging: false
                                        
                                        onEntered: { floatingWidget.hoveredBars++; hideTimer.stop(); }
                                        onExited: { floatingWidget.hoveredBars = Math.max(0, floatingWidget.hoveredBars - 1); floatingWidget.kickTimer(); }
                                        
                                        onPressed: mouse => { 
                                            let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                            startGlobalX = gp.x; 
                                            startGlobalY = gp.y; 
                                            isDragging = false;
                                        }
                                        onPositionChanged: mouse => {
                                            if (!pressed) return;
                                            let gp = mapToItem(mainHitArea, mouse.x, mouse.y);
                                            let deltaX = Math.abs(gp.x - startGlobalX);
                                            let deltaY = Math.abs(gp.y - startGlobalY);
                                            if (deltaX > 5 || deltaY > 5) isDragging = true;
                                            floatingWidget.evaluateDrag(startGlobalX, startGlobalY, gp.x, gp.y);
                                        }
                                        onClicked: {
                                            if (!isDragging) {
                                                if (!barPill.isActive) floatingWidget.activeIndex = index; 
                                                else floatingWidget.isExpanded = !floatingWidget.isExpanded;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
