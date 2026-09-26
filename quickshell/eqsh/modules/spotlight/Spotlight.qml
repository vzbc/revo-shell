import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs
import qs.config
import qs.ui.controls.advanced
import qs.ui.controls.auxiliary
import qs.ui.controls.providers
import qs.ui.controls.primitives
import qs.ui.controls.windows
import qs.ui.controls.windows.dropdown

import "Rail.js" as Rail

Scope {
    id: root

    property bool actionsShown: false
    property string selectedAction: ""
    property string hoveredAction: ""
    property string glassColor: Config.general.darkMode ? "#a01e1e1e" : "#a0ffffff"
    property string textColor: Config.general.darkMode ? "#dfdfdf" : "#1e1e1e"

    // Mode rail (circles emerge from the pill, pill contracts behind them)
    // Geometry follows the reference: the pill contracts by exactly the space
    // the four circles take, so the whole rail keeps a constant footprint.
    property real railProgress: 0.0
    readonly property real collapsedWidth: 600
    readonly property real circleD: 58
    readonly property real circleGap: 10
    readonly property real expandedWidth: root.collapsedWidth - 4 * (root.circleD + root.circleGap)
    readonly property real searchRowHeight: 66
    readonly property real panelTop: 200

    function animateRail(target: real) {
        _railAnim.stop();
        _railAnim.from = root.railProgress;
        _railAnim.to = target;
        _railAnim.duration = Math.max(100, Math.round(620 * Math.abs(target - root.railProgress)));
        _railAnim.start();
    }

    onActionsShownChanged: root.animateRail(root.actionsShown ? 1.0 : 0.0)

    NumberAnimation {
        id: _railAnim
        target: root
        property: "railProgress"
        duration: 620
        easing.type: Easing.Linear
    }

    function clickAction(action: string) {
        root.hoveredAction = ""
        root.selectedAction = action
        root.actionsShown = false
    }

    Component.onCompleted: {
        Ipc.mixin("eqdesktop.spotlight", "toggle", () => {
            Runtime.spotlightOpen = !Runtime.spotlightOpen;
        });
        Ipc.mixin("eqdesktop.spotlight", "set", (visible) => {
            Runtime.spotlightOpen = visible;
        });
        Ipc.mixin("eqdesktop.spotlight", "state", () => `actions=${root.actionsShown} rail=${root.railProgress.toFixed(3)} sel=${root.selectedAction} open=${Runtime.spotlightOpen} panel=${panel.width.toFixed(0)}`);
    }

    FollowingPanelWindow {
        id: launcher
        color: "transparent"
        WlrLayershell.namespace: "eqsh:spotlight"
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.keyboardFocus: launcher.isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        focusable: true

        mask: Region {
            item: Runtime.spotlightOpen ? spotlight : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        property bool isVisible: Runtime.spotlightOpen

        onIsVisibleChanged: {
            if (isVisible) {
                root.actionsShown = false;
                root.hoveredAction = "";
                root.selectedAction = "";
                search.focus = true
                hideAnim.stop()
                showAnim.start()
            } else {
                search.text = ""
                root.actionsShown = false
                root.hoveredAction = ""
                showAnim.stop()
                hideAnim.start()
            }
        }

        SequentialAnimation {
            id: showAnim
            ParallelAnimation {
                PropertyAnimation {
                    target: panel
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1
                }
                PropertyAnimation {
                    target: panel
                    property: "scaleX"
                    from: 1.3
                    to: 1
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1
                }
            }
        }

        SequentialAnimation {
            id: hideAnim
            ParallelAnimation {
                PropertyAnimation {
                    target: panel
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                }
                PropertyAnimation {
                    target: panel
                    property: "scaleX"
                    from: 1
                    to: 1.1
                    duration: 130
                }
            }
        }
        Item {
            id: spotlight
            anchors.fill: parent
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Runtime.spotlightOpen = false;
                }
            }
            Item {
                id: panel
                z: 99
                anchors.top: parent.top
                anchors.topMargin: root.panelTop
                anchors.left: parent.left
                anchors.leftMargin: parent.width / 2 - root.collapsedWidth / 2
                visible: true
                opacity: 0
                width: root.collapsedWidth + (root.expandedWidth - root.collapsedWidth) * Rail.pill(root.railProgress)
                height: searchRow.height + (results.height > 0 ? results.height + 8 : 0)
                property real scaleX: 1
                transform: Scale {
                    xScale: panel.scaleX
                    origin.x: panel.width / 2
                }

                // Pill + necks + lobes drawn as one signed-distance field
                SpotlightModeMorphSurface {
                    id: morphSurface
                    z: -1
                    x: 0
                    y: 0
                    width: root.collapsedWidth
                    height: root.searchRowHeight
                    railProgress: root.railProgress
                    mainLeft: 0
                    collapsedMainWidth: root.collapsedWidth
                    expandedMainWidth: root.expandedWidth
                    shapeCenterY: root.searchRowHeight / 2
                    shapeHeight: root.searchRowHeight
                    buttonDiameter: root.circleD
                    buttonGap: root.circleGap
                    blurEdgeInset: 2
                    surfaceColor: root.glassColor
                    shadowColor: Qt.rgba(0, 0, 0, 0.45)
                }

                Item {
                    id: searchRow
                    width: parent.width
                    height: root.searchRowHeight

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            if (root.selectedAction != "") return;
                            root.actionsShown = true
                        }
                        onPositionChanged: (mouse) => {
                            if (root.selectedAction != "") return;
                            root.actionsShown = true
                            root.hoveredAction = ""
                        }
                    }

                    // Interactive drag & swipe handle zone (reference behaviour)
                    MouseArea {
                        id: dragZone
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 60
                        z: 2
                        hoverEnabled: true
                        cursorShape: Qt.SplitHCursor

                        property real startMouseX: 0
                        property real startProgress: 0
                        property bool isDragging: false

                        onEntered: {
                            if (root.selectedAction != "") return;
                            root.actionsShown = true
                        }
                        onExited: {
                            if (isDragging || root.selectedAction != "" || search.activeFocus) return;
                            root.actionsShown = false
                        }
                        onPressed: (mouse) => {
                            startMouseX = mouse.x
                            startProgress = root.railProgress
                            isDragging = true
                            _railAnim.stop()
                        }
                        onPositionChanged: (mouse) => {
                            if (!isDragging) return;
                            var delta = mouse.x - startMouseX
                            var maxDist = root.circleD * 4 + root.circleGap * 4
                            root.railProgress = Math.max(0, Math.min(1, startProgress + delta / maxDist))
                        }
                        onReleased: {
                            if (!isDragging) return;
                            isDragging = false
                            if (root.railProgress > 0.25) {
                                root.actionsShown = true
                                root.animateRail(1.0)
                            } else {
                                root.actionsShown = false
                                root.animateRail(0.0)
                            }
                        }
                    }

                    TextField {
                        id: search
                        x: 4
                        y: (root.searchRowHeight - 50) / 2
                        width: parent.width - 8
                        height: 50
                        clip: true
                            leftPadding: 44
                            font.pixelSize: 30
                            color: root.textColor
                            CFVI {
                                id: sicon
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                size: {
                                    if (root.selectedAction == "applications") {
                                        30
                                    } else if (root.selectedAction == "files") {
                                        25
                                    } else if (root.selectedAction == "actions") {
                                        30
                                    } else if (root.selectedAction == "clipboard") {
                                        30
                                    } else {
                                        25
                                    }
                                }
                                opacity: 0.5
                                color: root.textColor
                                icon: {
                                    if (["", "search"].includes(root.selectedAction)) {
                                        "search.svg"
                                    } else if (root.selectedAction == "applications") {
                                        "spotlight/applications.svg"
                                    } else if (root.selectedAction == "files") {
                                        "spotlight/files.svg"
                                    } else if (root.selectedAction == "actions") {
                                        "spotlight/actions.svg"
                                    } else if (root.selectedAction == "clipboard") {
                                        "spotlight/clipboard.svg"
                                    }
                                }
                            }
                            background: Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                anchors.leftMargin: 44
                                font.pixelSize: 26
                                font.weight: 500
                                color: root.textColor
                                opacity: 0.7
                                visible: search.text == ""
                                text: {
                                    if (root.hoveredAction == "" && root.selectedAction == "") {
                                        return Translation.tr("Spotlight Search")
                                    } else {
                                        switch (root.hoveredAction == "" ? root.selectedAction : root.hoveredAction) { // This has to be hardcoded, because of the Translation manager
                                            case "applications": return Translation.tr("Applications")
                                            case "files": return Translation.tr("Files")
                                            case "actions": return Translation.tr("Actions")
                                            case "clipboard": return Translation.tr("Clipboard")
                                            default: return Translation.tr("Spotlight Search")
                                        }
                                    }
                                }
                                Key {
                                    anchors {
                                        right: parent.right
                                        rightMargin: 50
                                        verticalCenter: parent.verticalCenter
                                    }
                                    key: "⌃"
                                    keyColor: root.textColor
                                    visible: root.hoveredAction != ""
                                }
                                Key {
                                    anchors {
                                        right: parent.right
                                        rightMargin: 20
                                        verticalCenter: parent.verticalCenter
                                    }
                                    keyColor: root.textColor
                                    key: {
                                        switch (root.hoveredAction) {
                                            case "applications": return "1"
                                            case "files": return "2"
                                            case "actions": return "3"
                                            case "clipboard": return "4"
                                            default: return ""
                                        }
                                    }
                                    visible: root.hoveredAction != ""
                                }
                            }
                            focus: true
                            hoverEnabled: true
                            onHoveredChanged: {
                                if (!hovered || root.selectedAction != "") return;
                                root.actionsShown = true
                                root.hoveredAction = ""
                            }
                            Keys.onPressed: (event) => {
                                results.keyPressed(event)
                                if (event.key === Qt.Key_Escape) Ipc.runMixin("eqdesktop.spotlight", "toggle")
                                // toggle the mode rail (reference: Tab)
                                if (event.key === Qt.Key_Tab && root.selectedAction == "") {
                                    root.actionsShown = !root.actionsShown
                                    event.accepted = true
                                }
                                // action keys
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_0) root.clickAction("search")
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_1) root.clickAction("applications")
                                else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_2) root.clickAction("files")
                                else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_3) root.clickAction("actions")
                                else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_4) root.clickAction("clipboard")
                            }
                            onTextEdited: {
                                if (text == "") {
                                    root.clickAction("");
                                    return;
                                }
                                if (root.selectedAction != "") return;
                                root.clickAction("search");
                            }

                            Rectangle {
                                anchors {
                                    right: parent.right
                                    rightMargin: 12
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 18; height: 18
                                radius: 12
                                color: root.textColor
                                visible: root.selectedAction == "clipboard"
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: (mouse) => {
                                        rightClickMenuClipboard.x = mouse.x + panel.x + 500
                                        rightClickMenuClipboard.y = mouse.y + panel.y + 20
                                        rightClickMenuClipboard.open()
                                    }
                                }
                            }
                    }
                }

                BoxGlass {
                    id: body
                    x: 0
                    y: searchRow.height
                    width: root.collapsedWidth
                    height: results.height > 0 ? results.height + 8 : 0
                    visible: height > 0
                    radius: 30
                    color: root.glassColor
                    rimStrength: 1.7
                    light: "#20ffffff"
                    lightDir: Qt.point(1, 1)
                    layer.enabled: true

                    ContentView {
                        id: results
                        x: 4
                        y: 4
                        width: root.collapsedWidth - 8
                        text: search.text
                        selectedAction: root.selectedAction
                        textColor: root.textColor
                        shown: root.selectedAction != ""
                        onActionClicked: {
                            Ipc.runMixin("eqdesktop.spotlight", "toggle")
                        }
                    }
                }
            }
            DropDownMenu {
                id: rightClickMenuClipboard
                model: [
                    DropDownItem {
                        name: Translation.tr("Clear History")
                        action: function() {ClipboardService.clear()}
                    }
                ]
            }
            ActionButton {
                id: applications
                z: 100

                collapsedWidth: root.collapsedWidth
                topOffset: root.panelTop + (root.searchRowHeight - root.circleD) / 2
                actionsShown: root.actionsShown
                railProgress: root.railProgress
                launcherVisible: launcher.isVisible
                textColor: root.textColor
                glassColor: root.glassColor

                onHoveredAction: (action) => {root.hoveredAction = action}
                onSelectedAction: (action) => {root.clickAction(action)}

                position: 0
                action: "applications"
            }
            
            ActionButton {
                id: files
                z: 100

                collapsedWidth: root.collapsedWidth
                topOffset: root.panelTop + (root.searchRowHeight - root.circleD) / 2
                actionsShown: root.actionsShown
                railProgress: root.railProgress
                launcherVisible: launcher.isVisible
                textColor: root.textColor
                glassColor: root.glassColor

                onHoveredAction: (action) => {root.hoveredAction = action}
                onSelectedAction: (action) => {root.clickAction(action)}

                position: 1
                action: "files"
            }
            
            ActionButton {
                id: actions
                z: 100

                collapsedWidth: root.collapsedWidth
                topOffset: root.panelTop + (root.searchRowHeight - root.circleD) / 2
                actionsShown: root.actionsShown
                railProgress: root.railProgress
                launcherVisible: launcher.isVisible
                textColor: root.textColor
                glassColor: root.glassColor

                onHoveredAction: (action) => {root.hoveredAction = action}
                onSelectedAction: (action) => {root.clickAction(action)}

                position: 2
                action: "actions"
            }
            
            ActionButton {
                id: clipboard
                z: 100

                collapsedWidth: root.collapsedWidth
                topOffset: root.panelTop + (root.searchRowHeight - root.circleD) / 2
                actionsShown: root.actionsShown
                railProgress: root.railProgress
                launcherVisible: launcher.isVisible
                textColor: root.textColor
                glassColor: root.glassColor

                onHoveredAction: (action) => {root.hoveredAction = action}
                onSelectedAction: (action) => {root.clickAction(action)}

                position: 3
                iconSize: 38
                action: "clipboard"
            }
        }
    }
}