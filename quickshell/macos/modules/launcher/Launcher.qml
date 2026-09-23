import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: ShellController.launcherOpen
    WlrLayershell.namespace: "macos:launcher"
    WlrLayershell.layer: WlrLayer.Overlay

    property string searchText: ""
    property bool showAllApps: true
    property string selectedCategory: "All"
    property var filteredApps: []
    property var allApps: []
    property var categories: []

    readonly property int iconSize: 64
    readonly property int cellSize: 110
    readonly property int columns: 5
    readonly property real innerPadding: 15
    readonly property int searchHeight: 40
    readonly property int categoryHeight: 32

    // TahoeLauncher exact colors - deep dark blue/purple glass
    readonly property color fgColor: "#ffffff"
    readonly property color bgColor: Qt.rgba(0.04, 0.04, 0.12, 0.88)
    readonly property color dimmedFg: Qt.rgba(1, 1, 1, 0.7)
    readonly property color contrastBg: Qt.rgba(1, 1, 1, 0.12)
    readonly property color pillSelectedBg: Qt.rgba(255, 255, 255, 0.5)
    readonly property color pillUnselectedBg: Qt.rgba(255, 255, 255, 0.15)

    Component.onCompleted: _appScanner.running = true

    Process {
        id: _appScanner
        running: false
        command: ["bash", "-c", "find /usr/share/applications /usr/local/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | head -300"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (!path) continue;
                    _desktopParser.file = path;
                    _desktopParser.running = true;
                }
            }
        }
    }

    property var _pendingApps: []

    Process {
        id: _desktopParser
        running: false
        property string file: ""
        command: ["bash", "-c", "grep -E '^(Name|Exec|Icon|Categories|NoDisplay)=' " + file + " 2>/dev/null | head -10"]
        stdout: StdioCollector {
            onStreamFinished: {
                var name = "", exec = "", icon = "", cats = "", noDisplay = "";
                var lines = text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i];
                    if (l.startsWith("Name=")) name = l.substring(5);
                    else if (l.startsWith("Exec=")) exec = l.substring(5).split("%")[0].trim();
                    else if (l.startsWith("Icon=")) icon = l.substring(5);
                    else if (l.startsWith("Categories=")) cats = l.substring(11);
                    else if (l.startsWith("NoDisplay=true")) noDisplay = "true";
                }
                if (name && exec && noDisplay !== "true") {
                    root._pendingApps.push({ name: name, exec: exec, icon: icon, categories: cats });
                }
            }
        }
        onRunningChanged: {
            if (!running && root._pendingApps.length > 0) {
                root.allApps = root._pendingApps.slice();
                root._pendingApps = [];
                root.buildCategories();
                root.updateFiltered();
            }
        }
    }

    function buildCategories() {
        var cats = {};
        for (var i = 0; i < allApps.length; i++) {
            var c = allApps[i].categories.split(";");
            for (var j = 0; j < c.length; j++) {
                var cat = c[j].trim();
                if (cat && !cats[cat]) cats[cat] = true;
            }
        }
        var result = Object.keys(cats).sort();
        result.unshift("All Applications");
        categories = result;
        selectedCategory = "All Applications";
    }

    function updateFiltered() {
        var result = [];
        var catKey = selectedCategory === "All Applications" ? "" : selectedCategory.toLowerCase();
        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            var matchSearch = !searchText || app.name.toLowerCase().includes(searchText.toLowerCase());
            var matchCat = !catKey || app.categories.toLowerCase().includes(catKey);
            if (matchSearch && matchCat) result.push(app);
        }
        result.sort(function(a, b) { return a.name.localeCompare(b.name); });
        filteredApps = result;
    }

    Connections {
        target: ShellController
        function onLauncherOpenChanged() {
            if (ShellController.launcherOpen) {
                searchText = "";
                selectedCategory = "All Applications";
                showAllApps = true;
                _pendingApps = [];
                _appScanner.running = true;
                Qt.callLater(function() { searchField.forceActiveFocus(); });
            }
        }
    }

    function launchApp(exec) {
        ShellController.run("setsid -f " + exec + " >/dev/null 2>&1 &");
        ShellController.toggle("launcher");
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        MouseArea { anchors.fill: parent; onClicked: ShellController.toggle("launcher") }

        Rectangle {
            id: container
            anchors.centerIn: parent
            width: Math.min(parent.width - 120, root.columns * root.cellSize + root.innerPadding * 2)
            height: mainCol.implicitHeight + root.innerPadding * 2
            radius: 18
            color: root.bgColor
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            // Top blue-purple glow
            Rectangle {
                anchors.fill: parent
                radius: 18
                color: "transparent"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.2, 0.15, 0.5, 0.25) }
                    GradientStop { position: 0.3; color: Qt.rgba(0.1, 0.08, 0.3, 0.08) }
                    GradientStop { position: 0.6; color: "transparent" }
                }
            }

            ColumnLayout {
                id: mainCol
                anchors.fill: parent
                anchors.margins: root.innerPadding
                spacing: 0

                // ---- Search Bar ----
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.searchHeight
                    spacing: 8

                    // Apps icon (A symbol like TahoeLauncher)
                    Text {
                        text: "\udb80\udeb8"
                        font { pixelSize: 20; weight: Font.Bold }
                        color: root.dimmedFg
                        Layout.leftMargin: 4
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "Applications"
                        placeholderTextColor: root.dimmedFg
                        color: root.fgColor
                        font { family: Appearance.fontFamily; pixelSize: 18; weight: Font.Normal }
                        background: Rectangle { color: "transparent" }
                        focus: true
                        onTextChanged: {
                            root.searchText = text;
                            root.updateFiltered();
                        }
                        Keys.onEscapePressed: ShellController.toggle("launcher")
                    }

                    // Menu button (three dots like TahoeLauncher)
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: menuMa.pressed ? root.contrastBg : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "\u22ee"
                            font { pixelSize: 16 }
                            color: root.dimmedFg
                        }
                        MouseArea {
                            id: menuMa
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellController.toggle("session")
                        }
                    }
                }

                // ---- Category Pills ----
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.categoryHeight
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    ListView {
                        id: catListView
                        orientation: ListView.Horizontal
                        spacing: 7
                        anchors.fill: parent
                        anchors.topMargin: (parent.height - 26) / 2
                        model: root.categories

                        delegate: Rectangle {
                            property bool isSelected: root.selectedCategory === modelData
                            width: pillText.implicitWidth + 16
                            height: 26
                            radius: 8
                            color: isSelected ? root.pillSelectedBg : root.pillUnselectedBg

                            Text {
                                id: pillText
                                anchors.centerIn: parent
                                text: modelData
                                font { family: Appearance.fontFamily; pixelSize: 10; weight: Font.Medium }
                                color: isSelected ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(1, 1, 1, 0.4)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedCategory = modelData;
                                    root.updateFiltered();
                                }
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }

                // ---- App Grid ----
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    GridView {
                        id: appGrid
                        anchors.fill: parent
                        cellWidth: root.cellSize
                        cellHeight: root.cellSize + 10
                        model: root.filteredApps
                        focus: true
                        currentIndex: 0
                        highlightMoveDuration: 0

                        highlight: Rectangle {
                            radius: 14
                            color: "transparent"
                            border.width: 2
                            border.color: root.dimmedFg
                            opacity: 0.4
                        }
                        highlightFollowsCurrentItem: true

                        delegate: Item {
                            id: gridDelegate
                            width: appGrid.cellWidth
                            height: appGrid.cellHeight
                            property var appData: modelData

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                // Icon with drop shadow
                                Item {
                                    width: root.iconSize
                                    height: root.iconSize
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    // Shadow
                                    Rectangle {
                                        anchors.fill: appIconImg
                                        anchors.topMargin: 3
                                        radius: 16
                                        color: Qt.rgba(0, 0, 0, 0.35)
                                        scale: 0.92
                                    }

                                    Image {
                                        id: appIconImg
                                        anchors.centerIn: parent
                                        width: root.iconSize
                                        height: root.iconSize
                                        source: "file:///usr/share/icons/hicolor/64x64/apps/" + (gridDelegate.appData.icon || "application-x-executable") + ".png"
                                        sourceSize: Qt.size(width, height)
                                        asynchronous: true
                                        mipmap: true
                                        smooth: true
                                        onStatusChanged: {
                                            if (status === Image.Error) {
                                                source = "file:///usr/share/icons/hicolor/64x64/apps/application-x-executable.png";
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appGrid.currentIndex = index;
                                            root.launchApp(gridDelegate.appData.exec);
                                        }
                                    }
                                }

                                // App name
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: root.cellSize - 16
                                    text: gridDelegate.appData.name
                                    font { family: Appearance.fontFamily; pixelSize: 10; weight: 650 }
                                    color: root.fgColor
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideMiddle
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) ShellController.toggle("launcher");
        else if (event.key === Qt.Key_Up) appGrid.moveCurrentIndexUp();
        else if (event.key === Qt.Key_Down) appGrid.moveCurrentIndexDown();
        else if (event.key === Qt.Key_Left) appGrid.moveCurrentIndexLeft();
        else if (event.key === Qt.Key_Right) appGrid.moveCurrentIndexRight();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (appGrid.currentItem) root.launchApp(appGrid.currentItem.appData.exec);
        }
    }
}
