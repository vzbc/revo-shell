import QtQuick
import QtQuick.VectorImage
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import qs
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: ShellController.launcherOpen
    WlrLayershell.namespace: "macos:launchpad"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellController.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int panelW: Math.round(screen.width * 0.479)
    readonly property int panelH: Math.round(screen.height * 0.572)
    readonly property int pad: 22
    readonly property int gridCols: 7
    readonly property int cellW: Math.floor((panelW - 2 * pad) / gridCols)
    readonly property int iconSize: Math.round(cellW * 0.5)
    readonly property int labelSize: Math.max(13, Math.round(cellW * 0.125))
    readonly property int titleSize: Math.round(panelW * 0.026)
    readonly property int tabSize: Math.round(panelW * 0.0145)
    readonly property int glyphSize: Math.round(panelW * 0.025)

    property string selectedTab: "All"
    property var tabs: []
    property var sections: []
    property bool menuOpen: false

    readonly property var mainCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]

    function friendly(cat) {
        switch (cat) {
        case "Office": return "Productivity & Finance";
        case "Utility": return "Utilities";
        case "Development": return "Tools";
        case "Graphics": case "AudioVideo": return "Creativity";
        case "Game": return "Games";
        case "Network": return "Internet";
        case "Science": return "Science";
        case "Education": return "Education";
        case "Settings": return "Settings";
        case "System": return "System";
        case "Other": return "Other";
        default: return cat;
        }
    }

    function rebuild() {
        var apps = [];
        var counts = {};
        var values = DesktopEntries.applications.values;
        for (var i = 0; i < values.length; i++) {
            var e = values[i];
            if (!e.name) continue;
            var cats = [];
            try { cats = [...e.categories]; } catch (err) { cats = []; }
            var main = "Other";
            for (var c = 0; c < cats.length; c++) {
                if (root.mainCategories.indexOf(cats[c]) !== -1) { main = cats[c]; break; }
            }
            if (main === "Other" && cats.length > 0) main = cats[0];
            apps.push({ name: e.name, icon: e.icon, entry: e, cats: cats, main: main });
            if (!counts[main]) counts[main] = 0;
            counts[main] = counts[main] + 1;
        }

        var catsSorted = Object.keys(counts).sort((a, b) => counts[b] - counts[a]).filter(k => counts[k] >= 4);
        var t = ["All"];
        for (var k = 0; k < Math.min(catsSorted.length, 4); k++) t.push(catsSorted[k]);
        if (t.indexOf(root.selectedTab) === -1) root.selectedTab = "All";
        root.tabs = t;
        root._apps = apps;
        root._counts = counts;
        rebuildSections();
    }

    property var _apps: []
    property var _counts: ({})

    function rebuildSections() {
        var result = [];

        if (root.selectedTab !== "All") {
            var list = [];
            for (var i = 0; i < root._apps.length; i++) {
                var a = root._apps[i];
                if (a.cats.indexOf(root.selectedTab) === -1) continue;
                list.push(a);
            }
            list.sort((x, y) => x.name.localeCompare(y.name));
            if (list.length > 0) result.push({ title: root.friendly(root.selectedTab), apps: list });
        } else {
            var groups = {};
            for (var j = 0; j < root._apps.length; j++) {
                var b = root._apps[j];
                var key = b.main || "Other";
                if (!groups[key]) groups[key] = [];
                groups[key].push(b);
            }
            var keys = Object.keys(groups).sort((x, y) => (root._counts[y] || 0) - (root._counts[x] || 0));
            for (var m = 0; m < keys.length; m++) {
                var arr = groups[keys[m]];
                arr.sort((x, y) => x.name.localeCompare(y.name));
                result.push({ title: root.friendly(keys[m]), apps: arr });
            }
        }
        root.sections = result;
    }

    Component.onCompleted: {
        Ipc.mixin("eqdesktop.launchpad", "toggle", () => ShellController.toggle("launcher"));
        rebuild();
    }

    Connections {
        target: ShellController
        function onLauncherOpenChanged() {
            if (ShellController.launcherOpen) {
                root.selectedTab = "All";
                root.menuOpen = false;
                root.rebuild();
                Qt.callLater(() => { if (panelItem) panelItem.forceActiveFocus(); });
            } else {
                root.menuOpen = false;
            }
        }
    }

    function launchApp(app) {
        ShellController.toggle("launcher");
        try { app.entry.execute(); } catch (err) { console.log("[launchpad] execute failed:", err); }
    }

        Rectangle {
            id: panelItem
            anchors.fill: parent
            color: "transparent"
            focus: true
        Keys.onEscapePressed: {
            if (root.menuOpen) { root.menuOpen = false; event.accepted = true; }
            else ShellController.toggle("launcher");
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.menuOpen) root.menuOpen = false;
                else ShellController.toggle("launcher");
            }
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: root.panelW
            height: root.panelH
            radius: 36
            color: Qt.rgba(0.10, 0.10, 0.11, 0.55)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                    GradientStop { position: 0.28; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.pad
                spacing: 14

                // ---- header ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    VectorImage {
                        id: headerGlyph
                        Layout.preferredWidth: root.glyphSize
                        Layout.preferredHeight: root.glyphSize
                        source: Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/spotlight/applications.svg")
                        preferredRendererType: VectorImage.CurveRenderer
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: "#8e8e93"
                        }
                    }

                    Text {
                        text: "Applications"
                        font { family: Appearance.fontFamily; pixelSize: root.titleSize; weight: Font.Bold }
                        color: Qt.rgba(1, 1, 1, 0.95)
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: menuBtn
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 10
                        color: menuMa.containsMouse || root.menuOpen ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u22EF"
                            font { family: Appearance.fontFamily; pixelSize: 20; weight: Font.Bold }
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }
                        MouseArea {
                            id: menuMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.menuOpen = !root.menuOpen
                        }
                    }
                }

                // ---- category tabs ----
                Rectangle {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.09)

                    Row {
                        id: tabBarRow
                        anchors.fill: parent
                        anchors.margins: 4

                        Repeater {
                            model: root.tabs

                            delegate: Item {
                                required property string modelData
                                required property int index
                                readonly property bool active: root.selectedTab === modelData
                                width: tabBarRow.width / root.tabs.length
                                height: tabBarRow.height

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 9
                                    color: active ? Qt.rgba(1, 1, 1, 0.95)
                                         : tabMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    text: modelData === "All" ? "All" : root.friendly(modelData)
                                    font { family: Appearance.fontFamily; pixelSize: root.tabSize; weight: active ? Font.DemiBold : Font.Medium }
                                    color: active ? Qt.rgba(0.08, 0.08, 0.09, 0.9) : Qt.rgba(1, 1, 1, 0.6)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: tabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedTab = modelData;
                                        root.rebuildSections();
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- app grid ----
                ScrollView {
                    id: gridScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Column {
                        width: gridScroll.availableWidth

                        Repeater {
                            model: root.sections

                            delegate: Column {
                                property var sec: modelData
                                width: parent ? parent.width : 0
                                topPadding: 14
                                bottomPadding: 6
                                spacing: 4

                                Text {
                                    text: sec.title
                                    font { family: Appearance.fontFamily; pixelSize: root.labelSize; weight: Font.DemiBold }
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    leftPadding: 6
                                    bottomPadding: 4
                                    visible: sec.apps.length > 0
                                }

                                Flow {
                                    width: parent.width
                                    spacing: 0

                                    Repeater {
                                        model: sec.apps

                                        delegate: Item {
                                            required property var modelData
                                            width: root.cellW
                                            height: root.iconSize + root.labelSize + 24

                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                radius: 18
                                                color: appMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 8

                                                IconImage {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: root.iconSize
                                                    height: root.iconSize
                                                    source: modelData.icon
                                                        ? Quickshell.iconPath(modelData.icon, "application-x-executable")
                                                        : Quickshell.iconPath("application-x-executable")
                                                    smooth: true
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: root.cellW - 14
                                                    text: modelData.name
                                                    font { family: Appearance.fontFamily; pixelSize: root.labelSize; weight: Font.Medium }
                                                    color: Qt.rgba(1, 1, 1, 0.88)
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: appMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.launchApp(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- options menu ----
            Rectangle {
                id: menu
                visible: root.menuOpen
                z: 5
                x: root.panelW - root.pad - width
                y: root.pad + 46
                width: 176
                height: menuCol.implicitHeight + 12
                radius: 12
                color: Qt.rgba(0.12, 0.12, 0.14, 0.97)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                Column {
                    id: menuCol
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Repeater {
                        model: ["Show All", "Reload Apps", "Close"]

                        delegate: Rectangle {
                            required property string modelData
                            width: menuCol.width
                            height: 32
                            radius: 8
                            color: itemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: modelData
                                font { family: Appearance.fontFamily; pixelSize: 13; weight: Font.Medium }
                                color: Qt.rgba(1, 1, 1, 0.85)
                            }

                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.menuOpen = false;
                                    if (modelData === "Show All") {
                                        root.selectedTab = "All";
                                        root.rebuildSections();
                                    } else if (modelData === "Reload Apps") {
                                        root.rebuild();
                                    } else {
                                        ShellController.toggle("launcher");
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
