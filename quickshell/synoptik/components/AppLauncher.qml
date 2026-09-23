import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io

Item {
    id: appLauncherModule

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    property string pinFilePath: ""
    property var filteredApps: []
    property var localPins: []
    property var iconMap: ({})

    // Cached system icon indexer (loads ~/.cache/quickshell_icon_map.json or builds in background)
    Process {
        id: iconIndexer
        command: ["python3", "-c", `
import os, json

cache_file = os.path.expanduser("~/.cache/quickshell_icon_map.json")
if os.path.exists(cache_file):
    try:
        with open(cache_file, "r") as f:
            print(f.read())
            exit(0)
    except Exception:
        pass

dirs = [
    os.path.expanduser("~/.local/share/icons"),
    os.path.expanduser("~/.icons"),
    "/usr/share/icons/Papirus",
    "/usr/share/icons/Papirus-Dark",
    "/usr/share/icons/Papirus-Light",
    "/usr/share/icons/breeze",
    "/usr/share/icons/breeze-dark",
    "/usr/share/icons/Adwaita",
    "/usr/share/icons/hicolor",
    "/usr/share/pixmaps"
]
icon_map = {}
for d in dirs:
    if not os.path.isdir(d): continue
    for root, _, files in os.walk(d):
        if any(s in root for s in ["/16x16/", "/22x22/", "/24x24/", "/32x32/", "/symbolic/"]): continue
        for f in files:
            if f.endswith((".svg", ".png", ".xpm")):
                name = os.path.splitext(f)[0]
                if name not in icon_map:
                    icon_map[name] = os.path.join(root, f)

dumped = json.dumps(icon_map)
try:
    with open(cache_file, "w") as f:
        f.write(dumped)
except Exception:
    pass
print(dumped)
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let clean = this.text.trim()
                    if (clean) {
                        appLauncherModule.iconMap = JSON.parse(clean);
                        appLauncherModule.updateModel();
                    }
                } catch(e) {}
            }
        }
    }

    function getAppIcon(iconName) {
        if (!iconName) return Quickshell.iconPath("application-x-executable", true) || "";
        if (iconName.startsWith("/") || iconName.startsWith("file://")) {
            return iconName.startsWith("/") ? "file://" + iconName : iconName;
        }
        if (appLauncherModule.iconMap && appLauncherModule.iconMap[iconName]) {
            return "file://" + appLauncherModule.iconMap[iconName];
        }
        let qsPath = Quickshell.iconPath(iconName, true);
        if (qsPath) return qsPath;
        return Quickshell.iconPath("application-x-executable", true) || "";
    }

    // Clear search and refresh models when opened
    Connections {
        target: Config
        function onShowAppLauncherChanged() {
            if (Config.showAppLauncher) {
                searchInput.text = ""
                searchInput.forceActiveFocus()
                pinCacheReader.reload()
                appLauncherModule.updateModel()
            }
        }
    }

    // Reactively update application list when desktop entries are added, removed, or changed
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { appLauncherModule.updateModel(); }
        function onModelReset() { appLauncherModule.updateModel(); }
    }

    Process {
        id: initPinFile
        command: ["fish", "-c", "if not test -f ~/.cache/quickshell_launcher_pins.json; echo '{\"pins\":[]}'> ~/.cache/quickshell_launcher_pins.json; end"]
        running: true
        onExited: appLauncherModule.pinFilePath = Quickshell.env("HOME") + "/.cache/quickshell_launcher_pins.json"
    }

    FileView {
        id: pinCacheReader
        path: appLauncherModule.pinFilePath 
        onTextChanged: {
            let cleanText = text().trim();
            if (!cleanText || cleanText === "[]") return; 
            try {
                let parsed = JSON.parse(cleanText);
                if (parsed && parsed.pins) { 
                    appLauncherModule.localPins = parsed.pins;
                    appLauncherModule.updateModel(); 
                }
            } catch(e) {}
        }
    }

    function isAppPinned(app) {
        if (!app) return false;
        let pins = appLauncherModule.localPins;
        if (!pins || pins.length === 0) return false;
        let appId = app.id || "";
        return pins.includes(appId) || pins.some(p => p.endsWith("/" + appId + ".desktop") || p === appId);
    }

    function togglePin(app) {
        if (!app || !app.id) return;
        let appId = app.id;
        let currentPins = appLauncherModule.localPins.slice();
        let idx = currentPins.findIndex(p => p === appId || p.endsWith("/" + appId + ".desktop")); 
        if (idx !== -1) {
            currentPins.splice(idx, 1);
        } else { 
            currentPins.push(appId);
        } 
        appLauncherModule.localPins = currentPins;
        appLauncherModule.updateModel();
        
        let jsonStr = JSON.stringify({ "pins": currentPins }); 
        Quickshell.execDetached(["fish", "-c", "echo '" + jsonStr.replace(/'/g, "'\\''") + "' > ~/.cache/quickshell_launcher_pins.json"]);
    } 

    function updateModel() {
        let query = searchInput.text.trim().toLowerCase();
        let rawApps = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        let pins = []; 
        let others = [];

        for (let i = 0; i < rawApps.length; i++) {
            let app = rawApps[i];
            if (app.noDisplay) continue;

            if (query !== "") {
                let nameMatch = app.name && app.name.toLowerCase().includes(query);
                let genMatch = app.genericName && app.genericName.toLowerCase().includes(query);
                let descMatch = app.comment && app.comment.toLowerCase().includes(query);
                let catMatch = app.categories && app.categories.some(c => c.toLowerCase().includes(query));
                let kwMatch = app.keywords && app.keywords.some(k => k.toLowerCase().includes(query));

                if (!nameMatch && !genMatch && !descMatch && !catMatch && !kwMatch) continue;
            }

            if (appLauncherModule.isAppPinned(app)) {
                pins.push(app);
            } else { 
                others.push(app);
            } 
        }

        pins.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        others.sort((a, b) => (a.name || "").localeCompare(b.name || ""));

        appLauncherModule.filteredApps = pins.concat(others);
        
        if (appListView) {
            appListView.currentIndex = 0;
            appListView.positionViewAtBeginning();
        }
    } 

    function launchApp(app) {
        if (!app) return;
        if (typeof app.execute === "function") {
            app.execute();
        } else if (app.execString) {
            let cleanExec = app.execString.replace(/%[uUfFkKcCiI]/g, "").trim();
            Quickshell.execDetached(["fish", "-c", cleanExec]);
        }
        Config.showAppLauncher = false;
    }

    Component.onCompleted: appLauncherModule.updateModel()

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    ColumnLayout {
        id: mainLayout
        
        anchors.fill: parent
        anchors.margins: appLauncherModule.cardMargin
        
        spacing: appLauncherModule.cardMargin

        opacity: Config.showAppLauncher ? 1.0 : 0.0
        visible: Config.showAppLauncher || opacity > 0.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // ==========================================
        // APPLICATIONS CARD (Title + Search + List)
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 420
            implicitHeight: cardContentLayout.implicitHeight + (appLauncherModule.cardMargin * 2)
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            Watermark {
                icon: Config.getIcon("launcher")
                iconSize: 150
                seed: 14
            }

            ColumnLayout {
                id: cardContentLayout
                
                anchors.fill: parent
                anchors.margins: appLauncherModule.cardMargin
                
                spacing: appLauncherModule.cardMargin

                Item {
                    implicitWidth: appTitleText.implicitWidth
                    implicitHeight: appTitleText.implicitHeight
                    Layout.fillWidth: true

                    Glow {
                        anchors.fill: appTitleText
                        source: appTitleText
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    Text {
                        id: appTitleText
                        anchors.fill: parent
                        text: "APPLICATIONS"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle)
                        font.bold: true
                        font.italic: true
                    }
                }

                ColumnLayout {
                    id: innerColumn
                    Layout.fillWidth: true
                    spacing: appLauncherModule.cardMargin

                    // Search Input Surface
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Config.cornerRadius / 2
                        color: searchHover.hovered || searchInput.activeFocus ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.25)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: searchHover }

                        TapHandler {
                            onTapped: searchInput.forceActiveFocus()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "search"
                                color: searchInput.activeFocus ? Config.accent : Config.textMuted
                                font { family: "Material Symbols Outlined"; pixelSize: 18 }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                clip: true
                                selectByMouse: true
                                focus: true
                                Timer {
                                    running: Config.showAppLauncher
                                    interval: 50
                                    onTriggered: searchInput.forceActiveFocus()
                                }

                                HoverHandler { cursorShape: Qt.IBeamCursor }

                                Text {
                                    text: "Search apps..."
                                    color: Qt.rgba(255, 255, 255, 0.3)
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.italic: true
                                    visible: parent.text === "" && !parent.activeFocus
                                }

                                onTextChanged: appLauncherModule.updateModel() 

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Down) {
                                        appListView.incrementCurrentIndex();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Up) {
                                        appListView.decrementCurrentIndex();
                                        event.accepted = true; 
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (appListView.currentItem && appListView.currentItem.appObject) {
                                            appLauncherModule.launchApp(appListView.currentItem.appObject);
                                        } 
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        Config.showAppLauncher = false;
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    // App List View Frame Surface
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 340
                        radius: Config.cornerRadius / 2
                        color: Qt.rgba(0, 0, 0, 0.2)
                        clip: true

                        ListView {
                            id: appListView
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2 
                            keyNavigationEnabled: false
                            boundsBehavior: Flickable.StopAtBounds
                            model: appLauncherModule.filteredApps 
                            
                            delegate: Rectangle {
                                id: appDelegate
                                width: appListView.width 
                                implicitHeight: 54 
                                radius: Config.cornerRadius / 2
                                color: appListView.currentIndex === index 
                                    ? Qt.rgba(255, 255, 255, 0.12) 
                                    : (itemHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")
                                
                                property var appObject: modelData
                                property bool isPinned: appLauncherModule.isAppPinned(modelData)

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    Image { 
                                        Layout.preferredWidth: 32 
                                        Layout.preferredHeight: 32
                                        sourceSize.width: 32
                                        sourceSize.height: 32
                                        fillMode: Image.PreserveAspectFit
                                        source: appLauncherModule.getAppIcon(modelData.icon)
                                        asynchronous: true
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true 
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter 

                                        Text { 
                                            text: modelData.name || ""
                                            font.family: Config.sysFont 
                                            font.pixelSize: Config.size(Config.fontBody)
                                            color: Config.textMain 
                                            font.bold: appDelegate.isPinned
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: (modelData.comment && modelData.comment !== "") ? modelData.comment : ((modelData.genericName && modelData.genericName !== "") ? modelData.genericName : "Application")
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                            color: Config.textMuted
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        text: "keep" 
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: Config.accent
                                        visible: appDelegate.isPinned 
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                } 

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent 
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton 
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    property int lastScreenX: -1 
                                    property int lastScreenY: -1

                                    onPositionChanged: (mouse) => { 
                                        let currentX = Math.floor(mouse.screenX);
                                        let currentY = Math.floor(mouse.screenY);
                                        let deltaX = Math.abs(currentX - lastScreenX); 
                                        let deltaY = Math.abs(currentY - lastScreenY);
                                        if (lastScreenX !== -1 && (deltaX > 2 || deltaY > 2)) {
                                            if (appListView.currentIndex !== index) { 
                                                appListView.currentIndex = index;
                                            }
                                        }
                                        lastScreenX = currentX;
                                        lastScreenY = currentY; 
                                    }

                                    onExited: {
                                        lastScreenX = -1;
                                        lastScreenY = -1; 
                                    }

                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            appLauncherModule.togglePin(modelData);
                                        } else { 
                                            appLauncherModule.launchApp(modelData);
                                        }
                                    }
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                active: appListView.moving || appListView.flickableDirection
                                policy: ScrollBar.AsNeeded
                            }
                        } 
                    }
                }
            }
        }
    }
}